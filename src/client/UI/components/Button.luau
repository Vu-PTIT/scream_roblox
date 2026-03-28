local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Ripple = require(ReplicatedStorage.Packages.Ripple)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)

type ButtonProps = {
	Text: string,
	OnClick: () -> (),
	LayoutOrder: number?,
	Size: UDim2?,
	Position: UDim2?,
	Variant: string?, -- "Primary", "Success", "Rebirth", "Shop", "Pets", "Quest", "Cancel"
	Enabled: boolean?,
}

local function Button(props: ButtonProps)
	local isEnabled = if props.Enabled ~= nil then props.Enabled else true
	local variant = props.Variant or "Primary"

	local baseColor = Config.Theme.BtnShopBase
	local shadowColor = Config.Theme.BtnShopShadow

	if variant == "Success" then
		baseColor = Config.Theme.SuccessGradient[1]
		shadowColor = Config.Theme.SuccessGradient[2]
	elseif variant == "Rebirth" then
		baseColor = Config.Theme.BtnRebirthBase
		shadowColor = Config.Theme.BtnRebirthShadow
	elseif variant == "Pets" then
		baseColor = Config.Theme.BtnPetsBase
		shadowColor = Config.Theme.BtnPetsShadow
	elseif variant == "Quest" then
		baseColor = Config.Theme.BtnQuestBase
		shadowColor = Config.Theme.BtnQuestShadow
	elseif variant == "Cancel" or variant == "Secondary" then
		baseColor = Color3.fromRGB(60, 60, 80)
		shadowColor = Color3.fromRGB(40, 40, 60)
	end

	if not isEnabled then
		baseColor = Color3.fromRGB(80, 80, 80)
		shadowColor = Color3.fromRGB(50, 50, 50)
	end

	local radius = if props.Size then UDim.new(0, props.Size.Y.Offset / 2) else UDim.new(0, 22)

	-- Ripple Motion
	local scale, setScale = React.useState(1)
	local scaleMotion = React.useMemo(function()
		return Ripple.createMotion(1)
	end, {})

	React.useEffect(function()
		local disconnect = scaleMotion:onStep(function(value)
			setScale(value)
		end)
		return function()
			disconnect()
		end
	end, { scaleMotion })

	local function onMouseEnter()
		if isEnabled then
			scaleMotion:spring(1.05, Ripple.config.spring.gentle :: any)
		end
	end

	local function onMouseLeave()
		if isEnabled then
			scaleMotion:spring(1, Ripple.config.spring.gentle :: any)
		end
	end

	local function onInputBegan(rbx, input)
		if
			isEnabled
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			scaleMotion:spring(0.9, Ripple.config.spring.stiff :: any)
		end
	end

	local function onInputEnded(rbx, input)
		if
			isEnabled
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			scaleMotion:spring(1.05, Ripple.config.spring.gentle :: any)
		end
	end

	return React.createElement("Frame", {
		Name = props.Text .. "Button",
		Size = props.Size or UDim2.new(0, 160, 0, 44),
		Position = props.Position,
		LayoutOrder = props.LayoutOrder,
		BackgroundTransparency = 1,
	}, {
		UIScale = React.createElement("UIScale", {
			Scale = scale,
		}),

		Shadow = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = shadowColor,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = radius }),
		}),

		Main = React.createElement("TextButton", {
			Size = UDim2.new(1, 0, 1, -4),
			BackgroundColor3 = baseColor,
			Text = "",
			BorderSizePixel = 0,
			AutoButtonColor = false, -- Disable default Roblox hover effect to use Ripple
			ZIndex = 2,
			[React.Event.Activated] = function()
				if isEnabled then
					props.OnClick()
				end
			end,
			[React.Event.MouseEnter] = onMouseEnter,
			[React.Event.MouseLeave] = onMouseLeave,
			[React.Event.InputBegan] = onInputBegan,
			[React.Event.InputEnded] = onInputEnded,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = radius }),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.new(1, 1, 1),
				Thickness = 1,
				Transparency = 0.8,
			}),
			Label = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = props.Text,
				TextColor3 = isEnabled and Color3.new(1, 1, 1) or Color3.new(0.6, 0.6, 0.6),
				Font = Enum.Font.GothamBold,
				TextSize = 16,
				ZIndex = 3,
			}),
		}),
	})
end

return Button
