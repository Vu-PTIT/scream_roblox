--!strict
-- MapService.luau
-- Server-side: Tự động khởi tạo Bản đồ (Safe Zone, PvP) và quản lý logic khu vực

local MapService = {}
local CollectionService = game:GetService("CollectionService")
local Shared = game.ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ZoneTypes = require(Shared:WaitForChild("ZoneTypes"))
local ZonePlus = require(game.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ZonePlus"))

local DataService: any = nil
task.defer(function()
	DataService = require(script.Parent.DataService)
end)

-- Tạo part an toàn
local function createSafeZone()
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then
		mapFolder = Instance.new("Folder")
		mapFolder.Name = "Map"
		mapFolder.Parent = workspace
	end

	local safeZonesFolder = mapFolder:FindFirstChild("SafeZones")
	if not safeZonesFolder then
		safeZonesFolder = Instance.new("Folder")
		safeZonesFolder.Name = "SafeZones"
		safeZonesFolder.Parent = mapFolder
	end

	local szConfig = Config.Map.SafeZone
	local part: Part
	local existing = safeZonesFolder:FindFirstChild("SafeZoneBase")

	if existing and existing:IsA("Part") then
		part = existing
		print("ℹ️ [MapService] Sử dụng SafeZoneBase hiện có trong Studio.")
	else
		part = Instance.new("Part")
		part.Name = "SafeZoneBase"
		part.Anchored = true
		part.Size = szConfig.Size
		part.Position = szConfig.Position
		part.Color = Color3.fromRGB(150, 255, 150)
		part.Material = Enum.Material.Grass
		part.TopSurface = Enum.SurfaceType.Smooth
		part.Parent = safeZonesFolder
	end

	CollectionService:AddTag(part, ZoneTypes.Tags.Safezone)

	-- Thêm SpawnLocation nếu chưa có
	if not mapFolder:FindFirstChildOfClass("SpawnLocation") then
		local spawn = Instance.new("SpawnLocation")
		spawn.Anchored = true
		spawn.Size = Vector3.new(12, 1, 12)
		spawn.Position = part.Position + Vector3.new(0, 0.5, 0)
		spawn.BrickColor = BrickColor.new("Bright green")
		spawn.TopSurface = Enum.SurfaceType.Smooth
		spawn.Parent = mapFolder
	end
end

-- Tạo part PvP
local function createPvPArena()
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then
		mapFolder = Instance.new("Folder")
		mapFolder.Name = "Map"
		mapFolder.Parent = workspace
	end

	local pvpZonesFolder = mapFolder:FindFirstChild("PvPZones")
	if not pvpZonesFolder then
		pvpZonesFolder = Instance.new("Folder")
		pvpZonesFolder.Name = "PvPZones"
		pvpZonesFolder.Parent = mapFolder
	end

	local pvpConfig = Config.Map.PvPArena
	local existing = pvpZonesFolder:FindFirstChild("PvPArenaBase")

	if existing and existing:IsA("Part") then
		print("ℹ️ [MapService] Sử dụng PvPArenaBase hiện có trong Studio.")
	else
		local part = Instance.new("Part")
		part.Name = "PvPArenaBase"
		part.Anchored = true
		part.Size = pvpConfig.Size
		part.Position = pvpConfig.Position
		part.Color = Color3.fromRGB(255, 100, 100)
		part.Material = Enum.Material.Sand
		part.TopSurface = Enum.SurfaceType.Smooth
		part.Parent = pvpZonesFolder
	end
end

-- Tạo khu vực Quái Vật (PvE)
local function createZone(zoneName: string, config: any, color: Color3, material: Enum.Material)
	local zoneFolder = workspace:FindFirstChild(zoneName)
	if not zoneFolder then
		zoneFolder = Instance.new("Folder")
		zoneFolder.Name = zoneName
		zoneFolder.Parent = workspace
	end

	local part: Part
	local existing = zoneFolder:FindFirstChild("Base")

	if existing and existing:IsA("Part") then
		part = existing
	else
		part = Instance.new("Part")
		part.Name = "Base"
		part.Anchored = true
		part.Size = config.Size
		part.Position = config.Position
		part.Color = color
		part.Material = material
		part.TopSurface = Enum.SurfaceType.Smooth
		part.Parent = zoneFolder
	end

	-- You can add specific tags here for monster zones if needed
	-- CollectionService:AddTag(part, "MonsterZone")

	-- Thêm SpawnPoint cho Quái nếu chưa có
	if not zoneFolder:FindFirstChild("SpawnPoint") then
		local spawnPoint = Instance.new("Part")
		spawnPoint.Name = "SpawnPoint"
		spawnPoint.Anchored = true
		spawnPoint.Size = Vector3.new(4, 1, 4)
		spawnPoint.Position = part.Position + Vector3.new(0, 0.5, 0)
		spawnPoint.Transparency = 1
		spawnPoint.CanCollide = false
		spawnPoint.Parent = zoneFolder
	end
end


-- Tạo các khu vực Zone (mở tất cả - không cần Rebirth)
local function createZoneAreas()
	local areas: { any } = {
		{
			Name = "Desert",
			Color = Color3.fromRGB(244, 164, 96),
			Pos = Vector3.new(0, 0, -200),
			Material = Enum.Material.Sand,
			VFX = "Desert",
			MusicId = "rbxassetid://1837618405",
		},
		{
			Name = "IceZone",
			Color = Color3.fromRGB(173, 216, 230),
			Pos = Vector3.new(0, 0, -400),
			Material = Enum.Material.Ice,
			VFX = "Snow",
		},
		{
			Name = "VoidRealm",
			Color = Color3.fromRGB(30, 0, 50),
			Pos = Vector3.new(0, 0, -600),
			Material = Enum.Material.CorrodedMetal,
			VFX = "Void",
		},
		{
			Name = "HeavenlyStage",
			Color = Color3.fromRGB(255, 255, 230),
			Pos = Vector3.new(0, 0, -800),
			Material = Enum.Material.Neon,
			VFX = "Divine",
		},
	}

	local function applyAreaVFX(base: Part, vfxType: string)
		if vfxType == "Desert" then
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "SandDust"
			emitter.Color = ColorSequence.new(Color3.fromRGB(255, 200, 100))
			emitter.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 2),
				NumberSequenceKeypoint.new(1, 0),
			})
			emitter.Transparency = NumberSequence.new(0.6)
			emitter.Lifetime = NumberRange.new(2, 4)
			emitter.Rate = 20
			emitter.Speed = NumberRange.new(3, 8)
			emitter.VelocityInheritance = 0.1
			emitter.SpreadAngle = Vector2.new(45, 45)
			emitter.Parent = base
		elseif vfxType == "Snow" then
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "SnowFlakes"
			emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
			emitter.Size = NumberSequence.new(0.5)
			emitter.Transparency = NumberSequence.new(0.2)
			emitter.Lifetime = NumberRange.new(5, 8)
			emitter.Rate = 40
			emitter.Speed = NumberRange.new(10, 20)
			emitter.Acceleration = Vector3.new(0, -5, 0)
			emitter.EmissionDirection = Enum.NormalId.Top
			emitter.SpreadAngle = Vector2.new(180, 180)
			emitter.Parent = base
			local fogPart = Instance.new("Part")
			fogPart.Name = "LocalFog"
			fogPart.Size = base.Size + Vector3.new(0, 40, 0)
			fogPart.Position = base.Position + Vector3.new(0, 20, 0)
			fogPart.Anchored = true
			fogPart.CanCollide = false
			fogPart.Transparency = 0.85
			fogPart.Color = Color3.fromRGB(200, 230, 255)
			fogPart.Material = Enum.Material.ForceField
			fogPart.Parent = base.Parent
		elseif vfxType == "Void" then
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "VoidSmoke"
			emitter.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 100)),
			})
			emitter.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 2),
				NumberSequenceKeypoint.new(1, 10),
			})
			emitter.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(0.8, 0.8),
				NumberSequenceKeypoint.new(1, 1),
			})
			emitter.Lifetime = NumberRange.new(3, 6)
			emitter.Rate = 15
			emitter.Speed = NumberRange.new(2, 5)
			emitter.SpreadAngle = Vector2.new(30, 30)
			emitter.Parent = base
		elseif vfxType == "Divine" then
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "DivineSparkles"
			emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 150))
			emitter.LightEmission = 1
			emitter.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.2, 1),
				NumberSequenceKeypoint.new(0.8, 1),
				NumberSequenceKeypoint.new(1, 0),
			})
			emitter.Lifetime = NumberRange.new(1, 3)
			emitter.Rate = 50
			emitter.Speed = NumberRange.new(5, 15)
			emitter.SpreadAngle = Vector2.new(180, 180)
			emitter.Parent = base
		end
	end

	for _, area in ipairs(areas) do
		local zoneFolder = workspace:FindFirstChild(area.Name)
		if not zoneFolder then
			zoneFolder = Instance.new("Folder")
			zoneFolder.Name = area.Name
			zoneFolder.Parent = workspace
		end

		local floor = Instance.new("Part")
		floor.Name = "Base"
		floor.Size = Vector3.new(150, 1, 150)
		floor.Position = area.Pos
		floor.Anchored = true
		floor.Color = area.Color
		floor.Material = area.Material or Enum.Material.Sand
		floor.Parent = zoneFolder

		if area.VFX then
			applyAreaVFX(floor, area.VFX)
		end

		if (area :: any).MusicId then
			floor:SetAttribute("MusicId", (area :: any).MusicId)
			CollectionService:AddTag(floor, ZoneTypes.Tags.MusicZone)
		end
	end
