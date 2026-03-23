--!strict
-- CustomShoutUI.luau
-- Client-side: TextBox đổi câu hét cá nhân

local Players      = game:GetService("Players")
local _UserInputService = game:GetService("UserInputService")

local Shared      = game.ReplicatedStorage.Shared
local Config      = require(Shared.Config)
local Remotes     = require(Shared.Remotes)

local CustomShoutUI = {}
local LocalPlayer   = Players.LocalPlayer
local PlayerGui     = LocalPlayer:WaitForChild("PlayerGui")

local shoutScreen: ScreenGui? = nil
local isOpen = false

local function buildUI(): ScreenGui
	local screen           = Instance.new("ScreenGui")
	screen.Name            = "CustomShoutUI"
	screen.ResetOnSpawn    = false
	screen.DisplayOrder    = 20
	screen.Enabled         = false

	local panel            = Instance.new("Frame")
	panel.Name             = "Panel"
	panel.Size             = UDim2.new(0, 400, 0, 200)
	panel.Position         = UDim2.new(0.5, -200, 0.35, 0)
	panel.BackgroundColor3 = Config.Theme.Background
	panel.BackgroundTransparency = Config.Theme.Transparency
	panel.BorderSizePixel  = 0
	panel.Parent           = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Config.Theme.CornerRadius
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Config.Theme.StrokeColor
	stroke.Thickness = Config.Theme.StrokeThickness
	stroke.Transparency = 0.3
	stroke.Parent = panel

	local title    = Instance.new("TextLabel")
	title.Size     = UDim2.new(1, 0, 0, 48)
	title.BackgroundTransparency = 1
	title.Text     = "🎤 " .. Config.Localization.CustomShout.Title
	title.TextColor3 = Config.Theme.TextMain
	title.Font     = Enum.Font.GothamBlack
	title.TextSize = 22
	title.Parent   = panel

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new(Config.Theme.PrimaryGradient[1], Config.Theme.PrimaryGradient[2])
	titleGradient.Parent = title

	local hint     = Instance.new("TextLabel")
	hint.Size      = UDim2.new(1, -30, 0, 20)
	hint.Position  = UDim2.new(0, 15, 0, 48)
	hint.BackgroundTransparency = 1
	hint.Text      = Config.Localization.CustomShout.Desc
	hint.TextColor3 = Config.Theme.TextSecondary
	hint.Font      = Enum.Font.Gotham
	hint.TextSize  = 13
	hint.Parent    = panel

	local textBox  = Instance.new("TextBox")
	textBox.Name   = "ShoutTextBox"
	textBox.Size   = UDim2.new(1, -30, 0, 44)
	textBox.Position = UDim2.new(0, 15, 0, 75)
	textBox.BackgroundColor3 = Config.Theme.SecondaryBackground
	textBox.BackgroundTransparency = 0.4
	textBox.PlaceholderText = Config.Localization.CustomShout.Placeholder
	textBox.PlaceholderColor3 = Config.Theme.TextMuted
	textBox.Text   = ""
	textBox.TextColor3 = Config.Theme.TextMain
	textBox.Font   = Enum.Font.GothamBold
	textBox.TextSize = 18
	textBox.ClearTextOnFocus = false
	textBox.BorderSizePixel = 0
	textBox.Parent = panel

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Config.Theme.StrokeColor
	boxStroke.Thickness = 1
	boxStroke.Transparency = 0.6
	boxStroke.Parent = textBox

	local cornerBox = Instance.new("UICorner")
	cornerBox.CornerRadius = UDim.new(0, 10)
	cornerBox.Parent = textBox

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Size  = UDim2.new(0.48, -10, 0, 44)
	confirmBtn.Position = UDim2.new(0, 15, 1, -60)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.Text  = "✅ " .. Config.Localization.CustomShout.Confirm
	confirmBtn.TextColor3 = Config.Theme.TextMain
	confirmBtn.Font  = Enum.Font.GothamBold
	confirmBtn.TextSize = 16
	confirmBtn.BorderSizePixel = 0
	confirmBtn.Parent = panel

	local gConf = Instance.new("UIGradient")
	gConf.Color = ColorSequence.new(Config.Theme.SuccessGradient[1], Config.Theme.SuccessGradient[2])
	gConf.Parent = confirmBtn

	local cornerConf = Instance.new("UICorner")
	cornerConf.CornerRadius = UDim.new(0, 10)
	cornerConf.Parent = confirmBtn

	local cancelBtn  = Instance.new("TextButton")
	cancelBtn.Size   = UDim2.new(0.48, -10, 0, 44)
	cancelBtn.Position = UDim2.new(0.52, 5, 1, -60)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	cancelBtn.Text   = "❌ " .. Config.Localization.CustomShout.Cancel
	cancelBtn.TextColor3 = Config.Theme.TextSecondary
	cancelBtn.Font   = Enum.Font.GothamBold
	cancelBtn.TextSize = 16
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Parent = panel

	local cornerCan = Instance.new("UICorner")
	cornerCan.CornerRadius = UDim.new(0, 10)
	cornerCan.Parent = cancelBtn

	confirmBtn.Activated:Connect(function()
		local text = textBox.Text
		if #text > 0 then
			Remotes.Events.SetCustomShout:FireServer(text:sub(1, Config.CustomShout.MaxLength))
		end
		CustomShoutUI.Close()
	end)

	cancelBtn.Activated:Connect(function()
		CustomShoutUI.Close()
	end)

	return screen
end

function CustomShoutUI.Init()
	local screen = buildUI()
	screen.Parent = PlayerGui
	shoutScreen = screen
end

function CustomShoutUI.Open()
	if shoutScreen then shoutScreen.Enabled = true; isOpen = true end
end

function CustomShoutUI.Close()
	if shoutScreen then shoutScreen.Enabled = false; isOpen = false end
end

function CustomShoutUI.Toggle()
	if isOpen then CustomShoutUI.Close() else CustomShoutUI.Open() end
end

return CustomShoutUI
