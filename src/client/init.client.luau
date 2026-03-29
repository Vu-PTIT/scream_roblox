--!strict
-- init.client.luau
-- Client Entry Point: Boot tất cả Controllers theo thứ tự

print("=== [ShoutSimulator] Client Initializing... ===")

-- SAFE REQUIRE HELPER
local function safeRequire(path: any, name: string)
	local success, result = pcall(function() return require(path) end)
	if not success then
		warn("❌ [Client] Failed to load " .. name .. ": " .. tostring(result))
		return nil
	end
	return result
end

-- Layer 0: Data (phải đầu tiên vì UI depends vào nó)
local DataController = safeRequire(script.Controllers.DataController, "DataController")

-- Layer 1: Input & Audio Controller
local AudioController = safeRequire(script.Controllers.AudioController, "AudioController")
if AudioController then AudioController.Init() end

local _AnimationController = script.Controllers:WaitForChild("AnimationController", 5)
if _AnimationController then
	safeRequire(_AnimationController, "AnimationController")
end

local _ShoutController = safeRequire(script.Controllers.ShoutController, "ShoutController")
local _DashController = safeRequire(script.Controllers.DashController, "DashController")
local ZoneController = safeRequire(script.Controllers.ZoneController, "ZoneController")
local MonsterController = safeRequire(script.Controllers.MonsterController, "MonsterController")

if MonsterController then MonsterController.Init() end
if ZoneController then ZoneController.Init() end

-- Layer 2: UI (sau data để subscribe đúng)
local UIController = safeRequire(script.Controllers.UIController, "UIController")
if UIController then
	UIController.Init()
end

print("=== [ShoutSimulator] Client Ready! | Click/Space để HÉT! ===")
