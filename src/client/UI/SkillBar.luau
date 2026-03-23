--!strict
-- SkillBar.luau
-- Hiển thị skill đang được chọn

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config)

local DataController: any = nil
task.defer(function()
	DataController = require(script.Parent.Parent.Controllers.DataController)
end)

local SkillBar = {}
local iconLabel: TextLabel? = nil
local nameLabel: TextLabel? = nil

local function updateUI(shoutTypeId: string)
	if not iconLabel or not nameLabel then return end
	local config = Config.ShoutTypes[shoutTypeId] or Config.ShoutTypes.Normal
	iconLabel.Text = config.Icon
	nameLabel.Text = config.Name
end

function SkillBar.Init()
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SkillBar"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 150, 0, 50)
	frame.Position = UDim2.new(0.5, 0, 1, -110)
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.BackgroundColor3 = Config.Theme.SecondaryBackground
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Config.Theme.TextMuted
	stroke.Thickness = 1
	stroke.Parent = frame

	local _iconLabel = Instance.new("TextLabel")
	_iconLabel.Size = UDim2.new(0, 40, 1, 0)
	_iconLabel.Position = UDim2.new(0, 5, 0, 0)
	_iconLabel.BackgroundTransparency = 1
	_iconLabel.Text = "📢"
	_iconLabel.TextSize = 24
	_iconLabel.Font = Enum.Font.GothamBold
	_iconLabel.Parent = frame
	iconLabel = _iconLabel

	local _nameLabel = Instance.new("TextLabel")
	_nameLabel.Size = UDim2.new(1, -50, 1, 0)
	_nameLabel.Position = UDim2.new(0, 45, 0, 0)
	_nameLabel.BackgroundTransparency = 1
	_nameLabel.Text = "Normal Shout"
	_nameLabel.TextColor3 = Config.Theme.TextMain
	_nameLabel.TextSize = 14
	_nameLabel.Font = Enum.Font.GothamBold
	_nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	_nameLabel.Parent = frame
	nameLabel = _nameLabel
	
	local hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(1, 0, 0, 20)
	hintLabel.Position = UDim2.new(0, 0, 1, 5)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "Press 1, 2, 3 to switch"
	hintLabel.TextColor3 = Config.Theme.TextMuted
	hintLabel.TextSize = 12
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.Parent = frame

	task.spawn(function()
		while not DataController do task.wait(0.1) end
		
		-- Initial update
		local initialType = DataController.Get("CurrentShoutType") or "Normal"
		updateUI(initialType)
		
		-- Listen for changes
		DataController.OnDataChanged(function(key: string, value: any)
			if key == "CurrentShoutType" then
				updateUI(value)
				
				-- Pop effect
				frame.Size = UDim2.new(0, 160, 0, 55)
				TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {
					Size = UDim2.new(0, 150, 0, 50)
				}):Play()
			end
		end)
	end)
end

return SkillBar
