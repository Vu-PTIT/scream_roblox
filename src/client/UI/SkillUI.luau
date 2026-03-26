--!strict
-- SkillUI.luau
-- Client-side: Grid hiển thị skills, mở gacha cuộn skill, equip/unequip

local Players      = game:GetService("Players")

local Shared      = game.ReplicatedStorage.Shared
local Config      = require(Shared.Config)
local Remotes     = require(Shared.Remotes)
local Types       = require(Shared.Types)

local DataController: any = nil
task.defer(function()
	DataController = require(script.Parent.Parent.Controllers.DataController)
end)

local SkillHatchUI = require(script.Parent.SkillHatchUI)
local SkillUI = {}
local LocalPlayer = Players.LocalPlayer

local function getPlayerGui(): PlayerGui?
	if not LocalPlayer then return nil end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local skillScreen: ScreenGui? = nil
local isOpen = false
local currentFilter: string = "All"
local gridScrollRef: ScrollingFrame? = nil

local function getSkillConfig(skillType: string)
	for _, cfg in ipairs(Config.Skills) do
		if cfg.SkillType == skillType then
			return cfg
		end
	end
	return Config.Skills[1]
end

local function createSkillCard(parent: Instance, skill: Types.SkillData, index: number): Frame
	local cfg = getSkillConfig(skill.SkillType)
	local rarityColor = Config.Theme.RarityColors[skill.Rarity] or Color3.fromRGB(180,180,180)

	local card             = Instance.new("Frame")
	card.Name              = "Skill_" .. skill.Id
	card.Size              = UDim2.new(0, 128, 0, 150)
	card.BackgroundColor3  = Color3.fromRGB(35, 40, 50)
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel   = 0
	card.LayoutOrder       = index

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color     = Color3.fromRGB(80, 90, 110)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.2
	stroke.Parent    = card

	-- Top Icon Container
	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.new(1, -20, 0, 64)
	iconFrame.Position = UDim2.new(0, 10, 0, 10)
	iconFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = card

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconFrame

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Color3.fromRGB(45, 50, 65)
	iconStroke.Thickness = 1.5
	iconStroke.Parent = iconFrame
	
	local glowBase = Instance.new("Frame")
	glowBase.Size = UDim2.new(0.8, 0, 0.2, 0)
	glowBase.Position = UDim2.new(0.1, 0, 0.8, 0)
	glowBase.BackgroundColor3 = rarityColor
	glowBase.BorderSizePixel = 0
	glowBase.Parent = iconFrame

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(1, 0)
	glowCorner.Parent = glowBase

	local glowGradient = Instance.new("UIGradient")
	glowGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	glowGradient.Parent = glowBase

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 1, -10)
	icon.Position = UDim2.new(0, 0, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = cfg.Icon or "📜"
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 34
	icon.Parent = iconFrame

	-- Name
	local nameLabel    = Instance.new("TextLabel")
	nameLabel.Size     = UDim2.new(1, -10, 0, 18)
	nameLabel.Position = UDim2.new(0, 5, 0, 80)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text     = cfg.DisplayName
	nameLabel.TextColor3 = rarityColor
	nameLabel.Font     = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextScaled = true
	nameLabel.Parent   = card
	
	local sizeConstraint = Instance.new("UITextSizeConstraint")
	sizeConstraint.MaxTextSize = 14
	sizeConstraint.Parent = nameLabel

	-- Stats (Multiplier)
	local statLabel    = Instance.new("TextLabel")
	statLabel.Size     = UDim2.new(1, -10, 0, 14)
	statLabel.Position = UDim2.new(0, 5, 0, 98)
	statLabel.BackgroundTransparency = 1
	statLabel.Text     = string.format("x%.1f DMG | %.1fs", cfg.DamageMult, cfg.Cooldown)
	statLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	statLabel.Font     = Enum.Font.Gotham
	statLabel.TextSize = 11
	statLabel.Parent   = card

	if skill.Equipped then
		-- Unequip button
		local equipBtn     = Instance.new("TextButton")
		equipBtn.Name      = "EquipBtn"
		equipBtn.Size      = UDim2.new(1, -20, 0, 26)
		equipBtn.Position  = UDim2.new(0, 10, 1, -34)
		equipBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		equipBtn.Text      = "✓ UNEQUIP (S" .. tostring(skill.SlotIndex) .. ")"
		equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		equipBtn.Font      = Enum.Font.GothamBold
		equipBtn.TextSize  = 10
		equipBtn.BorderSizePixel = 0
		equipBtn.Parent    = card

		local cornerEquip = Instance.new("UICorner")
		cornerEquip.CornerRadius = UDim.new(1, 0)
		cornerEquip.Parent = equipBtn
		
		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(40, 50, 60)
		btnStroke.Thickness = 1.5
		btnStroke.Parent = equipBtn

		local btnGradient = Instance.new("UIGradient")
		btnGradient.Color = ColorSequence.new(Color3.fromRGB(60, 180, 100), Color3.fromRGB(40, 140, 70))
		btnGradient.Rotation = 90
		btnGradient.Parent = equipBtn
		
		equipBtn.Activated:Connect(function()
			Remotes.Events.SetSkillEquipped:FireServer(skill.Id, false)
		end)
	else
		-- S1 button
		local s1Btn = Instance.new("TextButton")
		s1Btn.Size = UDim2.new(0.5, -12, 0, 26)
		s1Btn.Position = UDim2.new(0, 10, 1, -34)
		s1Btn.Text = "S1"
		s1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		s1Btn.Font = Enum.Font.GothamBold
		s1Btn.TextSize = 12
		s1Btn.Parent = card
		local c1 = Instance.new("UICorner")
		c1.CornerRadius = UDim.new(1, 0)
		c1.Parent = s1Btn
		local grad1 = Instance.new("UIGradient")
		grad1.Color = ColorSequence.new(Color3.fromRGB(80, 90, 110), Color3.fromRGB(50, 60, 80))
		grad1.Rotation = 90
		grad1.Parent = s1Btn

		-- S2 button
		local s2Btn = Instance.new("TextButton")
		s2Btn.Size = UDim2.new(0.5, -12, 0, 26)
		s2Btn.Position = UDim2.new(0.5, 2, 1, -34)
		s2Btn.Text = "S2"
		s2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		s2Btn.Font = Enum.Font.GothamBold
		s2Btn.TextSize = 12
		s2Btn.Parent = card
		local c2 = Instance.new("UICorner")
		c2.CornerRadius = UDim.new(1, 0)
		c2.Parent = s2Btn
		local grad2 = Instance.new("UIGradient")
		grad2.Color = ColorSequence.new(Color3.fromRGB(80, 90, 110), Color3.fromRGB(50, 60, 80))
		grad2.Rotation = 90
		grad2.Parent = s2Btn

		s1Btn.Activated:Connect(function()
			Remotes.Events.SetSkillEquipped:FireServer(skill.Id, true, 1)
		end)
		s2Btn.Activated:Connect(function()
			Remotes.Events.SetSkillEquipped:FireServer(skill.Id, true, 2)
		end)
	end

	card.Parent = parent :: any
	return card
end

local function buildSkillUI(): ScreenGui
	print("[SkillUI] Building UI...")
	local screen            = Instance.new("ScreenGui")
	screen.Name             = "SkillUI"
	screen.ResetOnSpawn     = false
	screen.DisplayOrder     = 999
	screen.IgnoreGuiInset   = true
	screen.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	screen.Enabled          = false

	local overlay           = Instance.new("Frame")
	overlay.Size            = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent          = screen

	local panel             = Instance.new("Frame")
	panel.Name              = "Panel"
	panel.Size              = UDim2.new(0, 620, 0, 580)
	panel.Position          = UDim2.new(0.5, 0, 0.5, 0)
	panel.AnchorPoint       = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3  = Config.Theme.Background
	panel.BackgroundTransparency = 0.5
	panel.ZIndex            = 1
	panel.BorderSizePixel   = 4
	panel.BorderColor3      = Color3.fromRGB(180, 50, 255) -- PURPLE BORDER
	panel.Parent            = screen

	local cornerPanel = Instance.new("UICorner")
	cornerPanel.CornerRadius = Config.Theme.CornerRadius
	cornerPanel.Parent = panel

	local strokePanel = Instance.new("UIStroke")
	strokePanel.Color = Config.Theme.StrokeColor
	strokePanel.Thickness = Config.Theme.StrokeThickness
	strokePanel.Transparency = 0.3
	strokePanel.Parent = panel
	
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Config.Theme.PanelGradient[1], Config.Theme.PanelGradient[2])
	grad.Rotation = 45
	grad.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size  = UDim2.new(1, 0, 0, 64)
	title.BackgroundTransparency = 1
	title.Text  = "SKILL SCROLLS"
	title.TextColor3 = Config.Theme.TextMain
	title.Font  = Enum.Font.GothamBlack
	title.TextSize = 24
	title.ZIndex = 2
	title.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size  = UDim2.new(0, 44, 0, 44)
	closeBtn.Position = UDim2.new(1, -54, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	closeBtn.Text  = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
	closeBtn.Font  = Enum.Font.GothamBold
	closeBtn.TextSize = 20
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = panel
	
	local cornerClose = Instance.new("UICorner")
	cornerClose.CornerRadius = UDim.new(0, 10)
	cornerClose.Parent = closeBtn
	
	closeBtn.Activated:Connect(function() SkillUI.Close() end)

	-- Open buttons
	local row = Instance.new("Frame")
	row.Size  = UDim2.new(1, -20, 0, 60)
	row.Position = UDim2.new(0, 10, 0, 70)
	row.BackgroundTransparency = 1
	row.Parent = panel

	local function makeOpenBtn(text: string, cost: number, count: number, pos: UDim2)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 200, 0, 48)
		btn.Position = pos
		btn.BackgroundColor3 = Config.Theme.BtnCodeBase
		btn.Text = string.format("%dx (%d 💰)", count, cost)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 15
		btn.BorderSizePixel = 0
		btn.Parent = row
		
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 12)
		c.Parent = btn
		
		local s = Instance.new("UIStroke")
		s.Thickness = 1.5
		s.Color = Color3.fromRGB(255, 255, 255)
		s.Transparency = 0.7
		s.Parent = btn

		btn.Activated:Connect(function() Remotes.Events.OpenSkillScroll:FireServer(count) end)
		return btn
	end

	makeOpenBtn("Open 1x", Config.SkillScrollCost, 1, UDim2.new(0, 10, 0, 6))
	makeOpenBtn("Open 10x", Config.SkillScrollCost * 10, 10, UDim2.new(0, 220, 0, 6))

	-- Grid
	local gridScroll = Instance.new("ScrollingFrame")
	gridScroll.Name  = "SkillGrid"
	gridScroll.BackgroundTransparency = 1
	gridScroll.ScrollBarThickness = 4
	gridScroll.ScrollBarImageColor3 = Color3.fromRGB(150, 80, 200)
	gridScroll.BorderSizePixel = 0
	gridScroll.Parent = panel
	gridScrollRef = gridScroll

	local function refreshSkills()
		if not gridScrollRef then return end
		for _, child in ipairs(gridScrollRef:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		if not DataController then return end
		local data = DataController.GetData()
		if not data then return end

		local count = 0
		for _, skill in ipairs(data.Skills or {}) do
			if currentFilter == "All" or skill.Rarity == currentFilter then
				count += 1
				createSkillCard(gridScrollRef, skill, count)
			end
		end
	end

	-- Filter Buttons
	local filterBar = Instance.new("Frame")
	filterBar.Size = UDim2.new(1, -20, 0, 30)
	filterBar.Position = UDim2.new(0, 10, 0, 115)
	filterBar.BackgroundTransparency = 1
	filterBar.Parent = panel
	
	local filterLayout = Instance.new("UIListLayout")
	filterLayout.FillDirection = Enum.FillDirection.Horizontal
	filterLayout.Padding = UDim.new(0, 5)
	filterLayout.Parent = filterBar

	local rarities = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary"}
	for _, rarity in ipairs(rarities) do
		local btn = Instance.new("TextButton")
		btn.Name = rarity .. "Filter"
		btn.Size = UDim2.new(0, 80, 1, 0)
		btn.BackgroundColor3 = rarity == "All" and Color3.fromRGB(80, 80, 100) or (Config.Theme.RarityColors[rarity :: any] or Color3.fromRGB(60, 60, 70))
		btn.BackgroundTransparency = 0.2
		btn.Text = rarity:upper()
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 10
		btn.Parent = filterBar
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = btn

		btn.Activated:Connect(function()
			currentFilter = rarity
			-- Visual feedback: highlight active filter
			for _, other in ipairs(filterBar:GetChildren()) do
				if other:IsA("TextButton") then
					other.BackgroundTransparency = (other.Name == rarity .. "Filter") and 0 or 0.4
				end
			end
			refreshSkills()
		end)
	end

	-- Re-adjust Grid position
	gridScroll.Position = UDim2.new(0, 10, 0, 150)
	gridScroll.Size = UDim2.new(1, -20, 1, -160)

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize    = UDim2.new(0, 128, 0, 150)
	gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	gridLayout.Parent      = gridScroll

	task.defer(function()
		task.wait(0.5)
		if DataController then
			DataController.OnDataChanged(function(key, _)
				if key == "Skills" or key == "EquippedSkillIds" or key == "__all__" then
					refreshSkills()
				end
			end)
			refreshSkills()
		end
	end)

	return screen
end

function SkillUI.Init(overrideParent: Instance?)
	local pg = (overrideParent or getPlayerGui()) :: Instance?
	if not pg then 
		warn("[SkillUI] Init failed: PlayerGui not found") 
		return 
	end
	
	local existing = (pg :: any):FindFirstChild("SkillUI")
	if existing then existing:Destroy() end

	local newScreen = buildSkillUI()
	skillScreen = newScreen
	if not newScreen.Parent then
		newScreen.Parent = (pg :: any)
	end
	
	SkillHatchUI.Init()

	-- Subscribe to Skill Roll Event
	Remotes.Events.OpenSkillScroll.OnClientEvent:Connect(function(skillData)
		if skillData and skillData.Name then
			SkillHatchUI.PlayHatch(skillData.Name, skillData.Rarity)
		end
	end)
	
	print("[SkillUI] Init complete. skillScreen.Parent:", (newScreen.Parent :: any).Name)
end

function SkillUI.Open()
	local pg = getPlayerGui()
	if not pg then return end

	local isValid = skillScreen and skillScreen.Parent == pg and skillScreen:IsDescendantOf(pg)
	if not isValid then
		print("⚠️ [SkillUI] skillScreen invalid or detached. Re-initializing...")
		SkillUI.Init()
	end

	if skillScreen then 
		skillScreen.Enabled = true
		isOpen = true 
		print("[SkillUI] Opened successfully.")
	end
end

function SkillUI.Close()
	if skillScreen then skillScreen.Enabled = false; isOpen = false end
end

function SkillUI.Toggle()
	if isOpen then SkillUI.Close() else SkillUI.Open() end
end

return SkillUI
