--!strict
-- ShoutWave.luau
-- VFX: Sóng âm hình cone + ParticleEmitter khi hét
-- Module này được gọi từ client để hiển thị local VFX

local TweenService = game:GetService("TweenService")
local Debris       = game:GetService("Debris")

local Shared = game.ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local ShoutWave = {}

-- Màu sóng âm dựa theo attack power
local function getWaveColor(attackPower: number): Color3
	if attackPower < 50 then
		return Color3.fromRGB(0, 255, 255)     -- Xanh cyan sáng
	elseif attackPower < 150 then
		return Color3.fromRGB(255, 200, 50)    -- Cam vàng
	elseif attackPower < 300 then
		return Color3.fromRGB(255, 50, 20)     -- Đỏ rực
	else
		return Color3.fromRGB(200, 0, 255)     -- Tím đậm
	end
end

-- 1. Tạo vụ nổ quả cầu ngay tại miệng lúc bắt đầu hét
local function createMouthBlast(origin: CFrame, color: Color3, power: number)
	local sizeFactor = math.clamp(power / 50, 1, 4)
	local blast = Instance.new("Part")
	blast.Anchored = true
	blast.CanCollide = false
	blast.CastShadow = false
	blast.Shape = Enum.PartType.Ball
	blast.Size = Vector3.new(2, 2, 2)
	blast.CFrame = origin
	blast.Material = Enum.Material.Neon
	blast.Color = color
	blast.Transparency = 0.1
	blast.Parent = workspace

	local tween = TweenService:Create(blast, TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Size = Vector3.new(12 * sizeFactor, 12 * sizeFactor, 12 * sizeFactor),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(blast, 0.4)
end

-- 2. Sóng âm hình màng (ring/đĩa) bắn về phía trước
local function createFlyingWave(origin: CFrame, color: Color3, delayTime: number, duration: number, endRadius: number, distance: number, power: number)
	local sizeFactor = math.clamp(power / 50, 1, 3)
	task.delay(delayTime, function()
		local wave = Instance.new("Part")
		wave.Anchored = true
		wave.CanCollide = false
		wave.CastShadow = false
		wave.Shape = Enum.PartType.Cylinder
		wave.CFrame = origin * CFrame.Angles(0, math.pi / 2, 0)
		
		wave.Size = Vector3.new(0.3, 3 * sizeFactor, 3 * sizeFactor)
		wave.Material = Enum.Material.Neon
		wave.Color = color
		wave.Transparency = 0.2
		wave.Parent = workspace

		local targetCFrame = (origin + origin.LookVector * distance) * CFrame.Angles(0, math.pi / 2, 0)

		local tween = TweenService:Create(wave, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Size = Vector3.new(0.1, endRadius * 2 * sizeFactor, endRadius * 2 * sizeFactor),
			CFrame = targetCFrame,
			Transparency = 1,
		})
		tween:Play()
		Debris:AddItem(wave, duration + 0.1)
	end)
end

-- 3. Luồng nén chính (Beam) ở giữa vút nhanh
local function createBeam(origin: CFrame, color: Color3, distance: number, power: number)
	local sizeFactor = math.clamp(power / 50, 1, 4)
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CastShadow = false
	beam.Shape = Enum.PartType.Cylinder
	beam.CFrame = origin * CFrame.Angles(0, math.pi / 2, 0)
	beam.Size = Vector3.new(1, 1.5 * sizeFactor, 1.5 * sizeFactor)
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Transparency = 0.3
	beam.Parent = workspace

	local targetCFrame = origin * CFrame.new(0, 0, -distance / 2) * CFrame.Angles(0, math.pi / 2, 0)

	local tween = TweenService:Create(beam, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(distance, 5 * sizeFactor, 5 * sizeFactor),
		CFrame = targetCFrame,
		Transparency = 0.7
	})
	tween:Play()

	task.delay(0.2, function()
		local fade = TweenService:Create(beam, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(distance + 20, 0.1, 0.1),
			Transparency = 1
		})
		fade:Play()
		Debris:AddItem(beam, 0.25)
	end)
end

-- 4. Vòng tròn chấn động (Expanding Ring) cho Circular Shout
local function createExpandingRing(origin: CFrame, color: Color3, sizeFactor: number, duration: number, maxRadius: number)
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Shape = Enum.PartType.Cylinder
	-- Xoay part để mặt tròn nằm ngang (trục X của Cylinder hướng lên trên)
	ring.CFrame = (origin * CFrame.new(0, -1, 0)) * CFrame.Angles(0, 0, math.pi / 2) 
	ring.Size = Vector3.new(0.5, 4 * sizeFactor, 4 * sizeFactor)
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.4
	ring.Parent = workspace

	local tween = TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.1, maxRadius * 2, maxRadius * 2),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(ring, duration + 0.1)
end

