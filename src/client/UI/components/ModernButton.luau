--!strict
-- ModernButton.luau
-- A premium, reusable button component with glassmorphism and hover effects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Config = require(ReplicatedStorage.Shared.Config)

type Props = {
	Icon: string?,
	Text: string?,
	OnClick: () -> (),
	BackgroundColor: Color3?,
	Size: UDim2?,
	LayoutOrder: number?,
	BadgeCount: number?,
}

local function ModernButton(props: Props)
	local isHovered, setHovered = React.useState(false)
	local isPressed, setPressed = React.useState(false)

	local baseColor = props.BackgroundColor or Config.Theme.Background
	local targetColor = isHovered and baseColor:Lerp(Color3.new(1, 1, 1), 0.15) or baseColor
	if isPressed then
		targetColor = baseColor:Lerp(Color3.new(0, 0, 0), 0.1)
	end

	return React.createElement("Frame", {
		Size = props.Size or UDim2.new(0, 50, 0, 50),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		-- Shadow / Glow
		Shadow = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 3),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			ZIndex = 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = Config.Theme.CornerRadius }),
		}),

		-- Main Button
		Button = React.createElement("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = isPressed and UDim2.new(0, 0, 0, 2) or UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = targetColor,
			BackgroundTransparency = 0.1,
			Text = "",
			BorderSizePixel = 0,
			AutoButtonColor = false,

			[React.Event.MouseEnter] = function() setHovered(true) end,
			[React.Event.MouseLeave] = function() 
				setHovered(false) 
				setPressed(false)
			end,
			[React.Event.InputBegan] = (function(rbx, input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					setPressed(true)
				end
			end) :: any,
			[React.Event.InputEnded] = (function(rbx, input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					setPressed(false)
				end
			end) :: any,
			[React.Event.Activated] = props.OnClick :: any,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = Config.Theme.CornerRadius }),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Transparency = if isHovered then 0.1 else 0.4,
				Thickness = 1.6,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			
			IconLabel = props.Icon and React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = props.Icon,
				TextSize = 24,
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamBold,
			}),

			ContentText = props.Text and React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = props.Text,
				TextSize = 14,
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamBold,
				Visible = not props.Icon,
			}),

			Badge = (props.BadgeCount and props.BadgeCount > 0) and React.createElement("Frame", {
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(1, -5, 0, 5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 60, 60),
				ZIndex = 5,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Label = React.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = tostring(props.BadgeCount),
					TextSize = 10,
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold,
				}),
			}),
		}),
	})
end

return ModernButton
