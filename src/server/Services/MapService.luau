local MapService = {}


local function setupStations()
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then return end

	local stationsFolder = mapFolder:FindFirstChild("Stations")
	if not stationsFolder then return end

	-- Cấu hình trạm (chỉ cần tên và id để gắn logic)
	local stationData = {
		{ id = "Shop", name = "Upgrade Station" },
		{ id = "Pet", name = "Pet Station" },
		{ id = "Skill", name = "Skill Scroll Gacha" },
		{ id = "Inventory", name = "My Inventory (Bag)" },
		{ id = "Quest", name = "Quest Board" },
		{ id = "Reward", name = "Reward Chest" },
		{ id = "Shout", name = "Speech Customizer" },
	}

	for _, data in ipairs(stationData) do
		local part = stationsFolder:FindFirstChild(data.name)

		if part and part:IsA("BasePart") then
			-- Tạo ProximityPrompt nếu chưa có
			local prompt = (part:FindFirstChild("Prompt_" .. data.id) or Instance.new("ProximityPrompt")) :: ProximityPrompt
			prompt.Name = "Prompt_" .. data.id
			prompt.Parent = part
			prompt.ActionText = "Open"
			prompt.ObjectText = data.name
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = 15
			prompt.HoldDuration = 0
			prompt.Enabled = true

			-- Tạo ClickDetector nếu chưa có
			local click = (part:FindFirstChild("Click_" .. data.id) or Instance.new("ClickDetector")) :: ClickDetector
			click.Name = "Click_" .. data.id
			click.Parent = part
			click.MaxActivationDistance = 20
		else
			warn("⚠️ [MapService] Missing station part in Studio Map:", data.name)
		end
	end
end

local function setupLeaderboard()
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then return end

	local board = mapFolder:FindFirstChild("GlobalLeaderboardBoard")

	if board and board:IsA("BasePart") then
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
	else
		warn("⚠️ [MapService] Missing GlobalLeaderboardBoard part in Studio Map!")
	end
end

function MapService.Init()
	if not workspace:FindFirstChild("Map") then
		warn("⚠️ [MapService] BẠN CHƯA THÊM MAP VÀO STUDIO! Vui lòng tạo Map folder trong Workspace hoặc load file rbxml.")
	end

	setupStations()
	setupLeaderboard()

	-- StreamingEnabled is configured in default.project.json (Rojo)
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
		"✅ [MapService] Đã gắn logic cho Map trên Studio!"
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
