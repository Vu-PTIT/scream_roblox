--!strict
-- CodeService.luau
-- Hệ thống nhập Code thưởng (Twitter Codes) dành cho người chơi.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.DataService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CodeService = {}

-- Cấu hình danh sách Code có sẵn trong game
local ActiveCodes = {
	["RELEASE"] = {
		RewardType = "Gold",
		Amount = 500,
	},
	["SHOUT2026"] = {
		RewardType = "VocalPoints",
		Amount = 1000,
	},
}

function CodeService.Initialize()
	local count = 0
	for _ in pairs(ActiveCodes) do count += 1 end
	
	Remotes.Events.RedeemCode.OnServerEvent:Connect(function(player, code)
		if type(code) == "string" then
			CodeService.RedeemCode(player, code)
		end
	end)
	
	print("[CodeService] Initialized with", count, "active codes.")
end

-- Hàm xử lý logic nhận Code
function CodeService.RedeemCode(player: Player, code: string): boolean
	local codeKey = string.upper(code)
	local codeConfig = ActiveCodes[codeKey]
	
	if not codeConfig then
		Remotes.Events.Notification:FireClient(player, "Code không hợp lệ hoặc đã hết hạn!")
		return false
	end
	
	local data = DataService.GetData(player)
	if not data then return false end
	
	-- Xác minh xem code này đã dùng chưa
	if not data.RedeemedCodes then data.RedeemedCodes = {} end
	if data.RedeemedCodes[codeKey] then
		Remotes.Events.Notification:FireClient(player, "Bạn đã sử dụng Code này rồi!")
		return false
	end
	
	-- Đánh dấu đã dùng
	data.RedeemedCodes[codeKey] = true
	
	-- Trả phần thưởng
	if codeConfig.RewardType == "Gold" then
		DataService.UpdateField(player, "Gold", data.Gold + codeConfig.Amount)
	elseif codeConfig.RewardType == "VocalPoints" then
		DataService.UpdateField(player, "VocalPoints", data.VocalPoints + codeConfig.Amount)
	end
	
	Remotes.Events.Notification:FireClient(player, "Đổi Code thành công! Nhận " .. tostring(codeConfig.Amount) .. " " .. codeConfig.RewardType)
	return true
end

return CodeService
