local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local Window = require(script.Parent.Window)
local Button = require(script.Parent.Button)

type RebirthMenuProps = {
	Visible: boolean,
	OnClose: () -> (),
	Data: any, -- PlayerData
}

local function RebirthMenu(props: RebirthMenuProps)
	local data = props.Data or {}
	local rebirthCount = data.RebirthCount or 0
	local nextMult = 1 + ((rebirthCount + 1) * Config.Rebirth.MultiplierPerRebirth)
	local canRebirth = (data.VocalPoints or 0) >= Config.Rebirth.VocalPointsRequired

	return React.createElement(Window, {
		Title = "REBIRTH",
		Icon = "⭐",
		Visible = props.Visible,
		OnClose = props.OnClose,
		Size = UDim2.new(0, 480, 0, 380),
	}, {
		Layout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 20),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),

		Description = React.createElement("TextLabel", {
			Size = UDim2.new(1, -60, 0, 100),
			Text = Config.Localization.Rebirth.Desc,
			TextColor3 = Config.Theme.TextSecondary,
			Font = Enum.Font.Gotham,
			TextSize = 16,
			TextWrapped = true,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}),

		MultiplierPreview = React.createElement("Frame", {
			Size = UDim2.new(1, -60, 0, 60),
			BackgroundColor3 = Config.Theme.SecondaryBackground,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			LayoutOrder = 2,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
			Text = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Text = string.format("NEW MULTIPLIER: x%.2f", nextMult),
				TextColor3 = Config.Theme.TextMain,
				Font = Enum.Font.GothamBold,
				TextSize = 20,
				BackgroundTransparency = 1,
			}),
		}),

		Buttons = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 54),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 20),
			}),
			Confirm = React.createElement(Button, {
				Text = "REBIRTH",
				Size = UDim2.new(0, 180, 0, 54),
				Variant = "Rebirth",
				Enabled = canRebirth,
				OnClick = function()
					Remotes.Events.RebirthRequest:FireServer()
					props.OnClose()
				end,
			}),
			Cancel = React.createElement(Button, {
				Text = "CANCEL",
				Size = UDim2.new(0, 180, 0, 54),
				Variant = "Cancel",
				OnClick = props.OnClose,
			}),
		}),
		
		Requirement = if not canRebirth then React.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			Text = string.format("Need %d VP to Rebirth", Config.Rebirth.VocalPointsRequired),
			TextColor3 = Color3.fromRGB(255, 100, 100),
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			BackgroundTransparency = 1,
			LayoutOrder = 4,
		}) else nil
	})
end

return RebirthMenu
