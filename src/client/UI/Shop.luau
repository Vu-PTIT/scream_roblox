--!strict
-- Shop.luau
-- Client-side: Giao diện cửa hàng upgrade (Attack + Defense tabs)

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared      = game.ReplicatedStorage.Shared
local Config      = require(Shared.Config)
local Remotes     = require(Shared.Remotes)

local DataController: any = nil
task.defer(function()
	DataController = require(script.Parent.Parent.Controllers.DataController)
end)

local Shop = {}
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local shopScreen: ScreenGui? = nil
local isOpen = false

-- ============================================================
-- TÍNH COST TẠI LEVEL HIỆN TẠI
-- ============================================================
local MarketplaceService = game:GetService("MarketplaceService")
local function getCost(cfg: any, level: number): number
	return math.floor(cfg.BaseCost * (cfg.CostScaling ^ level))
end

-- ============================================================
-- TẠO PREMIUM CARD (GAMEPASS / DEV PRODUCTS)
-- ============================================================
local function createPremiumCard(parent: Instance, cfg: any, index: number): Frame
	local card             = Instance.new("Frame")
	card.Name              = "Premium_" .. tostring(cfg.Id)
	card.Size              = UDim2.new(1, -20, 0, 110)
	card.BackgroundColor3  = Color3.fromRGB(40, 35, 50)
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel   = 0
	card.LayoutOrder       = index
	card.Parent            = parent :: any

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(130, 100, 180)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.2
	stroke.Parent = card

	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.new(0, 90, 0, 90)
	iconFrame.Position = UDim2.new(0, 10, 0.5, -45)
	iconFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = card

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconFrame

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Color3.fromRGB(90, 60, 140)
	iconStroke.Thickness = 1.5
	iconStroke.Parent = iconFrame

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.new(1, 0, 1, 0)
	iconLbl.Position = UDim2.new(0, 0, 0, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = (cfg.Type == "Gamepass") and "⭐" or "💰"
	iconLbl.TextSize = 40
	iconLbl.Parent = iconFrame

	local nameLabel        = Instance.new("TextLabel")
	nameLabel.Size         = UDim2.new(0, 200, 0, 24)
	nameLabel.Position     = UDim2.new(0, 115, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text         = cfg.Name
	nameLabel.TextColor3   = Color3.fromRGB(255, 255, 255)
	nameLabel.Font         = Enum.Font.GothamBold
	nameLabel.TextSize     = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent       = card

	local descLabel        = Instance.new("TextLabel")
	descLabel.Name         = "DescLabel"
	descLabel.Size         = UDim2.new(0, 150, 0, 18)
	descLabel.Position     = UDim2.new(0, 115, 0, 45)
	descLabel.BackgroundTransparency = 1
	descLabel.Text         = cfg.Type
	descLabel.TextColor3   = Color3.fromRGB(180, 190, 200)
	descLabel.Font         = Enum.Font.Gotham
	descLabel.TextSize     = 14
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent       = card

	local buyBtn           = Instance.new("TextButton")
	buyBtn.Name            = "BuyBtn"
	buyBtn.Size            = UDim2.new(0, 110, 0, 36)
	buyBtn.Position        = UDim2.new(1, -125, 0.5, -18)
	buyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	buyBtn.Text            = string.format(Config.Localization.Shop.PriceRobux, cfg.Price)
	buyBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
	buyBtn.Font            = Enum.Font.GothamBold
	buyBtn.TextSize        = 14
	buyBtn.BorderSizePixel = 0
	buyBtn.Parent          = card

	local cornerBtn = Instance.new("UICorner")
	cornerBtn.CornerRadius = UDim.new(1, 0)
	cornerBtn.Parent = buyBtn

	local btnGradient = Instance.new("UIGradient")
	btnGradient.Color = ColorSequence.new(Color3.fromRGB(40, 160, 80), Color3.fromRGB(20, 110, 50))
	btnGradient.Rotation = 90
	btnGradient.Parent = buyBtn
	
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(20, 80, 40)
	btnStroke.Thickness = 2
	btnStroke.Parent = buyBtn

	buyBtn.MouseEnter:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.15), { Size = UDim2.new(0, 114, 0, 38), Position = UDim2.new(1, -127, 0.5, -19) }):Play()
	end)
	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.15), { Size = UDim2.new(0, 110, 0, 36), Position = UDim2.new(1, -125, 0.5, -18) }):Play()
	end)

	buyBtn.Activated:Connect(function()
		if cfg.Type == "Gamepass" then
			MarketplaceService:PromptGamePassPurchase(LocalPlayer, cfg.Id)
		else
			MarketplaceService:PromptProductPurchase(LocalPlayer, cfg.Id)
		end
	end)

	return card
