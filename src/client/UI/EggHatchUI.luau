--!strict
-- EggHatchUI.luau
-- Client-side: Hiệu ứng 3D mở trứng gacha

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local HatchUI = require(script.Parent:WaitForChild("HatchUI"))
local Ripple = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Ripple"))

local EggHatchUI = {}

local hatchScreen: ScreenGui? = nil
local isAnimating = false

-- Fallback for different Ripple versions
local createMotion = Ripple.createMotion or Ripple.create
if not createMotion then
	warn("[EggHatchUI] Ripple.createMotion is nil! Export structure:", Ripple)
end

local function getModel(modelType: string, idOrName: string, fallbackColor: Color3): Model
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	if modelsFolder then
		local subFolder = modelsFolder:FindFirstChild(modelType)
		if subFolder then
			local model = subFolder:FindFirstChild(idOrName) or subFolder:FindFirstChild("Default")
			if model then
				if model:IsA("Model") then
					return model:Clone()
				elseif model:IsA("BasePart") then
					local m = Instance.new("Model")
					local c = model:Clone()
					c.Parent = m
					m.PrimaryPart = c
					return m
				end
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
	
	local m = Instance.new("Model")
	part.Parent = m
	m.PrimaryPart = part
	return m
end

local function playHatchAnimation(pets: {Types.PetData}, overrideParent: Instance?)
	if isAnimating then return end
	if not hatchScreen then return end
	if not createMotion then 
		warn("[EggHatchUI] Cannot animate, Ripple library missing createMotion or create function")
		return 
	end
	isAnimating = true

	local screen = hatchScreen :: ScreenGui
	screen.Enabled = true

	local overlay = HatchUI.CreateOverlay(screen)
	TweenService:Create(overlay, TweenInfo.new(0.5), { BackgroundTransparency = 0.2 }):Play()

	local vp, cam = HatchUI.CreateViewport(overlay)
	cam.CFrame = CFrame.new(Vector3.new(0, 5, 22), Vector3.new(0, 5, 0))

	local eggModel = getModel("Eggs", "BasicEgg", Color3.fromRGB(220, 210, 190))
	eggModel.Parent = vp

	local baseCFrame = CFrame.new(0, 5, 0)
	eggModel:PivotTo(baseCFrame)

	local shakeDuration = 2.0
	local shakeMotion = createMotion(Vector3.new(0, 0, 0))
	local rotMotion = createMotion(Vector3.new(0, 0, 0))

	-- Set up solvers for Ripple 0.9+
	if shakeMotion.spring then
		shakeMotion:spring(Vector3.new(0, 0, 0), { frequency = 12, damping = 0.4 })
		rotMotion:spring(Vector3.new(0, 0, 0), { frequency = 10, damping = 0.5 })
	end

	local shakeConnection = RunService.RenderStepped:Connect(function(dt)
		local offset = shakeMotion:step(dt)
		local rot = rotMotion:step(dt)
		eggModel:PivotTo(baseCFrame * CFrame.new(offset) * CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z)))
	end)

	task.spawn(function()
		local intervals = 8
		for i = 1, intervals do
			local intensity = (i / intervals) * 2
			shakeMotion:impulse(Vector3.new(math.random(-5, 5) * intensity, math.random(-5, 5) * intensity, 0))
			rotMotion:impulse(Vector3.new(math.random(-15, 15) * intensity, math.random(-30, 30) * intensity, math.random(-15, 15) * intensity))
			
			if Config.Audio and Config.Audio.EggShakeSFX then
				HatchUI.PlaySFX(Config.Audio.EggShakeSFX, 0.8 + (i * 0.1))
			end
			task.wait(shakeDuration / intervals)
		end
	end)

	task.wait(shakeDuration)
	shakeConnection:Disconnect()
	eggModel:Destroy()

	if Config.Audio and Config.Audio.EggFlashSFX then
		HatchUI.PlaySFX(Config.Audio.EggFlashSFX)
	end
	
	HatchUI.Flash(screen)

	local hasEpicOrLeg = false
	for _, pet in ipairs(pets) do
		if pet.Rarity == "Epic" or pet.Rarity == "Legendary" then
			hasEpicOrLeg = true
		end
	end

	if Config.Audio then
		if hasEpicOrLeg and Config.Audio.EggHatchEpicSFX then
			HatchUI.PlaySFX(Config.Audio.EggHatchEpicSFX)
		elseif Config.Audio.EggHatchNormalSFX then
			HatchUI.PlaySFX(Config.Audio.EggHatchNormalSFX)
		end
	end

	HatchUI.EmitConfetti(overlay, 80)

	local spacing = 6
	local startX = -((#pets - 1) * spacing) / 2
	local spunModels = {}

	for i, pet in ipairs(pets) do
		local pColor = Config.Theme.RarityColors[pet.Rarity] or Color3.fromRGB(200, 200, 200)
		local pModel = getModel("Pets", pet.PetType, pColor)
		pModel.Parent = vp

		local tPos = Vector3.new(startX + (i-1)*spacing, 5, 0)
		local tCFrame = CFrame.new(tPos) * CFrame.Angles(0, math.rad(15), 0)
		pModel:PivotTo(tCFrame)
		
		-- Use Ripple for a "Pop-in" scale effect
		local popMotion = createMotion(0)
		popMotion:set(1.5)
		if popMotion.spring then
			popMotion:spring(1, { frequency = 6, damping = 0.5 })
		else
			popMotion:set(1)
		end
		
		local popConn
		popConn = RunService.RenderStepped:Connect(function(dt)
			if not pModel.Parent then popConn:Disconnect(); return end
			local s = popMotion:step(dt)
			pModel:ScaleTo(s)
		end)

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

	HatchUI.Cleanup(overlay, screen, 4.0)
	
	task.delay(4.5, function()
		if spinConn then spinConn:Disconnect() end
		isAnimating = false
	end)
end

function EggHatchUI.Init(overrideParent: Instance?)
	Remotes.Events.EggOpenResult.OnClientEvent:Connect(function(pets)
		playHatchAnimation(pets, overrideParent)
	end)
	
	hatchScreen = HatchUI.Init("EggHatchUI", overrideParent)
	
	print("[EggHatchUI] Initialized")
end

return EggHatchUI
