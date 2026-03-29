local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Ripple
local hasRipple = pcall(function()
	Ripple = require(ReplicatedStorage.Packages:WaitForChild("Ripple", 10))
end)

local MonsterController = {}

-- Lưu trữ motion cho từng monster
local activeMotions: { [Model]: any } = {}

local function animateMonster(model: Model)
	if not model:IsA("Model") then
		return
	end

	-- Đảm bảo model có PrimaryPart
	local hrp = model:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		return
	end

	-- Bắt đầu từ 1.0 (mặc định)
	-- model:ScaleTo(0.01)

	if hasRipple and Ripple then
		-- Sử dụng Ripple nếu có
		local scaleMotion = Ripple.createMotion(0.01)
		activeMotions[model] = scaleMotion

		local connection = scaleMotion:onStep(function(value)
			if model.Parent then
				model:ScaleTo(math.max(0.01, value))
			end
		end)

		scaleMotion:spring(1, Ripple.config.spring.wobbly :: any)

		-- Dying logic
		local function onDyingChanged()
			if model:GetAttribute("Dying") == true then
				scaleMotion:spring(1.3, Ripple.config.spring.stiff :: any)
				task.delay(0.15, function()
					if model.Parent then
						scaleMotion:spring(0, Ripple.config.spring.stiff :: any)
					end
				end)

				-- [TD-3] Client-side timeout: destroy if model still exists after 2s
				task.delay(2.0, function()
					if model.Parent then
						model:Destroy()
					end
				end)
			end
		end
		local attConn = model:GetAttributeChangedSignal("Dying"):Connect(onDyingChanged)
		onDyingChanged() -- Kiểm tra luôn nếu nó đã chết khi client mới nhận được model

		-- Procedural Movement Effects (Fake Walking)
		local lastPos = hrp.Position
		local walkCycle = 0
		local renderConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
			if not model.Parent or model:GetAttribute("Dying") then return end
			local velocity = (hrp.Position - lastPos).Magnitude / dt
			lastPos = hrp.Position
			
			if velocity > 1 then
				walkCycle += dt * velocity * 0.5
				-- Pulse scale while walking to simulate 'stepping'
				if scaleMotion then
					scaleMotion:impulse(0.015 * math.sin(walkCycle * 4))
				end
			end
		end)

		model.Destroying:Connect(function()
			renderConn:Disconnect()
			if connection then connection() end
			if attConn then attConn:Disconnect() end
			activeMotions[model] = nil
		end)
	else
		-- Fallback dùng TweenService nếu Ripple lỗi
		local val = Instance.new("NumberValue")
		val.Value = 0.01
		val.Changed:Connect(function(v)
			if model.Parent then
				model:ScaleTo(math.max(0.01, v))
			end
		end)

		local tween =
			TweenService:Create(val, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1 })
		tween:Play()

		local function onDyingChanged()
			if model:GetAttribute("Dying") == true then
				TweenService
					:Create(val, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 0 })
					:Play()

				-- [TD-3] Client-side timeout: destroy if model still exists after 2s
				task.delay(2.0, function()
					if model.Parent then
						model:Destroy()
					end
				end)
			end
		end
		local attConn = model:GetAttributeChangedSignal("Dying"):Connect(onDyingChanged)
		onDyingChanged() -- Kiểm tra luôn nếu nó đã chết khi client mới nhận được model

		model.Destroying:Connect(function()
			val:Destroy()
			if attConn then
				attConn:Disconnect()
			end
		end)
	end
end

function MonsterController.Init()
	-- Xử lý các quái đã có sẵn trong Workspace
	for _, monster in ipairs(CollectionService:GetTagged("Monster")) do
		task.spawn(animateMonster, monster)
	end

	-- Lắng nghe quái mới xuất hiện
	CollectionService:GetInstanceAddedSignal("Monster"):Connect(function(instance)
		if instance:IsA("Model") then
			task.spawn(animateMonster, instance)
		end
	end)

	print("[MonsterController] Initialized. Ripple support:", tostring(hasRipple))
end

return MonsterController
