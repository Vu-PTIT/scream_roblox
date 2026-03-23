--!strict
-- DataController.luau
-- Client-side: Cache PlayerData nhận từ server, cung cấp signal OnDataChanged cho các module khác



local Shared         = game.ReplicatedStorage.Shared
local Remotes        = require(Shared.Remotes)
local Types          = require(Shared.Types)

local DataController = {}

-- Local cache
local _data: Types.PlayerData? = nil

-- Simple signal: list of callbacks
type Callback = (key: string, value: any) -> ()
local _callbacks: { Callback } = {}

-- ============================================================
-- PUBLIC API
-- ============================================================

-- Lấy toàn bộ data (read-only trên client)
function DataController.GetData(): Types.PlayerData?
	return _data
end

-- Lấy 1 field cụ thể
function DataController.Get(key: string): any
	if not _data then return nil end
	return (_data :: any)[key]
end

-- Subscribe vào khi data thay đổi
function DataController.OnDataChanged(cb: Callback)
	table.insert(_callbacks, cb)
end

-- ============================================================
-- RECEIVE FROM SERVER
-- ============================================================

-- Full data load (lần đầu join)
Remotes.Events.PlayerDataLoaded.OnClientEvent:Connect(function(...)
	local args = { ... }
	local rawData = args[1]
	if type(rawData) == "table" then
		_data = rawData :: Types.PlayerData
		-- Notify tất cả subscribers (full reload)
		for _, cb in ipairs(_callbacks) do
			cb("__all__", _data)
		end
	end
end)

-- Partial update (1 field thay đổi)
Remotes.Events.PlayerDataUpdated.OnClientEvent:Connect(function(...)
	local args = { ... }
	local key   = args[1]
	local value = args[2]
	if not _data then return end
	if type(key) ~= "string" then return end

	local data_any = _data :: any
	data_any[key] = value

	-- Notify subscribers
	for _, cb in ipairs(_callbacks) do
		cb(key, value)
	end
end)

return DataController
