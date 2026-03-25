--!strict
-- EggHatchUI.luau
-- Client-side: Hiệu ứng 3D mở trứng gacha

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local EggHatchUI = {}
local LocalPlayer = Players.LocalPlayer

local function getPlayerGui(): PlayerGui?
	if not LocalPlayer then return nil end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local hatchScreen: ScreenGui? = nil
local isAnimating = false

local _RarityColors: { [string]: Color3 } = {
	Common    = Color3.fromRGB(180, 180, 200),
	Uncommon  = Color3.fromRGB(80, 255, 120),
	Rare      = Color3.fromRGB(80, 160, 255),
	Epic      = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 200, 50),
}

local function getModel(modelType: string, idOrName: string, fallbackColor: Color3): BasePart | Model
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	if modelsFolder then
		local subFolder = modelsFolder:FindFirstChild(modelType)
		if subFolder then
			local model = subFolder:FindFirstChild(idOrName) or subFolder:FindFirstChild("Default")
			if model and (model:IsA("Model") or model:IsA("BasePart")) then
				return model:Clone()
			end
		end
	end

	-- Tạo fallback nếu không tìm thấy custom model từ Toolbox/Blender
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Color = fallbackColor
	part.Material = Enum.Material.SmoothPlastic
	if modelType == "Eggs" then
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(4, 5, 4)
	else
		part.Shape = Enum.PartType.Block
		part.Size = Vector3.new(3, 3, 3)
	end
	return part
end

local function playSFX(soundId: string, pitch: number?)
	if not soundId or soundId == "" then return end
	local sfx = Instance.new("Sound")
	sfx.SoundId = soundId
	sfx.Volume = 1
	if pitch then sfx.PlaybackSpeed = pitch end
	sfx.Parent = workspace
	sfx:Play()
	game:GetService("Debris"):AddItem(sfx, 3)
end

local function emitConfetti(parent: GuiObject, amount: number)
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