end

-- ============================================================
-- TẠO UPGRADE CARD
-- ============================================================
local function createUpgradeCard(parent: Instance, cfg: any, index: number): Frame
	local card             = Instance.new("Frame")
	card.Name              = "Card_" .. cfg.Id
	card.Size              = UDim2.new(1, -20, 0, 110)
	card.BackgroundColor3  = Color3.fromRGB(35, 40, 50)
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel   = 0
	card.LayoutOrder       = index
	card.Parent            = parent :: any

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 110, 130)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.2
	stroke.Parent = card

	-- Left Icon Container
	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.new(0, 90, 0, 90)
	iconFrame.Position = UDim2.new(0, 10, 0.5, -45)
	iconFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = card

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconFrame

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Color3.fromRGB(60, 70, 90)
	iconStroke.Thickness = 1.5
	iconStroke.Parent = iconFrame

	-- Glowing base platform inside icon frame
	local glowBase = Instance.new("Frame")
	glowBase.Size = UDim2.new(0.8, 0, 0.2, 0)
	glowBase.Position = UDim2.new(0.1, 0, 0.8, 0)
	glowBase.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
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

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.new(1, 0, 1, -15)
	iconLbl.Position = UDim2.new(0, 0, 0, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = (cfg.Category == "Attack") and "🎙️" or "🔊"
	iconLbl.TextSize = 50
	iconLbl.Parent = iconFrame

	-- Center Content: Title
	local nameLabel        = Instance.new("TextLabel")
	nameLabel.Size         = UDim2.new(0, 200, 0, 24)
	nameLabel.Position     = UDim2.new(0, 115, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text         = cfg.DisplayName
	nameLabel.TextColor3   = Color3.fromRGB(255, 255, 255)
	nameLabel.Font         = Enum.Font.GothamBold
	nameLabel.TextSize     = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent       = card

	-- Center Content: Level
	local levelLabel       = Instance.new("TextLabel")
	levelLabel.Name        = "LevelLabel"
	levelLabel.Size        = UDim2.new(0, 100, 0, 18)
	levelLabel.Position    = UDim2.new(0, 115, 0, 38)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text        = string.format("Level: 0 / %d", cfg.MaxLevel)
	levelLabel.TextColor3  = Color3.fromRGB(180, 190, 200)
	levelLabel.Font        = Enum.Font.Gotham
	levelLabel.TextSize    = 13
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Parent      = card
	
	-- Center Content: Cost (Right align of center area)
	local costLabel        = Instance.new("TextLabel")
	costLabel.Name         = "CostLabel"
	costLabel.Size         = UDim2.new(0, 100, 0, 18)
	costLabel.Position     = UDim2.new(1, -125, 0, 38)
	costLabel.BackgroundTransparency = 1
	costLabel.Text         = "Cost: 0 Gold"
	costLabel.TextColor3   = Color3.fromRGB(255, 210, 50)
	costLabel.Font         = Enum.Font.Gotham
	costLabel.TextSize     = 13
	costLabel.TextXAlignment = Enum.TextXAlignment.Right
	costLabel.Parent       = card

	-- Progress Bar Outline
	local progBg = Instance.new("Frame")
	progBg.Size = UDim2.new(0, 180, 0, 12)
	progBg.Position = UDim2.new(0, 115, 0, 62)
	progBg.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	progBg.BorderSizePixel = 0
	progBg.Parent = card

	local progBgCorner = Instance.new("UICorner")
	progBgCorner.CornerRadius = UDim.new(1, 0)
	progBgCorner.Parent = progBg

	local progFill = Instance.new("Frame")
	progFill.Name = "Fill"
	progFill.Size = UDim2.new(0, 0, 1, 0)
	progFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	progFill.BorderSizePixel = 0
	progFill.Parent = progBg

	local progFillCorner = Instance.new("UICorner")
	progFillCorner.CornerRadius = UDim.new(1, 0)
	progFillCorner.Parent = progFill

	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 140, 20))
	if cfg.Category == "Defense" then
		fillGradient.Color = ColorSequence.new(Color3.fromRGB(50, 200, 255), Color3.fromRGB(20, 140, 255))
		glowBase.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	end
	fillGradient.Parent = progFill

	-- Buy Button
	local buyBtn           = Instance.new("TextButton")
	buyBtn.Name            = "BuyBtn"
	buyBtn.Size            = UDim2.new(0, 110, 0, 36)
	buyBtn.Position        = UDim2.new(1, -125, 0, 62)
	buyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	buyBtn.Text            = "UPGRADE"
	buyBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
	buyBtn.Font            = Enum.Font.GothamBold
	buyBtn.TextSize        = 14
	buyBtn.BorderSizePixel = 0
	buyBtn.Parent          = card

	local cornerBtn = Instance.new("UICorner")
	cornerBtn.CornerRadius = UDim.new(1, 0)
	cornerBtn.Parent = buyBtn

	local btnGradient = Instance.new("UIGradient")
	btnGradient.Color = ColorSequence.new(Color3.fromRGB(100, 110, 130), Color3.fromRGB(60, 70, 90))
	btnGradient.Rotation = 90
	btnGradient.Parent = buyBtn
	
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(40, 50, 60)
	btnStroke.Thickness = 2
	btnStroke.Parent = buyBtn

	-- Hover effect
	buyBtn.MouseEnter:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.15), { Size = UDim2.new(0, 114, 0, 38), Position = UDim2.new(1, -127, 0, 61) }):Play()
	end)
	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.15), { Size = UDim2.new(0, 110, 0, 36), Position = UDim2.new(1, -125, 0, 62) }):Play()
	end)

	-- Click
	buyBtn.Activated:Connect(function()
		Remotes.Events.PurchaseUpgrade:FireServer(cfg.Id)
	end)

	-- Refresh implementation
	local function refreshCard()
		if not DataController then return end
		local data = DataController.GetData()
		if not data then return end

		local currentLevel: number
		if cfg.Id == "microphone_1" then currentLevel = data.AttackUpgradeLevel
		elseif cfg.Id == "speaker_1" then currentLevel = data.SpeakerUpgradeLevel
		elseif cfg.Id == "headphone_1" then currentLevel = data.DefenseUpgradeLevel
		elseif cfg.Id == "armor_1" then currentLevel = data.ArmorUpgradeLevel
		else currentLevel = 0 end

		levelLabel.Text = string.format("Level: %d / %d", currentLevel, cfg.MaxLevel)
		local cost      = getCost(cfg, currentLevel)
		costLabel.Text  = string.format("Cost: %s Gold", tostring(cost))
		
		local mathLevel = math.clamp(currentLevel, 0, cfg.MaxLevel)
		local fillRatio = mathLevel / cfg.MaxLevel
		TweenService:Create(progFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(fillRatio, 0, 1, 0)}):Play()

		local canAfford = data.Gold >= cost
		local maxed     = currentLevel >= cfg.MaxLevel

		if maxed then
			buyBtn.Text            = "MAXED"
			btnGradient.Color      = ColorSequence.new(Color3.fromRGB(80, 80, 80), Color3.fromRGB(50, 50, 50))
			buyBtn.TextColor3      = Color3.fromRGB(150, 150, 150)
		elseif canAfford then
			btnGradient.Color      = ColorSequence.new(Color3.fromRGB(70, 200, 100), Color3.fromRGB(40, 140, 60))
			buyBtn.Text            = "UPGRADE"
			buyBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
		else
			btnGradient.Color      = ColorSequence.new(Color3.fromRGB(100, 110, 130), Color3.fromRGB(60, 70, 90))
			buyBtn.Text            = "UPGRADE"
			buyBtn.TextColor3      = Color3.fromRGB(200, 200, 200)
		end
	end

	task.defer(function()
		task.wait(0.5)
		if DataController then
			DataController.OnDataChanged(function(_k, _v)
				refreshCard()
			end)
			refreshCard()
		end
	end)

	return card
