--!strict
-- UIController.luau
-- Client-side: Điều phối tất cả UI modules, quản lý cửa sổ và tích hợp React.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local _Config = require(Shared.Config)

-- Lazy-load packages
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

-- UI modules
local HUDApp = require(script.Parent.Parent.UI.HUDApp)
local ShopApp = require(script.Parent.Parent.UI.ShopApp)
local BagUI = require(script.Parent.Parent.UI.BagUI)
local CustomShoutUI = require(script.Parent.Parent.UI.CustomShoutUI)
local CodeUI = require(script.Parent.Parent.UI.CodeUI)
local RewardUI = require(script.Parent.Parent.UI.RewardUI)
local EggHatchUI = require(script.Parent.Parent.UI.EggHatchUI)
local SkillHatchUI = require(script.Parent.Parent.UI.SkillHatchUI)

local UIController = {}
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- External Interface for React State
local _uiEventHandler: ((id: string) -> ())? = nil

-- ============================================================
-- WINDOW MANAGEMENT (LEGACY & EXTERNAL)
-- ============================================================

function UIController.HandleAction(id: string)
	-- Nếu React đã sẵn sàng, gửi action vào hệ thống React
	if _uiEventHandler then
		_uiEventHandler(id)
	else
		-- Fallback cho các module cũ chưa chuyển sang React hoàn toàn
		print("[UIController] React handler not ready, using fallback for:", id)
		if id == "Reward" then RewardUI.Open()
		elseif id == "Shout" then CustomShoutUI.Open()
		end
	end
end

-- ============================================================
-- REACT ROOT COMPONENT (THE BRAIN)
-- ============================================================

local function UIAppComponent(_props: any)
	local bagOpen, setBagOpen = React.useState(false)
	local openWindow, setOpenWindow = React.useState(nil :: string?)
	local data, setData = React.useState({})

	-- Cung cấp handler ra ngoài để UIController.HandleAction dùng được
	React.useLayoutEffect(function()
		_uiEventHandler = function(id: string)
			-- Logic đóng tất cả trước khi mở cái mới
			if id == "Bag" or id == "Inventory" then
				local newState = not bagOpen
				setOpenWindow(nil)
				setBagOpen(newState)
				print("[UIAppComponent] Set BagOpen to:", newState)
			elseif id == "Shop" or id == "Pet" or id == "Skill" or id == "Quest" or id == "Rebirth" or id == "Pets" or id == "Skills" then
				setBagOpen(false)
				local target = id
				if id == "Pets" then target = "Pet"
				elseif id == "Skills" then target = "Skill"
				elseif id == "Shop" then target = "Shop"
				end
				
				-- Toggle logic: Nếu đang mở đúng loại đó thì đóng lại
				if openWindow == target then
					setOpenWindow(nil)
				else
					setOpenWindow(target)
				end
				print("[UIAppComponent] Set OpenWindow to:", target or "nil")
			elseif id == "CloseAll" then
				setBagOpen(false)
				setOpenWindow(nil)
				if CustomShoutUI.Close then CustomShoutUI.Close() end
				if CodeUI.Close then CodeUI.Close() end
				if RewardUI.Close then RewardUI.Close() end
			else
				-- Xử lý các UI không phải React (Shout, Reward, v.v)
				setBagOpen(false)
				setOpenWindow(nil)
				if id == "Reward" then RewardUI.Open()
				elseif id == "Shout" then CustomShoutUI.Open()
				end
			end
		end
		return function() _uiEventHandler = nil end
	end, {bagOpen, openWindow})

	-- Unified Data Listener
	React.useEffect(function()
		local connection
		local function check()
			task.spawn(function()
				local DataController = require(script.Parent.DataController)
				if DataController and DataController.OnDataChanged then
					setData(DataController.GetData() or {})
					connection = DataController.OnDataChanged(function(key, val)
						setData(function(prev)
							if key == "__all__" then return val end
							local d = table.clone(prev)
							d[key] = val
							return d
						end)
					end)
				end
			end)
		end
		check()
		return function() if connection then connection() end end
	end, {})

	return React.createElement(React.Fragment, nil, {
		HUD = React.createElement(HUDApp, { 
			HandleAction = UIController.HandleAction,
			Data = data,
		}),
		
		-- ShopApp hiện tại nhận props để hiển thị (Centralized State)
		Shop = React.createElement(ShopApp.Component, {
			OpenWindow = openWindow,
			OnClose = function() setOpenWindow(nil) end,
			Data = data,
		}),
		
		Bag = React.createElement(BagUI, {
			Visible = bagOpen,
			OnClose = function() setBagOpen(false) end,
			Data = data,
		})
	})
