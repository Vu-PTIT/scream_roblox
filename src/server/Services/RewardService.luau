--!strict
-- RewardService.luau
-- Quản lý Quà Tặng Thời Gian (Playtime Rewards) và Quà Hàng Ngày / Đăng Nhập.

local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)

local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local RewardService = {}

function RewardService.Initialize()
	-- Vòng lặp đếm giờ, tự động cộng thêm thời gian nhận quà mỗi 60 giây
	task.spawn(function()
		while true do
			task.wait(60) 
			for _, player in Players:GetPlayers() do
				RewardService.UpdatePlaytime(player)
			end
		end
	end)
	
	Remotes.Events.ClaimPlaytimeReward.OnServerEvent:Connect(function(player, milestoneIndex)
		if type(milestoneIndex) == "number" then
			RewardService.ClaimPlaytimeReward(player, milestoneIndex)
		end
	end)
	
	print("[RewardService] Playtime reward loop started.")
end

-- Cập nhật PlayTime cho người chơi trong DataStore
function RewardService.UpdatePlaytime(player: Player)
	local data = DataService.GetData(player)
	if not data then return end
	
	-- Tăng PlayTime
	local newPlaytime = (data.PlayTime or 0) + 60
	DataService.UpdateField(player, "PlayTime", newPlaytime)
	
	-- Lưu ý: Bạn có thể code logic tự động phát quà hoặc gửi tín hiệu về client để người chơi bấm nút "Claim" ở đây.
	-- if not data.ClaimedPlaytimeRewards then data.ClaimedPlaytimeRewards = {} end
end

-- Cấu trúc khung hàm hỗ trợ nhận quà
function RewardService.ClaimPlaytimeReward(player: Player, milestoneIndex: number)
	local data = DataService.GetData(player)
	if not data then return false end
	
	local milestone = Config.Rewards.PlaytimeMilestones[milestoneIndex]
	if not milestone then return false end
	
	if data.PlayTime < milestone.Time then
		-- Chưa đủ thời gian
		return false
	end
	
	if not data.ClaimedPlaytimeRewards then data.ClaimedPlaytimeRewards = {} end
	
	if data.ClaimedPlaytimeRewards[tostring(milestoneIndex)] then
		-- Đã nhận mốc này
		return false
	end
	
	-- Phát quà & Đánh dấu đã nhận
	data.ClaimedPlaytimeRewards[tostring(milestoneIndex)] = true
	DataService.UpdateField(player, "ClaimedPlaytimeRewards", data.ClaimedPlaytimeRewards)
	
	if milestone.Reward.Type == "Gold" then
		DataService.UpdateField(player, "Gold", data.Gold + milestone.Reward.Amount)
	end
	
	return true
end

return RewardService
