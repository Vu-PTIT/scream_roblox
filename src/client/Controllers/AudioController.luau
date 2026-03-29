--!strict
-- AudioController.luau
-- Quản lý nhạc nền (BGM) và các âm thanh chung trên client

local SoundService = game:GetService("SoundService")

local Shared = game.ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local AudioController = {}

function AudioController.Init()
	local bgmConfig = Config.Audio.BGM
	if bgmConfig and bgmConfig ~= "" then
		local bgm = Instance.new("Sound")
		bgm.Name = "MainBGM"
		bgm.SoundId = bgmConfig
		bgm.Looped = true
		bgm.Volume = 0.3
		bgm.Parent = SoundService
		bgm:Play()
		print("🎵 [AudioController] Started BGM.")
	end

	-- Connect Jump and Land SFX
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local Debris = game:GetService("Debris")

	local function onCharacterAdded(char: Model)
		local humanoid = char:WaitForChild("Humanoid") :: Humanoid
		humanoid.StateChanged:Connect(function(oldState, newState)
			if newState == Enum.HumanoidStateType.Jumping then
				local snd = Instance.new("Sound")
				snd.SoundId = Config.Audio.JumpSFX or "rbxassetid://12222225"
				snd.Volume = 0.5
				snd.Parent = char.PrimaryPart
				snd:Play()
				Debris:AddItem(snd, 2)
			elseif newState == Enum.HumanoidStateType.Landed then
				local snd = Instance.new("Sound")
				snd.SoundId = Config.Audio.LandSFX or "rbxassetid://12222152"
				snd.Volume = 0.5
				snd.Parent = char.PrimaryPart
				snd:Play()
				Debris:AddItem(snd, 2)
			end
		end)
	end

	if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

return AudioController
