--!strict
-- PetUI.luau
-- Client-side: Grid hiển thị pets, mở trứng, equip/unequip

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared      = game.ReplicatedStorage.Shared
local Config      = require(Shared.Config)
local Remotes     = require(Shared.Remotes)
local Types       = require(Shared.Types)

local DataController: any = nil
task.defer(function()
	DataController = require(script.Parent.Parent.Controllers.DataController)
end)

local PetUI = {}
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local petScreen: ScreenGui? = nil
local isOpen = false

-- Màu theo rarity
-- Màu theo rarity (Vibrant)
local RarityColors: { [Types.PetRarity]: Color3 } = {
	Common    = Color3.fromRGB(180, 180, 200),
	Uncommon  = Color3.fromRGB(80, 255, 120),
	Rare      = Color3.fromRGB(80, 160, 255),
	Epic      = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 200, 50),
}

local function createPetCard(parent: Instance, pet: Types.PetData, index: number): Frame
	local rarityColor = RarityColors[pet.Rarity] or Color3.fromRGB(180,180,180)

	local card             = Instance.new("Frame")
	card.Name              = "Pet_" .. pet.Id
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
	
	-- Glowing base inside icon frame
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
	icon.Text = "🐾"
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 34
	icon.Parent = iconFrame

	-- Name
	local nameLabel    = Instance.new("TextLabel")
	nameLabel.Size     = UDim2.new(1, -10, 0, 18)
	nameLabel.Position = UDim2.new(0, 5, 0, 80)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text     = pet.PetType
	nameLabel.TextColor3 = rarityColor
	nameLabel.Font     = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextScaled = true
	nameLabel.Parent   = card
	
	-- Keep size balanced for TextScaled
	local sizeConstraint = Instance.new("UITextSizeConstraint")
	sizeConstraint.MaxTextSize = 14
	sizeConstraint.Parent = nameLabel

	-- Multiplier
	local multLabel    = Instance.new("TextLabel")
	multLabel.Size     = UDim2.new(1, -10, 0, 14)
	multLabel.Position = UDim2.new(0, 5, 0, 98)
	multLabel.BackgroundTransparency = 1
	multLabel.Text     = "x" .. string.format("%.2f", pet.Multiplier)
	multLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	multLabel.Font     = Enum.Font.Gotham
	multLabel.TextSize = 13
	multLabel.Parent   = card

	-- Equip button
	local equipBtn     = Instance.new("TextButton")
	equipBtn.Name      = "EquipBtn"
	equipBtn.Size      = UDim2.new(1, -20, 0, 26)
	equipBtn.Position  = UDim2.new(0, 10, 1, -34)
	equipBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	equipBtn.Text      = if pet.Equipped then "✓ UNEQUIP" else "EQUIP"
	equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	equipBtn.Font      = Enum.Font.GothamBold
	equipBtn.TextSize  = 11
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
	if pet.Equipped then
		btnGradient.Color = ColorSequence.new(Color3.fromRGB(60, 180, 100), Color3.fromRGB(40, 140, 70))
	else
		btnGradient.Color = ColorSequence.new(Color3.fromRGB(80, 90, 110), Color3.fromRGB(50, 60, 80))
	end
	btnGradient.Rotation = 90
	btnGradient.Parent = equipBtn
	
	equipBtn.MouseEnter:Connect(function()
		TweenService:Create(equipBtn, TweenInfo.new(0.15), { Size = UDim2.new(1, -16, 0, 28), Position = UDim2.new(0, 8, 1, -35) }):Play()
	end)
	equipBtn.MouseLeave:Connect(function()
		TweenService:Create(equipBtn, TweenInfo.new(0.15), { Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 1, -34) }):Play()
	end)

	equipBtn.Activated:Connect(function()
		Remotes.Events.SetPetEquipped:FireServer(pet.Id, not pet.Equipped)
	end)

	card.Parent = parent :: any
	return card
end

