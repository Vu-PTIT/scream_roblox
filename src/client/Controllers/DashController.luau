--!strict
-- DashController.luau
-- Client-side: Xử lý cơ chế lướt (Dash) bằng phím Q hoặc Shift

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local Shared = game.ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShoutController = require(script.Parent.ShoutController)

local DashController = {}

local LocalPlayer = Players.LocalPlayer
local lastDashTime = 0

local function performDash()
	local now = os.clock()
	if now - lastDashTime < Config.Dash.Cooldown then return end

	local character = LocalPlayer.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
	if not hrp or not humanoid then return end
	if humanoid.Health <= 0 then return end

	lastDashTime = now

	-- Hướng lướt: Ưu tiên hướng đang di chuyển, nếu đứng yên thì lướt tới trước
	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = hrp.CFrame.LookVector
	else
		direction = direction.Unit
	end

	-- Tránh lướt theo phương Y lên trời/xuống đất
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	-- Tạo Attachment cho LinearVelocity
	local attachment = Instance.new("Attachment")
	attachment.Name = "DashAttachment"
	attachment.Parent = hrp

	local lv = Instance.new("LinearVelocity")
	lv.Name = "DashVelocity"
	lv.Attachment0 = attachment
	-- Cần giới hạn MaxForce để không bị physics glitch, dùng math.huge có thể lỗi ở một số trường hợp, nên dùng số lớn
	lv.MaxForce = 100000 
	lv.VectorVelocity = direction * Config.Dash.ForceMultiplier
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = hrp

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

	-- Tự hủy LinearVelocity sau Duration
	Debris:AddItem(lv, Config.Dash.Duration)
	Debris:AddItem(attachment, Config.Dash.Duration)

	-- Gọi hàm hét (Shout) cùng lúc khi lướt, bắn sóng thẳng ra sau lưng
	task.spawn(function()
		if ShoutController.PerformShout then
			ShoutController.PerformShout(-direction)
		end
	end)
end

-- Lắng nghe phím
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftShift then
		performDash()
	end
end)

return DashController
