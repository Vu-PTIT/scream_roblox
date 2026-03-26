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
-- local HUD            = require(script.Parent.Parent.UI.HUD) -- Unused legacy HUD
local HUDApp         = require(script.Parent.Parent.UI.HUDApp)
local ShopApp        = require(script.Parent.Parent.UI.ShopApp)
local CustomShoutUI  = require(script.Parent.Parent.UI.CustomShoutUI)
local CodeUI         = require(script.Parent.Parent.UI.CodeUI)
local RewardUI       = require(script.Parent.Parent.UI.RewardUI)
local EggHatchUI     = require(script.Parent.Parent.UI.EggHatchUI)
local SkillBar       = require(script.Parent.Parent.UI.SkillBar)
local BagUI          = require(script.Parent.Parent.UI.BagUI)

local UIController = {}
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- WINDOW MANAGEMENT
-- ============================================================

local function CloseAllOpenWindows()
	ShopApp.OpenWindow(nil)
	if CustomShoutUI.Close then CustomShoutUI.Close() end
	if CodeUI.Close then CodeUI.Close() end
	if RewardUI.Close then RewardUI.Close() end
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
		{ id = "Shop",    icon = "🛒", baseColor = Config.Theme.BtnShopBase,    shadowColor = Config.Theme.BtnShopShadow,    action = function() CloseAllOpenWindows(); ShopApp.OpenWindow("Shop") end },
		{ id = "Pets",    icon = "🐾", baseColor = Config.Theme.BtnPetsBase,    shadowColor = Config.Theme.BtnPetsShadow,    action = function() CloseAllOpenWindows(); ShopApp.OpenWindow("Pet") end },
		{ id = "Skills",  icon = "🎴", baseColor = Config.Theme.BtnCodeBase,    shadowColor = Config.Theme.BtnCodeShadow,    action = function() CloseAllOpenWindows(); ShopApp.OpenWindow("Skill") end },
		{ id = "Quest",   icon = "📜", baseColor = Config.Theme.BtnQuestBase,   shadowColor = Config.Theme.BtnQuestShadow,   action = function() CloseAllOpenWindows(); ShopApp.OpenWindow("Quest") end },
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
-- ============================================================
-- STATION TRIGGERS (PROXIMITY & CLICK)
-- ============================================================
local function handleStationTrigger(stationId: string)
	print("[UIController] handleStationTrigger:", stationId)
	
	-- Play click sound if available
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://6895079853" -- Standard click
		sound.Volume = 0.5
		sound.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 2)
	end)

	CloseAllOpenWindows()
	print("[UIController] Trigggering window for stationId:", stationId)
	
	if stationId == "Shop" then
		ShopApp.OpenWindow("Shop")
	elseif stationId == "Pet" then
		ShopApp.OpenWindow("Pet")
	elseif stationId == "Rebirth" then
		ShopApp.OpenWindow("Rebirth")
	elseif stationId == "Skill" then
		ShopApp.OpenWindow("Skill")
	elseif stationId == "Quest" then
		ShopApp.OpenWindow("Quest")
	elseif stationId == "Reward" then
		RewardUI.Open()
	elseif stationId == "Shout" then
		CustomShoutUI.Open()
	elseif stationId == "Inventory" then
		BagUI.Open()
	else
		print("[UIController] Unknown stationId:", stationId)
	end
end

local function bindProximityPrompts()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		print("[UIController] PromptTriggered:", prompt.Name, "by", player.Name)
		if player == LocalPlayer then
			local stationId = prompt.Name:match("Prompt_(.+)")
			
			-- Fallback detection based on parent name or id
			if not stationId then
				local pName = prompt.Parent and prompt.Parent.Name or ""
				if pName:find("Skill") then stationId = "Skill"
				elseif pName:find("Pet") then stationId = "Pet"
				elseif pName:find("Upgrade") or pName:find("Shop") then stationId = "Shop"
				elseif pName:find("Rebirth") then stationId = "Rebirth"
				elseif pName:find("Quest") then stationId = "Quest"
				elseif pName:find("Reward") then stationId = "Reward"
				elseif pName:find("Speech") or pName:find("Shout") then stationId = "Shout"
				elseif pName:find("Inventory") or pName:find("Bag") then stationId = "Inventory"
				end
			end

			print("[UIController] Final stationId:", stationId)
			if stationId then
				handleStationTrigger(stationId)
			else
				warn("[UIController] No stationId found for prompt:", prompt.Name, "Parent:", prompt.Parent and prompt.Parent.Name)
			end
		end
	end)
end

local function bindClickDetectors()
	task.spawn(function()
		local map = workspace:WaitForChild("Map", 10)
		if not map then return end
		local stations = map:WaitForChild("Stations", 10)
		if not stations then return end

		local function setupClick(child: ClickDetector)
			child.MouseClick:Connect(function()
				local stationId = child.Name:match("Click_(.+)")
				if not stationId then
					local pName = child.Parent and child.Parent.Name or ""
					if pName:find("Skill") then stationId = "Skill"
					elseif pName:find("Pet") then stationId = "Pet"
					elseif pName:find("Upgrade") or pName:find("Shop") then stationId = "Shop"
					elseif pName:find("Rebirth") then stationId = "Rebirth"
					elseif pName:find("Quest") then stationId = "Quest"
					elseif pName:find("Reward") then stationId = "Reward"
					elseif pName:find("Speech") or pName:find("Shout") then stationId = "Shout"
					elseif pName:find("Inventory") or pName:find("Bag") then stationId = "Inventory"
					end
				end
				if stationId then
					handleStationTrigger(stationId)
				end
			end)
		end

		for _, station in ipairs(stations:GetChildren()) do
			if station:IsA("BasePart") then
				for _, child in ipairs(station:GetChildren()) do
					if child:IsA("ClickDetector") then
						setupClick(child)
					end
				end
			end
		end
		
		stations.ChildAdded:Connect(function(station)
			if station:IsA("BasePart") then
				task.wait(0.5) -- wait for children
				for _, child in ipairs(station:GetChildren()) do
					if child:IsA("ClickDetector") then
						setupClick(child)
					end
				end
			end
		end)
	end)
end

-- ============================================================
-- INIT
-- ============================================================
function UIController.Init()
	-- Khởi động tất cả UI modules
	-- HUD.Init() -- Legacy HUD disabled in favor of React HUDApp
	
	-- Mount React HUD
	local root = ReactRoblox.createRoot(PlayerGui)
	root:render(React.createElement(React.Fragment, nil,
		React.createElement(HUDApp),
		React.createElement(ShopApp.Component)
	))
	
	-- Disable default Roblox Health UI
	pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end)

	CustomShoutUI.Init()
	CodeUI.Init()
	RewardUI.Init()
	EggHatchUI.Init()
	SkillBar.Init()
	BagUI.Init()

	-- Nav bar + shortcuts + map
	_buildNavBar()
	_bindKeyShortcuts()
	bindProximityPrompts()
	bindClickDetectors()

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
