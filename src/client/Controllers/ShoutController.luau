--!strict
-- ShoutController.luau
-- Client-side: Detect input → play local VFX/SFX → fire Remote lên server
-- Camera shake khi bị knockback

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game.ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local Config = require(Shared.Config)
local ShoutWave = require(Shared.VFX.ShoutWave)
local Refx = require(Shared.Refx)
local AnimationController = require(script.Parent:WaitForChild("AnimationController")) :: any

local DamageIndicator = require(script.Parent.Parent.UI.DamageIndicator)

local DataController: any = nil
task.defer(function()
	DataController = require(script.Parent.DataController)
end)

local ShoutController = {} :: {
	PerformShout: (slotIndex: number, overrideDirection: Vector3?, powerMult: number?) -> (),
	GetCooldownData: (slotIndex: number) -> (number, number),
	GetChargingSlot: () -> number?,
	GetSelectedSlot: () -> number,
	SetSelectedSlot: (slot: number) -> (),
}

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local lastShoutTimes = { [0] = 0, [1] = 0, [2] = 0 }
local isCharging = false
local chargeStartTime = 0
local auraEmitter: ParticleEmitter? = nil
local auraLight: PointLight? = nil
local CurrentChargingSlot: number? = nil
local SelectedSkillSlot: number = 0
local hitStopEndTime = 0

local function getEquippedSkillConfig(slotIndex: number)
	if slotIndex == 0 then
		-- Tìm Basic Shout trong Config
		for _, cfg in ipairs(Config.Skills) do
			if cfg.IsBasic then
				return cfg
			end
		end
		return Config.Skills[1]
	end

	if not DataController then
		return Config.Skills[1]
	end
	local data = DataController.GetData()
	if not data or not data.EquippedSkillIds then
		return Config.Skills[1]
	end

	local skillId = data.EquippedSkillIds[slotIndex]
	if not skillId then
		return nil
	end -- Không có skill ở slot này

	for _, skill in ipairs(data.Skills or {}) do
		if skill.Id == skillId then
			for _, cfg in ipairs(Config.Skills) do
				if cfg.SkillType == skill.SkillType then
					return cfg
				end
			end
		end
	end
	return nil
end

-- BILLBOARD SHOUT
local shoutBillboard: BillboardGui? = nil

local function createShoutBillboard(character: Model): BillboardGui
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		error("No HRP")
	end

	local existing = hrp:FindFirstChild("ShoutBillboard")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "ShoutBillboard"
	gui.Size = UDim2.new(0, 200, 0, 50)
	gui.StudsOffset = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = false
	gui.Adornee = hrp
	gui.Parent = hrp

	local label = Instance.new("TextLabel")
	label.Name = "ShoutText"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = ""
	label.TextColor3 = Color3.fromRGB(255, 255, 100)
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui

	return gui
end

local function showShoutText(text: string)
	local character = LocalPlayer.Character
	if not character then
		return
	end

	if not shoutBillboard or not shoutBillboard.Parent then
		local ok, _err = pcall(createShoutBillboard, character)
		if not ok then
			return
		end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			shoutBillboard = hrp:FindFirstChild("ShoutBillboard") :: BillboardGui?
		end
	end

	if not shoutBillboard then
		return
	end
	local label = shoutBillboard:FindFirstChild("ShoutText") :: TextLabel?
	if not label then
		return
	end

	label.Text = text
	label.TextTransparency = 0

	TweenService
		:Create(
			label,
			TweenInfo.new(Config.CustomShout.DisplayDuration, Enum.EasingStyle.Linear),
			{ TextTransparency = 1 }
		)
		:Play()
end

local shakeActive = false
local shakeMagnitude = 0
local shakeDecay = 0

local function _cameraShake(magnitude: number, duration: number)
	shakeMagnitude = magnitude
	shakeDecay = magnitude / duration
	shakeActive = true
	task.delay(duration, function()
		shakeActive = false
		shakeMagnitude = 0
		shakeDecay = 0
	end)
end

