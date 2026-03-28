--!strict
-- SkillHatchUI.luau
-- Client-side: Hiệu ứng mở Skill Scroll 3D premium

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local HatchUI = require(script.Parent:WaitForChild("HatchUI"))
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Ripple = require(Packages:WaitForChild("Ripple"))

local SkillHatchUI = {}

local screen: ScreenGui? = nil

-- Fallback for Ripple
local createMotion = Ripple.createMotion or Ripple.create

function SkillHatchUI.Init(overrideParent: Instance?)
	screen = HatchUI.Init("SkillHatchUI", overrideParent)
end

function SkillHatchUI.PlayHatch(skillName: string, rarity: string)
	if not screen then SkillHatchUI.Init() end
	if not screen then return end
	
	local hatchScreen = screen :: ScreenGui
	hatchScreen.Enabled = true
	
	local overlay = HatchUI.CreateOverlay(hatchScreen)
	
	-- Fade in overlay
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.3}):Play()
	
	local vp, cam = HatchUI.CreateViewport(overlay)
	vp.Size = UDim2.new(0, 400, 0, 400)
	vp.Position = UDim2.new(0.5, 0, 0.45, 0)
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	
	local model = Instance.new("Part")
	model.Size = Vector3.new(2, 3, 0.1)
	model.Color = Config.Theme.RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
	model.Material = Enum.Material.Glass
	model.Parent = vp
	
	local baseCFrame = CFrame.new(0, 0, 0)
	model.CFrame = baseCFrame
	cam.CFrame = CFrame.new(Vector3.new(0, 0, 6), model.Position)

	-- Ripple Motion
	local shakeMotion = if createMotion then createMotion(baseCFrame) else nil
	if shakeMotion and shakeMotion.spring then
		shakeMotion:spring(baseCFrame, { frequency = 10, damping = 0.5 })
	end

	-- SFX: Shake
	if Config.Audio and Config.Audio.EggShakeSFX then
		HatchUI.PlaySFX(Config.Audio.EggShakeSFX, 1.2)
	end

	-- Animation: Shake and Reveal
	local startTime = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local elapsed = os.clock() - startTime
		if elapsed < 1.5 then
			-- Shaking
			if shakeMotion then
				if elapsed % 0.2 < 0.1 then
					shakeMotion:impulse(CFrame.Angles(math.random(-10,10)*0.01, math.random(-10,10)*0.01, math.random(-10,10)*0.01))
				end
				model.CFrame = shakeMotion:step(dt)
			else
				model.CFrame = baseCFrame * CFrame.Angles(0, math.rad(elapsed * 360), 0) * CFrame.Angles(math.sin(elapsed * 50) * 0.1, 0, 0)
			end
		else
			conn:Disconnect()
			
			-- Reveal Effects
			if Config.Audio and Config.Audio.EggFlashSFX then
				HatchUI.PlaySFX(Config.Audio.EggFlashSFX)
			end
			HatchUI.Flash(hatchScreen)
			HatchUI.EmitConfetti(overlay, 50)

			-- Model Reveal
			model.Color = Config.Theme.RarityColors[rarity]
			
			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(0, 400, 0, 50)
			title.Position = UDim2.new(0.5, 0, 0.75, 0)
			title.AnchorPoint = Vector2.new(0.5, 0.5)
			title.BackgroundTransparency = 1
			title.Text = skillName:upper()
			title.TextColor3 = Config.Theme.RarityColors[rarity]
			title.Font = Enum.Font.GothamBlack
			title.TextSize = 42
			title.TextStrokeTransparency = 0.5
			title.Parent = overlay
			
			local rarityLabel = Instance.new("TextLabel")
			rarityLabel.Size = UDim2.new(0, 400, 0, 30)
			rarityLabel.Position = UDim2.new(0.5, 0, 0.82, 0)
			rarityLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			rarityLabel.BackgroundTransparency = 1
			rarityLabel.Text = rarity:upper()
			rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			rarityLabel.Font = Enum.Font.GothamBold
			rarityLabel.TextSize = 20
			rarityLabel.Parent = overlay

			HatchUI.Cleanup(overlay, hatchScreen, 3.0)
		end
	end)
end

return SkillHatchUI
