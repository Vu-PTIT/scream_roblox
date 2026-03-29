--!strict
-- ShoutService.luau

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local Remotes = require(Shared.Remotes)

local DataService: any = nil
task.defer(function()
	DataService = require(script.Parent.DataService)
end)

local MapService: any = nil
task.defer(function()
	MapService = require(script.Parent.MapService)
end)

local ShoutService = {}
local ShoutCooldowns: { [string]: number } = {}

local function getTotalAttack(data: Types.PlayerData): number
	local upgradeCfg = Config.GetUpgrade("damage_1")
	local upgradeBonus = data.DamageUpgradeLevel * (upgradeCfg and upgradeCfg.StatPerLevel or 5)

	local petBonus = 0
	for _, petData in ipairs(data.Pets) do
		if petData.Equipped then
			petBonus += (petData.Multiplier - 1)
		end
	end
	local petMult = math.min(1 + petBonus, 3.0)  -- hard cap ×3

	return (data.Attack + upgradeBonus) * petMult
end

local function getTotalDefense(data: Types.PlayerData): number
	local upgradeCfg = Config.GetUpgrade("armor_1")
	local bonus = data.ArmorUpgradeLevel * (upgradeCfg and upgradeCfg.StatPerLevel or 10)
	return data.Defense + bonus
end

local function calculateKnockback(
	attackerAtk: number,
	targetDef: number,
	direction: Vector3,
	resistance: number?
): Vector3
	local res = resistance or 0
	local flatComponent = attackerAtk * 0.2 -- Reduced from 0.4

	-- New formula: use power function (0.7) to dampen extreme ratios
	local baseRatio = (attackerAtk / math.max(1, targetDef))
	local ratioComponent = math.pow(baseRatio, 0.7) * Config.Shout.KnockbackScaling

	local rawForce = (Config.Shout.BaseForce + flatComponent + ratioComponent) * (1 - res)
	local capped = math.min(rawForce, Config.Shout.MaxForce)

	local horizontalDir = Vector3.new(direction.X, 0, direction.Z).Unit
	local finalForce = (horizontalDir + Vector3.new(0, Config.Shout.VerticalBias, 0)).Unit * capped

	return finalForce
end

type TargetHit = {
	Character: Model,
	Humanoid: Humanoid,
	RootPart: BasePart,
	IsPlayer: boolean,
	Player: Player?,
}

local function getTargetsInShape(origin: CFrame, casterModel: Model, range: number, coneAngle: number): { TargetHit }
	local targets: { TargetHit } = {}
	local originPos = origin.Position
	local lookVector = origin.LookVector
	local halfAngle = math.rad(coneAngle)

	local function checkAndAdd(char: Model, isPlayer: boolean, ply: Player?)
		if char == casterModel then
			return
		end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
		if not hrp or not hum then
			return
		end

		local toTarget = (hrp.Position - originPos)
		local dist = toTarget.Magnitude
		if dist > range then
			return
		end

		local angle = math.acos(math.clamp(lookVector:Dot(toTarget.Unit), -1, 1))
		if angle <= halfAngle then
			table.insert(targets, {
				Character = char,
				Humanoid = hum,
				RootPart = hrp,
				IsPlayer = isPlayer,
				Player = ply,
			})
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			checkAndAdd(player.Character, true, player)
		end
	end

	for _, monster in ipairs(CollectionService:GetTagged("Monster")) do
		if monster:IsA("Model") then
			checkAndAdd(monster, false, nil)
		end
	end

	return targets
end

