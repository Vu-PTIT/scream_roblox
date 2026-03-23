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
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local hatchScreen: ScreenGui? = nil
local isAnimating = false

local RarityColors: { [string]: Color3 } = {
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

local function playHatchAnimation(pets: {Types.PetData})
	if isAnimating then return end
	isAnimating = true

	if not hatchScreen then
		local newScreen = Instance.new("ScreenGui")
		newScreen.Name = "EggHatchUI"
		newScreen.DisplayOrder = 100
		newScreen.ResetOnSpawn = false
		newScreen.IgnoreGuiInset = true
		newScreen.Parent = PlayerGui
		hatchScreen = newScreen
	end
	
	local screen = hatchScreen :: ScreenGui
	screen.Enabled = true

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Parent = screen

	TweenService:Create(overlay, TweenInfo.new(0.5), { BackgroundTransparency = 0.1 }):Play()

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
	
	local flashTween = TweenService:Create(overlay, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), { 
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), 
		BackgroundTransparency = 0 
	})
	flashTween:Play()

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
		local pColor = RarityColors[pet.Rarity] or Color3.fromRGB(200, 200, 200)
		local pModel = getModel("Pets", pet.PetType, pColor)
		local petInstance = pModel :: Instance
		petInstance.Parent = vp

		local tPos = Vector3.new(startX + (i-1)*spacing, 5, 0)
		local tCFrame = CFrame.new(tPos) * CFrame.Angles(0, math.rad(15), 0)
		
		pModel:PivotTo(tCFrame)
		
		table.insert(spunModels, {model = pModel, pos = tPos})

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0, 200, 0, 40)
		
		local pctX = 0.5
		if #pets > 1 then
			pctX = 0.1 + (i-1) * (0.8 / (#pets - 1))
		end
		lbl.Position = UDim2.new(pctX, -100, 0.5, 90)
		lbl.BackgroundTransparency = 1
		lbl.Text = pet.PetType .. "\n(" .. pet.Rarity .. ")"
		lbl.TextColor3 = pColor
		lbl.TextStrokeColor3 = Color3.fromRGB(20, 20, 30)
		lbl.TextStrokeTransparency = 0
		lbl.Font = Enum.Font.GothamBlack
		lbl.TextSize = 22
		lbl.Parent = overlay
		
		lbl.Position = UDim2.new(pctX, -100, 0.5, 120)
		lbl.TextTransparency = 1
		lbl.TextStrokeTransparency = 1
		TweenService:Create(lbl, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(pctX, -100, 0.5, 90),
			TextTransparency = 0,
			TextStrokeTransparency = 0
		}):Play()
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

function EggHatchUI.Init()
	Remotes.Events.EggOpenResult.OnClientEvent:Connect(function(pets)
		playHatchAnimation(pets)
	end)
	print("[EggHatchUI] Initialized")
end

return EggHatchUI
