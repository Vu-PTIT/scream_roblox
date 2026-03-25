--!strict
-- BagUI.luau
-- Client-side: Giao diện Túi đồ hợp nhất (Bag) gồm 3 trang: Chỉ số, Kỹ năng, Pet

local Players      = game:GetService("Players")
local _TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Config      = require(Shared.Config)
local Remotes     = require(Shared.Remotes)
local _Types       = require(Shared.Types)

local DataController = require(script.Parent.Parent.Controllers.DataController)

local BagUI = {}
local LocalPlayer = Players.LocalPlayer

local function getPlayerGui(): PlayerGui?
	if not LocalPlayer then return nil end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local screen: ScreenGui? = nil
local mainPanel: Frame? = nil
local contentArea: Frame? = nil
local isOpen = false
local currentTab = "Stats" -- Default tab

-- ============================================================
-- UTILS / THEME
-- ============================================================
local function createCorner(radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function createStroke(color: Color3, thickness: number, transparency: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency
	return stroke
end

-- ============================================================
-- TAB: STATS
-- ============================================================
local function renderStatsTab(parent: Instance)
	parent:ClearAllChildren()
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent

	local data = (DataController and DataController.GetData() or {}) :: any
	
	local function createStatRow(label: string, value: string, icon: string, order: number)
		local row = Instance.new("Frame")
		row.Name = label .. "Row"
		row.Size = UDim2.new(0.9, 0, 0, 50)
		row.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
		row.BackgroundTransparency = 0.4
		row.BorderSizePixel = 0
		row.LayoutOrder = order
		row.Parent = parent
		
		createCorner(8).Parent = row
		createStroke(Color3.fromRGB(100, 100, 120), 1, 0.6).Parent = row
		
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.new(0, 50, 1, 0)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text = icon
		iconLbl.TextSize = 24
		iconLbl.Font = Enum.Font.GothamBold
		iconLbl.Parent = row
		
		local textLbl = Instance.new("TextLabel")
		textLbl.Size = UDim2.new(0.4, 0, 1, 0)
		textLbl.Position = UDim2.new(0, 60, 0, 0)
		textLbl.BackgroundTransparency = 1
		textLbl.Text = label
		textLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		textLbl.Font = Enum.Font.GothamMedium
		textLbl.TextSize = 16
		textLbl.TextXAlignment = Enum.TextXAlignment.Left
		textLbl.Parent = row
		
		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.new(0.4, 0, 1, 0)
		valLbl.Position = UDim2.new(1, -60, 0, 0)
		valLbl.AnchorPoint = Vector2.new(1, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.Text = value
		valLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		valLbl.Font = Enum.Font.GothamBlack
		valLbl.TextSize = 18
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.Parent = row
	end

	local totalAtk = (data.Attack or 10) + (data.DamageUpgradeLevel or 0) * (Config.Upgrades[1].StatPerLevel or 1)
	local totalDef = (data.Defense or 10) + (data.ArmorUpgradeLevel or 0) * (Config.Upgrades[3].StatPerLevel or 1)

	createStatRow("Cường hóa Sát thương", "Lv. " .. (data.DamageUpgradeLevel or 0), "⚔️", 1)
	createStatRow("Cường hóa Giáp", "Lv. " .. (data.ArmorUpgradeLevel or 0), "🛡️", 2)
	createStatRow("Tổng Sát thương", tostring(totalAtk), "🔥", 3)
	createStatRow("Tổng Giáp", tostring(totalDef), "💎", 4)
	createStatRow("Số lần Rebirth", tostring(data.RebirthCount or 0), "⭐", 5)
	createStatRow("Hệ số Rebirth", "x" .. string.format("%.2f", (data.RebirthMultiplier or 1)), "📈", 6)
	createStatRow("Vocal Points", string.format("%d", (data.VocalPoints or 0)), "🎙️", 7)
end

-- ============================================================
-- TAB: SKILLS / PETS GRID HELPERS
-- ============================================================
local function renderSkillsTab(parent: Instance)
	parent:ClearAllChildren()
	local grid = Instance.new("ScrollingFrame")
	grid.Size = UDim2.new(1, -20, 1, -20)
	grid.Position = UDim2.new(0, 10, 0, 10)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 4
	grid.Parent = parent
	
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 120, 0, 140)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.Parent = grid

	local data = (DataController and DataController.GetData() or {}) :: any
	local skills = data.Skills or {}

	for i, skill in ipairs(skills) do
		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
		card.LayoutOrder = i
		card.Parent = grid
		createCorner(10).Parent = card
		
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 30)
		lbl.BackgroundTransparency = 1
		lbl.Text = skill.SkillType
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.Parent = card

		local equipBtn = Instance.new("TextButton")
		equipBtn.Size = UDim2.new(0.8, 0, 0, 30)
		equipBtn.AnchorPoint = Vector2.new(0.5, 1)
		equipBtn.Position = UDim2.new(0.5, 0, 1, -10)
		equipBtn.BackgroundColor3 = skill.Equipped and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(100, 100, 100)
		equipBtn.Text = skill.Equipped and "UNEQUIP" or "EQUIP"
		equipBtn.TextColor3 = Color3.new(1, 1, 1)
		equipBtn.Font = Enum.Font.GothamBold
		equipBtn.TextSize = 10
		equipBtn.Parent = card
		createCorner(8).Parent = equipBtn
		
		equipBtn.Activated:Connect(function()
			Remotes.Events.SetSkillEquipped:FireServer(skill.Id, not skill.Equipped, 1)
		end)
	end
	
	grid.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#skills/4) * 150)
end

local function renderPetsTab(parent: Instance)
	parent:ClearAllChildren()
	local grid = Instance.new("ScrollingFrame")
	grid.Size = UDim2.new(1, -20, 1, -20)
	grid.Position = UDim2.new(0, 10, 0, 10)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 4
	grid.Parent = parent
	
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 120, 0, 140)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.Parent = grid

	local data = (DataController and DataController.GetData() or {}) :: any
	local pets = data.Pets or {}

	for i, pet in ipairs(pets) do
		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
		card.LayoutOrder = i
		card.Parent = grid
		createCorner(10).Parent = card
		
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 30)
		lbl.BackgroundTransparency = 1
		lbl.Text = pet.PetType
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.Parent = card

		local equipBtn = Instance.new("TextButton")
		equipBtn.Size = UDim2.new(0.8, 0, 0, 30)
		equipBtn.AnchorPoint = Vector2.new(0.5, 1)
		equipBtn.Position = UDim2.new(0.5, 0, 1, -10)
		equipBtn.BackgroundColor3 = pet.Equipped and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(100, 100, 100)
		equipBtn.Text = pet.Equipped and "UNEQUIP" or "EQUIP"
		equipBtn.TextColor3 = Color3.new(1, 1, 1)
		equipBtn.Font = Enum.Font.GothamBold
		equipBtn.TextSize = 10
		equipBtn.Parent = card
		createCorner(8).Parent = equipBtn
		
		equipBtn.Activated:Connect(function()
			Remotes.Events.SetPetEquipped:FireServer(pet.Id, not pet.Equipped)
		end)
	end
	grid.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#pets/4) * 150)
