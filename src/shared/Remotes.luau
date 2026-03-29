--!strict
-- Remotes.luau
-- Định nghĩa tập trung tất cả RemoteEvents và RemoteFunctions
-- Cả Server và Client đều require module này để tránh magic strings

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Tạo folder chứa Remotes nếu chưa có
local function getOrCreate(parent: Instance, className: string, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing then return existing end
	local obj = Instance.new(className)
	obj.Name = name
	obj.Parent = parent
	return obj
end

local RemoteFolder = getOrCreate(ReplicatedStorage, "Folder", "Remotes") :: Folder

-- ============================================================
-- HELPER: Tạo Remote Events & Functions
-- ============================================================
local function Event(name: string): RemoteEvent
	return getOrCreate(RemoteFolder, "RemoteEvent", name) :: RemoteEvent
end

local function _Func(name: string): RemoteFunction
	return getOrCreate(RemoteFolder, "RemoteFunction", name) :: RemoteFunction
end

-- ============================================================
-- REMOTE EVENTS (Fire & Forget)
-- ============================================================
local Remotes = {

	-- [Client → Server] Người chơi kích hoạt tiếng hét
	-- Payload: direction: Vector3
	ShoutFired = Event("ShoutFired"),

	-- [Server → All Clients] Broadcast knockback để client render VFX
	-- Payload: targetUserId: number, force: Vector3, attackerUserId: number
	KnockbackOccurred = Event("KnockbackOccurred"),

	-- [Server → Client] Server gửi full PlayerData xuống client sau khi load xong
	-- Payload: data: PlayerData (serialized as table)
	PlayerDataLoaded = Event("PlayerDataLoaded"),

	-- [Server → Client] Khi data thay đổi (mua upgrade, nhận vocalpoints...)
	-- Payload: key: string, value: any  (partial update)
	PlayerDataUpdated = Event("PlayerDataUpdated"),

	-- [Client → Server] Yêu cầu mua upgrade
	-- Payload: upgradeId: string
	PurchaseUpgrade = Event("PurchaseUpgrade"),

	-- [Client → Server] Yêu cầu mở trứng pet
	-- Payload: quantity: number (1 hoặc 10)
	OpenEgg = Event("OpenEgg"),

	-- [Server → Client] Kết quả gacha trả về client để hiển thị animation
	-- Payload: pets: { PetData }
	EggOpenResult = Event("EggOpenResult"),
	
	-- [Client → Server] Bán pet thừa lấy vàng
	-- Payload: petId: string
	SellPet = Event("SellPet"),

	-- [Client → Server] Yêu cầu mở cuộn skill
	-- Payload: quantity: number (1 hoặc 10)
	OpenSkillScroll = Event("OpenSkillScroll"),

	-- [Server → Client] Kết quả gacha skill
	-- Payload: skills: { SkillData }
	SkillScrollResult = Event("SkillScrollResult"),

	-- [Client → Server] Bán skill thừa lấy vàng
	-- Payload: skillId: string
	SellSkill = Event("SellSkill"),

	MonsterShoutVFX = Event("MonsterShoutVFX"),

	-- [Client → Server] Equip/Unequip pet
	-- Payload: petId: string, equipped: boolean
	SetPetEquipped = Event("SetPetEquipped"),

	-- [Client → Server] Equip/Unequip skill
	-- Payload: skillId: string, equipped: boolean, slotIndex: number?
	SetSkillEquipped = Event("SetSkillEquipped"),

	-- [Client → Server] Yêu cầu Rebirth
	RebirthRequest = Event("RebirthRequest"),

	-- [Server → Client] Kết quả rebirth (thành công / thất bại)
	-- Payload: success: boolean, newMultiplier: number
	RebirthResult = Event("RebirthResult"),

	-- [Client → Server] Người chơi muốn đổi câu hét cá nhân
	-- Payload: text: string (sẽ bị filter server-side)
	SetCustomShout = Event("SetCustomShout"),

	-- [Server → All nearby Clients] Hiển thị câu hét cá nhân trên BillboardGui
	-- Payload: userId: number, filteredText: string
	DisplayCustomShout = Event("DisplayCustomShout"),

	-- [Client → Server] Thay đổi loại tiếng hét hiện tại
	-- Payload: shoutType: string ("Normal", "Circular", "Focused")
	SetShoutType = Event("SetShoutType"),

	-- [Server → Client] Thông báo lỗi/warning (VD không đủ tiền)
	-- Payload: message: string

	Notification = Event("Notification"),
	
	-- [Client → Server] Yêu cầu đổi mã thưởng Promo/Twitter
	-- Payload: code: string
	RedeemCode = Event("RedeemCode"),
	
	-- [Client → Server] Yêu cầu nhận phần thưởng Playtime
	-- Payload: milestoneIndex: number
	ClaimPlaytimeReward = Event("ClaimPlaytimeReward"),
	
	-- [Client → Server] Yêu cầu nhận phần thưởng Quest
	-- Payload: questId: string
	ClaimQuestReward = Event("ClaimQuestReward"),

	-- [Shared] Refx VFX System
	RefxSignal = Event("RefxSignal"),

	-- [Client → Server] Mua hiệu ứng di chuyển (Dash/Jump)
	-- Payload: effectId: string
	BuyMovementEffect = Event("BuyMovementEffect"),

	-- [Client → Server] Trang bị hiệu ứng di chuyển
	-- Payload: effectId: string, moveType: "Dash" | "Jump"
	SetMovementEffect = Event("SetMovementEffect"),
}

-- ============================================================
-- REMOTE FUNCTIONS (Request & Response)
-- ============================================================
local RemoteFunctions = {
	-- Không dùng RemoteFunction nhiều để tránh exploit timeout.
	-- Mọi "query" nên được push qua Events.
}

return {
	Events    = Remotes,
	Functions = RemoteFunctions,
}
