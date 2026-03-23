--!strict
-- init.client.luau
-- Client Entry Point: Boot tất cả Controllers theo thứ tự

print("=== [ShoutSimulator] Client Initializing... ===")

-- Layer 0: Data (phải đầu tiên vì UI depends vào nó)
local _DataController = require(script.Controllers.DataController)

-- Layer 1: Input & Audio Controller
local AudioController = require(script.Controllers.AudioController)
AudioController.Init()

local _ShoutController = require(script.Controllers.ShoutController)
local _DashController = require(script.Controllers.DashController)

-- Layer 2: UI (sau data để subscribe đúng)
local UIController = require(script.Controllers.UIController)
UIController.Init()

print("=== [ShoutSimulator] Client Ready! | Click/Space để HÉT! ===")
