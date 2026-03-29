local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)

export type ProgressBarProps = {
	Title: string,
	Icon: string?,
	Current: number,
	Max: number,
	FillGradient: ColorSequence?,
	Position: UDim2?,
	Size: UDim2?,
	AnchorPoint: Vector2?,
}

local function ProgressBar(props: ProgressBarProps)
	local frameRef = React.useRef(nil)
	local pct = math.clamp(props.Current / math.max(1, props.Max), 0, 1)

	React.useEffect(function()
		if frameRef.current then
			-- Animate the fill changing smoothly
			local tween = TweenService:Create(
				frameRef.current,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = UDim2.new(pct, 0, 1, 0),
				}
			)
			tween:Play()
		end
	end, { pct })

	local displayPct = pct * 100
	local pctText = ""
	if displayPct > 0 and displayPct < 100 and displayPct % 1 ~= 0 then
		pctText = string.format("%.1f%%", displayPct)
	else
		pctText = tostring(math.floor(displayPct)) .. "%"
	end

	local gradient = props.FillGradient
		or ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255)),
		})

	return React.createElement("Frame", {
		Name = props.Title .. "Container",
		Size = props.Size or UDim2.new(0, 260, 0, 55),
		Position = props.Position or UDim2.new(0, 15, 1, -15),
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 1),
		BackgroundColor3 = Color3.fromRGB(25, 25, 30),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
		Stroke = React.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Transparency = 0.75,
			Thickness = 1,
		}),

		-- Header text
		TitleLabel = React.createElement("TextLabel", {
			Size = UDim2.new(0.5, -12, 0, 16),
			Position = UDim2.new(0, 12, 0, 8),
			BackgroundTransparency = 1,
			Text = (props.Icon and props.Icon .. " " or "") .. props.Title,
			TextColor3 = Color3.fromRGB(200, 200, 220),
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 2,
		}),
		ValueLabel = React.createElement("TextLabel", {
			Size = UDim2.new(0.5, -12, 0, 16),
			Position = UDim2.new(0.5, 0, 0, 8),
			BackgroundTransparency = 1,
			Text = tostring(math.floor(props.Current)) .. " / " .. tostring(props.Max),
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 2,
		}),

		-- Track layer
		Track = React.createElement("Frame", {
			Size = UDim2.new(1, -24, 0, 14),
			Position = UDim2.new(0, 12, 0, 30),
			BackgroundColor3 = Color3.fromRGB(15, 15, 20),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			-- Fill layer
			Fill = React.createElement("Frame", {
				ref = frameRef,
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 3,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
				Gradient = React.createElement("UIGradient", { Color = gradient }),
			}),
			-- Percent text centered inside track
			PercentLabel = React.createElement("TextLabel", {
				Size = UDim2.new(1, -16, 1, 0),
				Position = UDim2.new(0, 8, 0, 0),
				BackgroundTransparency = 1,
				Text = pctText,
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamBold,
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 5, -- Ensure it is visible above the fill
			}),
		}),
	})
end

return ProgressBar
