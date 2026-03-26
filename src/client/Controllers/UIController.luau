--!strict
-- UIController.luau
-- Client-side: Điều phối tất cả UI modules, tạo navigation buttons, handle notifications

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared      = game.ReplicatedStorage.Shared
local Remotes     = require(Shared.Remotes)
local Config      = require(Shared.Config)

-- Lazy-load packages
local React          = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox    = require(game.ReplicatedStorage.Packages.ReactRoblox)

-- Lazy-load UI modules
local HUD            = require(script.Parent.Parent.UI.HUD)
local HUDApp         = require(script.Parent.Parent.UI.HUDApp)
local Shop           = require(script.Parent.Parent.UI.Shop)
local PetUI          = require(script.Parent.Parent.UI.PetUI)
local RebirthUI      = require(script.Parent.Parent.UI.RebirthUI)
local CustomShoutUI  = require(script.Parent.Parent.UI.CustomShoutUI)
local CodeUI         = require(script.Parent.Parent.UI.CodeUI)
local RewardUI       = require(script.Parent.Parent.UI.RewardUI)
local QuestUI        = require(script.Parent.Parent.UI.QuestUI)
local EggHatchUI     = require(script.Parent.Parent.UI.EggHatchUI)
local SkillBar       = require(script.Parent.Parent.UI.SkillBar)
local SkillUI        = require(script.Parent.Parent.UI.SkillUI)
local BagUI          = require(script.Parent.Parent.UI.BagUI)

local UIController = {}
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- WINDOW MANAGEMENT
-- ============================================================

local function CloseAllOpenWindows()
	if Shop.Close then Shop.Close() end
	if PetUI.Close then PetUI.Close() end
	if RebirthUI.Close then RebirthUI.Close() end
	if CustomShoutUI.Close then CustomShoutUI.Close() end
	if CodeUI.Close then CodeUI.Close() end
	if RewardUI.Close then RewardUI.Close() end
	if QuestUI.Close then QuestUI.Close() end
	if SkillUI.Close then SkillUI.Close() end
	if BagUI.Close then BagUI.Close() end
end

-- ============================================================
-- NOTIFICATION TOAST
-- ============================================================

local function showNotification(message: string)
	local existingScreen = PlayerGui:FindFirstChild("NotifScreen") :: ScreenGui?
	local screen: ScreenGui
	if existingScreen then
		screen = existingScreen
	else
		local newScreen     = Instance.new("ScreenGui")
		newScreen.Name      = "NotifScreen"
		newScreen.ResetOnSpawn = false
		newScreen.DisplayOrder = 100 -- Topmost
		newScreen.Parent    = PlayerGui
		screen = newScreen
	end

	local toast            = Instance.new("Frame")
	toast.Size             = UDim2.new(0, 380, 0, 52)
	toast.Position         = UDim2.new(0.5, -190, 0, -60)
	toast.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	toast.BackgroundTransparency = 0.1
	toast.BorderSizePixel  = 0
	toast.Parent           = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = toast

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 80, 200)
	stroke.Thickness = 1.5
	stroke.Parent = toast

	local label       = Instance.new("TextLabel")
	label.Size        = UDim2.new(1, -16, 1, 0)
	label.Position    = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text        = message
	label.TextColor3  = Color3.fromRGB(230, 230, 255)
	label.Font        = Enum.Font.GothamBold
	label.TextSize    = 15
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent      = toast

	-- Slide in từ top
	TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -190, 0, 12)
	}):Play()

	task.delay(2.8, function()
		-- Slide out
		TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, -190, 0, -60)
		}):Play()
		task.wait(0.3)
		if toast and toast.Parent then toast:Destroy() end
	end)
end

