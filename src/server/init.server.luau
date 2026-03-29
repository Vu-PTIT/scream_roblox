-- init.server.luau
-- Server Entry Point: Khởi động tất cả Services theo thứ tự phụ thuộc

print("=== [ShoutSimulator] Server Initializing... ===")

-- FIX: Xoá ZonePlusReference nếu tồn tại (từ Plugin context trong Studio) 
-- Để tránh lỗi "Requested module was required recursively"
local replicatedStorage = game:GetService("ReplicatedStorage")
local zpRef = replicatedStorage:FindFirstChild("ZonePlusReference")
if zpRef then
	zpRef:Destroy()
	print("✔️ [ZonePlus] Cleared stale Reference from Studio Plugin.")
end

-- Layer 0: DataService trước tiên (các service khác depend vào nó)
local _DataService = require(script.Services.DataService)

-- Layer 1: Services độc lập (song song)
local MapService = require(script.Services.MapService)
local _ShoutService = require(script.Services.ShoutService)
local _UpgradeService = require(script.Services.UpgradeService)
local _PetService = require(script.Services.PetService)
local _SkillService = require(script.Services.SkillService)
local _TextFilterService = require(script.Services.TextFilterService)
local MonsterService = require(script.Services.MonsterService)
local LeaderboardService = require(script.Services.LeaderboardService)
local RewardService = require(script.Services.RewardService)
local QuestService = require(script.Services.QuestService)
local CodeService = require(script.Services.CodeService)
local MonetizationService = require(script.Services.MonetizationService)
local ZoneService = require(script.Services.ZoneService)

-- Khởi động Services cần Init
MapService.Init()
RewardService.Initialize()
QuestService.Initialize()
CodeService.Initialize()
MonetizationService.Initialize()
ZoneService.Init()

task.defer(function()
	task.wait(2) -- Đợi map load
	MonsterService.Init()
	LeaderboardService.Init()
end)

print("=== [ShoutSimulator] Server Ready! ===")