end

-- ============================================================
-- BUILD SHOP UI
-- ============================================================
local function buildShop(): ScreenGui
	local screen            = Instance.new("ScreenGui")
	screen.Name             = "Shop"
	screen.ResetOnSpawn     = false
	screen.DisplayOrder     = 20
	screen.IgnoreGuiInset   = true
	screen.Enabled          = false

	-- Background overlay
	local overlay           = Instance.new("Frame")
	overlay.Size            = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent          = screen

	-- Main panel
	local panel             = Instance.new("Frame")
	panel.Name              = "Panel"
	panel.Size              = UDim2.new(0, 520, 0, 580)
	panel.Position          = UDim2.new(0.5, -260, 0.5, -290)
	panel.BackgroundColor3  = Config.Theme.Background
	panel.BackgroundTransparency = Config.Theme.Transparency
	panel.BorderSizePixel   = 0
	panel.Parent            = screen

	local cornerPanel = Instance.new("UICorner")
	cornerPanel.CornerRadius = Config.Theme.CornerRadius
	cornerPanel.Parent = panel

	local strokePanel = Instance.new("UIStroke")
	strokePanel.Color = Config.Theme.StrokeColor
	strokePanel.Thickness = Config.Theme.StrokeThickness
	strokePanel.Transparency = 0.3
	strokePanel.Parent = panel

	-- Title
	local title             = Instance.new("TextLabel")
	title.Size              = UDim2.new(1, 0, 0, 58)
	title.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 0.9 -- Very subtle glow top
	title.Text              = Config.Localization.Shop.Title
	title.TextColor3        = Config.Theme.TextMain
	title.Font              = Enum.Font.GothamBlack
	title.TextSize          = 22
	title.BorderSizePixel   = 0
	title.Parent            = panel

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new(Config.Theme.PrimaryGradient[1], Config.Theme.PrimaryGradient[2])
	titleGradient.Parent = title

	local cornerTitle = Instance.new("UICorner")
	cornerTitle.CornerRadius = Config.Theme.CornerRadius
	cornerTitle.Parent = title

	-- Close button
	local closeBtn          = Instance.new("TextButton")
	closeBtn.Size           = UDim2.new(0, 40, 0, 40)
	closeBtn.Position       = UDim2.new(1, -48, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text           = "✕"
	closeBtn.TextColor3     = Color3.fromRGB(255, 255, 255)
	closeBtn.Font           = Enum.Font.GothamBold
	closeBtn.TextSize       = 18
	closeBtn.BorderSizePixel= 0
	closeBtn.Parent         = panel

	local cornerClose = Instance.new("UICorner")
	cornerClose.CornerRadius = UDim.new(0, 6)
	cornerClose.Parent = closeBtn

	closeBtn.Activated:Connect(function()
		Shop.Close()
	end)

	-- Tab buttons
	local tabAtkBtn         = Instance.new("TextButton")
	tabAtkBtn.Name          = "TabAtk"
	tabAtkBtn.Size          = UDim2.new(0.33, -7, 0, 40)
	tabAtkBtn.Position      = UDim2.new(0, 5, 0, 65)
	tabAtkBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 255)
	tabAtkBtn.Text          = Config.Localization.Shop.TabAttack
	tabAtkBtn.TextColor3    = Config.Theme.TextMain
	tabAtkBtn.Font          = Enum.Font.GothamBold
	tabAtkBtn.TextSize      = 13
	tabAtkBtn.BorderSizePixel = 0
	tabAtkBtn.Parent        = panel

	local cornerTabAtk = Instance.new("UICorner")
	cornerTabAtk.CornerRadius = UDim.new(0, 8)
	cornerTabAtk.Parent = tabAtkBtn

	local tabDefBtn         = Instance.new("TextButton")
	tabDefBtn.Name          = "TabDef"
	tabDefBtn.Size          = UDim2.new(0.33, -7, 0, 40)
	tabDefBtn.Position      = UDim2.new(0.33, 5, 0, 65)
	tabDefBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	tabDefBtn.Text          = Config.Localization.Shop.TabDefense
	tabDefBtn.TextColor3    = Config.Theme.TextSecondary
	tabDefBtn.Font          = Enum.Font.GothamBold
	tabDefBtn.TextSize      = 13
	tabDefBtn.BorderSizePixel = 0
	tabDefBtn.Parent        = panel

	local cornerTabDef = Instance.new("UICorner")
	cornerTabDef.CornerRadius = UDim.new(0, 8)
	cornerTabDef.Parent = tabDefBtn

	local tabPremBtn         = Instance.new("TextButton")
	tabPremBtn.Name          = "TabPrem"
	tabPremBtn.Size          = UDim2.new(0.33, -7, 0, 40)
	tabPremBtn.Position      = UDim2.new(0.66, 5, 0, 65)
	tabPremBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	tabPremBtn.Text          = Config.Localization.Shop.TabPremium
	tabPremBtn.TextColor3    = Config.Theme.TextSecondary
	tabPremBtn.Font          = Enum.Font.GothamBold
	tabPremBtn.TextSize      = 13
	tabPremBtn.BorderSizePixel = 0
	tabPremBtn.Parent        = panel

	local cornerTabPrem = Instance.new("UICorner")
	cornerTabPrem.CornerRadius = UDim.new(0, 8)
	cornerTabPrem.Parent = tabPremBtn

	-- Scroll frame for cards
	local scrollFrame       = Instance.new("ScrollingFrame")
	scrollFrame.Name        = "CardList"
	scrollFrame.Size        = UDim2.new(1, -20, 1, -118)
	scrollFrame.Position    = UDim2.new(0, 10, 0, 108)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 80, 200)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.Parent      = panel

	local listLayout        = Instance.new("UIListLayout")
	listLayout.SortOrder    = Enum.SortOrder.LayoutOrder
	listLayout.Padding      = UDim.new(0, 8)
	listLayout.Parent       = scrollFrame

	-- Tạo cards ban đầu (Attack tab by default)
	local function showTab(category: string)
		for _, child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local idx = 0
		if category == "Premium" then
			for _, cfg in ipairs(Config.MonetizationProducts.Gamepasses) do
				idx += 1
				createPremiumCard(scrollFrame, cfg, idx)
			end
			for _, cfg in ipairs(Config.MonetizationProducts.DevProducts) do
				idx += 1
				createPremiumCard(scrollFrame, cfg, idx)
			end
		else
			for _, cfg in ipairs(Config.Upgrades) do
				if cfg.Category == category then
					idx += 1
					createUpgradeCard(scrollFrame, cfg, idx)
				end
			end
		end

		-- Update scroll canvas
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, idx * 118 + 8)
	end

	showTab("Attack")

	local function resetTabs()
		tabAtkBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		tabAtkBtn.TextColor3 = Config.Theme.TextSecondary
		tabDefBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		tabDefBtn.TextColor3 = Config.Theme.TextSecondary
		tabPremBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		tabPremBtn.TextColor3 = Config.Theme.TextSecondary
	end

	tabAtkBtn.Activated:Connect(function()
		showTab("Attack")
		resetTabs()
		tabAtkBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 255)
		tabAtkBtn.TextColor3 = Config.Theme.TextMain
	end)

	tabDefBtn.Activated:Connect(function()
		showTab("Defense")
		resetTabs()
		tabDefBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 255)
		tabDefBtn.TextColor3 = Config.Theme.TextMain
	end)

	tabPremBtn.Activated:Connect(function()
		showTab("Premium")
		resetTabs()
		tabPremBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 255)
		tabPremBtn.TextColor3 = Config.Theme.TextMain
	end)

	return screen
end

-- ============================================================
-- PUBLIC API
-- ============================================================
function Shop.Init()
	local screen = buildShop()
	screen.Parent = PlayerGui
	shopScreen = screen
end

function Shop.Open()
	if shopScreen then
		shopScreen.Enabled = true
		isOpen = true
	end
end

function Shop.Close()
	if shopScreen then
		shopScreen.Enabled = false
		isOpen = false
	end
end

function Shop.Toggle()
	if isOpen then Shop.Close() else Shop.Open() end
end

return Shop