local function createAura(character: Model)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "AuraAttachment"
	attachment.Parent = hrp

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "AuraParticles"
	emitter.Texture = "rbxassetid://6050511413"
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 6),
	})
	emitter.Lifetime = NumberRange.new(0.5, 0.8)
	emitter.Rate = 50
	emitter.Speed = NumberRange.new(5, 10)
	emitter.SpreadAngle = Vector2.new(-180, 180)
	emitter.VelocityInheritance = 0.5
	emitter.LightEmission = 1
	emitter.LockedToPart = true
	emitter.Parent = attachment

	local light = Instance.new("PointLight")
	light.Range = 10
	light.Brightness = 2
	light.Parent = hrp

	auraEmitter = emitter
	auraLight = light
end

local function removeAura()
	if auraEmitter then
		auraEmitter.Enabled = false
		local attachment = auraEmitter.Parent
		task.delay(1, function()
			if attachment then
				attachment:Destroy()
			end
		end)
		auraEmitter = nil
	end
	if auraLight then
		auraLight:Destroy()
		auraLight = nil
	end
end

RunService.RenderStepped:Connect(function(dt: number)
	local char = LocalPlayer.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	-- 1. Xử lý Camera Shake (Knockback hoặc Charging)
	if shakeActive and shakeMagnitude > 0 then
		local m = shakeMagnitude
		local offset = Vector3.new(
			(math.random() - 0.5) * 2 * m,
			(math.random() - 0.5) * 2 * m * 0.5,
			(math.random() - 0.5) * 2 * m
		)
		hum.CameraOffset = offset
		shakeMagnitude = math.max(0, shakeMagnitude - shakeDecay * dt)
	elseif not isCharging then
		hum.CameraOffset = hum.CameraOffset:Lerp(Vector3.new(0, 0, 0), 0.1)
	end

	-- 2. Xử lý logic Gồng lực (Charging) và Hit Stop
	local targetSpeed = 16
	local targetFOV = 70
	local chargeOffset = Vector3.new(0, 0, 0)

	local isHitStopping = os.clock() < hitStopEndTime
	if isHitStopping then
		targetSpeed = 1 -- Stall movement
	end

	if isCharging then
		local elapsed = os.clock() - chargeStartTime
		local chargeRatio = math.min(1, elapsed / Config.Shout.Charge.MaxTime)

		-- Constant small shake during charge
		local shakeM = 0.05 + (chargeRatio * 0.2)
		chargeOffset =
			Vector3.new((math.random() - 0.5) * shakeM, (math.random() - 0.5) * shakeM, (math.random() - 0.5) * shakeM)

		-- Update Aura Color
		if auraEmitter then
			local currentLevel = Config.Shout.Charge.Levels[1]
			for _, lvl in ipairs(Config.Shout.Charge.Levels) do
				if elapsed >= lvl.Time then
					currentLevel = lvl
				end
			end
			auraEmitter.Color = ColorSequence.new(currentLevel.Color)
			if auraLight then
				auraLight.Color = currentLevel.Color
			end
		end

		-- Slow down & FOV only if charging significantly (> 0.2s)
		if elapsed > 0.2 then
			targetSpeed = 6
			local fovRatio = math.min(1, (elapsed - 0.2) / (Config.Shout.Charge.MaxTime - 0.2))
			targetFOV = 70 - (fovRatio * 15)

			-- Create Aura if not already present
			if not auraEmitter and LocalPlayer.Character then
				createAura(LocalPlayer.Character)
				local skillConfig = getEquippedSkillConfig(CurrentChargingSlot or 0)
				AnimationController.Play("Charging", nil, nil, nil, skillConfig and skillConfig.ChargingAnimationId)
			end
		end
	end

	-- Combine offsets and apply smoothly
	local finalOffset = (shakeMagnitude > 0 and hum.CameraOffset) or chargeOffset
	if not isCharging and shakeMagnitude <= 0 then
		finalOffset = hum.CameraOffset:Lerp(Vector3.new(0, 0, 0), 0.1)
	end
	hum.CameraOffset = finalOffset

	-- Smooth transition for Speed & FOV (Only set if different enough to prevent physics hitching)
	local newSpeed = hum.WalkSpeed + (targetSpeed - hum.WalkSpeed) * 0.15
	if not isCharging and targetSpeed == 16 and math.abs(hum.WalkSpeed - 16) < 0.1 then
		newSpeed = 16
	end

	if math.abs(hum.WalkSpeed - newSpeed) > 0.01 then
		hum.WalkSpeed = newSpeed
	end

	local newFOV = Camera.FieldOfView + (targetFOV - Camera.FieldOfView) * 0.15
	if math.abs(Camera.FieldOfView - newFOV) > 0.01 then
		Camera.FieldOfView = newFOV
	end
end)