end

-- Boss Room Gates (không còn giới hạn Rebirth — chỉ tạo floor)
local function createBossRoomGates()
	-- Boss rooms đã được tạo bởi createZone() trong Init()
	-- Không cần gate hay điều kiện Rebirth nữa
end



-- Tạo các trạm chức năng (Nâng cấp, Pet, Rebirth)
local function createStations()
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then
		return
	end

	local stationsFolder = mapFolder:FindFirstChild("Stations")
	if not stationsFolder then
		stationsFolder = Instance.new("Folder")
		stationsFolder.Name = "Stations"
		stationsFolder.Parent = mapFolder
	end

	-- Cấu hình trạm
	local stationData = {
		{
			id = "Shop",
			name = "Upgrade Station",
			color = Color3.fromRGB(50, 150, 255),
			posOffset = Vector3.new(20, 2, -15),
		},
		{
			id = "Pet",
			name = "Pet Station",
			color = Color3.fromRGB(255, 200, 50),
			posOffset = Vector3.new(-20, 2, -15),
		},
		{
			id = "Skill",
			name = "Skill Scroll Gacha",
			color = Color3.fromRGB(180, 100, 255),
			posOffset = Config.Map.SkillStation.Offset,
		},
		{
			id = "Inventory",
			name = "My Inventory (Bag)",
			color = Color3.fromRGB(0, 255, 255),
			posOffset = Vector3.new(0, 2, -15),
		},
		{
			id = "Quest",
			name = "Quest Board",
			color = Color3.fromRGB(100, 255, 150),
			posOffset = Vector3.new(-25, 2, 20),
		},
		{
			id = "Reward",
			name = "Reward Chest",
			color = Color3.fromRGB(255, 100, 255),
			posOffset = Vector3.new(25, 2, 20),
		},
		{
			id = "Shout",
			name = "Speech Customizer",
			color = Color3.fromRGB(100, 100, 100),
			posOffset = Vector3.new(0, 2, -30),
		},
	}

	-- Tìm SafeZoneBase để lấy toạ độ gốc (nếu không có thì lấy 0,0,0)
	local basePos = Vector3.new(0, 0, 0)
	local safeZonesFolder = mapFolder:FindFirstChild("SafeZones")
	if safeZonesFolder then
		local szBase = safeZonesFolder:FindFirstChild("SafeZoneBase")
		if szBase and szBase:IsA("BasePart") then
			basePos = szBase.Position
		end
	end

	for _, data in ipairs(stationData) do
		local part: Part
		local existing = stationsFolder:FindFirstChild(data.name)

		if existing and existing:IsA("Part") then
			part = existing
		else
			part = Instance.new("Part")
			part.Name = data.name
			part.Size = Vector3.new(6, 4, 6)
			part.Position = basePos + data.posOffset
			part.Anchored = true
			part.Color = data.color
			part.Material = Enum.Material.Neon
			part.Parent = stationsFolder
		end

		-- Tạo ProximityPrompt nếu chưa có
		-- Tạo ProximityPrompt
		local prompt = (part:FindFirstChild("Prompt_" .. data.id) or Instance.new("ProximityPrompt")) :: ProximityPrompt
		prompt.Name = "Prompt_" .. data.id
		prompt.Parent = part

		prompt.ActionText = "Open"
		prompt.ObjectText = data.name
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 15 -- Increased helper
		prompt.HoldDuration = 0
		prompt.Enabled = true

		-- Tạo ClickDetector nếu chưa có
		-- Tạo ClickDetector
		local click = (part:FindFirstChild("Click_" .. data.id) or Instance.new("ClickDetector")) :: ClickDetector
		click.Name = "Click_" .. data.id
		click.Parent = part
		click.MaxActivationDistance = 20
	end
