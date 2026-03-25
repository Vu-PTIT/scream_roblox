--!strict
-- QuestUI.luau
-- Client-side: Daily Quests UI

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared      = game.ReplicatedStorage.Shared
local Config      = require(Shared.Config)
local Remotes     = require(Shared.Remotes)

local DataController: any = nil
task.defer(function()
	DataController = require(script.Parent.Parent.Controllers.DataController)
end)

local QuestUI = {}
local LocalPlayer   = Players.LocalPlayer

local function getPlayerGui(): PlayerGui?
	if not LocalPlayer then return nil end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local questScreen: ScreenGui? = nil
local isOpen = false

local function buildUI(): ScreenGui
	local screen           = Instance.new("ScreenGui")
	screen.Name            = "QuestUI"
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
	panel.Size             = UDim2.new(0, 520, 0, 560)
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

	local title    = Instance.new("TextLabel")
	title.Size     = UDim2.new(1, 0, 0, 64)
	title.BackgroundTransparency = 1
	title.Text     = "DAILY QUESTS"
	title.TextColor3 = Config.Theme.TextMain
	title.Font     = Enum.Font.GothamBlack
	title.TextSize = 24
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
	
	closeBtn.Activated:Connect(function() QuestUI.Close() end)

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "QuestList"
	listFrame.Size = UDim2.new(1, -30, 1, -85)
	listFrame.Position = UDim2.new(0, 15, 0, 70)
	listFrame.BackgroundTransparency = 1
	listFrame.ScrollBarThickness = 4
	listFrame.ScrollBarImageColor3 = Config.Theme.BtnQuestBase
	listFrame.BorderSizePixel = 0
	listFrame.Parent = panel
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.Parent = listFrame

	for i, q in ipairs(Config.Quests) do
		local item = Instance.new("Frame")
		item.Name = "Quest_" .. q.Id
		item.Size = UDim2.new(1, -10, 0, 100)
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
		
		local qTitle = Instance.new("TextLabel")
		qTitle.Size = UDim2.new(0.65, 0, 0, 24)
		qTitle.Position = UDim2.new(0, 15, 0, 12)
		qTitle.BackgroundTransparency = 1
		qTitle.Text = q.Title
		qTitle.TextColor3 = Config.Theme.TextMain
		qTitle.Font = Enum.Font.GothamBold
		qTitle.TextSize = 16
		qTitle.TextXAlignment = Enum.TextXAlignment.Left
		qTitle.Parent = item
		
		local qReward = Instance.new("TextLabel")
		qReward.Size = UDim2.new(0.65, 0, 0, 20)
		qReward.Position = UDim2.new(0, 15, 0, 36)
		qReward.BackgroundTransparency = 1
		qReward.Text = "🎁 Reward: " .. tostring(q.Reward.Amount) .. " " .. q.Reward.Type
		qReward.TextColor3 = Config.Theme.TextGold
		qReward.Font = Enum.Font.Gotham
		qReward.TextSize = 13
		qReward.TextXAlignment = Enum.TextXAlignment.Left
		qReward.Parent = item
		
		-- Progress Bar
		local progContainer = Instance.new("Frame")
		progContainer.Size = UDim2.new(0.6, 0, 0, 12)
		progContainer.Position = UDim2.new(0, 15, 0, 68)
		progContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		progContainer.BorderSizePixel = 0
		progContainer.Parent = item
		
		local pcCorner = Instance.new("UICorner")
		pcCorner.CornerRadius = UDim.new(1, 0)
		pcCorner.Parent = progContainer
		
		local progFill = Instance.new("Frame")
		progFill.Name = "Fill"
		progFill.Size = UDim2.new(0.5, 0, 1, 0)
		progFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		progFill.BorderSizePixel = 0
		progFill.Parent = progContainer
		
		local pfCorner = Instance.new("UICorner")
		pfCorner.CornerRadius = UDim.new(1, 0)
		pfCorner.Parent = progFill
		
		local fGrad = Instance.new("UIGradient")
		fGrad.Color = ColorSequence.new(Config.Theme.BtnQuestBase, Config.Theme.BtnQuestShadow)
		fGrad.Parent = progFill
		
		local progText = Instance.new("TextLabel")
		progText.Name = "ProgressText"
		progText.Size = UDim2.new(0.3, 0, 0, 12)
		progText.Position = UDim2.new(1, 10, 0, 0)
		progText.BackgroundTransparency = 1
		progText.Text = "0/" .. tostring(q.Required)
		progText.TextColor3 = Config.Theme.TextSecondary
		progText.Font = Enum.Font.GothamBold
		progText.TextSize = 11
		progText.TextXAlignment = Enum.TextXAlignment.Left
		progText.Parent = progContainer
		
		local claimBtn = Instance.new("TextButton")
		claimBtn.Name = "ClaimButton"
		claimBtn.Size = UDim2.new(0, 110, 0, 40)
		claimBtn.Position = UDim2.new(1, -125, 0.5, -20)
		claimBtn.BackgroundColor3 = Config.Theme.BtnQuestBase
		claimBtn.Text = "LOCKED"
		claimBtn.TextColor3 = Config.Theme.TextMain
		claimBtn.Font = Enum.Font.GothamBold
		claimBtn.TextSize = 14
		claimBtn.BorderSizePixel = 0
		claimBtn.Parent = item
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 20)
		btnCorner.Parent = claimBtn
		
		claimBtn.Activated:Connect(function()
			if claimBtn.Text == "CLAIM" then
				Remotes.Events.ClaimQuestReward:FireServer(q.Id)
			end
		end)
	end
	
	listFrame.CanvasSize = UDim2.new(0, 0, 0, #Config.Quests * 112 + 10)

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
			
			local fill = item:FindFirstChild("Fill", true) :: Frame
			local pText = item:FindFirstChild("ProgressText", true) :: TextLabel
			
			if fill then
				TweenService:Create(fill, TweenInfo.new(0.5), {Size = UDim2.new(ratio, 0, 1, 0)}):Play()
			end
			if pText then pText.Text = string.format("%d/%d", math.floor(prog), q.Required) end
			
			local btn = item:FindFirstChild("ClaimButton") :: TextButton
			if btn then
				if claimed[q.Id] then
					btn.Text = "CLAIMED"
					btn.BackgroundColor3 = Color3.fromRGB(60, 65, 90)
					btn.AutoButtonColor = false
				elseif isCompleted then
					btn.Text = "CLAIM"
					btn.BackgroundColor3 = Color3.fromRGB(60, 210, 160)
					btn.AutoButtonColor = true
				else
					btn.Text = "LOCKED"
					btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
					btn.AutoButtonColor = false
				end
			end
		end
	end
end

function QuestUI.Init(overrideParent: Instance?)
	local pg = overrideParent or getPlayerGui()
	if not pg then return end
	
	-- [SMART BINDING] Detect existing QuestUI
	local existing: ScreenGui? = nil
	for _, child in ipairs(pg:GetChildren()) do
		if child:IsA("ScreenGui") then
			if child.Name == "QuestUI" or child:FindFirstChild("QuestList", true) then
				if not existing then
					existing = child
				else
					child:Destroy()
				end
			end
		end
	end
	
	if existing then
		questScreen = existing
		print("ℹ️ [QuestUI] Using existing ScreenGui for smart binding.")
	else
		local screen = buildUI()
		screen.Parent = pg
		questScreen = screen
	end
	
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