local function playHatchAnimation(pets: {Types.PetData}, overrideParent: Instance?)
	if isAnimating then return end
	isAnimating = true

	if not hatchScreen then
		local pg = overrideParent or getPlayerGui()
		if not pg then return end
		
		local existing = (pg :: any):FindFirstChild("EggHatchUI")
		if existing and existing:IsA("ScreenGui") then
			hatchScreen = existing
		else
			local newScreen = Instance.new("ScreenGui")
			newScreen.Name = "EggHatchUI"
			newScreen.DisplayOrder = 100
			newScreen.ResetOnSpawn = false
			newScreen.IgnoreGuiInset = true
			newScreen.Parent = pg
			hatchScreen = newScreen
		end
	end
	
	local screen = hatchScreen :: ScreenGui
	screen.Enabled = true

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

	TweenService:Create(overlay, TweenInfo.new(0.5), { BackgroundTransparency = 0.2 }):Play()

	local vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.new(1, 0, 1, 0)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(200, 200, 200)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(-1, -1, -1)
	vp.Parent = overlay

	local cam = Instance.new("Camera")
	cam.CFrame = CFrame.new(Vector3.new(0, 5, 22), Vector3.new(0, 5, 0))
	cam.FieldOfView = 50
	vp.CurrentCamera = cam

	local eggModel = getModel("Eggs", "BasicEgg", Color3.fromRGB(220, 210, 190))
	local eggInstance = eggModel :: Instance
	eggInstance.Parent = vp

	local baseCFrame = CFrame.new(0, 5, 0)
	eggModel:PivotTo(baseCFrame)

	local shakeDuration = 2.0
	local shakeEndTime = os.clock() + shakeDuration
	local shakeConnection: RBXScriptConnection

	shakeConnection = RunService.RenderStepped:Connect(function()
		local t = os.clock()
		if t >= shakeEndTime then
			shakeConnection:Disconnect()
			return
		end
		
		local progress = 1 - ((shakeEndTime - t) / shakeDuration)
		local intensity = progress * 2.0
		local offset = Vector3.new(math.random(-10,10)*0.01*intensity, math.random(-10,10)*0.01*intensity, 0)
		local rotY = math.random(-25, 25) * intensity
		local rotZ = math.random(-15, 15) * intensity

		local newCF = baseCFrame * CFrame.new(offset) * CFrame.Angles(0, math.rad(rotY), math.rad(rotZ))

		eggModel:PivotTo(newCF)
	end)

	task.spawn(function()
		for i = 1, 5 do
			if Config.Audio and Config.Audio.EggShakeSFX then
				playSFX(Config.Audio.EggShakeSFX, 0.8 + (i * 0.1))
			end
			task.wait(shakeDuration / 5)
		end
	end)

	task.wait(shakeDuration)
	eggModel:Destroy()

	if Config.Audio and Config.Audio.EggFlashSFX then
		playSFX(Config.Audio.EggFlashSFX)
	end
	
	local flashLayer = Instance.new("Frame")
	flashLayer.Size = UDim2.new(1, 0, 1, 0)
	flashLayer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flashLayer.BackgroundTransparency = 0
	flashLayer.BorderSizePixel = 0
	flashLayer.ZIndex = 10
	flashLayer.Parent = screen
	
	TweenService:Create(flashLayer, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	task.delay(0.3, function() flashLayer:Destroy() end)

	local hasEpicOrLeg = false
	for _, pet in ipairs(pets) do
		if pet.Rarity == "Epic" or pet.Rarity == "Legendary" then
			hasEpicOrLeg = true
		end
	end

	if Config.Audio then
		if hasEpicOrLeg and Config.Audio.EggHatchEpicSFX then
			playSFX(Config.Audio.EggHatchEpicSFX)
		elseif Config.Audio.EggHatchNormalSFX then
			playSFX(Config.Audio.EggHatchNormalSFX)
		end
	end

	emitConfetti(overlay, 80)

	local spacing = 6
	local startX = -((#pets - 1) * spacing) / 2
	local spunModels = {}

	for i, pet in ipairs(pets) do
		local pColor = Config.Theme.RarityColors[pet.Rarity] or Color3.fromRGB(200, 200, 200)
		local pModel = getModel("Pets", pet.PetType, pColor)
		local petInstance = pModel :: Instance
		petInstance.Parent = vp

		local tPos = Vector3.new(startX + (i-1)*spacing, 5, 0)
		local tCFrame = CFrame.new(tPos) * CFrame.Angles(0, math.rad(15), 0)
		
		pModel:PivotTo(tCFrame)
		
		table.insert(spunModels, {model = pModel, pos = tPos})

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0, 240, 0, 60)
		
		local pctX = 0.5
		if #pets > 1 then
			pctX = 0.1 + (i-1) * (0.8 / (#pets - 1))
		end
		lbl.Position = UDim2.new(pctX, -120, 0.5, 90)
		lbl.BackgroundTransparency = 1
		lbl.Text = pet.PetType .. "\n" .. string.upper(pet.Rarity)
		lbl.TextColor3 = pColor
		lbl.Font = Enum.Font.GothamBlack
		lbl.TextSize = 24
		lbl.Parent = overlay
		
		local lStroke = Instance.new("UIStroke")
		lStroke.Color = Color3.new(0,0,0)
		lStroke.Thickness = 2
		lStroke.Parent = lbl
		
		lbl.Position = UDim2.new(pctX, -120, 0.5, 140)
		lbl.TextTransparency = 1
		lStroke.Transparency = 1
		
		TweenService:Create(lbl, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(pctX, -120, 0.5, 100),
			TextTransparency = 0
		}):Play()
		TweenService:Create(lStroke, TweenInfo.new(0.5), { Transparency = 0.4 }):Play()
	end

	local spinConn
	spinConn = RunService.RenderStepped:Connect(function(dt)
		if not overlay.Parent then spinConn:Disconnect(); return end
		local spinT = os.clock() * 2
		for _, data in ipairs(spunModels) do
			local offset = math.sin(spinT + data.pos.X) * 0.5
			local bBox = CFrame.new(data.pos + Vector3.new(0, offset, 0)) * CFrame.Angles(math.rad(offset*10), spinT, math.sin(spinT)*0.1)
			data.model:PivotTo(bBox)
		end
	end)

	task.wait(4.0)

	TweenService:Create(overlay, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	task.wait(0.5)

	if spinConn then spinConn:Disconnect() end
	overlay:Destroy()
	if hatchScreen then hatchScreen.Enabled = false end
	isAnimating = false
end

function EggHatchUI.Init(overrideParent: Instance?)
	Remotes.Events.EggOpenResult.OnClientEvent:Connect(function(pets)
		playHatchAnimation(pets, overrideParent)
	end)
	
	-- [SMART BINDING] Detect existing EggHatchUI
	local pg = overrideParent or getPlayerGui()
	if not pg then return end
	
	local existing: ScreenGui? = nil
	for _, child in ipairs(pg:GetChildren()) do
		if child:IsA("ScreenGui") then
			if child.Name == "EggHatchUI" or child:FindFirstChild("Overlay", true) then
				if not existing then
					existing = child
				else
					child:Destroy()
				end
			end
		end
	end
	
	if existing then
		hatchScreen = existing
		print("ℹ️ [EggHatchUI] Using existing ScreenGui for smart binding.")
	else
		local newScreen = Instance.new("ScreenGui")
		newScreen.Name = "EggHatchUI"
		newScreen.DisplayOrder = 100
		newScreen.ResetOnSpawn = false
		newScreen.IgnoreGuiInset = true
		newScreen.Enabled = false
		newScreen.Parent = pg
		hatchScreen = newScreen
		
		local overlay = Instance.new("Frame")
		overlay.Name = "Overlay"
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundTransparency = 1
		overlay.Parent = newScreen
	end
	
	print("[EggHatchUI] Initialized")
end

return EggHatchUI
