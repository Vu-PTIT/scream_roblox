--!strict
-- PetUI.luau
-- Client-side: Grid hiển thị pets, mở trứng, equip/unequip

local Players      = game:GetService("Players")

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

local function getPlayerGui(): PlayerGui?
	if not LocalPlayer then return nil end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local petScreen: ScreenGui? = nil
local isOpen = false

local RarityColors: { [string]: Color3 } = Config.Theme.RarityColors

local function createPetCard(parent: Instance, pet: Types.PetData, index: number): Frame
	local rarityColor = RarityColors[pet.Rarity] or Color3.fromRGB(180,180,180)

	local card             = Instance.new("Frame")
	card.Name              = "Pet_" .. pet.Id
	card.Size              = UDim2.new(0, 130, 0, 160)
	card.BackgroundColor3  = Config.Theme.SecondaryBackground
	card.BackgroundTransparency = 0.2
	card.BorderSizePixel   = 0
	card.LayoutOrder       = index

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color     = Config.Theme.StrokeColor
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent    = card

	-- Top Icon Container
	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.new(1, -20, 0, 70)
	iconFrame.Position = UDim2.new(0, 10, 0, 10)
	iconFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = card

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 10)
	iconCorner.Parent = iconFrame
	
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
	icon.TextSize = 36
	icon.Parent = iconFrame

	-- Name
	local nameLabel    = Instance.new("TextLabel")
	nameLabel.Size     = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 0, 85)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text     = pet.PetType
	nameLabel.TextColor3 = rarityColor
	nameLabel.Font     = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextScaled = true
	nameLabel.Parent   = card
	
	local sizeConstraint = Instance.new("UITextSizeConstraint")
	sizeConstraint.MaxTextSize = 14
	sizeConstraint.Parent = nameLabel

	-- Multiplier
	local multLabel    = Instance.new("TextLabel")
	multLabel.Size     = UDim2.new(1, -10, 0, 16)
	multLabel.Position = UDim2.new(0, 5, 0, 105)
	multLabel.BackgroundTransparency = 1
	multLabel.Text     = "x" .. string.format("%.2f", pet.Multiplier)
	multLabel.TextColor3 = Config.Theme.TextSecondary
	multLabel.Font     = Enum.Font.Gotham
	multLabel.TextSize = 13
	multLabel.Parent   = card

	-- Equip button
	local equipBtn     = Instance.new("TextButton")
	equipBtn.Name      = "EquipBtn"
	equipBtn.Size      = UDim2.new(1, -20, 0, 28)
	equipBtn.Position  = UDim2.new(0, 10, 1, -36)
	equipBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	equipBtn.Text      = if pet.Equipped then "✓ EQUIPPED" else "EQUIP"
	equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	equipBtn.Font      = Enum.Font.GothamBold
	equipBtn.TextSize  = 11
	equipBtn.BorderSizePixel = 0
	equipBtn.Parent    = card

	local cornerEquip = Instance.new("UICorner")
	cornerEquip.CornerRadius = UDim.new(1, 0)
	cornerEquip.Parent = equipBtn
	
	local btnGradient = Instance.new("UIGradient")
	if pet.Equipped then
		btnGradient.Color = ColorSequence.new(Color3.fromRGB(60, 200, 100), Color3.fromRGB(40, 150, 70))
	else
		btnGradient.Color = ColorSequence.new(Config.Theme.BtnPetsBase, Config.Theme.BtnPetsShadow)
	end
	btnGradient.Rotation = 90
	btnGradient.Parent = equipBtn

	equipBtn.Activated:Connect(function()
		Remotes.Events.SetPetEquipped:FireServer(pet.Id, not pet.Equipped)
	end)

	card.Parent = parent :: any
	return card
end

