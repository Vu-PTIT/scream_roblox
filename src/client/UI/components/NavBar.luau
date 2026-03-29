--!strict
-- NavBar.luau
-- A React component for the bottom navigation bar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Config = require(ReplicatedStorage.Shared.Config)
local ModernButton = require(script.Parent.ModernButton)

type Props = {
	OnAction: (id: string) -> (),
	LayoutOrder: number?,
}

local function NavBar(props: Props)
	local buttons = {
		{ id = "Shop", icon = "🛒", color = Config.Theme.BtnShopBase },
		{ id = "Pets", icon = "🐾", color = Config.Theme.BtnPetsBase },
		{ id = "Skills", icon = "🎴", color = Config.Theme.BtnCodeBase },
		{ id = "Quest", icon = "📜", color = Config.Theme.BtnQuestBase },
		{ id = "Reward", icon = "⏱️", color = Config.Theme.BtnRewardBase },
		{ id = "Shout", icon = "✏️", color = Config.Theme.BtnShoutBase },
		{ id = "Inventory", icon = "🎒", color = Color3.fromRGB(150, 100, 200) },
	}

	return React.createElement("Frame", {
		Name = "NavBarContainer",
		Size = UDim2.new(0, (#buttons * 55) + ((#buttons - 1) * 10), 0, 55),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		Buttons = React.createElement(React.Fragment, nil, (function()
			local list = {}
			for i, btn in ipairs(buttons) do
				list[btn.id] = React.createElement(ModernButton, {
					Icon = btn.icon,
					OnClick = function() props.OnAction(btn.id) end,
					BackgroundColor = btn.color,
					Size = UDim2.new(0, 48, 0, 48),
					LayoutOrder = i,
				})
			end
			return list
		end)()),
	})
end

return NavBar
