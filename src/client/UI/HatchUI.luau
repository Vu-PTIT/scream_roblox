--!strict
-- HatchUI.luau
-- Base module for 3D hatching/opening UI effects (Eggs, Skills, etc.)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local HatchUI = {}

local LocalPlayer = Players.LocalPlayer

local function getPlayerGui(): PlayerGui?
	if not LocalPlayer then return nil end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

-- Initialize or retrieve a ScreenGui with smart binding
function HatchUI.Init(screenName: string, overrideParent: Instance?): ScreenGui?
	local pg = overrideParent or getPlayerGui()
	if not pg then return nil end
	
	local existing = (pg :: any):FindFirstChild(screenName)
	if existing and existing:IsA("ScreenGui") then
		return existing
	end
	
	local newScreen = Instance.new("ScreenGui")
	newScreen.Name = screenName
	newScreen.DisplayOrder = 100
	newScreen.ResetOnSpawn = false
	newScreen.IgnoreGuiInset = true
	newScreen.Enabled = false
	newScreen.Parent = pg
	return newScreen
end

-- Create a standard overlay with theme support
function HatchUI.CreateOverlay(screen: ScreenGui): Frame
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Config.Theme.Background
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Parent = screen
	
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Config.Theme.PanelGradient[1], Config.Theme.PanelGradient[2])
	grad.Rotation = 45
	grad.Parent = overlay
	
	return overlay
end

-- Create a ViewportFrame and Camera for 3D rendering
function HatchUI.CreateViewport(parent: Instance): (ViewportFrame, Camera)
	local vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.new(1, 0, 1, 0)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(200, 200, 200)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(-1, -1, -1)
	vp.Parent = parent

	local cam = Instance.new("Camera")
	cam.FieldOfView = 50
	vp.CurrentCamera = cam
	cam.Parent = vp

	return vp, cam
end

-- Play a sound effect
function HatchUI.PlaySFX(soundId: string, pitch: number?)
	if not soundId or soundId == "" then return end
	local sfx = Instance.new("Sound")
	sfx.SoundId = soundId
	sfx.Volume = 1
	if pitch then sfx.PlaybackSpeed = pitch end
	sfx.Parent = workspace
	sfx:Play()
	Debris:AddItem(sfx, 3)
end

-- Emit confetti effect
function HatchUI.EmitConfetti(parent: GuiObject, amount: number)
	local colors = {
		Color3.fromRGB(255, 100, 100),
		Color3.fromRGB(100, 255, 100),
		Color3.fromRGB(100, 100, 255),
		Color3.fromRGB(255, 255, 100),
		Color3.fromRGB(255, 100, 255),
	}

	for i = 1, amount do
		local shred = Instance.new("Frame")
		shred.Size = UDim2.new(0, math.random(10, 20), 0, math.random(10, 20))
		shred.Position = UDim2.new(math.random(5, 95) / 100, 0, -0.1, 0)
		shred.BackgroundColor3 = colors[math.random(1, #colors)]
		shred.Rotation = math.random(0, 360)
		shred.BorderSizePixel = 0
		shred.Parent = parent

		local duration = math.random(15, 30) / 10
		local targetY = math.random(100, 120) / 100

		local tween = TweenService:Create(shred, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Position = UDim2.new(shred.Position.X.Scale + (math.random(-20, 20) / 100), 0, targetY, 0),
			Rotation = shred.Rotation + math.random(180, 720)
		})
		tween:Play()
		task.delay(duration, function() shred:Destroy() end)
	end
end

-- Flash effect
function HatchUI.Flash(screen: ScreenGui)
	local flashLayer = Instance.new("Frame")
	flashLayer.Size = UDim2.new(1, 0, 1, 0)
	flashLayer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flashLayer.BackgroundTransparency = 0
	flashLayer.BorderSizePixel = 0
	flashLayer.ZIndex = 10
	flashLayer.Parent = screen
	
	TweenService:Create(flashLayer, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	task.delay(0.3, function() flashLayer:Destroy() end)
end

-- Standardized cleanup
function HatchUI.Cleanup(overlay: Frame, screen: ScreenGui, duration: number)
	task.wait(duration)
	
	local tween = TweenService:Create(overlay, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
	tween.Completed:Connect(function()
		overlay:Destroy()
		screen.Enabled = false
	end)
	tween:Play()
end

return HatchUI