local function buildPetUI(): ScreenGui
	local screen            = Instance.new("ScreenGui")
	screen.Name             = "PetUI"
	screen.ResetOnSpawn     = false
	screen.DisplayOrder     = 20
	screen.IgnoreGuiInset   = true
	screen.Enabled          = false

	local overlay           = Instance.new("Frame")
	overlay.Size            = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent          = screen

	local panel             = Instance.new("Frame")
	panel.Name              = "Panel"
	panel.Size              = UDim2.new(0, 580, 0, 560)
	panel.Position          = UDim2.new(0.5, -290, 0.5, -280)
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
	local title = Instance.new("TextLabel")
	title.Size  = UDim2.new(1, 0, 0, 58)
	title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 0.9
	title.Text  = Config.Localization.Pets.Title
	title.TextColor3 = Config.Theme.TextMain
	title.Font  = Enum.Font.GothamBlack
	title.TextSize = 22
	title.BorderSizePixel = 0
	title.Parent = panel

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new(Config.Theme.SecondaryGradient[1], Config.Theme.SecondaryGradient[2])
	titleGradient.Parent = title

	local cornerTitle = Instance.new("UICorner")
	cornerTitle.CornerRadius = Config.Theme.CornerRadius
	cornerTitle.Parent = title

	-- Close
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size  = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -48, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text  = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
	closeBtn.Font  = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = panel

	local cornerClose = Instance.new("UICorner")
	cornerClose.CornerRadius = UDim.new(0, 6)
	cornerClose.Parent = closeBtn

	closeBtn.Activated:Connect(function() PetUI.Close() end)

	-- Open egg buttons row
	local eggRow = Instance.new("Frame")
	eggRow.Size  = UDim2.new(1, -20, 0, 50)
	eggRow.Position = UDim2.new(0, 10, 0, 60)
	eggRow.BackgroundTransparency = 1
	eggRow.Parent = panel

	local openBtn1 = Instance.new("TextButton")
	openBtn1.Size  = UDim2.new(0, 180, 0, 44)
	openBtn1.Position = UDim2.new(0, 0, 0, 4)
	openBtn1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	openBtn1.Text  = string.format(Config.Localization.Pets.Open1x, Config.EggCostGold)
	openBtn1.TextColor3 = Color3.fromRGB(255, 255, 255)
	openBtn1.Font  = Enum.Font.GothamBold
	openBtn1.TextSize = 14
	openBtn1.BorderSizePixel = 0
	openBtn1.Parent = eggRow

	local g1 = Instance.new("UIGradient")
	g1.Color = ColorSequence.new(Color3.fromRGB(50, 150, 255), Color3.fromRGB(20, 100, 200))
	g1.Rotation = 90
	g1.Parent = openBtn1

	local cornerE1 = Instance.new("UICorner")
	cornerE1.CornerRadius = UDim.new(1, 0)
	cornerE1.Parent = openBtn1
	
	local strokeE1 = Instance.new("UIStroke")
	strokeE1.Color = Color3.fromRGB(30, 80, 150)
	strokeE1.Thickness = 2
	strokeE1.Parent = openBtn1

	openBtn1.MouseEnter:Connect(function()
		TweenService:Create(openBtn1, TweenInfo.new(0.15), { Size = UDim2.new(0, 186, 0, 48), Position = UDim2.new(0, -3, 0, 2) }):Play()
	end)
	openBtn1.MouseLeave:Connect(function()
		TweenService:Create(openBtn1, TweenInfo.new(0.15), { Size = UDim2.new(0, 180, 0, 44), Position = UDim2.new(0, 0, 0, 4) }):Play()
	end)

	local openBtn10 = Instance.new("TextButton")
	openBtn10.Size  = UDim2.new(0, 200, 0, 44)
	openBtn10.Position = UDim2.new(0, 190, 0, 4)
	openBtn10.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	openBtn10.Text  = string.format(Config.Localization.Pets.Open10x, Config.EggCostGold * 10)
	openBtn10.TextColor3 = Color3.fromRGB(255, 255, 255)
	openBtn10.Font  = Enum.Font.GothamBold
	openBtn10.TextSize = 14
	openBtn10.BorderSizePixel = 0
	openBtn10.Parent = eggRow

	local g10 = Instance.new("UIGradient")
	g10.Color = ColorSequence.new(Color3.fromRGB(255, 180, 50), Color3.fromRGB(200, 100, 20))
	g10.Rotation = 90
	g10.Parent = openBtn10

	local cornerE10 = Instance.new("UICorner")
	cornerE10.CornerRadius = UDim.new(1, 0)
	cornerE10.Parent = openBtn10
	
	local strokeE10 = Instance.new("UIStroke")
	strokeE10.Color = Color3.fromRGB(150, 80, 15)
	strokeE10.Thickness = 2
	strokeE10.Parent = openBtn10

	openBtn10.MouseEnter:Connect(function()
		TweenService:Create(openBtn10, TweenInfo.new(0.15), { Size = UDim2.new(0, 206, 0, 48), Position = UDim2.new(0, 187, 0, 2) }):Play()
	end)
	openBtn10.MouseLeave:Connect(function()
		TweenService:Create(openBtn10, TweenInfo.new(0.15), { Size = UDim2.new(0, 200, 0, 44), Position = UDim2.new(0, 190, 0, 4) }):Play()
	end)

	openBtn1.Activated:Connect(function()
		Remotes.Events.OpenEgg:FireServer(1)
	end)
	openBtn10.Activated:Connect(function()
		Remotes.Events.OpenEgg:FireServer(10)
	end)

	-- Pet grid
	local gridScroll = Instance.new("ScrollingFrame")
	gridScroll.Name  = "PetGrid"
	gridScroll.Size  = UDim2.new(1, -20, 1, -125)
	gridScroll.Position = UDim2.new(0, 10, 0, 115)
	gridScroll.BackgroundTransparency = 1
	gridScroll.ScrollBarThickness = 4
	gridScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 130, 20)
	gridScroll.BorderSizePixel = 0
	gridScroll.Parent = panel

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize    = UDim2.new(0, 128, 0, 150)
	gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	gridLayout.Parent      = gridScroll

	-- Refresh pet grid từ data
	local function refreshPets()
		for _, child in ipairs(gridScroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		if not DataController then return end
		local data = DataController.GetData()
		if not data then return end

		for i, pet in ipairs(data.Pets) do
			createPetCard(gridScroll, pet, i)
		end
	end

	task.defer(function()
		task.wait(0.5)
		if DataController then
			DataController.OnDataChanged(function(key, _)
				if key == "Pets" or key == "EquippedPetIds" or key == "__all__" then
					refreshPets()
				end
			end)
			refreshPets()
		end
	end)

	return screen
end

function PetUI.Init()
	local screen = buildPetUI()
	screen.Parent = PlayerGui
	petScreen = screen
end

function PetUI.Open()
	if petScreen then petScreen.Enabled = true; isOpen = true end
end

function PetUI.Close()
	if petScreen then petScreen.Enabled = false; isOpen = false end
end

function PetUI.Toggle()
	if isOpen then PetUI.Close() else PetUI.Open() end
end

return PetUI
