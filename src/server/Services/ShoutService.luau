--!strict
-- ShoutService.luau

local Players      = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Shared      = game.ReplicatedStorage.Shared
local Config      = require(Shared.Config)
local Types       = require(Shared.Types)
local Remotes     = require(Shared.Remotes)

local DataService: any = nil
task.defer(function()
	DataService = require(script.Parent.DataService)
end)

local MapService: any = nil
task.defer(function()
	MapService = require(script.Parent.MapService)
end)

local ShoutService = {}
local ShoutCooldowns: { [number]: number } = {}

local function getTotalAttack(data: Types.PlayerData): number
	local upgradeBonus = 0
	local atkUpgrades = Config.Upgrades[1] 
	local atkUpgrades2 = Config.Upgrades[2] 
	upgradeBonus = (data.AttackUpgradeLevel * atkUpgrades.StatPerLevel) + (data.SpeakerUpgradeLevel * atkUpgrades2.StatPerLevel)

	local petMult = 1
	for _, petData in ipairs(data.Pets) do
		if petData.Equipped then
			petMult *= petData.Multiplier
		end
	end

	return (data.Attack + upgradeBonus) * data.RebirthMultiplier * petMult
end

local function getTotalDefense(data: Types.PlayerData): number
	local defUpgrade1 = Config.Upgrades[3] 
	local defUpgrade2 = Config.Upgrades[4] 
	local bonus = (data.DefenseUpgradeLevel * defUpgrade1.StatPerLevel) + (data.ArmorUpgradeLevel * defUpgrade2.StatPerLevel)
	return data.Defense + bonus
end

local function calculateKnockback(attackerAtk : number, targetDef : number, direction : Vector3): Vector3
	local ratio = attackerAtk / math.max(1, targetDef)
	local rawForce = Config.Shout.BaseForce + (ratio * Config.Shout.KnockbackScaling)
	local capped   = math.min(rawForce, Config.Shout.MaxForce)

	local horizontalDir = Vector3.new(direction.X, 0, direction.Z).Unit
	local finalForce    = (horizontalDir + Vector3.new(0, Config.Shout.VerticalBias, 0)).Unit * capped

	return finalForce
end

type TargetHit = {
	Character: Model,
	Humanoid: Humanoid,
	RootPart: BasePart,
	IsPlayer: boolean,
	Player: Player?
}

local function getTargetsInShape(origin: CFrame, casterModel: Model, range: number, coneAngle: number): { TargetHit }
	local targets: { TargetHit } = {}
	local originPos  = origin.Position
	local lookVector = origin.LookVector
	local halfAngle  = math.rad(coneAngle)

	local function checkAndAdd(char: Model, isPlayer: boolean, ply: Player?)
		if char == casterModel then return end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
		if not hrp or not hum then return end

		local toTarget = (hrp.Position - originPos)
		local dist     = toTarget.Magnitude
		if dist > range then return end

		local angle = math.acos(math.clamp(lookVector:Dot(toTarget.Unit), -1, 1))
		if angle <= halfAngle then
			table.insert(targets, {
				Character = char,
				Humanoid = hum,
				RootPart = hrp,
				IsPlayer = isPlayer,
				Player = ply
			})
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then checkAndAdd(player.Character, true, player) end
	end

	for _, monster in ipairs(CollectionService:GetTagged("Monster")) do
		if monster:IsA("Model") then checkAndAdd(monster, false, nil) end
	end

	return targets
end

