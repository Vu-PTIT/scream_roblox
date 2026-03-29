local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)

type WindowProps = {
	Title: string,
	Icon: string?,
	Visible: boolean,
	OnClose: () -> (),
	Children: any?,
	Size: UDim2?,
}

local function Window(props: WindowProps)
	if not props.Visible then return nil end

	local size = props.Size or UDim2.new(0, 520, 0, 580)

	return React.createElement("Frame", {
		Name = props.Title .. "Window",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 10,
	}, {
		Panel = React.createElement("Frame", {
			Size = size,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Config.Theme.Background,
			BackgroundTransparency = Config.Theme.PanelTransparency,
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = Config.Theme.CornerRadius }),
			Stroke = React.createElement("UIStroke", {
				Color = Config.Theme.StrokeColor,
				Thickness = Config.Theme.StrokeThickness,
				Transparency = 0.3,
			}),
			Gradient = React.createElement("UIGradient", {
				Color = ColorSequence.new(Config.Theme.PanelGradient[1], Config.Theme.PanelGradient[2]),
				Rotation = 45,
			}),

			-- Title Bar
			TitleBar = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 60),
				BackgroundTransparency = 1,
			}, {
				Text = React.createElement("TextLabel", {
					Size = UDim2.new(1, -60, 1, 0),
					Position = UDim2.new(0, 15, 0, 0),
					BackgroundTransparency = 1,
					Text = (props.Icon or "") .. " " .. props.Title,
					TextColor3 = Config.Theme.TextMain,
					Font = Enum.Font.GothamBlack,
					TextSize = 22,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				CloseButton = React.createElement("TextButton", {
					Size = UDim2.new(0, 40, 0, 40),
					Position = UDim2.new(1, -50, 0, 10),
					BackgroundColor3 = Color3.fromRGB(220, 60, 60),
					Text = "✕",
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold,
					TextSize = 18,
					BorderSizePixel = 0,
					[React.Event.Activated] = props.OnClose,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
				}),
			}),

			-- Content Container
			Content = React.createElement("Frame", {
				Size = UDim2.new(1, -20, 1, -80),
				Position = UDim2.new(0, 10, 0, 75),
				BackgroundTransparency = 1,
				ZIndex = 2,
			}, (function()
				local c = props.Children or (props :: any).children
				print("[Window] Rendering content for:", props.Title, "Children exist:", c ~= nil)
				return c
			end)()),
		}),
	})
end

return Window
