--!strict
-- CodeUI.luau
-- Client-side: TextBox đổi câu hét cá nhân (Redesigned as Promo Code modal)
local Players      = game:GetService("Players")

local Shared      = game.ReplicatedStorage.Shared
local Config      = require(Shared.Config)
local Remotes     = require(Shared.Remotes)

local CodeUI = {}
local LocalPlayer   = Players.LocalPlayer
local PlayerGui     = LocalPlayer:WaitForChild("PlayerGui")

local codeScreen: ScreenGui? = nil
local isOpen = false

local function buildUI(): ScreenGui
	local screen           = Instance.new("ScreenGui")
	screen.Name            = "CodeUI"
	screen.ResetOnSpawn    = false
	screen.DisplayOrder    = 20
	screen.Enabled         = false

	local panel            = Instance.new("Frame")
	panel.Name             = "Panel"
	panel.Size             = UDim2.new(0, 350, 0, 180)
	panel.Position         = UDim2.new(0.5, -175, 0.35, 0)
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
	title.Text     = "🎁 " .. Config.Localization.CodeUI.Title
	title.TextColor3 = Config.Theme.TextMain
	title.Font     = Enum.Font.GothamBlack
	title.TextSize = 22
	title.Parent   = panel

	local textBox  = Instance.new("TextBox")
	textBox.Name   = "CodeTextBox"
	textBox.Size   = UDim2.new(1, -30, 0, 44)
	textBox.Position = UDim2.new(0, 15, 0, 60)
	textBox.BackgroundColor3 = Config.Theme.SecondaryBackground
	textBox.BackgroundTransparency = 0.4
	textBox.PlaceholderText = Config.Localization.CodeUI.Placeholder
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
	confirmBtn.BackgroundColor3 = Config.Theme.BtnCodeBase
	confirmBtn.Text  = "✅ " .. Config.Localization.CodeUI.Redeem
	confirmBtn.TextColor3 = Config.Theme.TextMain
	confirmBtn.Font  = Enum.Font.GothamBold
	confirmBtn.TextSize = 16
	confirmBtn.BorderSizePixel = 0
	confirmBtn.Parent = panel

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
			Remotes.Events.RedeemCode:FireServer(text)
		end
		CodeUI.Close()
	end)

	cancelBtn.Activated:Connect(function()
		CodeUI.Close()
	end)

	return screen
end

function CodeUI.Init()
	local screen = buildUI()
	screen.Parent = PlayerGui
	codeScreen = screen
end

function CodeUI.Open()
	if codeScreen then codeScreen.Enabled = true; isOpen = true end
end

function CodeUI.Close()
	if codeScreen then codeScreen.Enabled = false; isOpen = false end
end

function CodeUI.Toggle()
	if isOpen then CodeUI.Close() else CodeUI.Open() end
end

return CodeUI
