--!strict
-- DashController.luau
-- Client-side: Xử lý cơ chế lướt (Dash) bằng phím Q hoặc Shift

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local Shared = game.ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShoutController = require(script.Parent.ShoutController)
local AnimationController = require(script.Parent:WaitForChild("AnimationController")) :: any

local DashController = {}

local LocalPlayer = Players.LocalPlayer
local lastDashTime = 0

local function performDash()
	local now = os.clock()
	if now - lastDashTime < Config.Dash.Cooldown then
		return
	end

	local character = LocalPlayer.Character
	if not character then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	lastDashTime = now
	
	-- Phát Animation lướt
	AnimationController.Play("Dash")

	-- Sound Effect: Tiếng vút gió khi lướt (DashSFX từ Config)
	if Config.Audio and Config.Audio.DashSFX and Config.Audio.DashSFX ~= "" then
		local sound = Instance.new("Sound")
		sound.Name = "DashSound"
		sound.SoundId = Config.Audio.DashSFX
		sound.Volume = 0.6
		sound.RollOffMaxDistance = 40
		sound.Parent = hrp
		sound:Play()
		Debris:AddItem(sound, 2)
	end

	-- Hướng lướt: Ưu tiên hướng di chuyển, nếu đứng yên thì lướt tới trước
	local direction = hrp.CFrame.LookVector
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
	if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
		direction = humanoid.MoveDirection.Unit
	end

	-- Apply Movement Force (Dash)
	local dashVelocity = Instance.new("BodyVelocity")
	dashVelocity.Name = "DashForce"
	dashVelocity.MaxForce = Vector3.new(1, 1, 1) * 500000 -- Đủ mạnh để thắng ma sát
	dashVelocity.Velocity = direction * Config.Dash.ForceMultiplier
	dashVelocity.Parent = hrp
	
	-- Xóa lực lướt sau thời gian chỉ định trong Config
	Debris:AddItem(dashVelocity, Config.Dash.Duration)

	-- Gọi hàm hét (Shout) cùng lúc khi lướt, bắn sóng thẳng ra sau lưng
	task.spawn(function()
		if ShoutController.PerformShout then
			ShoutController.PerformShout(0, -direction)
		end
	end)
end

-- Lắng nghe phím
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftShift then
		performDash()
	end
end)

return DashController
