--!strict
-- ZoneService.luau

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local ZonePlus = require(Packages:WaitForChild("ZonePlus"))
local ZoneTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ZoneTypes"))

local ZoneService = {}
local zones = {}

function ZoneService.Init()
	-- Initialize Safezones
	for _, part in ipairs(CollectionService:GetTagged(ZoneTypes.Tags.Safezone)) do
		if part:IsA("BasePart") then
			local zone = ZonePlus.new(part)
			zone.playerEntered:Connect(function(player)
				player:SetAttribute("InSafezone", true)
				print("[ZoneService] Player entered Safezone:", player.Name)
			end)
			zone.playerExited:Connect(function(player)
				player:SetAttribute("InSafezone", false)
				print("[ZoneService] Player left Safezone:", player.Name)
			end)
			table.insert(zones, zone)
		end
	end

	-- Initialize Lava (Damage Zones)
	for _, part in ipairs(CollectionService:GetTagged(ZoneTypes.Tags.Lava)) do
		if part:IsA("BasePart") then
			local zone = ZonePlus.new(part)
			
			-- Damage loop for players in the zone
			task.spawn(function()
				while task.wait(0.5) do
					local playersInZone = zone:getPlayers()
					for _, player in ipairs(playersInZone) do
						local character = player.Character
						local humanoid = character and character:FindFirstChildOfClass("Humanoid")
						if humanoid and humanoid.Health > 0 then
							humanoid:TakeDamage(5) -- Base lava damage
						end
					end
				end
			end)
			
			table.insert(zones, zone)
		end
	end

	print("✅ [ZoneService] Initialized " .. #zones .. " zones.")
end

return ZoneService
