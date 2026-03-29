--!strict
-- MonsterService.luau
-- Server-side: Spawn quái vật, AI đơn giản, drop Gold/Egg khi chết

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local Remotes = require(Shared.Remotes)

local DataService: any = nil
task.defer(function()
	DataService = require(script.Parent.DataService)
end)

local _MapService: any = nil
task.defer(function()
	_MapService = require(script.Parent.MapService)
end)

local MonsterService = {}

-- Track instances đang sống
-- Track instances đang sống
type MonsterAIState = "IDLE" | "WANDER" | "CHASE" | "ATTACK" | "RETURN"

type MonsterInstance = {
	Model: Model,
	Config: Types.MonsterConfig,
	CurrentHP: number,
	IsAlive: boolean,
	LastAttackTime: number,
	State: MonsterAIState,

	SpawnPos: Vector3,
	ZoneCenter: Vector3,
	ZoneSize: Vector3,
	LastUpdate: number,
	TargetPos: Vector3?,
	LastPosition: Vector3,
	StuckTime: number,
}

local ActiveMonsters: { [Model]: MonsterInstance } = {}

-- ============================================================
-- HELPER: Tạo model quái đơn giản (placeholder - dev thêm model sau)
-- ============================================================
local function createMonsterModel(cfg: Types.MonsterConfig, position: Vector3): Model?
	-- Tìm zone trong workspace
	local zoneFolder = Workspace:WaitForChild(cfg.SpawnZone, 10)
	if not zoneFolder then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = cfg.Id

	-- Main body
	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Position = position

	if cfg.Id == "ScreechSlime" then
		body.Size = Vector3.new(4, 4, 4)
		body.Shape = Enum.PartType.Ball
		body.BrickColor = BrickColor.new("Lime green")
		body.Material = Enum.Material.Neon

		-- Eyes
		for i = -1, 1, 2 do
			local eye = Instance.new("Part")
			eye.Size = Vector3.new(0.5, 0.5, 0.5)
			eye.Shape = Enum.PartType.Ball
			eye.Color = Color3.fromRGB(0, 0, 0)
			eye.Parent = model

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = eye
			weld.Parent = body
			eye.Position = body.Position + Vector3.new(i * 0.8, 0.5, -1.8)
		end
	elseif cfg.Id == "BoomGolem" then
		body.Size = Vector3.new(5, 6, 5)
		body.BrickColor = BrickColor.new("Dark stone grey")
		body.Material = Enum.Material.Slate

		-- Arms
		for i = -1, 1, 2 do
			local arm = Instance.new("Part")
			arm.Size = Vector3.new(2, 4, 2)
			arm.BrickColor = BrickColor.new("Sand red")
			arm.Material = Enum.Material.Granite
			arm.Parent = model

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = arm
			weld.Parent = body
			arm.Position = body.Position + Vector3.new(i * 3.5, 0, 0)
		end
		-- Head
		local head = Instance.new("Part")
		head.Size = Vector3.new(3, 3, 3)
		head.BrickColor = BrickColor.new("Dark stone grey")
		head.Material = Enum.Material.Slate
		head.Parent = model
		local headWeld = Instance.new("WeldConstraint")
		headWeld.Part0 = body
		headWeld.Part1 = head
		headWeld.Parent = body
		head.Position = body.Position + Vector3.new(0, 4.5, 0)
	elseif cfg.Id == "SoundKing" then
		body.Size = Vector3.new(6, 8, 6)
		body.Color = Color3.fromRGB(255, 215, 0) -- Gold
		body.Material = Enum.Material.Foil

		-- Crown
		local crown = Instance.new("Part")
		crown.Size = Vector3.new(4, 2, 4)
		crown.Color = Color3.fromRGB(255, 255, 0)
		crown.Material = Enum.Material.Neon
		crown.Parent = model
		local crownWeld = Instance.new("WeldConstraint")
		crownWeld.Part0 = body
		crownWeld.Part1 = crown
		crownWeld.Parent = body
		crown.Position = body.Position + Vector3.new(0, 5, 0)

		-- Cape
		local cape = Instance.new("Part")
		cape.Size = Vector3.new(6, 7, 1)
		cape.Color = Color3.fromRGB(200, 0, 0)
		cape.Material = Enum.Material.Fabric
		cape.Parent = model
		local capeWeld = Instance.new("WeldConstraint")
		capeWeld.Part0 = body
		capeWeld.Part1 = cape
		capeWeld.Parent = body
		cape.Position = body.Position + Vector3.new(0, 0.5, 3.5)
	elseif cfg.Id == "EchoToad" then
		body.Size = Vector3.new(5, 3, 5)
		body.BrickColor = BrickColor.new("Earth green")
		body.Material = Enum.Material.Grass
	elseif cfg.Id == "DustDevil" then
		body.Size = Vector3.new(3, 8, 3)
		body.BrickColor = BrickColor.new("Brick yellow")
		body.Material = Enum.Material.Sand
	elseif cfg.Id == "SandGolem" then
		body.Size = Vector3.new(6, 7, 6)
		body.BrickColor = BrickColor.new("Deep orange")
		body.Material = Enum.Material.Slate
	elseif cfg.Id == "IcyWraith" then
		body.Size = Vector3.new(3, 6, 3)
		body.BrickColor = BrickColor.new("Pastel light blue")
		body.Material = Enum.Material.Ice
		body.Transparency = 0.5
	elseif cfg.Id == "FrostGiant" then
		body.Size = Vector3.new(8, 10, 8)
		body.BrickColor = BrickColor.new("Cyan")
		body.Material = Enum.Material.Ice
	elseif cfg.Id == "VoidSerpent" then
		body.Size = Vector3.new(4, 12, 4)
		body.BrickColor = BrickColor.new("Royal purple")
		body.Material = Enum.Material.Neon
	elseif cfg.Id == "ShadowBeast" then
		body.Size = Vector3.new(7, 6, 8)
		body.BrickColor = BrickColor.new("Really black")
		body.Material = Enum.Material.Granite
	elseif cfg.Id == "DivineGuardian" then
		body.Size = Vector3.new(8, 12, 8)
		body.BrickColor = BrickColor.new("Institutional white")
		body.Material = Enum.Material.Neon
	elseif cfg.Id == "IceColossus" then
		body.Size = Vector3.new(12, 16, 12)
		body.BrickColor = BrickColor.new("Toothpaste")
		body.Material = Enum.Material.Ice
	else
		-- Fallback placeholder
		body.Size = Vector3.new(4, 5, 4)
		body.BrickColor = BrickColor.new("Bright red")
	end

	body.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = cfg.MaxHP
	humanoid.Health = cfg.MaxHP
	humanoid.WalkSpeed = cfg.MovementSpeed
	humanoid.DisplayName = cfg.DisplayName
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model

	-- Set attributes for ShoutService lookup
	model:SetAttribute("Defense", cfg.Defense)
	model:SetAttribute("KnockbackResistance", cfg.KnockbackResistance or 0)

	-- Health display bar
	local billGui = Instance.new("BillboardGui")
	billGui.Size = UDim2.new(4, 0, 0.7, 0)
	billGui.StudsOffset = Vector3.new(0, body.Size.Y / 2 + 1.5, 0)
	billGui.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = cfg.DisplayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = billGui

	local healthBg = Instance.new("Frame")
	healthBg.Name = "HealthBg"
	healthBg.Size = UDim2.new(1, 0, 0.3, 0)
	healthBg.Position = UDim2.new(0, 0, 0.7, 0)
	healthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = billGui

	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthBg

	CollectionService:AddTag(model, "Monster")

	model.PrimaryPart = body
	-- model:ScaleTo(0.01)
	model.Parent = Workspace

	-- Spawn Effect
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Position = body.Position
	p.Parent = Workspace
	local attachment = Instance.new("Attachment", p)
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(body.Color)
	particles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0) })
	particles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Speed = NumberRange.new(5, 15)
	particles.Rate = 0
	particles.Parent = attachment
	particles:Emit(30)
	game.Debris:AddItem(p, 2)

	print("[MonsterService] Created model for:", cfg.Id, "at", body.Position)

	return model
