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

local function getPlayerGui(): PlayerGui?
	if not LocalPlayer then return nil end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local rebirthScreen: ScreenGui? = nil
local _isOpen = false

local function buildRebirthUI(): ScreenGui
	local screen           = Instance.new("ScreenGui")
	screen.Name            = "RebirthUI"
	screen.ResetOnSpawn    = false
	screen.DisplayOrder    = 20
	screen.IgnoreGuiInset  = true
	screen.Enabled         = false

	local overlay          = Instance.new("Frame")
	overlay.Size           = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent         = screen

	local panel            = Instance.new("Frame")
	panel.Name             = "Panel"
	panel.Size             = UDim2.new(0, 480, 0, 380)
	panel.Position         = UDim2.new(0.5, 0, 0.5, 0)
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

	local title = Instance.new("TextLabel")
	title.Size  = UDim2.new(1, 0, 0, 64)
	title.BackgroundTransparency = 1
	title.Text  = "REBIRTH"
	title.TextColor3 = Config.Theme.TextMain
	title.Font  = Enum.Font.GothamBlack
	title.TextSize = 24
	title.Parent = panel
	
	local titleGrad = Instance.new("UIGradient")
	titleGrad.Color = ColorSequence.new(Config.Theme.RebirthGradient[1], Config.Theme.RebirthGradient[2])
	titleGrad.Parent = title

	local descLabel = Instance.new("TextLabel")
	descLabel.Name  = "DescLabel"
	descLabel.Size  = UDim2.new(1, -60, 0, 100)
	descLabel.Position = UDim2.new(0, 30, 0, 80)
	descLabel.BackgroundTransparency = 1
	descLabel.Text  = Config.Localization.Rebirth.Desc
	descLabel.TextColor3 = Config.Theme.TextSecondary
	descLabel.Font  = Enum.Font.Gotham
	descLabel.TextSize = 15
	descLabel.TextWrapped = true
	descLabel.Parent = panel

	local multPreview = Instance.new("TextLabel")
	multPreview.Name  = "MultPreview"
	multPreview.Size  = UDim2.new(1, -60, 0, 50)
	multPreview.Position = UDim2.new(0, 30, 0, 190)
	multPreview.BackgroundColor3 = Config.Theme.SecondaryBackground
	multPreview.BackgroundTransparency = 0.3
	multPreview.Text  = string.format("NEW MULTIPLIER: x%.2f", 1.25)
	multPreview.TextColor3 = Config.Theme.TextMain
	multPreview.Font  = Enum.Font.GothamBold
	multPreview.TextSize = 20
	multPreview.BorderSizePixel = 0
	multPreview.Parent = panel

	local cornerPrev = Instance.new("UICorner")
	cornerPrev.CornerRadius = UDim.new(0, 12)
	cornerPrev.Parent = multPreview

	-- Confirm Button
	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Size  = UDim2.new(0, 200, 0, 54)
	confirmBtn.Position = UDim2.new(0.5, -210, 1, -85)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.Text  = "CONFIRM"
	confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.Font  = Enum.Font.GothamBold
	confirmBtn.TextSize = 18
	confirmBtn.BorderSizePixel = 0
	confirmBtn.Parent = panel

	local gCon = Instance.new("UIGradient")
	gCon.Color = ColorSequence.new(Config.Theme.SuccessGradient[1], Config.Theme.SuccessGradient[2])
	gCon.Parent = confirmBtn

	local cornerCon = Instance.new("UICorner")
	cornerCon.CornerRadius = UDim.new(0, 27)
	cornerCon.Parent = confirmBtn

	confirmBtn.Activated:Connect(function()
		Remotes.Events.RebirthRequest:FireServer()
		RebirthUI.Close()
	end)

	-- Cancel Button
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size  = UDim2.new(0, 200, 0, 54)
	cancelBtn.Position = UDim2.new(0.5, 10, 1, -85)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	cancelBtn.Text  = "CANCEL"
	cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.Font  = Enum.Font.GothamBold
	cancelBtn.TextSize = 18
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Parent = panel

	local cornerCan = Instance.new("UICorner")
	cornerCan.CornerRadius = UDim.new(0, 27)
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

function RebirthUI.Init(overrideParent: Instance?)
	local pg = overrideParent or getPlayerGui()
	if not pg then return end
	
	-- [SMART BINDING] Detect existing RebirthUI
	local existing: ScreenGui? = nil
	for _, child in ipairs(pg:GetChildren()) do
		if child:IsA("ScreenGui") then
			if child.Name == "RebirthUI" or child:FindFirstChild("MultPreview", true) then
				if not existing then
					existing = child
				else
					child:Destroy()
				end
			end
		end
	end
	
	if existing then
		rebirthScreen = existing
		print("ℹ️ [RebirthUI] Using existing ScreenGui for smart binding.")
		return
	end

	local screen = buildRebirthUI()
	screen.Parent = pg
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