local function buildPetUI(): ScreenGui
	print("[PetUI] Building UI...")
	local screen            = Instance.new("ScreenGui")
	screen.Name             = "PetUI"
	screen.ResetOnSpawn     = false
	screen.DisplayOrder     = 999 -- Extremely high
	screen.IgnoreGuiInset   = true
	screen.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	screen.Enabled          = false

	local panel             = Instance.new("Frame")
	panel.Name              = "Panel"
	panel.Size              = UDim2.new(0, 600, 0, 500)
	panel.Position          = UDim2.new(0.5, 0, 0.5, 0)
	panel.AnchorPoint       = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3  = Color3.fromRGB(30, 30, 40)
	panel.BackgroundTransparency = 0.2 -- Slightly see-through
	panel.ZIndex            = 1
	panel.BorderSizePixel   = 4
	panel.BorderColor3      = Color3.fromRGB(255, 0, 0) -- RED BORDER
	panel.Parent            = screen
	
	print("[PetUI] Panel created and parented to screen. Panel.Visible:", panel.Visible)

	local title             = Instance.new("TextLabel")
	title.Size              = UDim2.new(1, 0, 0, 50)
	title.Text              = "🐾 PET SHOP & INVENTORY"
	title.TextColor3        = Color3.new(1, 1, 1)
	title.Font              = Enum.Font.GothamBlack
	title.TextSize          = 24
	title.Parent            = panel

	local strokePanel = Instance.new("UIStroke")
	strokePanel.Color = Config.Theme.StrokeColor
	strokePanel.Thickness = Config.Theme.StrokeThickness
	strokePanel.Transparency = 0.3
	strokePanel.Parent = panel
	
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Config.Theme.PanelGradient[1], Config.Theme.PanelGradient[2])
	grad.Rotation = 45
	grad.Parent = panel

	local invTitle = Instance.new("TextLabel")
	invTitle.Size  = UDim2.new(1, 0, 0, 64)
	invTitle.BackgroundTransparency = 1
	invTitle.Text  = "MY PETS"
	invTitle.TextColor3 = Config.Theme.TextMain
	invTitle.Font  = Enum.Font.GothamBlack
	invTitle.TextSize = 24
	invTitle.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size  = UDim2.new(0, 44, 0, 44)
	closeBtn.Position = UDim2.new(1, -54, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	closeBtn.Text  = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font  = Enum.Font.GothamBold
	closeBtn.TextSize = 20
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = panel

	local cornerClose = Instance.new("UICorner")
	cornerClose.CornerRadius = UDim.new(0, 10)
	cornerClose.Parent = closeBtn

	closeBtn.Activated:Connect(function() PetUI.Close() end)

	-- Open egg buttons row
	local eggRow = Instance.new("Frame")
	eggRow.Size  = UDim2.new(1, -30, 0, 54)
	eggRow.Position = UDim2.new(0, 15, 0, 65)
	eggRow.BackgroundTransparency = 1
	eggRow.Parent = panel

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.Padding = UDim.new(0, 12)
	listLayout.Parent = eggRow

	local function makeEggBtn(text: string, count: number)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 240, 0, 48)
		btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.BorderSizePixel = 0
		btn.Parent = eggRow

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 24)
		corner.Parent = btn

		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new(Config.Theme.BtnPetsBase, Config.Theme.BtnPetsShadow)
		grad.Rotation = 90
		grad.Parent = btn
		
		btn.Activated:Connect(function() Remotes.Events.OpenEgg:FireServer(count) end)
		return btn
	end

	makeEggBtn(string.format("OPEN 1X (%dG)", Config.EggCostGold), 1)
	makeEggBtn(string.format("OPEN 10X (%dG)", Config.EggCostGold * 10), 10)

	-- Pet grid
	local gridScroll = Instance.new("ScrollingFrame")
	gridScroll.Name  = "PetGrid"
	gridScroll.Size  = UDim2.new(1, -20, 1, -145)
	gridScroll.Position = UDim2.new(0, 10, 0, 125)
	gridScroll.BackgroundTransparency = 1
	gridScroll.ScrollBarThickness = 4
	gridScroll.ScrollBarImageColor3 = Config.Theme.BtnPetsBase
	gridScroll.BorderSizePixel = 0
	gridScroll.Parent = panel

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize    = UDim2.new(0, 130, 0, 160)
	gridLayout.CellPadding = UDim2.new(0, 12, 0, 12)
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
		
		local cols = 4
		local rows = math.ceil(#data.Pets / cols)
		gridScroll.CanvasSize = UDim2.new(0, 0, 0, rows * 172 + 12)
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

function PetUI.Init(overrideParent: Instance?)
	local pg = overrideParent or getPlayerGui()
	if not pg then 
		warn("[PetUI] Init failed: PlayerGui not found") 
		return 
	end
	
	local existing = (pg :: any):FindFirstChild("PetUI")
	if existing then existing:Destroy() end

	local newScreen = buildPetUI()
	petScreen = newScreen
	newScreen.Parent = (pg :: any)
	
	print("[PetUI] Init complete. petScreen.Parent:", (newScreen.Parent :: any).Name)
end

function PetUI.Open()
	local pg = getPlayerGui()
	if not pg then return end
	
	-- Verify petScreen is valid and in PlayerGui
	local isValid = petScreen and petScreen.Parent == pg and petScreen:IsDescendantOf(pg)
	if not isValid then
		print("⚠️ [PetUI] petScreen invalid or detached. Re-initializing...")
		PetUI.Init()
	end

	if petScreen then 
		petScreen.Enabled = true
		isOpen = true 
		print("[PetUI] Opened successfully.")
	end
end

function PetUI.Close()
	if petScreen then petScreen.Enabled = false; isOpen = false end
end

function PetUI.Toggle()
	if isOpen then PetUI.Close() else PetUI.Open() end
end

return PetUI