end

-- Drop reward khi quái chết
local function dropRewards(cfg: Types.MonsterConfig, position: Vector3, killerPlayer: Player?)
	if not killerPlayer then
		return
	end
	if not DataService then
		return
	end

	local data = DataService.GetData(killerPlayer) :: Types.PlayerData?
	if not data then
		return
	end

	local updates: { [string]: any } = {
		Gold = data.Gold + cfg.GoldDrop,
	}

	-- Egg drop
	if math.random() <= cfg.EggDropChance then
		-- Tặng 1 trứng = roll 1 pet ngay (simplification: có thể làm physical egg sau)
		Remotes.Events.Notification:FireClient(killerPlayer, Config.Localization.Notifications.EggDropped)
		-- PetService sẽ handle trực tiếp trên server
		local PetService = require(script.Parent.PetService)
		PetService.OnOpenEgg(killerPlayer, 1)
	end

	DataService.UpdateFields(killerPlayer, updates)
	Remotes.Events.Notification:FireClient(
		killerPlayer,
		string.format(Config.Localization.Notifications.MonsterKilled, cfg.DisplayName, cfg.GoldDrop)
	)

	-- Gold dropping effect
	local coin = Instance.new("Part")
	coin.Size = Vector3.new(1.5, 1.5, 1.5)
	coin.Position = position + Vector3.new(0, 2, 0)
	coin.Anchored = false
	coin.CanCollide = false
	coin.Color = Color3.fromRGB(255, 215, 0)
	coin.Material = Enum.Material.Neon
	coin.Shape = Enum.PartType.Ball
	coin.Parent = Workspace

	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	pe.Size = NumberSequence.new(0.5, 0)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.Speed = NumberRange.new(5, 15)
	pe.Parent = coin
	pe:Emit(20)

	game:GetService("Debris"):AddItem(coin, 2)
