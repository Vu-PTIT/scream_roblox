--!strict
-- SkillHatchUI.luau
-- Client-side: Hiệu ứng mở Skill Scroll 3D premium
-- Tương tự EggHatchUI nhưng dành cho Skill

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local _Debris = game:GetService("Debris")

local Shared = game.ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local SkillHatchUI = {}
local localPlayer = Players.LocalPlayer

local function getPlayerGui(): PlayerGui?
	if not localPlayer then return nil end
	return localPlayer:FindFirstChildOfClass("PlayerGui")
end

local screen: ScreenGui? = nil

local function buildHatchUI(parent: Instance?)
	local pg = parent or getPlayerGui()
	if not pg then return end
	
	local existing = (pg :: any):FindFirstChild("SkillHatchUI")
	if existing and existing:IsA("ScreenGui") then
		screen = existing :: ScreenGui
		print("ℹ️ [SkillHatchUI] Sử dụng SkillHatchUI hiện có.")
		return
	end

	screen = (Instance.new("ScreenGui") :: any) :: ScreenGui
	if not screen then return end
	screen.Name = "SkillHatchUI"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Enabled = false
	screen.Parent = pg

	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1 -- Start transparent
	overlay.BorderSizePixel = 0
	overlay.Parent = screen :: Instance
end

function SkillHatchUI.Init(overrideParent: Instance?)
	buildHatchUI(overrideParent)
end

function SkillHatchUI.PlayHatch(skillName: string, rarity: string)
	if not screen then buildHatchUI() end
	if not screen then return end
	
	screen.Enabled = true
	local overlay = (screen :: ScreenGui):FindFirstChild("Overlay") :: Frame
	
	-- Fade in black overlay
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.3}):Play()
	
	if not screen then return end
	
	-- Create 3D Viewport for the "Scroll" or "Skill Icon"
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(0, 400, 0, 400)
	viewport.Position = UDim2.new(0.5, 0, 0.45, 0)
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.BackgroundTransparency = 1
	viewport.Parent = screen :: Instance
	
	local camera = Instance.new("Camera")
	camera.FieldOfView = 50
	viewport.CurrentCamera = camera
	camera.Parent = viewport :: Instance

	-- For now, use a simple colored block or an icon part to represent the skill
	local model = Instance.new("Part")
	model.Size = Vector3.new(2, 3, 0.5)
	model.Color = Config.Theme.RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
	model.Material = Enum.Material.Glass
	model.Parent = viewport
	
	camera.CFrame = CFrame.new(Vector3.new(0, 0, 6), model.Position)

	-- Animation: Shake and Reveal
	local startTime = tick()
	local conn
	conn = game:GetService("RunService").RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed < 1.5 then
			-- Shaking
			model.CFrame = CFrame.Angles(0, math.rad(elapsed * 360), 0) * CFrame.Angles(math.sin(elapsed * 50) * 0.1, 0, 0)
		else
			conn:Disconnect()
			-- Final Reveal
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
			title.Parent = screen
			
			local rarityLabel = Instance.new("TextLabel")
			rarityLabel.Size = UDim2.new(0, 400, 0, 30)
			rarityLabel.Position = UDim2.new(0.5, 0, 0.82, 0)
			rarityLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			rarityLabel.BackgroundTransparency = 1
			rarityLabel.Text = rarity:upper()
			rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			rarityLabel.Font = Enum.Font.GothamBold
			rarityLabel.TextSize = 20
			rarityLabel.Parent = screen

			task.wait(2)
			-- Cleanup
			TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
			task.wait(0.5)
			if screen then
				screen.Enabled = false
			end
			viewport:Destroy()
			title:Destroy()
			rarityLabel:Destroy()
		end
	end)
end

return SkillHatchUI
