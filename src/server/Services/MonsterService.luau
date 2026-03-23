--!strict
-- MonsterService.luau
-- Server-side: Spawn quái vật, AI đơn giản, drop Gold/Egg khi chết

local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")

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

local MonsterService = {}

-- Track instances đang sống
type MonsterInstance = {
	Model     : Model,
	Config    : Types.MonsterConfig,
	CurrentHP : number,
	IsAlive   : boolean,
	LastAttackInfo : number?,
}

local ActiveMonsters: { MonsterInstance } = {}

-- ============================================================
-- HELPER: Tạo model quái đơn giản (placeholder - dev thêm model sau)
-- ============================================================
local function createMonsterModel(cfg: Types.MonsterConfig, position: Vector3): Model?
	-- Tìm zone trong workspace
	local zoneFolder = Workspace:WaitForChild(cfg.SpawnZone, 10)
	if not zoneFolder then return nil end

	local model = Instance.new("Model")
	model.Name = cfg.Id

	-- Main body
	local body = Instance.new("Part")
	body.Name      = "HumanoidRootPart"
	body.Position  = position

	if cfg.Id == "ScreechSlime" then
		body.Size      = Vector3.new(4, 4, 4)
		body.Shape     = Enum.PartType.Ball
		body.BrickColor = BrickColor.new("Lime green")
		body.Material  = Enum.Material.Neon
		
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
		body.Size      = Vector3.new(5, 6, 5)
		body.BrickColor = BrickColor.new("Dark stone grey")
		body.Material  = Enum.Material.Slate

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
		body.Size      = Vector3.new(6, 8, 6)
		body.Color = Color3.fromRGB(255, 215, 0) -- Gold
		body.Material  = Enum.Material.Foil

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
	
	else
		-- Fallback placeholder
		body.Size      = Vector3.new(4, 5, 4)
		body.BrickColor = BrickColor.new("Bright red")
	end

	body.Parent    = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth   = cfg.MaxHP
	humanoid.Health      = cfg.MaxHP
	humanoid.WalkSpeed   = cfg.MovementSpeed
	humanoid.DisplayName = cfg.DisplayName
	humanoid.Parent      = model

	-- Health display bar
	local billGui       = Instance.new("BillboardGui")
	billGui.Size        = UDim2.new(4, 0, 0.7, 0)
	billGui.StudsOffset = Vector3.new(0, body.Size.Y/2 + 1.5, 0)
	billGui.Parent      = body

	local nameLabel        = Instance.new("TextLabel")
	nameLabel.Size         = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text         = cfg.DisplayName
	nameLabel.TextColor3   = Color3.fromRGB(255, 80, 80)
	nameLabel.Font         = Enum.Font.GothamBold
	nameLabel.TextScaled   = true
	nameLabel.Parent       = billGui

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
	model.Parent      = Workspace

	return model
end

