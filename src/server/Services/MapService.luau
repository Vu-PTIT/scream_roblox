--!strict
-- MapService.luau
-- Server-side: Tự động khởi tạo Bản đồ (Safe Zone, PvP) và quản lý logic khu vực

local MapService = {}

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

	-- Lấy config từ Shared
	local Shared = game.ReplicatedStorage:WaitForChild("Shared")
	local Config = require(Shared:WaitForChild("Config"))

	local szConfig = Config.Map.SafeZone

	local part = Instance.new("Part")
	part.Name = "SafeZoneBase"
	part.Anchored = true
	part.Size = szConfig.Size
	part.Position = szConfig.Position
	part.Color = Color3.fromRGB(150, 255, 150) -- Màu xanh nhạt hiền hòa
	part.Material = Enum.Material.Grass
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Parent = safeZonesFolder

	-- Thêm SpawnLocation mặc định ở giữa SafeZone
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = szConfig.Position + Vector3.new(0, 0.5, 0)
	spawn.BrickColor = BrickColor.new("Bright green")
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = mapFolder
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

	local Shared = game.ReplicatedStorage:WaitForChild("Shared")
	local Config = require(Shared:WaitForChild("Config"))

	local pvpConfig = Config.Map.PvPArena

	local part = Instance.new("Part")
	part.Name = "PvPArenaBase"
	part.Anchored = true
	part.Size = pvpConfig.Size
	part.Position = pvpConfig.Position
	part.Color = Color3.fromRGB(255, 100, 100) -- Màu đỏ đại diện PvP
	part.Material = Enum.Material.Sand
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Parent = pvpZonesFolder

	-- Tạo tường vô hình hoặc cảnh báo quanh PvP nếu cần
end

-- Tạo khu vực Quái Vật (PvE)
local function createZone(zoneName: string, config: any, color: Color3, material: Enum.Material)
	if workspace:FindFirstChild(zoneName) then return end

	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = zoneName
	zoneFolder.Parent = workspace

	local part = Instance.new("Part")
	part.Name = "Base"
	part.Anchored = true
	part.Size = config.Size
	part.Position = config.Position
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Parent = zoneFolder

	-- Thêm SpawnPoint cho Quái
	local spawnPoint = Instance.new("Part")
	spawnPoint.Name = "SpawnPoint"
	spawnPoint.Anchored = true
	spawnPoint.Size = Vector3.new(4, 1, 4)
	spawnPoint.Position = config.Position + Vector3.new(0, 0.5, 0)
	spawnPoint.Transparency = 1
	spawnPoint.CanCollide = false
	spawnPoint.Parent = zoneFolder
end

-- Tạo các khu vực Rebirth
local function createRebirthAreas()
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then return end
	local rebirthZonesFolder = mapFolder:FindFirstChild("RebirthZones")
	if not rebirthZonesFolder then
		rebirthZonesFolder = Instance.new("Folder")
		rebirthZonesFolder.Name = "RebirthZones"
		rebirthZonesFolder.Parent = mapFolder
	end

	local DataService = require(script.Parent.DataService)
	local Remotes = game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")
	local RunService = game:GetService("RunService")

	local areas = {
		{ Name = "Desert", Req = 1, Color = Color3.fromRGB(244, 164, 96), Pos = Vector3.new(0, 0, -200) },
		{ Name = "IceZone", Req = 3, Color = Color3.fromRGB(173, 216, 230), Pos = Vector3.new(0, 0, -400) },
		{ Name = "VoidRealm", Req = 7, Color = Color3.fromRGB(75, 0, 130), Pos = Vector3.new(0, 0, -600) },
		{ Name = "HeavenlyStage", Req = 15, Color = Color3.fromRGB(255, 250, 205), Pos = Vector3.new(0, 0, -800) },
	}

	local blockedGates = {}

	for _, area in ipairs(areas) do
		local floor = Instance.new("Part")
		floor.Name = area.Name .. "_Floor"
		floor.Size = Vector3.new(100, 1, 100)
		floor.Position = area.Pos
		floor.Anchored = true
		floor.Color = area.Color
		floor.Parent = rebirthZonesFolder

		local blocker = Instance.new("Part")
		blocker.Name = area.Name .. "_Gate"
		blocker.Size = Vector3.new(100, 20, 5)
		blocker.Position = area.Pos + Vector3.new(0, 10, 50)
		blocker.Anchored = true
		blocker.CanCollide = false
		blocker.Transparency = 0.5
		blocker.Color = Color3.fromRGB(255, 50, 50)
		blocker.Material = Enum.Material.Neon
		blocker.Parent = rebirthZonesFolder

		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.Parent = blocker
		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.Text = area.Name .. "\\nRequires " .. area.Req .. " Rebirths"
		txt.TextScaled = true
		txt.TextColor3 = Color3.new(1,1,1)
		txt.Font = Enum.Font.GothamBold
		txt.Parent = gui

		table.insert(blockedGates, {
			Req = area.Req,
			Name = area.Name,
			MinZ = area.Pos.Z - 60,
			MaxZ = blocker.Position.Z + 2,
			MinX = blocker.Position.X - (blocker.Size.X / 2),
			MaxX = blocker.Position.X + (blocker.Size.X / 2),
			PushBackTarget = blocker.Position + Vector3.new(0, 0, 15) -- 15 studs before the gate
		})
	end

	-- Sử dụng Heartbeat thay thế Touched chống bypass lách góc
	RunService.Heartbeat:Connect(function()
		for _, player in ipairs(game.Players:GetPlayers()) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then continue end

			local pos = hrp.Position
			for _, gate in ipairs(blockedGates) do
				-- Kiểm tra bounding box của khu vực bị khóa
				if pos.Z < gate.MaxZ and pos.Z > gate.MinZ and pos.X < gate.MaxX and pos.X > gate.MinX then
					-- Load data kiểm tra
					local ok, data = pcall(function() return DataService.GetData(player) end)
					if ok and data and data.RebirthCount < gate.Req then
						-- Hoàn trả vị trí nhưng giữ nguyên góc xoay của người chơi
						hrp.CFrame = CFrame.new(gate.PushBackTarget.X, hrp.Position.Y, gate.PushBackTarget.Z) * hrp.CFrame.Rotation
						
						-- Tránh spam notification
						local lastNotif = player:GetAttribute("LastRebirthNotif_" .. gate.Name) or 0
						if os.clock() - lastNotif > 2 then
							player:SetAttribute("LastRebirthNotif_" .. gate.Name, os.clock())
							Remotes.Events.Notification:FireClient(player, "❌ Cần " .. gate.Req .. " Rebirth để vào khu vực " .. gate.Name .. "!")
						end
					end
				end
			end
		end
	end)