local function createImpactFlash()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ImpactFlash"
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	TweenService
		:Create(
			frame,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		)
		:Play()
	game:GetService("Debris"):AddItem(screenGui, 0.2)
end

local function performShout(slotIndex: number, overrideDirection: Vector3?, powerMult: number?)
	local pMult = powerMult or 1.0
	local character = LocalPlayer.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local skillConfig = getEquippedSkillConfig(slotIndex)
	if not skillConfig then
		return
	end

	local shoutConfig = Config.ShoutTypes[skillConfig.ShoutTypeId] or Config.ShoutTypes.Normal

	local now = os.clock()
	local lastTime = lastShoutTimes[slotIndex] or 0
	if now - lastTime < skillConfig.Cooldown then
		return
	end
	lastShoutTimes[slotIndex] = now

	local direction = Vector3.new(0, 0, -1)
	if overrideDirection then
		direction = overrideDirection.Unit
	else
		local mouse = LocalPlayer:GetMouse()
		local targetPosition = mouse.UnitRay.Origin + mouse.UnitRay.Direction * 1000
		direction = (targetPosition - hrp.Position).Unit
	end

	local originCFrame = CFrame.new(hrp.Position, hrp.Position + direction * 100)
	local attackPower = 50
	if DataController then
		local data = DataController.GetData()
		if data then
			attackPower = data.Attack + (data.DamageUpgradeLevel * Config.Upgrades[1].StatPerLevel)
		end
	end

	-- Calculate base skill power (without charge)
	local baseSkillPower = attackPower * skillConfig.DamageMult
	local rarityColor = Config.Theme.RarityColors and Config.Theme.RarityColors[skillConfig.Rarity]

	if shoutConfig.Id == "Circular" then
		ShoutWave.PlayCircular(
			originCFrame,
			baseSkillPower,
			shoutConfig,
			rarityColor,
			pMult,
			skillConfig.EffectColor,
			skillConfig.EffectSize
		)
		AnimationController.Play("Shout_Circular", nil, nil, nil, skillConfig.AnimationId)
	else
		ShoutWave.Play(
			originCFrame,
			baseSkillPower,
			shoutConfig,
			rarityColor,
			pMult,
			skillConfig.EffectColor,
			skillConfig.EffectSize
		)
		-- Chọn animation dựa theo kiểu Shout (hoặc dùng chiêu riêng nếu có)
		if skillConfig.AnimationId then
			AnimationController.Play(skillConfig.SkillType, nil, nil, nil, skillConfig.AnimationId)
		elseif shoutConfig.Id == "Focused" then
			AnimationController.Play("Shout_Focused")
		else
			AnimationController.Play("Shout_Normal")
		end
	end

	local shoutText = "AAAAHHH!!!"
	if pMult >= 3 then
		shoutText = "OVERPOWERED!!!"
	elseif pMult >= 2 then
		shoutText = "ULTIMATE ROAR!!!"
	elseif DataController then
		local customText = DataController.Get("CustomShoutText")
		if type(customText) == "string" and #customText > 0 then
			shoutText = customText
		end
	end
	showShoutText(shoutText)

	if Config.Audio and Config.Audio.ShoutSFX and Config.Audio.ShoutSFX ~= "" then
		local shoutSound = Instance.new("Sound")
		shoutSound.SoundId = Config.Audio.ShoutSFX
		shoutSound.Volume = 0.8 + (pMult * 0.1)
		shoutSound.PlaybackSpeed = 1 / math.clamp(pMult * 0.8, 0.5, 1)
		shoutSound.RollOffMaxDistance = 60 + (pMult * 20)
		shoutSound.Parent = hrp
		shoutSound:Play()
		game:GetService("Debris"):AddItem(shoutSound, 3)
	end

	-- Camera Kick-back (Dùng CameraOffset thay vì CFrame Tween để tránh khựng)
	local kickIntensity = 0.5 * pMult
	_cameraShake(kickIntensity, 0.15)

	-- Check for actual hits after a short delay (or immediately if predictable)
	-- For local "Juice", we'll just assume it hits if they are in range
	-- Server will confirm later, but HitStop feels better if instant
	hitStopEndTime = os.clock() + 0.05 -- 50ms stall

	Remotes.Events.ShoutFired:FireServer(direction, pMult, slotIndex)
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	local slotToCharge: number? = nil
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Execute: Chọn slot để gồng dựa trên SelectedSkillSlot + Cooldown
		local slotToTry = SelectedSkillSlot
		if slotToTry > 0 then
			local lastTime = lastShoutTimes[slotToTry] or 0
			local skillConfig = getEquippedSkillConfig(slotToTry)
			local cd = skillConfig and skillConfig.Cooldown or 0.8

			if os.clock() - lastTime < cd then
				-- Đang hồi chiêu -> Fallback về Basic (Slot 0)
				slotToTry = 0
			end
		end
		slotToCharge = slotToTry
	elseif input.KeyCode == Enum.KeyCode.One then
		-- Select only
		SelectedSkillSlot = 1
		print("[ShoutController] Selected Skill Slot 1")
		return
	elseif input.KeyCode == Enum.KeyCode.Two then
		-- Select only
		SelectedSkillSlot = 2
		print("[ShoutController] Selected Skill Slot 2")
		return
	end

	if slotToCharge ~= nil then
		local skillConfig = getEquippedSkillConfig(slotToCharge)
		if not skillConfig then
			return
		end

		local now = os.clock()
		local lastTime = lastShoutTimes[slotToCharge] or 0
		if now - lastTime < skillConfig.Cooldown then
			return
		end

		isCharging = true
		chargeStartTime = now
		CurrentChargingSlot = slotToCharge
		-- Aura will be created in RenderStepped if charge > 0.4s
	end

	if input.KeyCode == Enum.KeyCode.Space then
		performShout(0, Vector3.new(0, -1, 0), 1) -- Basic slam slot 0
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject, _gameProcessed: boolean)
	local isMatch = false
	if input.UserInputType == Enum.UserInputType.MouseButton1 and CurrentChargingSlot ~= nil then
		isMatch = true
	elseif input.KeyCode == Enum.KeyCode.One and CurrentChargingSlot == 1 then
		isMatch = true
	elseif input.KeyCode == Enum.KeyCode.Two and CurrentChargingSlot == 2 then
		isMatch = true
	end

	if isMatch and isCharging then
		isCharging = false
		local slotMatched = CurrentChargingSlot :: number
		CurrentChargingSlot = nil

		local elapsed = os.clock() - chargeStartTime
		removeAura()
		local skillConfig = getEquippedSkillConfig(slotMatched)
		AnimationController.Stop(
			if skillConfig and skillConfig.ChargingAnimationId then skillConfig.ChargingAnimationId else "Charging"
		)

		local finalMult = 1.0
		if elapsed >= Config.Shout.Charge.MinTime then
			for _, lvl in ipairs(Config.Shout.Charge.Levels) do
				if elapsed >= lvl.Time then
					finalMult = lvl.Mult
				end
			end
		end

		performShout(slotMatched, nil, finalMult)
		print("[ShoutController] Client fired shout. Slot:", slotMatched, "Mult:", finalMult)
	end