-- ============================================================
-- BOTTOM NAV BUTTONS
-- ============================================================
local function _buildNavBar()
	local screen        = Instance.new("ScreenGui")
	screen.Name         = "NavBar"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 10
	screen.Parent       = PlayerGui

	local container = Instance.new("Frame")
	container.Name = "ButtonContainer"
	
	local buttons = {
		{ id = "Shop",    icon = "🛒", baseColor = Config.Theme.BtnShopBase,    shadowColor = Config.Theme.BtnShopShadow,    action = function() CloseAllOpenWindows(); Shop.Open() end },
		{ id = "Pets",    icon = "🐾", baseColor = Config.Theme.BtnPetsBase,    shadowColor = Config.Theme.BtnPetsShadow,    action = function() CloseAllOpenWindows(); PetUI.Open() end },
		{ id = "Skills",  icon = "🎴", baseColor = Config.Theme.BtnCodeBase,    shadowColor = Config.Theme.BtnCodeShadow,    action = function() CloseAllOpenWindows(); SkillUI.Open() end },
		{ id = "Quest",   icon = "📜", baseColor = Config.Theme.BtnQuestBase,   shadowColor = Config.Theme.BtnQuestShadow,   action = function() CloseAllOpenWindows(); QuestUI.Open() end },
		{ id = "Reward",  icon = "⏱️", baseColor = Config.Theme.BtnRewardBase,  shadowColor = Config.Theme.BtnRewardShadow,  action = function() CloseAllOpenWindows(); RewardUI.Open() end },
		{ id = "Shout",   icon = "✏️", baseColor = Config.Theme.BtnShoutBase,   shadowColor = Config.Theme.BtnShoutShadow,   action = function() CloseAllOpenWindows(); CustomShoutUI.Open() end },
	}

	local numBtns = #buttons
	container.Size = UDim2.new(0, (numBtns * 58) + ((numBtns - 1) * 12), 0, 58)
	container.Position = UDim2.new(0.5, 0, 1, -85)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundTransparency = 1
	container.Parent = screen

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.Parent = container

	for i, btnData in ipairs(buttons) do
		local btnWrapper = Instance.new("Frame")
		btnWrapper.Name = btnData.id .. "Wrapper"
		btnWrapper.Size = UDim2.new(0, 58, 0, 58)
		btnWrapper.BackgroundTransparency = 1
		btnWrapper.LayoutOrder = i
		btnWrapper.Parent = container

		-- Modern Glow / Shadow
		local shadow = Instance.new("Frame")
		shadow.Name = "Shadow"
		shadow.Size = UDim2.new(1, 0, 1, 0)
		shadow.BackgroundColor3 = btnData.shadowColor
		shadow.BackgroundTransparency = 0.2
		shadow.BorderSizePixel = 0
		shadow.Parent = btnWrapper

		local shadowCorner = Instance.new("UICorner")
		shadowCorner.CornerRadius = Config.Theme.CornerRadius
		shadowCorner.Parent = shadow

		-- Main Button
		local btn = Instance.new("TextButton")
		btn.Name = "Button"
		btn.Size = UDim2.new(1, 0, 1, -4)
		btn.BackgroundColor3 = btnData.baseColor
		btn.Text = btnData.icon
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 28
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Parent = btnWrapper

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = Config.Theme.CornerRadius
		btnCorner.Parent = btn
		
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.5
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Transparency = 0.8
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = btn

		local action = btnData.action
		
		-- Hover effect
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = btnData.baseColor:Lerp(Color3.new(1,1,1), 0.15)
			}):Play()
		end)
		
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = btnData.baseColor
			}):Play()
		end)

		-- Click animation
		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				TweenService:Create(btn, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(0, 0, 0, 4)
				}):Play()
			end
		end)

		btn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(0, 0, 0, 0)
				}):Play()
			end
		end)

		btn.Activated:Connect(function()
			action()
		end)
	end
end

-- ============================================================
-- KEYBOARD SHORTCUTS
-- ============================================================
local function _bindKeyShortcuts()
	UserInputService.InputBegan:Connect(function(input: InputObject, gp: boolean)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.T then
			CloseAllOpenWindows()
			CustomShoutUI.Open()
		elseif input.KeyCode == Enum.KeyCode.B then
			CloseAllOpenWindows()
			BagUI.Toggle()
		end
	end)
end

-- ============================================================
-- PROXIMITY PROMPTS
-- ============================================================
local function bindProximityPrompts()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if player == LocalPlayer then
			if prompt.Name == "Prompt_Shop" then
				CloseAllOpenWindows()
				Shop.Open()
			elseif prompt.Name == "Prompt_Pet" then
				CloseAllOpenWindows()
				PetUI.Open()
			elseif prompt.Name == "Prompt_Rebirth" then
				CloseAllOpenWindows()
				RebirthUI.Open()
			elseif prompt.Name == "Prompt_Skill" then
				CloseAllOpenWindows()
				SkillUI.Open()
			elseif prompt.Name == "Prompt_Quest" then
				CloseAllOpenWindows()
				QuestUI.Open()
			elseif prompt.Name == "Prompt_Reward" then
				CloseAllOpenWindows()
				RewardUI.Open()
			elseif prompt.Name == "Prompt_Shout" then
				CloseAllOpenWindows()
				CustomShoutUI.Open()
			elseif prompt.Name == "Prompt_Inventory" then
				CloseAllOpenWindows()
				BagUI.Open()
			end
		end
	end)
end

-- ============================================================
-- INIT
-- ============================================================
function UIController.Init()
	-- Khởi động tất cả UI modules
	-- HUD.Init() -- Legacy HUD disabled in favor of React HUDApp
	
	-- Mount React HUD
	local hudRoot = ReactRoblox.createRoot(PlayerGui)
	hudRoot:render(React.createElement(HUDApp))
	
	-- Disable default Roblox Health UI (moved from legacy HUD)
	pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end)

	Shop.Init()
	PetUI.Init()
	RebirthUI.Init()
	CustomShoutUI.Init()
	CodeUI.Init()
	RewardUI.Init()
	QuestUI.Init()
	EggHatchUI.Init()
	SkillBar.Init()
	SkillUI.Init()
	BagUI.Init()

	-- Nav bar + shortcuts + map
	-- _buildNavBar()
	_bindKeyShortcuts()
	bindProximityPrompts()

	-- Notification remote
	Remotes.Events.Notification.OnClientEvent:Connect(function(...)
		local args = { ... }
		local msg  = args[1]
		if type(msg) == "string" then
			showNotification(msg)
		end
	end)

	print("[UIController] All UI initialized | Shortcuts: T=Shout")
end

return UIController