end

-- ============================================================
-- MAIN BUILD
-- ============================================================
function BagUI.SwitchTab(tabName: string)
	currentTab = tabName
	if not contentArea then return end
	
	if tabName == "Stats" then
		renderStatsTab(contentArea)
	elseif tabName == "Skills" then
		renderSkillsTab(contentArea)
	elseif tabName == "Pets" then
		renderPetsTab(contentArea)
	end
end

local function buildUI(parent: Instance?)
	local pg = parent or getPlayerGui()
	if not pg then return end
	
	-- [SMART BINDING] Detect existing BagUI
	local existing: ScreenGui? = nil
	for _, child in ipairs(pg:GetChildren()) do
		if child:IsA("ScreenGui") then
			if child.Name == "BagUI" or child:FindFirstChild("MainPanel", true) then
				if not existing then
					existing = child
				else
					child:Destroy()
				end
			end
		end
	end
	
	if existing then
		screen = existing
		mainPanel = existing:FindFirstChild("MainPanel") :: Frame
		contentArea = mainPanel and mainPanel:FindFirstChild("Content") :: Frame
		print("ℹ️ [BagUI] Using existing ScreenGui for smart binding.")
		return
	end
	
	screen = Instance.new("ScreenGui")
	if not screen then return end
	screen.Name = "BagUI"
	screen.ResetOnSpawn = false
	screen.Enabled = false
	screen.Parent = pg

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = screen

	mainPanel = Instance.new("Frame")
	if not mainPanel then return end
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(0, 600, 0, 500)
	mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	mainPanel.BackgroundColor3 = Config.Theme.Background
	mainPanel.BackgroundTransparency = 0.1
	mainPanel.BorderSizePixel = 0
	mainPanel.Parent = screen
	
	createCorner(15).Parent = mainPanel
	createStroke(Config.Theme.StrokeColor, 2, 0.4).Parent = mainPanel

	-- Header / Tabs
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundTransparency = 1
	header.Parent = mainPanel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 150, 1, 0)
	title.Position = UDim2.new(0, 20, 0, 0)
	title.Text = "TÚI ĐỒ"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.BackgroundTransparency = 1
	title.Parent = header

	local tabContainer = Instance.new("Frame")
	tabContainer.Size = UDim2.new(0, 300, 1, 0)
	tabContainer.Position = UDim2.new(1, -20, 0, 0)
	tabContainer.AnchorPoint = Vector2.new(1, 0)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = header

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 10)
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabContainer

	local function createTabBtn(name: string, icon: string, order: number)
		local btn = Instance.new("TextButton")
		btn.Name = name .. "Tab"
		btn.Size = UDim2.new(0, 80, 0, 34)
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		btn.BackgroundTransparency = 0.4
		btn.Text = icon .. " " .. name
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.LayoutOrder = order
		btn.Parent = tabContainer
		
		createCorner(8).Parent = btn
		
		btn.Activated:Connect(function()
			BagUI.SwitchTab(name)
		end)
	end

	createTabBtn("Stats", "📊", 1)
	createTabBtn("Skills", "🔥", 2)
	createTabBtn("Pets", "🐾", 3)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -10, 0, 10)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.Parent = header
	createCorner(10).Parent = closeBtn
	closeBtn.Activated:Connect(function() BagUI.Close() end)

	-- Content Area
	contentArea = Instance.new("Frame")
	if not contentArea then return end
	contentArea.Name = "Content"
	contentArea.Size = UDim2.new(1, -40, 1, -80)
	contentArea.Position = UDim2.new(0, 20, 0, 70)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = mainPanel

	BagUI.SwitchTab("Stats")
end

function BagUI.Init(overrideParent: Instance?)
	buildUI(overrideParent)
	
	-- Force initial tab render for Studio/Bake mode
	if contentArea then
		pcall(function() BagUI.SwitchTab("Stats") end)
	end
	
	print("[BagUI] Initialized")
end

function BagUI.Open()
	if screen then 
		screen.Enabled = true; 
		isOpen = true 
		BagUI.SwitchTab(currentTab)
	end
end

function BagUI.Close()
	if screen then screen.Enabled = false; isOpen = false end
end

function BagUI.Toggle()
	if isOpen then BagUI.Close() else BagUI.Open() end
end

return BagUI
