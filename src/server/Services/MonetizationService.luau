--!strict
-- MonetizationService.luau
-- Quản lý xác nhận mua Gamepass, Developer Products (Nhân x2, Mua Vàng...).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)

local MonetizationService = {}

-- Cấu hình IDs: Điền ID sản phẩm thực tế từ trang cài đặt Monetization của Roblox
local GamepassIDs = {
	AutoTrain = 12345678,
	VIP = 87654321,
}

local DevProductIDs = {
	BuyGold_1000 = 10000001,
	BuyGold_5000 = 10000002,
}

function MonetizationService.Initialize()
	-- Event callback toàn cầu của Server khi người chơi Mua Product
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local playerId = receiptInfo.PlayerId
		local productId = receiptInfo.ProductId
		local player = Players:GetPlayerByUserId(playerId)
		
		if not player then
			-- Chờ khi nào player rejoin thì trả sau
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		
		local success = MonetizationService.HandleDevProductPurchase(player, productId)
		
		if success then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
	
	print("[MonetizationService] Listening for Market transactions.")
end

-- Logic thanh toán và cồng đồ
function MonetizationService.HandleDevProductPurchase(player: Player, productId: number): boolean
	local data = DataService.GetData(player)
	if not data then return false end
	
	-- Kiểm tra ID
	if productId == DevProductIDs.BuyGold_1000 then
		DataService.UpdateField(player, "Gold", data.Gold + 1000)
		return true
	elseif productId == DevProductIDs.BuyGold_5000 then
		DataService.UpdateField(player, "Gold", data.Gold + 5000)
		return true
	end
	
	return false -- Không nhận diện được product
end

-- Kiểm tra xem người chơi có sỡ hữu Gamepass (cần dùng để buff multipliers)
function MonetizationService.UserOwnsGamepass(player: Player, passName: string): boolean
	local passId = GamepassIDs[passName]
	if not passId then return false end
	
	-- Lưu ý: Để tối ưu network, API thường được cache trên server.
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	
	return success and hasPass
end

return MonetizationService
