--!strict
-- DamageIndicator.luau
-- Client VFX: Text bay lên đầu nạn nhân khi bị Knockback
-- Hiển thị "💥 X Force" nổi lên và fade out dần

local TweenService = game:GetService("TweenService")
local _Players      = game:GetService("Players")

local DamageIndicator = {}

-- ============================================================
-- Tạo floating text trên đầu target với force magnitude
-- ============================================================
function DamageIndicator.Show(targetChar: Model, forceMagnitude: number)
	if type(targetChar) ~= "userdata" or not targetChar:IsA("Model") then return end

	local hrp = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	-- Chọn màu và emoji theo mức độ force
	local displayText: string
	local textColor: Color3

	if forceMagnitude >= 600 then
		displayText = string.format("💥 %.0f FORCE!", forceMagnitude)
		textColor   = Color3.fromRGB(255, 60, 60)   -- Đỏ - cực mạnh
	elseif forceMagnitude >= 300 then
		displayText = string.format("💢 %.0f Force", forceMagnitude)
		textColor   = Color3.fromRGB(255, 140, 40)  -- Cam - mạnh
	elseif forceMagnitude >= 100 then
		displayText = string.format("⚡ %.0f Force", forceMagnitude)
		textColor   = Color3.fromRGB(255, 220, 50)  -- Vàng - trung bình
	else
		displayText = string.format("%.0f Force", forceMagnitude)
		textColor   = Color3.fromRGB(200, 200, 200) -- Xám - yếu
	end

	-- Tạo BillboardGui làm anchor bay lên
	local billboard = Instance.new("BillboardGui")
	billboard.Name            = "DamageIndicator"
	billboard.Size            = UDim2.new(0, 180, 0, 40)
	billboard.StudsOffset     = Vector3.new(
		math.random(-20, 20) / 10,  -- lệch trái/phải ngẫu nhiên một chút
		4,                           -- bắt đầu ngay trên đầu
		0
	)
	billboard.AlwaysOnTop     = false
	billboard.Adornee         = hrp
	billboard.Parent          = workspace

	local label = Instance.new("TextLabel")
	label.Name                = "IndicatorText"
	label.Size                = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text                = displayText
	label.TextColor3          = textColor
	label.TextStrokeColor3    = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.3
	label.Font                = Enum.Font.GothamBlack
	label.TextScaled          = true
	label.Parent              = billboard

	-- Phase 1: Pop in nhanh (scale lên)
	label.TextTransparency = 0.0

	-- Phase 2: Bay lên và fade out đồng thời
	local riseTween = TweenService:Create(billboard, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(
			billboard.StudsOffset.X,
			billboard.StudsOffset.Y + 6,  -- Bay lên thêm 6 stud
			0
		)
	})

	local fadeTween = TweenService:Create(label, TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.25), {
		TextTransparency = 1
	})

	riseTween:Play()
	fadeTween:Play()

	-- Cleanup sau khi animation xong
	task.delay(1.3, function()
		if billboard and billboard.Parent then
			billboard:Destroy()
		end
	end)
end

return DamageIndicator