function ShoutService.PerformShout(casterChar: Model, totalAtk: number, direction: Vector3, isMonster: boolean, casterUserId: number?, powerMult: number?, shoutTypeConfig: any)
	local pMult = powerMult or 1.0
	local hrp = casterChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return 0 end

	if not isMonster and MapService and MapService.IsInSafeZone(hrp.Position) then return 0 end

	local originCFrame = CFrame.new(hrp.Position, hrp.Position + direction)
	
	local range = shoutTypeConfig and shoutTypeConfig.Range or Config.Shout.KnockbackRange
	local angle = shoutTypeConfig and shoutTypeConfig.Angle or Config.Shout.ConeAngle
	
	local targets = getTargetsInShape(originCFrame, casterChar, range, angle)
	local hitCount = 0

	for _, target in ipairs(targets) do
		local targetCharAct = target.Character
		local targetHRP = target.RootPart
		local targetHum = target.Humanoid

		if MapService and MapService.IsInSafeZone(targetHRP.Position) then continue end
		if isMonster and not target.IsPlayer then continue end 

		local totalDef = 10 
		if target.IsPlayer and target.Player then
			local targetData = DataService.GetData(target.Player) :: Types.PlayerData?
			if targetData then totalDef = getTotalDefense(targetData) end
		end

		local force = calculateKnockback(totalAtk * pMult, totalDef, direction)
		local ratio = (totalAtk * pMult) / math.max(1, totalDef)
		local damageTaken = ratio * Config.Shout.BaseDamage

		if not target.IsPlayer then
			targetCharAct:SetAttribute("LastDamagedBy", casterUserId)
			targetHum:TakeDamage(damageTaken)
		else
			targetHum:TakeDamage(damageTaken * 0.5) 
		end

		Remotes.Events.KnockbackOccurred:FireAllClients(targetCharAct, force, damageTaken, casterUserId)
		hitCount += 1

		-- Server xử lý physics văng cho Quái Vật (Tuyệt đối không áp dụng cho Player để tránh Server-Client Replication Snap)
		if not target.IsPlayer then
			local hum = targetHum
			if hum.Health > 0 then
				hum.AutoRotate = false
				hum:ChangeState(Enum.HumanoidStateType.Physics)
				targetHRP.AssemblyLinearVelocity = force + Vector3.new(0, 20, 0)
				
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
		Remotes.Events.MonsterShoutVFX:FireAllClients(CFrame.new(hrp.Position, hrp.Position + direction * 100), totalAtk)
		
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

local function onShoutFired(caster: Player, direction: Vector3, powerMult: number?)
	local pMult = math.clamp(powerMult or 1.0, 1.0, 5.0) -- Cap safety
	if not caster.Character then return end
	if direction.Magnitude < 0.01 then return end
	direction = direction.Unit

	if not DataService then return end
	local attackerData = DataService.GetData(caster) :: Types.PlayerData?
	if not attackerData then return end

	local shoutTypeId = attackerData.CurrentShoutType or "Normal"
	local shoutConfig = Config.ShoutTypes[shoutTypeId] or Config.ShoutTypes.Normal

	local now     = os.clock()
	local lastTime = ShoutCooldowns[caster.UserId] or 0
	if now - lastTime < shoutConfig.Cooldown then return end
	ShoutCooldowns[caster.UserId] = now

	local totalAtk = getTotalAttack(attackerData) * shoutConfig.DamageMult
	local hitCount = ShoutService.PerformShout(caster.Character, totalAtk, direction, false, caster.UserId, pMult, shoutConfig)

	local vpGain = (Config.Shout.VocalPointsPerUse * pMult) * attackerData.RebirthMultiplier
	if hitCount > 0 then
		vpGain += (Config.Shout.VocalPointsPerHit * hitCount * pMult) * attackerData.RebirthMultiplier
	end

	DataService.UpdateField(caster, "VocalPoints", attackerData.VocalPoints + vpGain)
	
	local QuestService = require(script.Parent.QuestService)
	QuestService.RegisterAction(caster, "Shout", 1)
end

Remotes.Events.ShoutFired.OnServerEvent:Connect(function(player: Player, ...)
	local args = { ... }
	local direction = args[1]
	local pMult     = args[2]
	if typeof(direction) == "Vector3" then
		onShoutFired(player, direction, tonumber(pMult))
	end
end)

Remotes.Events.SetShoutType.OnServerEvent:Connect(function(player: Player, ...)
	local args = { ... }
	local shoutType = args[1]
	if type(shoutType) == "string" and Config.ShoutTypes[shoutType] then
		if not DataService then return end
		local data = DataService.GetData(player)
		if data then
			DataService.UpdateField(player, "CurrentShoutType", shoutType)
		end
	end
end)

return ShoutService