end)

Remotes.Events.KnockbackOccurred.OnClientEvent:Connect(
	function(targetChar: Model, force: Vector3, damageTaken: number, attackerUserId: number?)
		local forceMag = typeof(force) == "Vector3" and force.Magnitude or 0

		DamageIndicator.Show(targetChar, damageTaken or forceMag)

		if targetChar ~= LocalPlayer.Character then
			return
		end

		local char = LocalPlayer.Character
		if not char then
			return
		end

		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
		if not hrp or not hum then
			return
		end

		ShoutWave.PlayHitEffect(char)

		if damageTaken > 40 then
			createImpactFlash()
		end

		if hum.Health > 0 then
			hum.AutoRotate = false
			hum:ChangeState(Enum.HumanoidStateType.FallingDown)

			hrp.AssemblyAngularVelocity = Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15))
			hrp.AssemblyLinearVelocity = force + Vector3.new(0, 20, 0)

			local a0 = Instance.new("Attachment", hrp)
			a0.Position = Vector3.new(0, 1, 0)
			local a1 = Instance.new("Attachment", hrp)
			a1.Position = Vector3.new(0, -1, 0)

			local trail = Instance.new("Trail")
			trail.Attachment0 = a0
			trail.Attachment1 = a1
			trail.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100), Color3.fromRGB(255, 50, 50))
			trail.Transparency = NumberSequence.new(0, 1)
			trail.Lifetime = 0.4
			trail.Parent = hrp

			game:GetService("Debris"):AddItem(trail, 0.7)
			game:GetService("Debris"):AddItem(a0, 0.7)
			game:GetService("Debris"):AddItem(a1, 0.7)

			task.delay(0.7, function()
				if hum and hum.Parent and hum.Health > 0 then
					hum.AutoRotate = true
					hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end)
		end
	end
)