end

-- ============================================================
-- SPAWN MONSTER
-- ============================================================
-- ============================================================
-- SPAWN MONSTER
-- ============================================================
local function spawnMonster(cfg: Types.MonsterConfig)
	-- Tìm vị trí spawn trong zone
	local zoneFolder = Workspace:WaitForChild(cfg.SpawnZone, 10)
	local spawnPos = Vector3.new(0, 5, 0)
	local zoneCenter = Vector3.new(0, 0, 0)
	local zoneSizeX = 150
	local zoneSizeZ = 150

	if zoneFolder then
		local base = zoneFolder:FindFirstChild("Base") :: BasePart?
		if base then
			zoneCenter = base.Position
			zoneSizeX = base.Size.X
			zoneSizeZ = base.Size.Z

			spawnPos = zoneCenter
				+ Vector3.new(
					math.random(-math.floor(zoneSizeX / 2) + 5, math.floor(zoneSizeX / 2) - 5),
					5,
					math.random(-math.floor(zoneSizeZ / 2) + 5, math.floor(zoneSizeZ / 2) - 5)
				)
		end
	end

	local model = createMonsterModel(cfg, spawnPos)
	if not model then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hrp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") :: BasePart

	-- CRITICAL: Prevent network ownership jitter
	if hrp:CanSetNetworkOwnership() then
		hrp:SetNetworkOwner(nil)
	end



	local instance: MonsterInstance = {
		Model = model,
		Config = cfg,
		CurrentHP = cfg.MaxHP,
		IsAlive = true,
		LastAttackTime = 0,
		State = "IDLE",
		SpawnPos = spawnPos,
		ZoneCenter = zoneCenter,
		ZoneSize = Vector3.new(zoneSizeX, 0, zoneSizeZ),
		LastUpdate = 0,
		TargetPos = nil,
		LastPosition = spawnPos,
		StuckTime = 0,
	}

	ActiveMonsters[model] = instance

	-- Damage handler
	if humanoid then
		humanoid.HealthChanged:Connect(function(newHP)
			if not instance.IsAlive then
				return
			end
			instance.CurrentHP = newHP

			-- Cập nhật thanh máu mượt mà
			local rootPart = model:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local bGui = rootPart:FindFirstChildOfClass("BillboardGui")
				if bGui then
					local hBg = bGui:FindFirstChild("HealthBg")
					if hBg then
						local hBar = hBg:FindFirstChild("HealthBar") :: GuiObject?
						if hBar then
							local pct = math.clamp(newHP / cfg.MaxHP, 0, 1)
							TweenService:Create(hBar, TweenInfo.new(0.2), { Size = UDim2.new(pct, 0, 1, 0) }):Play()
							hBar.BackgroundColor3 = Color3.fromRGB(255 - (205 * pct), 50 + (205 * pct), 50)
						end
					end
				end
			end

			if newHP <= 0 then
				instance.IsAlive = false

				-- Chỉ nhận quà nếu được kết liễu bởi Player (LastDamagedBy)
				local killer: Player? = nil
				local lastDamagedById = model:GetAttribute("LastDamagedBy")
				if lastDamagedById then
					killer = Players:GetPlayerByUserId(lastDamagedById)
				end

				dropRewards(cfg, spawnPos, killer)

				-- Set Dying attribute so client can play an animation
				model:SetAttribute("Dying", true)

				-- Delay destruction to allow for client-side VFX (e.g., Ripple squash/fade)
				task.delay(1.0, function()
					if model and model.Parent then
						model:Destroy()
					end
				end)

				-- Remove from active
				ActiveMonsters[model] = nil

				-- Respawn sau interval
				task.delay(Config.MonsterRespawnTime, function()
					spawnMonster(cfg)
				end)
			end
		end)
	end
