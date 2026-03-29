local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local Window = require(script.Parent.Window)
local ModernButton = require(script.Parent.ModernButton)

type PetInventoryProps = {
	Visible: boolean,
	OnClose: () -> (),
	Data: any, -- PlayerData
}

local function PetInventory(props: PetInventoryProps)
	return React.createElement(Window, {
		Title = "PET GACHA",
		Icon = "🐾",
		Visible = props.Visible,
		OnClose = props.OnClose,
		Size = UDim2.new(0, 480, 0, 220),
	}, {
		-- Egg Hatching Section (Centered)
		HatchSection = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 20),
			}),
			Hatch1x = React.createElement(ModernButton, {
				Text = string.format("OPEN 1X (%dG)", Config.EggCostGold),
				Size = UDim2.new(0, 180, 0, 56),
				BackgroundColor = Color3.fromRGB(240, 160, 50),
				OnClick = function() Remotes.Events.OpenEgg:FireServer(1) end,
			}),
			Hatch10x = React.createElement(ModernButton, {
				Text = string.format("OPEN 10X (%dG)", Config.EggCostGold * 10),
				Size = UDim2.new(0, 180, 0, 56),
				BackgroundColor = Color3.fromRGB(240, 160, 50),
				OnClick = function() Remotes.Events.OpenEgg:FireServer(10) end,
			}),
		})
	})
end

return PetInventory

