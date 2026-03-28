--!strict
-- ZoneController.luau

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local ZonePlus = require(Packages:WaitForChild("ZonePlus"))
local ZoneTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ZoneTypes"))

local ZoneController = {}
local localZones = {}

function ZoneController.Init()
	-- Handle Music Zones
	for _, part in ipairs(CollectionService:GetTagged(ZoneTypes.Tags.MusicZone)) do
		if part:IsA("BasePart") then
			local zone = ZonePlus.new(part)
			local zoneMusicId = part:GetAttribute("MusicId")
			
			if zoneMusicId then
				local sound = Instance.new("Sound")
				sound.Name = "ZoneMusic_" .. part.Name
				sound.SoundId = zoneMusicId
				sound.Looped = true
				sound.Volume = 0 -- Start silent
				sound.Parent = SoundService
				sound:Play()

				zone.localPlayerEntered:Connect(function()
					-- Fade in zone music, fade out main BGM
					local mainBGM = SoundService:FindFirstChild("MainBGM") :: Sound?
					if mainBGM then
						game:GetService("TweenService"):Create(mainBGM, TweenInfo.new(1), { Volume = 0 }):Play()
					end
					game:GetService("TweenService"):Create(sound, TweenInfo.new(1), { Volume = 0.5 }):Play()
					print("[ZoneController] Entered Music Zone:", part.Name)
				end)

				zone.localPlayerExited:Connect(function()
					-- Fade out zone music, fade in main BGM
					local mainBGM = SoundService:FindFirstChild("MainBGM") :: Sound?
					if mainBGM then
						game:GetService("TweenService"):Create(mainBGM, TweenInfo.new(1), { Volume = 0.3 }):Play()
					end
					game:GetService("TweenService"):Create(sound, TweenInfo.new(1), { Volume = 0 }):Play()
					print("[ZoneController] Left Music Zone:", part.Name)
				end)
			end
			table.insert(localZones, zone)
		end
	end

	-- Handle client-side Safezone notifications or UI
	for _, part in ipairs(CollectionService:GetTagged(ZoneTypes.Tags.Safezone)) do
		if part:IsA("BasePart") then
			local zone = ZonePlus.new(part)
			zone.localPlayerEntered:Connect(function()
				-- You could fire an event to UIController here
				print("[ZoneController] Local Player entered Safezone")
			end)
			zone.localPlayerExited:Connect(function()
				print("[ZoneController] Local Player left Safezone")
			end)
			table.insert(localZones, zone)
		end
	end

	print("✅ [ZoneController] Initialized " .. #localZones .. " local zones.")
end

return ZoneController
