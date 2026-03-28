--!strict
-- AnimationController.luau
-- Quản lý việc load và phát các Animation cho nhân vật (Chickynoid/Humanoid)

local Players = game:GetService("Players")

local Shared = game.ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local AnimationController = {}
local loadedAnimations: { [string]: AnimationTrack } = {}
local currentCharacter: Model? = nil
local animator: Animator? = nil

-- Khởi tạo Animation cho nhân vật mới
function AnimationController.Init(character: Model)
	if not Config.Animations.Enabled then return end
	if currentCharacter == character then return end
	
	-- Dọn dẹp cũ
	for _, track in pairs(loadedAnimations) do
		track:Stop()
		track:Destroy()
	end
	table.clear(loadedAnimations)
	
	currentCharacter = character
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not humanoid then 
		warn("[AnimationController] Không tìm thấy Humanoid trong nhân vật")
		return 
	end
	
	animator = humanoid:WaitForChild("Animator", 5) :: Animator?
	if not animator then
		local newAnimator = Instance.new("Animator")
		newAnimator.Parent = humanoid
		animator = newAnimator
	end
	
	-- Ghi đè animations mặc định (Idle/Run) nếu có script Animate
	local animateScript = character:FindFirstChild("Animate")
	if animateScript then
		local function setAnim(name: string, id: string)
			if id == "" or id == "rbxassetid://0" then return end
			local folder = animateScript:FindFirstChild(name)
			if folder then
				local anim = folder:FindFirstChildOfClass("Animation")
				if anim then
					anim.AnimationId = id
				end
			end
		end
		
		pcall(function()
			if Config.Animations.Idle then setAnim("idle", Config.Animations.Idle) end
			if Config.Animations.Run then setAnim("run", Config.Animations.Run) end
			if Config.Animations.Walk then setAnim("walk", Config.Animations.Walk) end
		end)
	end
	
	-- Pre-load some animations if needed, or load on demand
	print("[AnimationController] Đã khởi tạo cho nhân vật:", character.Name)
end

-- Phát một animation theo tên hoặc ID trực tiếp
function AnimationController.Play(name: string, fadeTime: number?, weight: number?, speed: number?, overrideId: string?): AnimationTrack?
	if not animator then 
		return nil 
	end
	
	local animId = overrideId or Config.Animations[name]
	if not animId or animId == "" or animId == "rbxassetid://0" then
		return nil
	end
	
	-- Cache Key: Dùng overrideId làm key nếu có để tránh xung đột tên
	local key = overrideId or name
	
	-- Load nếu chưa có
	if not loadedAnimations[key] then
		local animation = Instance.new("Animation")
		animation.AnimationId = animId
		local ok, track = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if ok then
			loadedAnimations[key] = track
		else
			warn("[AnimationController] Lỗi load animation:", key, track)
			return nil
		end
	end
	
	local track = loadedAnimations[key]
	if track then
		track:Play(fadeTime or 0.1, weight or 1, speed or 1)
	end
	return track
end

-- Dừng một animation
function AnimationController.Stop(name: string, fadeTime: number?)
	local track = loadedAnimations[name]
	if track then
		track:Stop(fadeTime or 0.1)
	end
end

-- Dừng tất cả animation
function AnimationController.StopAll(fadeTime: number?)
	for _, track in pairs(loadedAnimations) do
		track:Stop(fadeTime or 0.1)
	end
end

-- Tự động khởi tạo khi local player có nhân vật
local function onCharacterAdded(character: Model)
	AnimationController.Init(character)
end

if Players.LocalPlayer.Character then
	onCharacterAdded(Players.LocalPlayer.Character)
end
Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

return AnimationController
