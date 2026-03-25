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

local function getPlayerGui(): PlayerGui?
	if not LocalPlayer then return nil end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local shoutScreen: ScreenGui? = nil
local isOpen = false

local function buildUI(): ScreenGui
	local screen           = Instance.new("ScreenGui")
	screen.Name            = "CustomShoutUI"
	screen.ResetOnSpawn    = false
	screen.DisplayOrder    = 20
	screen.IgnoreGuiInset  = true
	screen.Enabled         = false

	local overlay           = Instance.new("Frame")
	overlay.Size            = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent          = screen

	local panel            = Instance.new("Frame")
	panel.Name             = "Panel"
	panel.Size             = UDim2.new(0, 440, 0, 260)
	panel.Position         = UDim2.new(0.5, 0, 0.45, 0)
	panel.AnchorPoint      = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Config.Theme.Background
	panel.BackgroundTransparency = Config.Theme.PanelTransparency
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
	
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Config.Theme.PanelGradient[1], Config.Theme.PanelGradient[2])
	grad.Rotation = 45
	grad.Parent = panel

	local title    = Instance.new("TextLabel")
	title.Size     = UDim2.new(1, 0, 0, 64)
	title.BackgroundTransparency = 1
	title.Text     = "CUSTOM SHOUT"
	title.TextColor3 = Config.Theme.TextMain
	title.Font     = Enum.Font.GothamBlack
	title.TextSize = 24
	title.Parent   = panel
	
	local titleGrad = Instance.new("UIGradient")
	titleGrad.Color = ColorSequence.new(Config.Theme.PrimaryGradient[1], Config.Theme.PrimaryGradient[2])
	titleGrad.Parent = title

	local hint     = Instance.new("TextLabel")
	hint.Size      = UDim2.new(1, -60, 0, 40)
	hint.Position  = UDim2.new(0, 30, 0, 65)
	hint.BackgroundTransparency = 1
	hint.Text      = "CHANGES YOUR SHOUT TEXT VISUALLY"
	hint.TextColor3 = Config.Theme.TextSecondary
	hint.Font      = Enum.Font.Gotham
	hint.TextSize  = 13
	hint.Parent    = panel

	local textBox  = Instance.new("TextBox")
	textBox.Name   = "ShoutTextBox"
	textBox.Size   = UDim2.new(1, -60, 0, 50)
	textBox.Position = UDim2.new(0, 30, 0, 105)
	textBox.BackgroundColor3 = Config.Theme.SecondaryBackground
	textBox.BackgroundTransparency = 0.3
	textBox.PlaceholderText = "TYPE YOUR SHOUT..."
	textBox.PlaceholderColor3 = Config.Theme.TextMuted
	textBox.Text   = ""
	textBox.TextColor3 = Config.Theme.TextMain
	textBox.Font   = Enum.Font.GothamBold
	textBox.TextSize = 18
	textBox.ClearTextOnFocus = false
	textBox.BorderSizePixel = 0
	textBox.Parent = panel

	local cornerBox = Instance.new("UICorner")
	cornerBox.CornerRadius = UDim.new(0, 12)
	cornerBox.Parent = textBox
	
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Config.Theme.StrokeColor
	boxStroke.Thickness = 1
	boxStroke.Transparency = 0.5
	boxStroke.Parent = textBox

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Size  = UDim2.new(0, 185, 0, 50)
	confirmBtn.Position = UDim2.new(0, 30, 1, -75)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.Text  = "CONFIRM"
	confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.Font  = Enum.Font.GothamBold
	confirmBtn.TextSize = 16
	confirmBtn.BorderSizePixel = 0
	confirmBtn.Parent = panel
	
	local gCon = Instance.new("UIGradient")
	gCon.Color = ColorSequence.new(Config.Theme.SuccessGradient[1], Config.Theme.SuccessGradient[2])
	gCon.Parent = confirmBtn

	local cornerConf = Instance.new("UICorner")
	cornerConf.CornerRadius = UDim.new(0, 25)
	cornerConf.Parent = confirmBtn

	local cancelBtn  = Instance.new("TextButton")
	cancelBtn.Size   = UDim2.new(0, 185, 0, 50)
	cancelBtn.Position = UDim2.new(1, -215, 1, -75)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	cancelBtn.Text   = "CANCEL"
	cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.Font   = Enum.Font.GothamBold
	cancelBtn.TextSize = 16
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Parent = panel

	local cornerCan = Instance.new("UICorner")
	cornerCan.CornerRadius = UDim.new(0, 25)
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

function CustomShoutUI.Init(overrideParent: Instance?)
	local pg = overrideParent or getPlayerGui()
	if not pg then return end
	
	-- [SMART BINDING] Detect existing CustomShoutUI
	local existing: ScreenGui? = nil
	for _, child in ipairs(pg:GetChildren()) do
		if child:IsA("ScreenGui") then
			if child.Name == "CustomShoutUI" or child:FindFirstChild("Panel", true) then
				if not existing then
					existing = child
				else
					child:Destroy()
				end
			end
		end
	end
	
	if existing then
		shoutScreen = existing
		print("ℹ️ [CustomShoutUI] Using existing ScreenGui for smart binding.")
		return
	end

	local screen = buildUI()
	screen.Parent = pg
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
