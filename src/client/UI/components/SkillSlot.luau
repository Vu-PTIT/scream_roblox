--!strict
-- SkillSlot.luau
-- A reusable skill slot component for the HUD.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local Config = require(ReplicatedStorage.Shared.Config)

type Props = {
	Index: number,
	Data: any, -- Current player data
	ShoutController: any,
	LayoutOrder: number?,
}

local function SkillSlot(props: Props)
	local cooldown, setCooldown = React.useState(0)
	local isCharging, setCharging = React.useState(false)
	local isSelected, setSelected = React.useState(false)

	-- Get current skill config
	local skillId = props.Data.EquippedSkillIds and (props.Data.EquippedSkillIds[props.Index] or props.Data.EquippedSkillIds[tostring(props.Index)])
	if skillId == "" then skillId = nil end
	local skillCfg = nil
	local targetType = nil
	if skillId and props.Data.Skills then
		for _, s in ipairs(props.Data.Skills) do
			if s.Id == skillId then
				targetType = s.SkillType
				break
			end
		end
	end

	if targetType then
		for _, cfg in ipairs(Config.Skills) do
			if cfg.SkillType == targetType then
				skillCfg = cfg
				break
			end
		end
	end
	if not skillCfg then skillCfg = Config.Skills[1] end -- Fallback to basic shout

	-- Cooldown and Charge Update Loop
	React.useEffect(function()
		local connection = RunService.RenderStepped:Connect(function()
			if not props.ShoutController then return end
			
			local now = os.clock()
			local lastTime, cdDuration = props.ShoutController.GetCooldownData(props.Index)
			local elapsed = now - lastTime
			
			if elapsed < cdDuration then
				setCooldown(1 - (elapsed / cdDuration))
			else
				setCooldown(0)
			end

			setCharging(props.ShoutController.GetChargingSlot() == props.Index)
			setSelected(props.ShoutController.GetSelectedSlot() == props.Index)
		end)

		return function()
			connection:Disconnect()
		end
	end, {props.Index, props.ShoutController})

	local baseColor = isCharging and Color3.fromRGB(255, 255, 200) or Config.Theme.Background
	local strokeColor = isSelected and Color3.fromRGB(255, 215, 0) or Color3.new(1, 1, 1)
	local strokeThickness = isSelected and 2.5 or 1.5

	return React.createElement("Frame", {
		Size = UDim2.new(0, 60, 0, 60),
		BackgroundColor3 = baseColor,
		BackgroundTransparency = 0.2,
		LayoutOrder = props.LayoutOrder,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = Config.Theme.CornerRadius }),
		Stroke = React.createElement("UIStroke", {
			Color = strokeColor,
			Thickness = strokeThickness,
			Transparency = 0.6,
		}),

		Icon = React.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = skillCfg.Icon or "📢",
			TextSize = 28,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold,
			ZIndex = 2,
		}),

		-- Cooldown Overlay
		CDOverlay = React.createElement("Frame", {
			Size = UDim2.new(1, 0, cooldown, 0),
			Position = UDim2.new(0, 0, 1 - cooldown, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			ZIndex = 5,
			Visible = cooldown > 0,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = Config.Theme.CornerRadius }),
		}),

		-- Shortcut Tag
		ShortcutTag = React.createElement("TextLabel", {
			Size = UDim2.new(0, 18, 0, 18),
			Position = UDim2.new(1, -4, 1, -4),
			AnchorPoint = Vector2.new(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.4,
			Text = tostring(props.Index),
			TextSize = 10,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBlack,
			ZIndex = 6,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }),
		}),
	})
end

return SkillSlot