-- 4. Particle bắn khí mạnh do tiếng hét
local function emitShoutParticles(origin: CFrame, color: Color3, distance: number, shoutConfig: any)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.CFrame = origin
	anchor.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.3, color),
		ColorSequenceKeypoint.new(1, color),
	})
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 4),
		NumberSequenceKeypoint.new(1, 8),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.6, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	-- Tốc độ dựa theo khoảng cách (sức tấn công)
	local speedMax = math.max(100, distance * 3)
	emitter.Speed = NumberRange.new(speedMax * 0.6, speedMax)
	emitter.Lifetime = NumberRange.new(0.3, 0.5)
	emitter.Rate = 0
	
	local spreadAngle = shoutConfig and shoutConfig.Angle or 12
	if shoutConfig then
		-- Adjust spread for visual representation. 180 means 360 circle. 
		local maxSpread = math.clamp(spreadAngle, 10, 180)
		emitter.SpreadAngle = Vector2.new(-maxSpread, maxSpread)
		
		-- Nếu là Circular (360), cho phép hạt bay theo mọi hướng y
		if maxSpread >= 170 then
			emitter.VelocityInheritance = 0
		end
	else
		-- Tia bắn hình nón hẹp default
		emitter.SpreadAngle = Vector2.new(-12, 12)
	end
	
	emitter.Drag = 3
	emitter.Parent = anchor

	emitter:Emit(if spreadAngle >= 170 then 100 else 60)
	Debris:AddItem(anchor, 1.0)
end

-- ============================================================
-- API chính: Phát sóng âm
-- ============================================================
function ShoutWave.Play(origin: CFrame, attackPower: number, shoutConfig: any, rarityColor: Color3?, powerMult: number?)
	local pMult = powerMult or 1.0
	local color = rarityColor or getWaveColor(attackPower)
	local baseDist = shoutConfig and shoutConfig.Range or Config.Shout.KnockbackRange
	local attackDist = baseDist * math.pow(pMult, 0.45)
	
	createMouthBlast(origin, color, attackPower * pMult)
	createBeam(origin, color, attackDist, attackPower * pMult)
	
	local waveCount = 5
	for i = 1, waveCount do
		local delayTime = (i - 1) * 0.05
		local endRadius = (6 + i * 3) * math.sqrt(pMult)
		local waveDistance = attackDist * (0.5 + (i / waveCount) * 0.5)
		createFlyingWave(origin, color, delayTime, 0.35, endRadius, waveDistance, attackPower)
	end
	
	emitShoutParticles(origin, color, attackDist, shoutConfig)
end

-- API riêng cho Circular Shout (Shockwave)
function ShoutWave.PlayCircular(origin: CFrame, attackPower: number, shoutConfig: any, rarityColor: Color3?, powerMult: number?)
	local pMult = powerMult or 1.0
	local color = rarityColor or getWaveColor(attackPower)
	local range = shoutConfig and shoutConfig.Range or 20
	local attackDist = range * math.pow(pMult, 0.45)
	local sizeFactor = math.clamp((attackPower * pMult) / 50, 1, 4)

	-- 1. Nổ miệng
	createMouthBlast(origin, color, attackPower * pMult)

	-- 2. Vòng tròn chấn động tỏa ra (Thay vì Beam)
	createExpandingRing(origin, color, sizeFactor, 0.4, attackDist)
	
	-- 3. Thêm một vòng phụ trễ một chút để trông premium hơn
	task.delay(0.1, function()
		createExpandingRing(origin, color, sizeFactor * 0.7, 0.5, attackDist * 1.2)
	end)

	-- 4. Particles tỏa tròn 360
	emitShoutParticles(origin, color, attackDist, shoutConfig)
end

-- Hiệu ứng khi bị knockback (flash đỏ + ImpactSFX)
function ShoutWave.PlayHitEffect(character: Model)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local flash = Instance.new("Part")
	flash.Anchored    = true
	flash.CanCollide  = false
	flash.CastShadow  = false
	flash.Massless    = true
	flash.Size        = Vector3.new(4, 4, 4)
	flash.Shape       = Enum.PartType.Ball
	flash.Material    = Enum.Material.Neon
	flash.Color       = Color3.fromRGB(255, 50, 50)
	flash.Transparency = 0.3
	flash.CFrame      = hrp.CFrame
	flash.Parent      = workspace

	local tween = TweenService:Create(flash, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size         = Vector3.new(8, 8, 8),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(flash, 0.3)

	-- ImpactSFX khi bị trúng
	if Config.Audio and Config.Audio.ImpactSFX and Config.Audio.ImpactSFX ~= "" then
		local impactSound = Instance.new("Sound")
		impactSound.SoundId              = Config.Audio.ImpactSFX
		impactSound.Volume               = 0.9
		impactSound.RollOffMaxDistance   = 50
		impactSound.Parent               = hrp
		impactSound:Play()
		Debris:AddItem(impactSound, 3)
	end
end

return ShoutWave