Remotes.Events.DisplayCustomShout.OnClientEvent:Connect(function(userId: number, filteredText: string)
	local targetPlayer = Players:GetPlayerByUserId(userId)
	if not targetPlayer then
		return
	end
	local char = targetPlayer.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	if userId == LocalPlayer.UserId then
		return
	end

	local existingGui = hrp:FindFirstChild("ShoutBillboard") :: BillboardGui?
	local displayGui: BillboardGui
	if existingGui then
		displayGui = existingGui
	else
		displayGui = Instance.new("BillboardGui")
		displayGui.Name = "ShoutBillboard"
		displayGui.Size = UDim2.new(0, 200, 0, 50)
		displayGui.StudsOffset = Vector3.new(0, 3.5, 0)
		displayGui.Adornee = hrp
		displayGui.Parent = hrp

		local lbl = Instance.new("TextLabel")
		lbl.Name = "ShoutText"
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(255, 255, 100)
		lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		lbl.TextStrokeTransparency = 0.3
		lbl.Font = Enum.Font.GothamBlack
		lbl.TextScaled = true
		lbl.Parent = displayGui
	end

	local textLabel = displayGui:FindFirstChild("ShoutText") :: TextLabel?
	if not textLabel then
		return
	end
	textLabel.Text = filteredText
	textLabel.TextTransparency = 0
	TweenService:Create(textLabel, TweenInfo.new(Config.CustomShout.DisplayDuration), { TextTransparency = 1 }):Play()
end)

function ShoutController.GetCooldownData(slotIndex: number)
	local lastTime = lastShoutTimes[slotIndex] or 0
	local skillConfig = getEquippedSkillConfig(slotIndex)
	return lastTime, skillConfig and skillConfig.Cooldown or 0.8
end

function ShoutController.GetChargingSlot()
	return CurrentChargingSlot
end

function ShoutController.GetSelectedSlot()
	return SelectedSkillSlot
end

function ShoutController.SetSelectedSlot(slot: number)
	SelectedSkillSlot = slot
end

ShoutController.PerformShout = performShout

-- Register with Refx
Refx.Register("MonsterShoutVFX", function(position: Vector3, lookPos: Vector3, attackPower: number, shoutTypeId: string)
	local sType = shoutTypeId or "Normal"
	local shoutConfig = Config.ShoutTypes[sType] or Config.ShoutTypes.Normal
	local originCFrame = CFrame.new(position, position + lookPos)

	if sType == "Circular" then
		ShoutWave.PlayCircular(originCFrame, attackPower, shoutConfig)
	else
		ShoutWave.Play(originCFrame, attackPower, shoutConfig)
	end

	-- Return a cleanup function if needed (ShoutWave uses Debris internally)
	return function()
		-- Manual cleanup if needed
	end
end)

local function onCharAdded(character: Model)
	if shoutBillboard then
		shoutBillboard:Destroy()
		shoutBillboard = nil
	end
end
LocalPlayer.CharacterAdded:Connect(onCharAdded)

Refx.Listen()

return ShoutController