-- Drop reward khi quái chết
local function dropRewards(cfg: Types.MonsterConfig, position: Vector3, killerPlayer: Player?)
	if not killerPlayer then return end
	if not DataService then return end

	local data = DataService.GetData(killerPlayer) :: Types.PlayerData?
	if not data then return end

	local updates: { [string]: any } = {
		Gold = data.Gold + cfg.GoldDrop,
	}

	-- Egg drop
	if math.random() <= cfg.EggDropChance then
		-- Tặng 1 trứng = roll 1 pet ngay (simplification: có thể làm physical egg sau)
		Remotes.Events.Notification:FireClient(killerPlayer, Config.Localization.Notifications.EggDropped)
		-- PetService sẽ handle qua remote, tại đây fire event giả lập
		Remotes.Events.OpenEgg:FireClient(killerPlayer) -- client tự re-fire lên server với qty=1
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
local function spawnMonster(cfg: Types.MonsterConfig)
	-- Tìm vị trí spawn trong zone
	local zoneFolder = Workspace:WaitForChild(cfg.SpawnZone, 10)
	local spawnPos   = Vector3.new(0, 5, 0)

	if zoneFolder then
		local spawnPart = zoneFolder:FindFirstChild("SpawnPoint") :: BasePart?
		if spawnPart then
			spawnPos = spawnPart.Position + Vector3.new(
				math.random(-10, 10), 3, math.random(-10, 10)
			)
		end
	end

	local model = createMonsterModel(cfg, spawnPos)
	if not model then return end

	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if not humanoid then return end

	local instance: MonsterInstance = {
		Model     = model,
		Config    = cfg,
		CurrentHP = cfg.MaxHP,
		IsAlive   = true,
	}

	table.insert(ActiveMonsters, instance)

	-- Pathfinding AI Loop
	task.spawn(function()
		while instance.IsAlive and model.Parent do
			task.wait(0.5)
			if not instance.IsAlive then break end

			local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then continue end
			if humanoid.PlatformStand then continue end -- Đang bị knocked back

			local nearestPlayer: Player? = nil
			local minDist = 150 -- Chase radius
			
			for _, p in ipairs(Players:GetPlayers()) do
				local c = p.Character
				if c then
					local phrp = c:FindFirstChild("HumanoidRootPart") :: BasePart?
					if phrp then
						if MapService and MapService.IsInSafeZone(phrp.Position) then continue end
						
						local dist = (phrp.Position - hrp.Position).Magnitude
						if dist < minDist then
							minDist = dist
							nearestPlayer = p
						end
					end
				end
			end

			if nearestPlayer and nearestPlayer.Character then
				local targetHrp = nearestPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if targetHrp then
					local distToTarget = (hrp.Position - targetHrp.Position).Magnitude
					
					if distToTarget <= Config.Shout.KnockbackRange then
						-- ATK RANGE
						local now = os.clock()
						local lastAtk = instance.LastAttackInfo or 0
						if now - lastAtk >= 3.0 then -- 3 seconds cooldown
							instance.LastAttackInfo = now
							
							local shoutDir = (targetHrp.Position - hrp.Position).Unit
							-- Quick lock on
							hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + shoutDir * Vector3.new(1,0,1))
							
							task.spawn(function()
								local ShoutService = require(script.Parent.ShoutService)
								;(ShoutService :: any).PerformShout(model, cfg.Attack, shoutDir, true, nil)
							end)
						end
					else
						local path = PathfindingService:CreatePath({AgentRadius = 3, AgentHeight = 5, AgentCanJump = true})
						local success, _ = pcall(function() path:ComputeAsync(hrp.Position, targetHrp.Position) end)

						if success and path.Status == Enum.PathStatus.Success then
							local waypoints = path:GetWaypoints()
							if #waypoints > 1 then humanoid:MoveTo(waypoints[2].Position) end
						else
							humanoid:MoveTo(targetHrp.Position)
						end
					end
				end
			end
		end
	end)

	-- Damage handler: nhận knockback từ ShoutService via workspace collision
	humanoid.HealthChanged:Connect(function(newHP)
		if not instance.IsAlive then return end
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
						TweenService:Create(hBar, TweenInfo.new(0.2), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
						hBar.BackgroundColor3 = Color3.fromRGB(255 - (205 * pct), 50 + (205 * pct), 50)
					end
				end
			end
		end

		if newHP <= 0 then
			instance.IsAlive = false

			-- Chỉ nhận quà nếu được kết liễu bởi Player (LastDamagedBy)
			local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			local killer: Player? = nil
			if hrp then
				local lastDamagedById = model:GetAttribute("LastDamagedBy")
				if lastDamagedById then
					killer = Players:GetPlayerByUserId(lastDamagedById)
				end
			end

			dropRewards(cfg, spawnPos, killer)
			model:Destroy()

			-- Remove from active
			for i, m in ipairs(ActiveMonsters) do
				if m == instance then
					table.remove(ActiveMonsters, i)
					break
				end
			end

			-- Respawn sau interval
			task.delay(Config.MonsterRespawnTime, function()
				spawnMonster(cfg)
			end)
		end
	end)
end

-- ============================================================
-- INIT: Spawn tất cả monsters khi server start
-- ============================================================
function MonsterService.Init()
	for _, cfg in ipairs(Config.Monsters) do
		task.spawn(spawnMonster, cfg)
	end
	print("[MonsterService] Spawned " .. #Config.Monsters .. " monster types")
end

return MonsterService
