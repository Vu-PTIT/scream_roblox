local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local Window = require(script.Parent.Window)
local ModernButton = require(script.Parent.ModernButton)

type SkillInventoryProps = {
	Visible: boolean,
	OnClose: () -> (),
	Data: any, -- PlayerData
}

local function SkillInventory(props: SkillInventoryProps)
	return React.createElement(Window, {
		Title = "SKILL GACHA",
		Icon = "🎴",
		Visible = props.Visible,
		OnClose = props.OnClose,
		Size = UDim2.new(0, 480, 0, 220),
	}, {
		-- Gacha Buttons
		GachaRow = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 20),
			}),
			Open1x = React.createElement(ModernButton, {
				Text = string.format("OPEN 1X (%d 💰)", Config.SkillScrollCost),
				Size = UDim2.new(0, 180, 0, 56),
				BackgroundColor = Color3.fromRGB(80, 120, 255),
				OnClick = function() Remotes.Events.OpenSkillScroll:FireServer(1) end,
			}),
			Open10x = React.createElement(ModernButton, {
				Text = string.format("OPEN 10X (%d 💰)", Config.SkillScrollCost * 10),
				Size = UDim2.new(0, 180, 0, 56),
				BackgroundColor = Color3.fromRGB(80, 120, 255),
				OnClick = function() Remotes.Events.OpenSkillScroll:FireServer(10) end,
			}),
		}),
	})
end

return SkillInventory