function ShoutService.PerformShout(
	casterChar: Model,
	totalAtk: number,
	direction: Vector3,
	isMonster: boolean,
	casterUserId: number?,
	powerMult: number?,
	shoutTypeConfig: any
)
	local pMult = powerMult or 1.0
	local hrp = casterChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return 0
	end

	if not isMonster and MapService and MapService.IsInSafeZone(hrp.Position) then
		return 0
	end

	local originCFrame = CFrame.new(hrp.Position, hrp.Position + direction)

	local baseRange = shoutTypeConfig and shoutTypeConfig.Range or Config.Shout.KnockbackRange
	local range = baseRange * math.pow(pMult, 0.45) -- Scale range by power (sqrt-ish)
	local angle = shoutTypeConfig and shoutTypeConfig.Angle or Config.Shout.ConeAngle

	local targets = getTargetsInShape(originCFrame, casterChar, range, angle)
	local hitCount = 0

	for _, target in ipairs(targets) do
		local targetCharAct = target.Character
		local targetHRP = target.RootPart
		local targetHum = target.Humanoid

		if MapService and MapService.IsInSafeZone(targetHRP.Position) then
			continue
		end
		if isMonster and not target.IsPlayer then
			continue
		end

		local totalDef = 10
		local knockbackRes = 0

		if target.IsPlayer and target.Player then
			local targetData = DataService.GetData(target.Player) :: Types.PlayerData?
			if targetData then
				totalDef = getTotalDefense(targetData)
			end
		else
			-- Lấy chỉ số thực tế của quái từ Attribute
			totalDef = (targetCharAct:GetAttribute("Defense") :: number) or 10
			knockbackRes = (targetCharAct:GetAttribute("KnockbackResistance") :: number) or 0
		end

		local force = calculateKnockback(totalAtk * pMult, totalDef, direction, knockbackRes)
		local ratio = (totalAtk * pMult) / math.max(1, totalDef)
		local damageTaken = ratio * Config.Shout.BaseDamage

		if not target.IsPlayer then
			targetCharAct:SetAttribute("LastDamagedBy", casterUserId)
			targetHum:TakeDamage(damageTaken)
			print(string.format("[ShoutService] HIT MONSTER: %s | Damage: %.1f", targetCharAct.Name, damageTaken))
		else
			-- Monster attacks on players are more punishing (1.5x), PvP is reduced (0.5x)
			local finalDamage = if isMonster then math.max(1, damageTaken * 1.5) else damageTaken * 0.5
			targetHum:TakeDamage(finalDamage)
			print(
				string.format(
					"[ShoutService] HIT PLAYER: %s | Damage: %.1f (Attacker isMonster: %s)",
					targetCharAct.Name,
					finalDamage,
					tostring(isMonster)
				)
			)
		end

		Remotes.Events.KnockbackOccurred:FireAllClients(targetCharAct, force, damageTaken, casterUserId)
		hitCount += 1

		-- Server xử lý physics văng cho Quái Vật (Tuyệt đối không áp dụng cho Player để tránh Server-Client Replication Snap)
		if not target.IsPlayer then
			local hum = targetHum
			if hum.Health > 0 then
				hum.AutoRotate = false
				hum:ChangeState(Enum.HumanoidStateType.Physics)

				-- Giảm lực đẩy Y thêm vào (trước là 20) để quái không bay quá cao
				targetHRP.AssemblyLinearVelocity = force + Vector3.new(0, 10, 0)

				task.delay(0.6, function()
					if hum and hum.Parent and hum.Health > 0 then
						hum.AutoRotate = true
						hum:ChangeState(Enum.HumanoidStateType.GettingUp)
					end
				end)
			end
		end
	end

	if isMonster then
		local sType = shoutTypeConfig and shoutTypeConfig.Id or "Normal"
		local Refx = require(Shared.Refx)
		Refx.Fire("MonsterShoutVFX", hrp.Position, direction * 100, totalAtk, sType)

		if Config.Audio and Config.Audio.ShoutSFX and Config.Audio.ShoutSFX ~= "" then
			local sound = Instance.new("Sound")
			sound.SoundId = Config.Audio.ShoutSFX
			sound.Volume = 0.8
			sound.RollOffMaxDistance = 60
			sound.Parent = hrp
			sound:Play()
			game:GetService("Debris"):AddItem(sound, 3)
		end
	end

	return hitCount
