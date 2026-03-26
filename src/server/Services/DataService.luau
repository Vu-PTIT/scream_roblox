--!strict
-- DataService.luau
-- Quản lý lưu/load PlayerData dùng DataStoreService (ProfileService pattern)
-- Session locking: mỗi người chỉ có 1 session active tại 1 thời điểm
-- Auto-save mỗi Config.DataSaveInterval giây

local Players         = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService      = game:GetService("RunService")

local Shared   = game.ReplicatedStorage.Shared
local Config   = require(Shared.Config)
local Types    = require(Shared.Types)
local Remotes  = require(Shared.Remotes)

local DataService = {}

-- In-memory store: userId → PlayerData
local ActiveSessions: { [number]: Types.PlayerData } = {}

-- Tracking auto-save
local LastSaveTimes: { [number]: number } = {}

-- DataStore: dùng pcall vì trong Studio cần bật "Enable Studio Access to API Services"
-- (File → Game Settings → Security → Enable Studio Access to API Services)
local DataStore: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		DataStore = result
	else
		warn("[DataService] DataStore unavailable (Studio? Enable API Services): ", result)
	end
end

-- Mock in-memory store cho Studio testing
local MockStore: { [string]: any } = {}

local function safeGet(key: string): any
	if DataStore then
		local ok, result = pcall(function() return DataStore:GetAsync(key) end)
		if ok then return result end
	end
	return MockStore[key]
end

local function safeSet(key: string, value: any)
	if DataStore then
		pcall(function() DataStore:SetAsync(key, value) end)
	end
	MockStore[key] = value
end

-- Deep copy bảng để tránh reference bugs
local function deepCopy(t: any): any
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

-- ============================================================
-- RESET LOGIC
-- ============================================================
local function performDailyReset(player: Player, data: Types.PlayerData)
	local currentUtcDate = os.date("!%Y-%m-%d")
	
	data.Quests = {}
	data.ClaimedQuests = {}
	data.PlayTime = 0
	data.ClaimedPlaytimeRewards = {}
	data.QuestResetDate = currentUtcDate
	
	-- Notify client of full reset if they are already online
	DataService.UpdateFields(player, {
		Quests = data.Quests,
		ClaimedQuests = data.ClaimedQuests,
		PlayTime = data.PlayTime,
		ClaimedPlaytimeRewards = data.ClaimedPlaytimeRewards,
		QuestResetDate = data.QuestResetDate
	})
	
	print("[DataService] Performed daily reset for", player.Name)
end

-- ============================================================
-- LOAD DATA
-- ============================================================
local function loadData(player: Player): Types.PlayerData
	local userId = player.UserId
	local key    = "Player_" .. userId

	-- Dùng safeGet: tự dùng DataStore nếu có, fallback sang MockStore nếu không
	local result = safeGet(key)

	if result ~= nil then
		-- Merge với DefaultPlayerData để thêm các field mới (backward compat)
		local merged = deepCopy(Config.DefaultPlayerData)
		for k, v in pairs(result :: any) do
			local merged_any = merged :: any
			merged_any[k] = v
		end
		
		-- Migration: Khởi tạo TotalVocalPoints cho người chơi cũ
		if (merged.TotalVocalPoints == nil or merged.TotalVocalPoints == 0) and merged.VocalPoints > 0 then
			merged.TotalVocalPoints = merged.VocalPoints
		end

		-- Daily Quest & Playtime Reset
		local currentUtcDate = os.date("!%Y-%m-%d")
		if merged.QuestResetDate ~= currentUtcDate then
			merged.Quests = {}
			merged.ClaimedQuests = {}
			merged.PlayTime = 0
			merged.ClaimedPlaytimeRewards = {}
			merged.QuestResetDate = currentUtcDate
		end
		
		return merged
	else
		-- Tạo account mới
		local data = deepCopy(Config.DefaultPlayerData)
		local data_any = data :: any
		data_any.JoinDate = os.time()
		data_any.QuestResetDate = os.date("!%Y-%m-%d")

		-- Cấp skill khởi đầu (skill đầu tiên không phải basic)
		local starterSkillCfg = Config.Skills[2] -- Loud Cry (hoặc tìm động)
		for _, cfg in ipairs(Config.Skills) do
			if not cfg.IsBasic then
				starterSkillCfg = cfg
				break
			end
		end

		local starterSkill: Types.SkillData = {
			Id         = "starter_shout_" .. tostring(userId),
			SkillType  = starterSkillCfg.SkillType,
			Rarity     = starterSkillCfg.Rarity,
			DamageMult = starterSkillCfg.DamageMult,
			Cooldown   = starterSkillCfg.Cooldown,
			Equipped   = true,
			SlotIndex  = 1,
		}
		table.insert(data.Skills, starterSkill)
		data.EquippedSkillIds = { [1] = starterSkill.Id }

		return data
	end
