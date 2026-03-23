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
local PlayerGui     = LocalPlayer:WaitForChild("PlayerGui")

local rewardScreen: ScreenGui? = nil
local isOpen = false

local function buildUI(): ScreenGui
	local screen           = Instance.new("ScreenGui")
	screen.Name            = "RewardUI"
	screen.ResetOnSpawn    = false
	screen.DisplayOrder    = 20
	screen.Enabled         = false

	local panel            = Instance.new("Frame")
	panel.Name             = "Panel"
	panel.Size             = UDim2.new(0, 400, 0, 360)
	panel.Position         = UDim2.new(0.5, -200, 0.5, -180)
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
	title.Text     = "⏱️ " .. Config.Localization.RewardUI.Title
	title.TextColor3 = Config.Theme.TextMain
	title.Font     = Enum.Font.GothamBlack
	title.TextSize = 22
	title.Parent   = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size  = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -45, 0, 4)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text  = "❌"
	closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeBtn.TextSize = 20
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = panel

	closeBtn.Activated:Connect(function()
		RewardUI.Close()
	end)

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, -30, 1, -65)
	listFrame.Position = UDim2.new(0, 15, 0, 50)
	listFrame.BackgroundTransparency = 1
	listFrame.ScrollBarThickness = 4
	listFrame.Parent = panel
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = listFrame

	for i, milestone in ipairs(Config.Rewards.PlaytimeMilestones) do
		local item = Instance.new("Frame")
		item.Name = "Milestone_" .. tostring(i)
		item.Size = UDim2.new(1, -10, 0, 65)
		item.BackgroundColor3 = Config.Theme.SecondaryBackground
		item.BorderSizePixel = 0
		item.LayoutOrder = i
		item.Parent = listFrame
		
		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 8)
		itemCorner.Parent = item
		
		local minutes = math.floor(milestone.Time / 60)
		local timeLabel = Instance.new("TextLabel")
		timeLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
		timeLabel.Position = UDim2.new(0, 10, 0, 5)
		timeLabel.BackgroundTransparency = 1
		timeLabel.Text = string.format(Config.Localization.RewardUI.TimeFormat, minutes)
		timeLabel.TextColor3 = Config.Theme.TextMain
		timeLabel.Font = Enum.Font.GothamBold
		timeLabel.TextSize = 16
		timeLabel.TextXAlignment = Enum.TextXAlignment.Left
		timeLabel.Parent = item
		
		local rewardStr = string.format(Config.Localization.RewardUI.RewardFormat, tostring(milestone.Reward.Amount), milestone.Reward.Type)
		local rewardLabel = Instance.new("TextLabel")
		rewardLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
		rewardLabel.Position = UDim2.new(0, 10, 0.5, -5)
		rewardLabel.BackgroundTransparency = 1
		rewardLabel.Text = "🎁 " .. rewardStr
		rewardLabel.TextColor3 = Config.Theme.TextGold
		rewardLabel.Font = Enum.Font.Gotham
		rewardLabel.TextSize = 14
		rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
		rewardLabel.Parent = item
		
		local claimBtn = Instance.new("TextButton")
		claimBtn.Name = "ClaimButton"
		claimBtn.Size = UDim2.new(0, 100, 0, 40)
		claimBtn.Position = UDim2.new(1, -110, 0.5, -20)
		claimBtn.BackgroundColor3 = Config.Theme.BtnRewardBase
		claimBtn.Text = Config.Localization.RewardUI.Locked
		claimBtn.TextColor3 = Config.Theme.TextMain
		claimBtn.Font = Enum.Font.GothamBold
		claimBtn.TextSize = 14
		claimBtn.Parent = item
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = claimBtn
		
		claimBtn.Activated:Connect(function()
			if claimBtn.Text == Config.Localization.RewardUI.Claim then
				Remotes.Events.ClaimPlaytimeReward:FireServer(i)
			end
		end)
	end
	
	listFrame.CanvasSize = UDim2.new(0, 0, 0, #Config.Rewards.PlaytimeMilestones * 75)

	return screen
end

local function updateUIState()
	if not rewardScreen or not DataController then return end
	local panel = rewardScreen:FindFirstChild("Panel")
	if not panel then return end
	local listFrame = panel:FindFirstChild("ScrollingFrame")
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
					btn.Text = Config.Localization.RewardUI.Claimed
					btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
				elseif playtime >= milestone.Time then
					btn.Text = Config.Localization.RewardUI.Claim
					-- Missing gradient definition locally, simplify color
					btn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
				else
					btn.Text = Config.Localization.RewardUI.Locked
					btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
				end
			end
		end
	end
end

function RewardUI.Init()
	local screen = buildUI()
	screen.Parent = PlayerGui
	rewardScreen = screen
	
	task.defer(function()
		task.wait(0.5)
		if DataController then
			DataController.OnDataChanged(function(key: string, value: any)
				if key == "PlayTime" or key == "ClaimedPlaytimeRewards" or key == "__all__" then
					if isOpen then
						updateUIState()
					end
				end
			end)
		end
	end)
end

function RewardUI.Open()
	if rewardScreen then 
		rewardScreen.Enabled = true
		isOpen = true 
		updateUIState()
	end
end

function RewardUI.Close()
	if rewardScreen then rewardScreen.Enabled = false; isOpen = false end
end

function RewardUI.Toggle()
	if isOpen then RewardUI.Close() else RewardUI.Open() end
end

return RewardUI
