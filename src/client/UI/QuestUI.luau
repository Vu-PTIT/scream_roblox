--!strict
-- QuestUI.luau
-- Client-side: Daily Quests UI

local Players      = game:GetService("Players")

local Shared      = game.ReplicatedStorage.Shared
local Config      = require(Shared.Config)
local Remotes     = require(Shared.Remotes)

local DataController: any = nil
task.defer(function()
	DataController = require(script.Parent.Parent.Controllers.DataController)
end)

local QuestUI = {}
local LocalPlayer   = Players.LocalPlayer
local PlayerGui     = LocalPlayer:WaitForChild("PlayerGui")

local questScreen: ScreenGui? = nil
local isOpen = false

local function buildUI(): ScreenGui
	local screen           = Instance.new("ScreenGui")
	screen.Name            = "QuestUI"
	screen.ResetOnSpawn    = false
	screen.DisplayOrder    = 20
	screen.Enabled         = false

	local panel            = Instance.new("Frame")
	panel.Name             = "Panel"
	panel.Size             = UDim2.new(0, 420, 0, 400)
	panel.Position         = UDim2.new(0.5, -210, 0.5, -200)
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
	title.Text     = "📜 " .. Config.Localization.QuestUI.Title
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
		QuestUI.Close()
	end)

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "QuestList"
	listFrame.Size = UDim2.new(1, -30, 1, -65)
	listFrame.Position = UDim2.new(0, 15, 0, 50)
	listFrame.BackgroundTransparency = 1
	listFrame.ScrollBarThickness = 4
	listFrame.Parent = panel
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = listFrame

	for i, q in ipairs(Config.Quests) do
		local item = Instance.new("Frame")
		item.Name = "Quest_" .. q.Id
		item.Size = UDim2.new(1, -10, 0, 75)
		item.BackgroundColor3 = Config.Theme.SecondaryBackground
		item.BorderSizePixel = 0
		item.LayoutOrder = i
		item.Parent = listFrame
		
		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 8)
		itemCorner.Parent = item
		
		local qTitle = Instance.new("TextLabel")
		qTitle.Size = UDim2.new(0.6, 0, 0.4, 0)
		qTitle.Position = UDim2.new(0, 10, 0, 5)
		qTitle.BackgroundTransparency = 1
		qTitle.Text = q.Title
		qTitle.TextColor3 = Config.Theme.TextMain
		qTitle.Font = Enum.Font.GothamBold
		qTitle.TextSize = 15
		qTitle.TextXAlignment = Enum.TextXAlignment.Left
		qTitle.Parent = item
		
		local qReward = Instance.new("TextLabel")
		qReward.Size = UDim2.new(0.6, 0, 0.3, 0)
		qReward.Position = UDim2.new(0, 10, 0.4, 5)
		qReward.BackgroundTransparency = 1
		qReward.Text = "🎁 Reward: " .. tostring(q.Reward.Amount) .. " " .. q.Reward.Type
		qReward.TextColor3 = Config.Theme.TextGold
		qReward.Font = Enum.Font.Gotham
		qReward.TextSize = 13
		qReward.TextXAlignment = Enum.TextXAlignment.Left
		qReward.Parent = item
		
		-- Progress Bar
		local progBg = Instance.new("Frame")
		progBg.Name = "ProgressBg"
		progBg.Size = UDim2.new(0.65, 0, 0, 8)
		progBg.Position = UDim2.new(0, 10, 0.8, -2)
		progBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		progBg.BorderSizePixel = 0
		progBg.Parent = item
		
		local progCorner = Instance.new("UICorner")
		progCorner.CornerRadius = UDim.new(1, 0)
		progCorner.Parent = progBg
		
		local progFill = Instance.new("Frame")
		progFill.Name = "Fill"
		progFill.Size = UDim2.new(0, 0, 1, 0)
		progFill.BackgroundColor3 = Config.Theme.BtnQuestBase
		progFill.BorderSizePixel = 0
		progFill.Parent = progBg
		
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = progFill
		
		local progText = Instance.new("TextLabel")
		progText.Name = "ProgressText"
		progText.Size = UDim2.new(1, 0, 1, 0)
		progText.Position = UDim2.new(1, 10, 0, 0)
		progText.BackgroundTransparency = 1
		progText.Text = "0/" .. tostring(q.Required)
		progText.TextColor3 = Config.Theme.TextSecondary
		progText.Font = Enum.Font.Gotham
		progText.TextSize = 12
		progText.TextXAlignment = Enum.TextXAlignment.Left
		progText.Parent = progBg
		
		local claimBtn = Instance.new("TextButton")
		claimBtn.Name = "ClaimButton"
		claimBtn.Size = UDim2.new(0, 90, 0, 40)
		claimBtn.Position = UDim2.new(1, -100, 0.5, -20)
		claimBtn.BackgroundColor3 = Config.Theme.BtnQuestBase
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
				Remotes.Events.ClaimQuestReward:FireServer(q.Id)
			end
		end)
	end
	
	listFrame.CanvasSize = UDim2.new(0, 0, 0, #Config.Quests * 85)

	return screen
end

local function updateUIState()
	if not questScreen or not DataController then return end
	local panel = questScreen:FindFirstChild("Panel")
	if not panel then return end
	local listFrame = panel:FindFirstChild("QuestList")
	if not listFrame then return end
	
	local data = DataController.GetData()
	if not data then return end
	
	local quests = data.Quests or {}
	local claimed = data.ClaimedQuests or {}
	
	for _, q in ipairs(Config.Quests) do
		local item = listFrame:FindFirstChild("Quest_" .. q.Id)
		if item then
			local prog = quests[q.ActionType] or 0
			local isCompleted = prog >= q.Required
			local ratio = math.clamp(prog / q.Required, 0, 1)
			local actualProgBg = item:FindFirstChild("ProgressBg")
			
			if actualProgBg then
				local fill = actualProgBg:FindFirstChild("Fill") :: Frame
				local pText = actualProgBg:FindFirstChild("ProgressText") :: TextLabel
				if fill then fill.Size = UDim2.new(ratio, 0, 1, 0) end
				if pText then pText.Text = tostring(math.floor(prog)) .. "/" .. tostring(q.Required) end
			end
			
			local btn = item:FindFirstChild("ClaimButton") :: TextButton
			if btn then
				if claimed[q.Id] then
					btn.Text = Config.Localization.RewardUI.Claimed
					btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
				elseif isCompleted then
					btn.Text = Config.Localization.RewardUI.Claim
					btn.BackgroundColor3 = Config.Theme.SuccessGradient[1]
				else
					btn.Text = Config.Localization.RewardUI.Locked
					btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
				end
			end
		end
	end
end

function QuestUI.Init()
	local screen = buildUI()
	screen.Parent = PlayerGui
	questScreen = screen
	
	task.defer(function()
		task.wait(0.5)
		if DataController then
			DataController.OnDataChanged(function(key: string, value: any)
				if key == "Quests" or key == "ClaimedQuests" or key == "__all__" then
					if isOpen then updateUIState() end
				end
			end)
		end
	end)
end

function QuestUI.Open()
	if questScreen then 
		questScreen.Enabled = true
		isOpen = true 
		updateUIState()
	end
end

function QuestUI.Close()
	if questScreen then questScreen.Enabled = false; isOpen = false end
end

function QuestUI.Toggle()
	if isOpen then QuestUI.Close() else QuestUI.Open() end
end

return QuestUI
