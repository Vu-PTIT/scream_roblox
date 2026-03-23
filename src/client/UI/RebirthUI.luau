--!strict
-- RebirthUI.luau
-- Client-side: Rebirth confirmation dialog

local Players      = game:GetService("Players")
local _TweenService = game:GetService("TweenService")

local Shared      = game.ReplicatedStorage.Shared
local Config      = require(Shared.Config)
local Remotes     = require(Shared.Remotes)

local DataController: any = nil
task.defer(function()
	DataController = require(script.Parent.Parent.Controllers.DataController)
end)

local RebirthUI = {}
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local rebirthScreen: ScreenGui? = nil
local _isOpen = false

local function buildRebirthUI(): ScreenGui
	local screen           = Instance.new("ScreenGui")
	screen.Name            = "RebirthUI"
	screen.ResetOnSpawn    = false
	screen.DisplayOrder    = 20
	screen.Enabled         = false

	local overlay          = Instance.new("Frame")
	overlay.Size           = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.6
	overlay.BorderSizePixel = 0
	overlay.Parent         = screen

	local panel            = Instance.new("Frame")
	panel.Name             = "Panel"
	panel.Size             = UDim2.new(0, 440, 0, 330)
	panel.Position         = UDim2.new(0.5, -220, 0.5, -165)
	panel.BackgroundColor3 = Config.Theme.Background
	panel.BackgroundTransparency = Config.Theme.Transparency
	panel.BorderSizePixel  = 0
	panel.Parent           = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Config.Theme.CornerRadius
	corner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Config.Theme.StrokeColor
	panelStroke.Thickness = Config.Theme.StrokeThickness
	panelStroke.Transparency = 0.3
	panelStroke.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(200, 160, 0)
	stroke.Thickness = 2
	stroke.Parent = panel

	local starLabel = Instance.new("TextLabel")
	starLabel.Size  = UDim2.new(1, 0, 0, 60)
	starLabel.Position = UDim2.new(0, 0, 0, 10)
	starLabel.BackgroundTransparency = 1
	starLabel.Text  = "⭐   " .. Config.Localization.Rebirth.Title .. "   ⭐"
	starLabel.TextColor3 = Config.Theme.TextMain
	starLabel.Font  = Enum.Font.GothamBlack
	starLabel.TextSize = 24 -- Reduced from 28 to prevent overlap
	starLabel.TextWrapped = true
	starLabel.Parent = panel

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new(Config.Theme.RebirthGradient[1], Config.Theme.RebirthGradient[2])
	titleGradient.Parent = starLabel

	local descLabel = Instance.new("TextLabel")
	descLabel.Name  = "DescLabel"
	descLabel.Size  = UDim2.new(1, -50, 0, 80)
	descLabel.Position = UDim2.new(0, 25, 0, 75)
	descLabel.BackgroundTransparency = 1
	descLabel.Text  = Config.Localization.Rebirth.Desc
	descLabel.TextColor3 = Config.Theme.TextSecondary
	descLabel.Font  = Enum.Font.Gotham
	descLabel.TextSize = 15
	descLabel.TextWrapped = true
	descLabel.Parent = panel

	local multPreview = Instance.new("TextLabel")
	multPreview.Name  = "MultPreview"
	multPreview.Size  = UDim2.new(1, -50, 0, 44)
	multPreview.Position = UDim2.new(0, 25, 0, 165)
	multPreview.BackgroundColor3 = Config.Theme.SecondaryBackground
	multPreview.BackgroundTransparency = 0.4
	multPreview.Text  = string.format(Config.Localization.Rebirth.NewMult, 1.25)
	multPreview.TextColor3 = Config.Theme.TextMain
	multPreview.Font  = Enum.Font.GothamBold
	multPreview.TextSize = 18
	multPreview.BorderSizePixel = 0
	multPreview.Parent = panel

	local prevStroke = Instance.new("UIStroke")
	prevStroke.Color = Config.Theme.StrokeColor
	prevStroke.Thickness = 1
	prevStroke.Transparency = 0.6
	prevStroke.Parent = multPreview

	local cornerPrev = Instance.new("UICorner")
	cornerPrev.CornerRadius = UDim.new(0, 10)
	cornerPrev.Parent = multPreview

	-- Confirm Button
	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Size  = UDim2.new(0, 180, 0, 50)
	confirmBtn.Position = UDim2.new(0, 25, 1, -75)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.Text  = Config.Localization.Rebirth.Confirm
	confirmBtn.TextColor3 = Config.Theme.TextMain
	confirmBtn.Font  = Enum.Font.GothamBold
	confirmBtn.TextSize = 16
	confirmBtn.TextScaled = true -- Added to ensure text fits
	confirmBtn.BorderSizePixel = 0
	confirmBtn.Parent = panel

	local cornerIcon = Instance.new("TextLabel")
	cornerIcon.Size = UDim2.new(0, 30, 1, 0)
	cornerIcon.Position = UDim2.new(0, 10, 0, 0)
	cornerIcon.BackgroundTransparency = 1
	cornerIcon.Text = "✅"
	cornerIcon.TextSize = 18
	cornerIcon.ZIndex = 2
	cornerIcon.Parent = confirmBtn

	local gCon = Instance.new("UIGradient")
	gCon.Color = ColorSequence.new(Config.Theme.SuccessGradient[1], Config.Theme.SuccessGradient[2])
	gCon.Parent = confirmBtn

	local cornerCon = Instance.new("UICorner")
	cornerCon.CornerRadius = UDim.new(0, 12)
	cornerCon.Parent = confirmBtn

	confirmBtn.Activated:Connect(function()
		Remotes.Events.RebirthRequest:FireServer()
		RebirthUI.Close()
	end)

	-- Cancel Button
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size  = UDim2.new(0, 180, 0, 50)
	cancelBtn.Position = UDim2.new(1, -205, 1, -75)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	cancelBtn.Text  = "❌ " .. Config.Localization.Rebirth.Cancel
	cancelBtn.TextColor3 = Config.Theme.TextSecondary
	cancelBtn.Font  = Enum.Font.GothamBold
	cancelBtn.TextSize = 18
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Parent = panel

	local cornerCan = Instance.new("UICorner")
	cornerCan.CornerRadius = UDim.new(0, 12)
	cornerCan.Parent = cancelBtn

	cancelBtn.Activated:Connect(function() RebirthUI.Close() end)

	-- Update multiplier preview khi mở
	task.defer(function()
		task.wait(0.5)
		if DataController then
			DataController.OnDataChanged(function(key, _)
				if key == "RebirthCount" or key == "RebirthMultiplier" or key == "__all__" then
					local data = DataController.GetData()
					if data then
						local newMult = 1 + ((data.RebirthCount + 1) * Config.Rebirth.MultiplierPerRebirth)
						multPreview.Text = string.format(Config.Localization.Rebirth.NewMult, newMult)
					end
				end
			end)
		end
	end)

	return screen
end

function RebirthUI.Init()
	local screen = buildRebirthUI()
	screen.Parent = PlayerGui
	rebirthScreen = screen
end

function RebirthUI.Open()
	if rebirthScreen then
		-- Refresh preview
		if DataController then
			local data = DataController.GetData()
			if data then
				local panel    = rebirthScreen:FindFirstChild("Panel") :: Frame?
				local preview  = panel and panel:FindFirstChild("MultPreview") :: TextLabel?
				if preview then
					local newMult = 1 + ((data.RebirthCount + 1) * Config.Rebirth.MultiplierPerRebirth)
					preview.Text = string.format(Config.Localization.Rebirth.NewMult, newMult)
				end
			end
		end
		rebirthScreen.Enabled = true
		_isOpen = true
	end
end

function RebirthUI.Close()
	if rebirthScreen then rebirthScreen.Enabled = false; _isOpen = false end
end

return RebirthUI