end

-- ============================================================
-- TRIGGERS & SHORTCUTS
-- ============================================================

local function bindProximityPrompts()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if player == LocalPlayer then
			local stationId = prompt.Name:match("Prompt_(.+)")
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
			if stationId then UIController.HandleAction(stationId) end
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
				if stationId then UIController.HandleAction(stationId) end
			end)
		end

		for _, station in ipairs(stations:GetChildren()) do
			if station:IsA("BasePart") then
				for _, child in ipairs(station:GetChildren()) do
					if child:IsA("ClickDetector") then setupClick(child) end
				end
			end
		end
	end)
end

local function _bindKeyShortcuts()
	UserInputService.InputBegan:Connect(function(input: InputObject, gp: boolean)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.T then
			UIController.HandleAction("Shout")
		elseif input.KeyCode == Enum.KeyCode.B then
			UIController.HandleAction("Bag")
		elseif input.KeyCode == Enum.KeyCode.E then
			UIController.HandleAction("Shop")
		elseif input.KeyCode == Enum.KeyCode.Escape then
			UIController.HandleAction("CloseAll")
		end
	end)
end

-- ============================================================
-- NOTIFICATION TOAST
-- ============================================================

local function showNotification(message: string)
	local screen = PlayerGui:FindFirstChild("NotifScreen") :: ScreenGui?
	if not screen then
		local newScreen = Instance.new("ScreenGui")
		newScreen.Name = "NotifScreen"
		newScreen.ResetOnSpawn = false
		newScreen.DisplayOrder = 1000
		newScreen.Parent = PlayerGui
		screen = newScreen
	end
	if not screen then return end

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(0, 380, 0, 52)
	toast.Position = UDim2.new(0.5, -190, 0, -60)
	toast.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	toast.BackgroundTransparency = 0.1
	toast.BorderSizePixel = 0
	toast.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = toast

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = Color3.fromRGB(230, 230, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextWrapped = true
	label.Parent = toast

	TweenService:Create(toast, TweenInfo.new(0.3), { Position = UDim2.new(0.5, -190, 0, 20) }):Play()
	task.delay(3, function()
		if toast then
			TweenService:Create(toast, TweenInfo.new(0.3), { Position = UDim2.new(0.5, -190, 0, -60) }):Play()
			task.wait(0.3)
			toast:Destroy()
		end
	end)
end

-- ============================================================
-- INIT
-- ============================================================

function UIController.Init()
	print("[UIController] Mounting React root...")
	local root = ReactRoblox.createRoot(PlayerGui)
	root:render(React.createElement(UIAppComponent))

	pcall(function()
		game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)

	CustomShoutUI.Init()
	CodeUI.Init()
	RewardUI.Init()
	EggHatchUI.Init()
	SkillHatchUI.Init()

	_bindKeyShortcuts()
	bindProximityPrompts()
	bindClickDetectors()

	Remotes.Events.Notification.OnClientEvent:Connect(function(msg)
		if type(msg) == "string" then showNotification(msg) end
	end)

	print("[UIController] Unified UI System Ready")
end

return UIController