end

-- Tạo các trạm chức năng (Nâng cấp, Pet, Rebirth)
local function createStations()
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then return end

	local stationsFolder = mapFolder:FindFirstChild("Stations")
	if not stationsFolder then
		stationsFolder = Instance.new("Folder")
		stationsFolder.Name = "Stations"
		stationsFolder.Parent = mapFolder
	end

	-- Cấu hình trạm
	local stationData = {
		{ id = "Shop", name = "Upgrade Station", color = Color3.fromRGB(50, 150, 255), posOffset = Vector3.new(20, 2, -15) },
		{ id = "Pet", name = "Pet Station", color = Color3.fromRGB(255, 200, 50), posOffset = Vector3.new(-20, 2, -15) },
		{ id = "Rebirth", name = "Rebirth Station", color = Color3.fromRGB(150, 50, 200), posOffset = Vector3.new(0, 2, 25) },
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
		local part = Instance.new("Part")
		part.Name = data.name
		part.Size = Vector3.new(6, 4, 6)
		part.Position = basePos + data.posOffset
		part.Anchored = true
		part.Color = data.color
		part.Material = Enum.Material.Neon
		part.Parent = stationsFolder

		-- Tạo ProximityPrompt
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Prompt_" .. data.id
		prompt.ActionText = "Open"
		prompt.ObjectText = data.name
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 12
		prompt.Parent = part
	end
end

-- Bảng xếp hạng Global
local function createLeaderboardBoard()
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then return end
	local board = Instance.new("Part")
	board.Name = "GlobalLeaderboardBoard"
	board.Size = Vector3.new(20, 15, 1)
	board.Position = Vector3.new(0, 7.5, -45)
	board.Anchored = true
	board.Color = Color3.fromRGB(30, 30, 40)
	board.Parent = mapFolder

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

function MapService.Init()
	-- Chỉ tạo nếu chưa có map trong workspace
	if not workspace:FindFirstChild("Map") then
		createSafeZone()
		createPvPArena()
	end

	local Shared = game.ReplicatedStorage:WaitForChild("Shared")
	local Config = require(Shared:WaitForChild("Config"))

	if Config.Map.PvEZone then
		createZone("PvEZone", Config.Map.PvEZone, Color3.fromRGB(150, 200, 100), Enum.Material.Grass)
	end
	
	if Config.Map.BossRoom then
		createZone("BossRoom", Config.Map.BossRoom, Color3.fromRGB(80, 80, 80), Enum.Material.Slate)
	end
	
	createRebirthAreas()
	createStations()
	createLeaderboardBoard()

	print("✅ [MapService] Đã tạo toàn bộ Map cơ bản (SafeZone, PvP Arena, PvEZone, BossRoom, Rebirths, Stations)!")
end

-- Hàm kiểm tra xem 1 vị trí (thường là HRP) có đang ở trong SafeZone không
function MapService.IsInSafeZone(position: Vector3): boolean
	local safeZonesFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("SafeZones")
	if not safeZonesFolder then return false end

	for _, zone in ipairs(safeZonesFolder:GetChildren()) do
		if zone:IsA("BasePart") then
			local localPos = zone.CFrame:PointToObjectSpace(position)
			local size = zone.Size / 2
			-- Thêm chiều cao Y cao hơn một chút để luôn bắt được cả thân trên
			if math.abs(localPos.X) <= size.X and math.abs(localPos.Y) <= size.Y + 20 and math.abs(localPos.Z) <= size.Z then
				return true
			end
		end
	end
	return false
end

return MapService
