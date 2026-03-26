--!strict
-- RewardUI.luau
-- Client-side: Playtime rewards UI

local Players      = game:GetService("Players")

local Shared      = game.ReplicatedStorage.Shared
local Config      = require(Shared.Config)
local Remotes     = require(Shared.Remotes)

local DataController: any = nil
task.defer(function()
	DataController = require(script.Parent.Parent.Controllers.DataController)
end)

local RewardUI = {}
local LocalPlayer   = Players.LocalPlayer

local function getPlayerGui(): PlayerGui?
	if not LocalPlayer then return nil end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local rewardScreen: ScreenGui? = nil
local isOpen = false

local function buildUI(): ScreenGui
	local screen           = Instance.new("ScreenGui")
	screen.Name            = "RewardUI"
	screen.ResetOnSpawn    = false
	screen.DisplayOrder    = 20
	screen.IgnoreGuiInset  = true
	screen.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	screen.Enabled         = false

	local overlay           = Instance.new("Frame")
	overlay.Size            = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent          = screen

	local panel            = Instance.new("Frame")
	panel.Name             = "Panel"
	panel.Size             = UDim2.new(0, 480, 0, 460)
	panel.Position         = UDim2.new(0.5, 0, 0.5, 0)
	panel.AnchorPoint      = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Config.Theme.Background
	panel.BackgroundTransparency = Config.Theme.PanelTransparency
	panel.BorderSizePixel  = 4
	panel.BorderColor3     = Color3.fromRGB(100, 255, 100) -- LIGHT GREEN BORDER
	panel.ZIndex           = 1
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
	title.Text     = "PLAYTIME REWARDS"
	title.TextColor3 = Config.Theme.TextMain
	title.Font     = Enum.Font.GothamBlack
	title.TextSize = 24
	title.ZIndex   = 2
	title.Parent   = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size  = UDim2.new(0, 44, 0, 44)
	closeBtn.Position = UDim2.new(1, -54, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	closeBtn.Text  = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font  = Enum.Font.GothamBold
	closeBtn.TextSize = 20
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = panel
	
	local cornerClose = Instance.new("UICorner")
	cornerClose.CornerRadius = UDim.new(0, 10)
	cornerClose.Parent = closeBtn

	closeBtn.Activated:Connect(function() RewardUI.Close() end)

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "RewardList"
	listFrame.Size = UDim2.new(1, -30, 1, -85)
	listFrame.Position = UDim2.new(0, 15, 0, 70)
	listFrame.BackgroundTransparency = 1
	listFrame.ScrollBarThickness = 4
	listFrame.ScrollBarImageColor3 = Config.Theme.BtnRewardBase
	listFrame.BorderSizePixel = 0
	listFrame.Parent = panel
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.Parent = listFrame

	for i, milestone in ipairs(Config.Rewards.PlaytimeMilestones) do
		local item = Instance.new("Frame")
		item.Name = "Milestone_" .. tostring(i)
		item.Size = UDim2.new(1, -10, 0, 80)
		item.BackgroundColor3 = Config.Theme.SecondaryBackground
		item.BackgroundTransparency = 0.3
		item.BorderSizePixel = 0
		item.LayoutOrder = i
		item.Parent = listFrame
		
		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 12)
		itemCorner.Parent = item
		
		local itemStroke = Instance.new("UIStroke")
		itemStroke.Color = Config.Theme.StrokeColor
		itemStroke.Thickness = 1
		itemStroke.Transparency = 0.5
		itemStroke.Parent = item
		
		local minutes = math.floor(milestone.Time / 60)
		local timeLabel = Instance.new("TextLabel")
		timeLabel.Size = UDim2.new(0.65, 0, 0, 24)
		timeLabel.Position = UDim2.new(0, 15, 0, 15)
		timeLabel.BackgroundTransparency = 1
		timeLabel.Text = string.format("TIME: %d MINUTES", minutes)
		timeLabel.TextColor3 = Config.Theme.TextMain
		timeLabel.Font = Enum.Font.GothamBold
		timeLabel.TextSize = 16
		timeLabel.TextXAlignment = Enum.TextXAlignment.Left
		timeLabel.Parent = item
		
		local rewardStr = string.format("%s %s", tostring(milestone.Reward.Amount), milestone.Reward.Type)
		local rewardLabel = Instance.new("TextLabel")
		rewardLabel.Size = UDim2.new(0.65, 0, 0, 20)
		rewardLabel.Position = UDim2.new(0, 15, 0, 40)
		rewardLabel.BackgroundTransparency = 1
		rewardLabel.Text = "🎁 REWARD: " .. rewardStr
		rewardLabel.TextColor3 = Config.Theme.TextGold
		rewardLabel.Font = Enum.Font.Gotham
		rewardLabel.TextSize = 14
		rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
		rewardLabel.Parent = item
		
		local claimBtn = Instance.new("TextButton")
		claimBtn.Name = "ClaimButton"
		claimBtn.Size = UDim2.new(0, 120, 0, 44)
		claimBtn.Position = UDim2.new(1, -135, 0.5, -22)
		claimBtn.BackgroundColor3 = Config.Theme.BtnRewardBase
		claimBtn.Text = "LOCKED"
		claimBtn.TextColor3 = Config.Theme.TextMain
		claimBtn.Font = Enum.Font.GothamBold
		claimBtn.TextSize = 14
		claimBtn.BorderSizePixel = 0
		claimBtn.Parent = item
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 22)
		btnCorner.Parent = claimBtn
		
		claimBtn.Activated:Connect(function()
			if claimBtn.Text == "CLAIM" then
				Remotes.Events.ClaimPlaytimeReward:FireServer(i)
			end
		end)
	end
	
	listFrame.CanvasSize = UDim2.new(0, 0, 0, #Config.Rewards.PlaytimeMilestones * 92 + 10)

	return screen
end

local function updateUIState()
	if not rewardScreen or not DataController then return end
	local panel = (rewardScreen :: any):FindFirstChild("Panel")
	if not panel then return end
	local listFrame = panel:FindFirstChild("RewardList")
	if not listFrame then return end
	
	local data = DataController.GetData()
	if not data then return end
	
	local playtime = data.PlayTime or 0
	local claimed = data.ClaimedPlaytimeRewards or {}
	
	for i, milestone in ipairs(Config.Rewards.PlaytimeMilestones) do
		local item = listFrame:FindFirstChild("Milestone_" .. tostring(i))
		if item then
			local btn = item:FindFirstChild("ClaimButton") :: TextButton
			if btn then
				if claimed[tostring(i)] then
					btn.Text = "CLAIMED"
					btn.BackgroundColor3 = Color3.fromRGB(60, 65, 90)
				elseif playtime >= milestone.Time then
					btn.Text = "CLAIM"
					btn.BackgroundColor3 = Color3.fromRGB(60, 210, 160)
				else
					btn.Text = "LOCKED"
					btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
				end
			end
		end
	end
end

function RewardUI.Init(overrideParent: Instance?)
	local pg = (overrideParent or getPlayerGui()) :: Instance?
	if not pg then 
		warn("[RewardUI] Init failed: PlayerGui not found") 
		return 
	end
	
	local existing = (pg :: any):FindFirstChild("RewardUI")
	if existing then 
		print("ℹ️ [RewardUI] Destroying existing UI to rebuild.")
		existing:Destroy() 
	end

	local newScreen = buildUI()
	rewardScreen = newScreen
	newScreen.Parent = (pg :: any)
	
	print("[RewardUI] Init complete. Parent:", (newScreen.Parent :: any).Name)
	
	task.defer(function()
		task.wait(0.5)
		if DataController then
			DataController.OnDataChanged(function(key: string, _)
				if key == "PlayTime" or key == "ClaimedPlaytimeRewards" or key == "__all__" then
					if isOpen then updateUIState() end
				end
			end)
		end
	end)
end

function RewardUI.Open()
	local pg = getPlayerGui()
	if not pg then return end

	local isValid = rewardScreen and rewardScreen.Parent == pg and rewardScreen:IsDescendantOf(pg)
	if not isValid then
		print("⚠️ [RewardUI] rewardScreen invalid or detached. Re-initializing...")
		RewardUI.Init()
	end

	if rewardScreen then 
		rewardScreen.Enabled = true
		isOpen = true 
		updateUIState()
		print("[RewardUI] Opened successfully.")
	end
end

function RewardUI.Close()
	if rewardScreen then rewardScreen.Enabled = false; isOpen = false end
end

function RewardUI.Toggle()
	if isOpen then RewardUI.Close() else RewardUI.Open() end
end

return RewardUI