end

-- ============================================================
-- INIT: Spawn tất cả monsters khi server start
-- ============================================================
function MonsterService.Init()
	for _, cfg in ipairs(Config.Monsters) do
		task.spawn(spawnMonster, cfg)
	end

	-- Centralized AI Loop with Proximity Culling
	game:GetService("RunService").Heartbeat:Connect(function()
		local now = os.clock()
		local allPlayers = Players:GetPlayers()

		for model, instance in pairs(ActiveMonsters) do
			-- Throttle updates (5Hz for normal, faster for bosses)
			local updateRate = if instance.Config.IsBoss then 0.1 else 0.2
			if now - (instance.LastUpdate or 0) < updateRate then
				continue
			end
			instance.LastUpdate = now

			local hrp = model.PrimaryPart :: BasePart?
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if not hrp or not humanoid or humanoid.Health <= 0 then
				continue
			end

			-- 1. Proximity Culling: Don't process AI if no player is nearby
			local nearestPlayer: Player? = nil
			local minDist = 300 -- Massive cull radius
			local activeDist = instance.Config.AggroRange or (if instance.Config.IsBoss then 100 else 30)

			for _, p in ipairs(allPlayers) do
				local c = p.Character
				local phrp = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
				if phrp then
					local d = (phrp.Position - hrp.Position).Magnitude
					if d < minDist then
						minDist = d
						if d < activeDist then
							nearestPlayer = p
						end
					end
				end
			end

			-- Culling check
			if minDist > 300 and instance.State == "IDLE" then
				continue
			end

			-- 2. Stuck Detection & Auto-Jump
			local distMoved = (hrp.Position - instance.LastPosition).Magnitude
			local isIdle = (instance.State :: string) == "IDLE"
			local isAttack = (instance.State :: string) == "ATTACK"
			
			if not isIdle and not isAttack then
				if distMoved < 0.2 then
					instance.StuckTime += updateRate
					if instance.StuckTime > 0.5 then
						humanoid.Jump = true
						instance.StuckTime = 0
					end
				else
					instance.StuckTime = 0
				end
			end
			instance.LastPosition = hrp.Position

			-- 3. AI Logic
			if humanoid.PlatformStand then
				humanoid:MoveTo(hrp.Position) 
				continue
			end

			local zoneCenter = instance.ZoneCenter
			local zoneSizeX = instance.ZoneSize.X
			local zoneSizeZ = instance.ZoneSize.Z

			-- Leashing logic: Force return if too far
			local flatPos = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
			local flatCenter = Vector3.new(zoneCenter.X, 0, zoneCenter.Z)
			local distFromZoneCenter = (flatPos - flatCenter).Magnitude
			local leashRange = (math.max(zoneSizeX, zoneSizeZ) / 2) + 20

			if distFromZoneCenter > leashRange then
				instance.State = "RETURN"
			end

			-- canAggro check
			local canAggro = true
			local distFromSpawn = (hrp.Position - instance.SpawnPos).Magnitude
			if instance.State == "RETURN" then
				if distFromSpawn > 5 then
					canAggro = false
				else
					instance.State = "IDLE"
					instance.TargetPos = nil
				end
			end

			if canAggro and nearestPlayer and nearestPlayer.Character then
				local targetHrp = nearestPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if targetHrp then
					local distToTarget = (hrp.Position - targetHrp.Position).Magnitude
					local attackRange = Config.Shout.KnockbackRange - 4

					if distToTarget <= attackRange then
						instance.State = "ATTACK"
						humanoid:MoveTo(hrp.Position)
						instance.TargetPos = nil
						humanoid.AutoRotate = false

						-- Smooth Rotation for Attack
						local lookDir = (targetHrp.Position - hrp.Position).Unit
						local targetCF = CFrame.lookAt(hrp.Position, hrp.Position + Vector3.new(lookDir.X, 0, lookDir.Z))
						hrp.CFrame = hrp.CFrame:Lerp(targetCF, 0.3)

						if now - instance.LastAttackTime >= 3.0 then
							instance.LastAttackTime = now
							TweenService:Create(hrp, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), { Color = Color3.new(1, 0, 0) }):Play()
							task.delay(0.6, function()
								if not instance.IsAlive or not model.Parent then return end
								local shoutType = if instance.Config.IsBoss and instance.CurrentHP < instance.Config.MaxHP * 0.5 then Config.ShoutTypes.Circular else Config.ShoutTypes.Normal
								local ShoutService = require(script.Parent.ShoutService)
								ShoutService.PerformShout(model, instance.Config.Attack, lookDir, true, nil, nil, shoutType)
							end)
						end
					else
						instance.State = "CHASE"
						instance.TargetPos = nil
						humanoid.AutoRotate = true
						humanoid:MoveTo(targetHrp.Position)
					end
				end
			else
				-- Idle / Wander / Return
				if instance.State == "RETURN" then
					humanoid.AutoRotate = true
					humanoid:MoveTo(instance.SpawnPos)
				elseif instance.State == "WANDER" then
					humanoid.AutoRotate = true
					if not instance.TargetPos then
						instance.TargetPos = zoneCenter + Vector3.new(math.random(-zoneSizeX/2 + 10, zoneSizeX/2 - 10), 0, math.random(-zoneSizeZ/2 + 10, zoneSizeZ/2 - 10))
					end
					humanoid:MoveTo(instance.TargetPos :: Vector3)
					if (hrp.Position - (instance.TargetPos :: Vector3)).Magnitude < 5 then
						instance.State = "IDLE"
						instance.TargetPos = nil
					end
				else
					if math.random() > 0.98 then -- Lower wander chance
						instance.State = "WANDER"
					else
						instance.State = "IDLE"
						humanoid:MoveTo(hrp.Position)
					end
				end
			end
		end
	end)

	print("[MonsterService] Initialized with Centralized Loop and Proximity Culling")
end

return MonsterService
