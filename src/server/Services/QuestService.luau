--!strict
-- QuestService.luau
-- Hệ thống Quản Lý Nhiệm Vụ Hàng Ngày (Daily Quests).

local DataService = require(script.Parent.DataService)

local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local QuestService = {}

function QuestService.Initialize()
	Remotes.Events.ClaimQuestReward.OnServerEvent:Connect(function(player, questId)
		if type(questId) == "string" then
			QuestService.ClaimReward(player, questId)
		end
	end)
	print("[QuestService] Ready to track player actions and missions.")
end

-- Function gọi để báo cáo một hành động (Click Hét, Mở Trứng, Đánh Quái Vong...)
-- Bạn chèn dòng QuestService.RegisterAction(player, "Shout", 1) vào trong ShoutService.luau để theo dõi
function QuestService.RegisterAction(player: Player, actionType: string, amount: number)
	local data = DataService.GetData(player)
	if not data then return end
	
	if not data.Quests then data.Quests = {} end
	data.Quests[actionType] = (data.Quests[actionType] or 0) + amount
	
	-- Bạn có thể kiểm tra xem if data.Quests[actionType] >= 50 thì phát quà ở đây
	-- Cập nhật data
	DataService.UpdateField(player, "Quests", data.Quests)
end

-- Check xem nhiệm vụ đã hoàn thành chưa
function QuestService.CheckGoal(player: Player, actionType: string, requiredAmount: number): boolean
	local data = DataService.GetData(player)
	if not data or not data.Quests then return false end
	
	return (data.Quests[actionType] or 0) >= requiredAmount
end

-- Xử lý nhận quà cho Nhiệm vụ
function QuestService.ClaimReward(player: Player, questId: string): boolean
	local data = DataService.GetData(player)
	if not data then return false end
	
	local questDef
	for _, q in ipairs(Config.Quests) do
		if q.Id == questId then
			questDef = q
			break
		end
	end
	
	if not questDef then return false end
	
	local progress = data.Quests[questDef.ActionType] or 0
	if progress < questDef.Required then return false end
	
	if not data.ClaimedQuests then data.ClaimedQuests = {} end
	if data.ClaimedQuests[questId] then return false end
	
	data.ClaimedQuests[questId] = true
	DataService.UpdateField(player, "ClaimedQuests", data.ClaimedQuests)
	
	if questDef.Reward.Type == "Gold" then
		DataService.UpdateField(player, "Gold", data.Gold + questDef.Reward.Amount)
	elseif questDef.Reward.Type == "VocalPoints" then
		DataService.UpdateField(player, "VocalPoints", data.VocalPoints + questDef.Reward.Amount)
	end
	
	Remotes.Events.Notification:FireClient(player, "✅ Claimed Quest Reward: " .. questDef.Title)
	return true
end

return QuestService
