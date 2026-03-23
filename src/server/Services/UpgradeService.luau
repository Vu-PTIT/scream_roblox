--!strict
-- UpgradeService.luau
-- Server-side: Xử lý logic mua upgrade, kiểm tra đủ tiền, apply stats

local _Players = game:GetService("Players")
local Shared  = game.ReplicatedStorage.Shared
local Config  = require(Shared.Config)
local Types   = require(Shared.Types)
local Remotes = require(Shared.Remotes)

local DataService: any = nil
task.defer(function()
	DataService = require(script.Parent.DataService)
end)

local UpgradeService = {}

-- Build map: upgradeId → UpgradeConfig
local UpgradeMap: { [string]: Types.UpgradeConfig } = {}
for _, cfg in ipairs(Config.Upgrades) do
	UpgradeMap[cfg.Id] = cfg
end

-- Tính cost tại level hiện tại
local function getCostAtLevel(cfg: Types.UpgradeConfig, currentLevel: number): number
	return math.floor(cfg.BaseCost * (cfg.CostScaling ^ currentLevel))
end

local function onPurchaseUpgrade(player: Player, upgradeId: string)
	if not DataService then return end
	local data = DataService.GetData(player) :: Types.PlayerData?
	if not data then return end

	local cfg = UpgradeMap[upgradeId]
	if not cfg then
		Remotes.Events.Notification:FireClient(player, Config.Localization.Notifications.UpgradeNotFound)
		return
	end

	-- Xác định level hiện tại
	local currentLevel: number
	if cfg.Id == "microphone_1" then currentLevel = data.AttackUpgradeLevel
	elseif cfg.Id == "speaker_1" then currentLevel = data.SpeakerUpgradeLevel
	elseif cfg.Id == "headphone_1" then currentLevel = data.DefenseUpgradeLevel
	elseif cfg.Id == "armor_1" then currentLevel = data.ArmorUpgradeLevel
	else currentLevel = 0 end

	-- Kiểm tra max level
	if currentLevel >= cfg.MaxLevel then
		Remotes.Events.Notification:FireClient(player, Config.Localization.Notifications.MaxLevelReached)
		return
	end

	local cost = getCostAtLevel(cfg, currentLevel)
	if data.Gold < cost then
		Remotes.Events.Notification:FireClient(player, string.format(Config.Localization.Notifications.NotEnoughGoldUpgrade, cost))
		return
	end

	-- Trừ tiền, tăng level
	local newGold  = data.Gold - cost
	local newLevel = currentLevel + 1

	local updates = { Gold = newGold }
	if cfg.Id == "microphone_1" then updates.AttackUpgradeLevel = newLevel
	elseif cfg.Id == "speaker_1" then updates.SpeakerUpgradeLevel = newLevel
	elseif cfg.Id == "headphone_1" then updates.DefenseUpgradeLevel = newLevel
	elseif cfg.Id == "armor_1" then updates.ArmorUpgradeLevel = newLevel
	end
	
	DataService.UpdateFields(player, updates)

	Remotes.Events.Notification:FireClient(player, string.format(Config.Localization.Notifications.UpgradeSuccess, cfg.DisplayName, newLevel))
end

-- Bind remote
Remotes.Events.PurchaseUpgrade.OnServerEvent:Connect(function(player: Player, ...)
	local args = { ... }
	local upgradeId = args[1]
	if type(upgradeId) == "string" then
		onPurchaseUpgrade(player, upgradeId)
	end
end)

return UpgradeService
