local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local Window = require(script.Parent.Window)
local Button = require(script.Parent.Button)

type PetInventoryProps = {
	Visible: boolean,
	OnClose: () -> (),
	Data: any, -- PlayerData
}

local function PetCard(props: { Pet: any, IsEquipped: boolean })
	local pet = props.Pet
	
	-- Look up config for icon and rarity if needed
	local cfg = nil
	for _, p in ipairs(Config.Pets) do
		if p.PetType == pet.PetType then
			cfg = p
			break
		end
	end
	
	local rarity = pet.Rarity or (cfg and cfg.Rarity) or "Common"
	local rarityColor = Config.Theme.RarityColors[rarity] or Color3.new(1, 1, 1)
	local icon = if cfg then cfg.Icon else ""
	local multiplier = pet.Multiplier or (cfg and cfg.Multiplier) or 1

	return React.createElement("Frame", {
		Size = UDim2.new(0, 120, 0, 150),
		BackgroundColor3 = Config.Theme.SecondaryBackground,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
		Stroke = React.createElement("UIStroke", {
			Color = if props.IsEquipped then Color3.fromRGB(100, 255, 100) else Config.Theme.StrokeColor,
			Thickness = if props.IsEquipped then 2 else 1,
			Transparency = 0.5,
		}),

		IconContainer = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 60),
			BackgroundTransparency = 1,
		}, {
			Image = React.createElement("ImageLabel", {
				Size = UDim2.new(0, 48, 0, 48),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = icon,
				BackgroundTransparency = 1,
				ZIndex = 2,
			}),
			Emoji = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Text = "🐾",
				TextSize = 32,
				TextTransparency = 0.5,
				BackgroundTransparency = 1,
				ZIndex = 1,
			}),
		}),

		Name = React.createElement("TextLabel", {
			Size = UDim2.new(1, -10, 0, 20),
			Position = UDim2.new(0, 5, 0, 65),
			Text = pet.PetType,
			TextColor3 = rarityColor,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextScaled = true,
			BackgroundTransparency = 1,
		}),

		Multiplier = React.createElement("TextLabel", {
			Size = UDim2.new(1, -10, 0, 16),
			Position = UDim2.new(0, 5, 0, 85),
			Text = "x" .. string.format("%.2f", multiplier),
			TextColor3 = Config.Theme.TextSecondary,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			BackgroundTransparency = 1,
		}),

		EquipBtn = React.createElement(Button, {
			Text = if props.IsEquipped then "UNEQUIP" else "EQUIP",
			Size = UDim2.new(1, -16, 0, 28),
			Position = UDim2.new(0, 8, 1, -36),
			Variant = if props.IsEquipped then "Cancel" else "Pets",
			OnClick = function()
				Remotes.Events.SetPetEquipped:FireServer(pet.Id, not props.IsEquipped)
			end,
		})
	})
end

local function PetInventory(props: PetInventoryProps)
	local data = props.Data or {}
	local pets = data.Pets or {}
	local equippedIds = data.EquippedPetIds or {}

	local petElements = {}
	for i, pet in ipairs(pets) do
		local isEquipped = false
		for _, eid in ipairs(equippedIds) do
			if eid == pet.Id then
				isEquipped = true
				break
			end
		end
		petElements[pet.Id] = React.createElement(PetCard, {
			Pet = pet,
			IsEquipped = isEquipped,
		})
	end

	return React.createElement(Window, {
		Title = "PET SHOP & INVENTORY",
		Icon = "🐾",
		Visible = props.Visible,
		OnClose = props.OnClose,
		Size = UDim2.new(0, 600, 0, 540),
	}, {
		-- Egg Hatching Section
		HatchSection = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 60),
			BackgroundTransparency = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 15),
			}),
			Hatch1x = React.createElement(Button, {
				Text = string.format("OPEN 1X (%dG)", Config.EggCostGold),
				Size = UDim2.new(0, 200, 0, 48),
				Variant = "Pets",
				OnClick = function() Remotes.Events.OpenEgg:FireServer(1) end,
			}),
			Hatch10x = React.createElement(Button, {
				Text = string.format("OPEN 10X (%dG)", Config.EggCostGold * 10),
				Size = UDim2.new(0, 200, 0, 48),
				Variant = "Pets",
				OnClick = function() Remotes.Events.OpenEgg:FireServer(10) end,
			}),
		}),

		-- Inventory Grid
		Scroll = React.createElement("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, -70),
			Position = UDim2.new(0, 0, 0, 70),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Config.Theme.BtnPetsBase,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, (function()
			local children = {
				Layout = React.createElement("UIGridLayout", {
					CellSize = UDim2.new(0, 128, 0, 150),
					CellPadding = UDim2.new(0, 10, 0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Padding = React.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 15),
					PaddingRight = UDim.new(0, 5),
				}),
			}
			for k, v in pairs(petElements) do
				children[k] = v
			end
			return children
		end)())
	})
end

return PetInventory