end

-- Bảng xếp hạng Global
local function createLeaderboardBoard()
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then
		return
	end

	local board: Part
	local existingBoard = mapFolder:FindFirstChild("GlobalLeaderboardBoard")

	if existingBoard and existingBoard:IsA("Part") then
		board = existingBoard
	else
		board = Instance.new("Part")
		board.Name = "GlobalLeaderboardBoard"
		board.Size = Vector3.new(20, 15, 1)
		board.Position = Vector3.new(0, 7.5, -45)
		board.Anchored = true
		board.Color = Color3.fromRGB(30, 30, 40)
		board.Parent = mapFolder
	end

	if not board:FindFirstChild("LeaderboardGUI") then
		local gui = Instance.new("SurfaceGui")
		gui.Name = "LeaderboardGUI"
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(800, 600)
		gui.ResetOnSpawn = false
		gui.Parent = board

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 80)
		title.BackgroundTransparency = 1
		title.Text = "🏆 TOP VOCAL POINTS 🏆"
		title.TextColor3 = Color3.fromRGB(255, 215, 0)
		title.Font = Enum.Font.GothamBlack
		title.TextSize = 50
		title.Parent = gui

		local listFrame = Instance.new("ScrollingFrame")
		listFrame.Name = "ListFrame"
		listFrame.Size = UDim2.new(1, -40, 1, -100)
		listFrame.Position = UDim2.new(0, 20, 0, 90)
		listFrame.BackgroundTransparency = 1
		listFrame.ScrollBarThickness = 0
		listFrame.Parent = gui

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 5)
		layout.Parent = listFrame
	end