end

local function onShoutFired(caster: Player, direction: Vector3, powerMult: number?, slotIndex: number?)
	-- powerMult sẽ được validate và clamp dựa trên timing bên dưới
	if not caster.Character then
		return
	end
	if direction.Magnitude < 0.01 then
		return
	end
	direction = direction.Unit

	if not DataService then
		return
	end
	local attackerData = DataService.GetData(caster) :: Types.PlayerData?
	if not attackerData then
		return
	end

	local sIndex = slotIndex or 0
	local skillConfig: Types.SkillConfig? = nil

	if sIndex == 0 then
		-- Basic Attack (Normal Click)
		for _, cfg in ipairs(Config.Skills) do
			if cfg.IsBasic then
				skillConfig = cfg
				break
			end
		end
	else
		-- Gacha Skill (Phím 1, 2)
		local skillId = attackerData.EquippedSkillIds[sIndex] or (attackerData.EquippedSkillIds :: any)[tostring(sIndex)]
		if skillId then
			for _, skill in ipairs(attackerData.Skills) do
				if skill.Id == skillId then
					for _, cfg in ipairs(Config.Skills) do
						if cfg.SkillType == skill.SkillType then
							skillConfig = cfg
							break
						end
					end
					break
				end
			end
		end
	end

	if not skillConfig then
		-- Fallback về skill đầu tiên nếu không tìm thấy
		skillConfig = Config.Skills[1]
	end

	local finalSkillConfig = skillConfig :: Types.SkillConfig

	local now = os.clock()
	local lastTime = ShoutCooldowns[caster.UserId .. "_" .. sIndex] or 0
	local elapsedSinceLast = now - lastTime
	if elapsedSinceLast < finalSkillConfig.Cooldown then
		return
	end

	-- [SECURITY] Validate powerMult based on time since last shout
	local chargeTimePossible = math.max(0, elapsedSinceLast - finalSkillConfig.Cooldown)
	local maxMultPossible = 1.0
	for _, lvl in ipairs(Config.Shout.Charge.Levels) do
		if chargeTimePossible >= (lvl.Time * 0.9) then -- 10% buffer for latency
			maxMultPossible = lvl.Mult
		end
	end

	local pMult = math.clamp(powerMult or 1.0, 1.0, maxMultPossible)
	ShoutCooldowns[caster.UserId .. "_" .. sIndex] = now

	local shoutTypeConfig = Config.ShoutTypes[finalSkillConfig.ShoutTypeId] or Config.ShoutTypes.Normal
	local totalAtk = getTotalAttack(attackerData) * finalSkillConfig.DamageMult

	print(
		"[ShoutService] Caster:",
		caster.Name,
		"Skill:",
		finalSkillConfig.DisplayName,
		"TotalAtk:",
		totalAtk,
		"pMult:",
		pMult
	)

	local hitCount =
		ShoutService.PerformShout(caster.Character, totalAtk, direction, false, caster.UserId, pMult, shoutTypeConfig)

	local vpGain = (Config.Shout.VocalPointsPerUse * pMult)
	if hitCount > 0 then
		vpGain += (Config.Shout.VocalPointsPerHit * hitCount * pMult)
	end

	DataService.UpdateFields(caster, {
		VocalPoints = attackerData.VocalPoints + vpGain,
		TotalVocalPoints = (attackerData.TotalVocalPoints or 0) + vpGain,
	})

	local QuestService = require(script.Parent.QuestService)
	QuestService.RegisterAction(caster, "Shout", 1)
end

Remotes.Events.ShoutFired.OnServerEvent:Connect(function(player: Player, ...)
	local args = { ... }
	local direction = args[1]
	local pMult = args[2]
	local slotIndex = args[3]
	if typeof(direction) == "Vector3" and type(pMult) == "number" then
		onShoutFired(player, direction, pMult, type(slotIndex) == "number" and slotIndex or 1)
	end
end)

return ShoutService