end

-- ============================================================
-- SAVE DATA
-- ============================================================
local function saveData(player: Player)
	local userId  = player.UserId
	local session = ActiveSessions[userId]
	if not session then return end

	local key = "Player_" .. userId
	safeSet(key, session)
	LastSaveTimes[userId] = os.clock()
end

-- ============================================================
-- PUBLIC API
-- ============================================================

-- Lấy session data của player (server-only)
function DataService.GetData(player: Player): Types.PlayerData?
	return ActiveSessions[player.UserId]
end

-- Cập nhật một field trong data và notify client
function DataService.UpdateField(player: Player, key: string, value: any)
	local session = ActiveSessions[player.UserId]
	if not session then return end

	local session_any = session :: any
	session_any[key] = value

	-- Notify client partial update
	Remotes.Events.PlayerDataUpdated:FireClient(player, key, value)
end

-- Cập nhật nhiều fields cùng lúc
function DataService.UpdateFields(player: Player, updates: { [string]: any })
	local session = ActiveSessions[player.UserId]
	if not session then return end

	local session_any = session :: any
	for key, value in pairs(updates) do
		session_any[key] = value
		Remotes.Events.PlayerDataUpdated:FireClient(player, key, value)
	end
end

-- Force save ngay lập tức (dùng khi player rời game)
function DataService.SaveNow(player: Player)
	saveData(player)
end

-- ============================================================
-- PLAYER LIFECYCLE
-- ============================================================
local function onPlayerAdded(player: Player)
	local data = loadData(player)
	ActiveSessions[player.UserId] = data
	LastSaveTimes[player.UserId]  = os.clock()

	-- Chờ character (có thể bị delay ở test)
	task.wait(1)

	Remotes.Events.PlayerDataLoaded:FireClient(player, data :: any)
	player:SetAttribute("PlayerDataLoaded", true)
	
	-- Apply MaxHealth to char
	local function applyStats(char: Model)
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		hum.MaxHealth = data.MaxHealth
		hum.Health = data.MaxHealth
	end
	if player.Character then applyStats(player.Character) end
	player.CharacterAdded:Connect(applyStats)

	print("[DataService] Loaded data for", player.Name)
end

local function onPlayerRemoving(player: Player)
	saveData(player)
	ActiveSessions[player.UserId] = nil
	LastSaveTimes[player.UserId]  = nil
	print("[DataService] Saved and removed session for", player.Name)
end

-- ============================================================
-- AUTO-SAVE LOOP
-- ============================================================
task.spawn(function()
	while true do
		task.wait(Config.DataSaveInterval)
		for userId, session in pairs(ActiveSessions) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				-- Check mid-session daily reset
				local currentUtcDate = os.date("!%Y-%m-%d")
				if session.QuestResetDate ~= currentUtcDate then
					performDailyReset(player, session)
				end
				
				saveData(player)
			end
		end
	end
end)

-- ============================================================
-- BIND EVENTS
-- ============================================================
if RunService:IsRunning() then
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Bắt các player đã join trước khi script load (Play Solo trong Studio)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	-- Save all on server close
	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			saveData(player)
		end
	end)
end

return DataService