end

function MapService.Init()
	-- Chỉ tạo nếu chưa có map trong workspace
	if not workspace:FindFirstChild("Map") then
		createSafeZone()
		createPvPArena()
	end

	if Config.Map.StarterZone then
		createZone("StarterZone", Config.Map.StarterZone, Color3.fromRGB(180, 255, 180), Enum.Material.Grass)
	end

	if Config.Map.PvEZone then
		createZone("PvEZone", Config.Map.PvEZone, Color3.fromRGB(150, 200, 100), Enum.Material.Grass)
	end

	if Config.Map.BossRoom then
		createZone("BossRoom", Config.Map.BossRoom, Color3.fromRGB(80, 80, 80), Enum.Material.Slate)
	end

	if Config.Map.IceBossRoom then
		createZone("IceBossRoom", Config.Map.IceBossRoom, Color3.fromRGB(173, 216, 230), Enum.Material.Ice)
	end

	createZoneAreas()
	createBossRoomGates()
	createStations()
	createLeaderboardBoard()

	-- StreamingEnabled is configured in default.project.json (Rojo)
	-- It cannot be set from a regular script at runtime (lacking Plugin capability)

	-- Manage ReplicationFocus for smooth map loading
	local function onCharacterAdded(player: Player, character: Model)
		local hrp = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
		if hrp then
			player.ReplicationFocus = hrp
		end
	end

	local function onPlayerAdded(player: Player)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end

	local Players = game:GetService("Players")
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	print(
		"✅ [MapService] Đã tạo toàn bộ Map cơ bản và cấu hình StreamingEnabled!"
	)
end

-- Hàm kiểm tra xem 1 vị trí (thường là HRP) có đang ở trong SafeZone không
function MapService.IsInSafeZone(position: Vector3): boolean
	local safeZonesFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("SafeZones")
	if not safeZonesFolder then
		return false
	end

	for _, zone in ipairs(safeZonesFolder:GetChildren()) do
		if zone:IsA("BasePart") then
			local localPos = zone.CFrame:PointToObjectSpace(position)
			local size = zone.Size / 2
			-- Thêm chiều cao Y cao hơn một chút để luôn bắt được cả thân trên
			if
				math.abs(localPos.X) <= size.X
				and math.abs(localPos.Y) <= size.Y + 20
				and math.abs(localPos.Z) <= size.Z
			then
				return true
			end
		end
	end
	return false
end

return MapService
