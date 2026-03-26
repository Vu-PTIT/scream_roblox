--!strict
-- PetService.luau
-- Server-side: Gacha pet system (mở trứng, equip/unequip pet)

local _Players = game:GetService("Players")
local Shared  = game.ReplicatedStorage.Shared
local Config  = require(Shared.Config)
local Types   = require(Shared.Types)
local Remotes = require(Shared.Remotes)

local DataService: any = nil
task.defer(function()
	DataService = require(script.Parent.DataService)
end)

local PetService = {}

-- Theo dõi model pet vật lý của từng người chơi
local PhysicalPets: { [Player]: { [string]: Model } } = {}

-- Build weighted rarity pool để gacha
local RarityPool: { Types.PetRarity } = {}
for rarity, weight in pairs(Config.PetGachaWeights) do
	for _ = 1, weight do
		table.insert(RarityPool, rarity :: Types.PetRarity)
	end
end

-- Build: rarity → list of PetConfig
local PetsByRarity: { [Types.PetRarity]: { Types.PetConfig } } = {
	Common = {}, Uncommon = {}, Rare = {}, Epic = {}, Legendary = {}
}
for _, cfg in ipairs(Config.Pets) do
	table.insert(PetsByRarity[cfg.Rarity], cfg)
end

-- Roll 1 con pet
local function rollPet(): Types.PetData
	-- Pick rarity
	local rarityRoll = RarityPool[math.random(1, #RarityPool)]

	-- Pick pet trong rarity đó
	local pool = PetsByRarity[rarityRoll :: Types.PetRarity]
	local petCfg = pool[math.random(1, #pool)]

	local pet: Types.PetData = {
		Id         = tostring(math.random(100000, 999999)) .. "_" .. os.time(),
		PetType    = petCfg.PetType,
		Rarity     = rarityRoll :: Types.PetRarity,
		Multiplier = petCfg.Multiplier,
		Equipped   = false,
	}
	return pet
end

-- ============================================================
-- MỞ TRỨNG
-- ============================================================
local function onOpenEgg(player: Player, quantity: number)
	if not DataService then return end
	quantity = math.clamp(math.floor(quantity), 1, 10)

	local data = DataService.GetData(player) :: Types.PlayerData?
	if not data then return end

	local totalCost = Config.EggCostGold * quantity
	if data.Gold < totalCost then
		Remotes.Events.Notification:FireClient(player, string.format(Config.Localization.Notifications.NotEnoughGold, totalCost, quantity))
		return
	end

	-- Trừ tiền
	DataService.UpdateField(player, "Gold", data.Gold - totalCost)

	-- Roll pets
	local newPets: { Types.PetData } = {}
	for _ = 1, quantity do
		table.insert(newPets, rollPet())
	end

	-- Thêm vào data (cần load lại sau khi update Gold)
	local freshData = DataService.GetData(player) :: Types.PlayerData?
	if freshData then
		for _, pet in ipairs(newPets) do
			table.insert(freshData.Pets, pet)
		end
		DataService.UpdateField(player, "Pets", freshData.Pets)
	end

	-- Gửi kết quả về client để animation
	Remotes.Events.EggOpenResult:FireClient(player, newPets :: any)

	local rarityNames = {}
	for _, p in ipairs(newPets) do
		table.insert(rarityNames, p.Rarity .. " " .. p.PetType)
	end
	Remotes.Events.Notification:FireClient(player, string.format(Config.Localization.Notifications.GetPets, table.concat(rarityNames, ", ")))
end
PetService.OnOpenEgg = onOpenEgg

-- ============================================================
-- EQUIP / UNEQUIP PET
-- ============================================================
local MAX_EQUIPPED = 3

local function onSetPetEquipped(player: Player, petId: string, equipped: boolean)
	if not DataService then return end
	local data = DataService.GetData(player) :: Types.PlayerData?
	if not data then return end

	-- Tìm pet
	local targetPet: Types.PetData? = nil
	for _, pet in ipairs(data.Pets) do
		if pet.Id == petId then
			targetPet = pet
			break
		end
	end

	if not targetPet then
		Remotes.Events.Notification:FireClient(player, Config.Localization.Notifications.PetNotFound)
		return
	end

	if equipped then
		-- Đếm số đang equip
		local equippedCount = 0
		for _, pet in ipairs(data.Pets) do
			if pet.Equipped then equippedCount += 1 end
		end
		if equippedCount >= MAX_EQUIPPED then
			Remotes.Events.Notification:FireClient(player, string.format(Config.Localization.Notifications.MaxPetsEquipped, MAX_EQUIPPED))
			return
		end
		targetPet.Equipped = true
	else
		targetPet.Equipped = false
	end

	-- Rebuild EquippedPetIds
	local equippedIds: { string } = {}
	for _, pet in ipairs(data.Pets) do
		if pet.Equipped then
			table.insert(equippedIds, pet.Id)
		end
	end

	DataService.UpdateFields(player, {
		Pets            = data.Pets,
		EquippedPetIds  = equippedIds,
	})

	-- Cập nhật Model 3D ngoài thế giới
	PetService.UpdatePhysicalPets(player)
end

-- ============================================================
-- PHYSICAL PETS LOGIC (Hiển thị 3D)
-- ============================================================
function PetService.UpdatePhysicalPets(player: Player)
	if not DataService then return end
	local data = DataService.GetData(player) :: Types.PlayerData?
	if not data then return end

	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart
	if not hrp then return end

	-- Map các pet đang equip
	local equippedDict = {}
	for _, pet in ipairs(data.Pets) do
		if pet.Equipped then
			equippedDict[pet.Id] = pet
		end
	end

	local playerPets = PhysicalPets[player] :: { [string]: Model }
	if not playerPets then 
		playerPets = {}
		PhysicalPets[player] = playerPets
	end

	-- 1. Xóa model của pet không còn được equip
	for petId, model in pairs(playerPets) do
		if not equippedDict[petId] then
			model:Destroy()
			playerPets[petId] = nil
		end
	end

	-- 2. Tạo model cho mớ equip mới
	local currentCount = 0
	for petId, pet in pairs(equippedDict) do
		currentCount += 1
		if not playerPets[petId] then
			local model = Instance.new("Model")
			model.Name = pet.PetType

			local mainPart = Instance.new("Part")
			mainPart.Size = Vector3.new(1.2, 1.2, 1.2)
			mainPart.Shape = Enum.PartType.Ball
			mainPart.CanCollide = false
			mainPart.Massless = true

			-- Trang trí theo Rarity
			if pet.Rarity == "Common" then
				mainPart.Color = Color3.fromRGB(200, 200, 200)
				mainPart.Material = Enum.Material.Plastic
			elseif pet.Rarity == "Uncommon" then
				mainPart.Color = Color3.fromRGB(100, 255, 100)
				mainPart.Material = Enum.Material.Neon
			elseif pet.Rarity == "Rare" then
				mainPart.Color = Color3.fromRGB(100, 150, 255)
				mainPart.Material = Enum.Material.Neon
			elseif pet.Rarity == "Epic" then
				mainPart.Color = Color3.fromRGB(200, 50, 255)
				mainPart.Material = Enum.Material.Neon
			elseif pet.Rarity == "Legendary" then
				mainPart.Color = Color3.fromRGB(255, 200, 50)
				mainPart.Material = Enum.Material.Neon
			end

			local attPet = Instance.new("Attachment", mainPart)
			mainPart.Parent = model
			model.PrimaryPart = mainPart

			-- Attachment trên HumanoidRootPart
			local attCharName = "PetAtt_" .. petId
			local existingAtt = hrp:FindFirstChild(attCharName)
			local finalAtt: Attachment
			
			if existingAtt and existingAtt:IsA("Attachment") then
				finalAtt = existingAtt
			else
				local newAtt = Instance.new("Attachment")
				newAtt.Name = attCharName
				newAtt.Parent = hrp
				
				-- Vị trí bám theo: Tùy theo số thứ tự (Xếp vòng cung sau lưng)
				local angle = (currentCount - 2) * 45 -- -45, 0, 45 độ
				local rad = math.rad(angle)
				newAtt.Position = Vector3.new(math.sin(rad) * 4, 3, math.cos(rad) * 4 + 2)
				finalAtt = newAtt
			end

			-- BodyMovers để pet bay lơ lửng bám theo
			local alignPos = Instance.new("AlignPosition")
			alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
			alignPos.MaxForce = math.huge
			alignPos.Responsiveness = 40
			alignPos.Attachment0 = attPet
			alignPos.Attachment1 = finalAtt
			alignPos.Parent = mainPart

			local alignOri = Instance.new("AlignOrientation")
			alignOri.Mode = Enum.OrientationAlignmentMode.TwoAttachment
			alignOri.MaxTorque = math.huge
			alignOri.Responsiveness = 40
			alignOri.Attachment0 = attPet
			alignOri.Attachment1 = finalAtt
			alignOri.Parent = mainPart

			model.Parent = workspace
			playerPets[petId] = model
		end
	end
end

-- Dọn dẹp pet khi player rời khỏi
local function cleanupPets(player: Player)
	if PhysicalPets[player] then
		for _, model in pairs(PhysicalPets[player]) do
			model:Destroy()
		end
		PhysicalPets[player] = nil
	end
end

-- ============================================================
-- BIND REMOTES
-- ============================================================
Remotes.Events.OpenEgg.OnServerEvent:Connect(function(player: Player, ...)
	local args = { ... }
	local qty = args[1]
	if type(qty) == "number" then
		onOpenEgg(player, qty)
	end
end)

Remotes.Events.SetPetEquipped.OnServerEvent:Connect(function(player: Player, ...)
	local args = { ... }
	local petId   = args[1]
	local equip   = args[2]
	if type(petId) == "string" and type(equip) == "boolean" then
		onSetPetEquipped(player, petId, equip)
	end
end)

_Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(char)
		if not player:GetAttribute("PlayerDataLoaded") then
			player:GetAttributeChangedSignal("PlayerDataLoaded"):Wait()
		end
		char:WaitForChild("HumanoidRootPart", 5)
		if char and player.Parent then
			PetService.UpdatePhysicalPets(player)
		end
	end)
end)

_Players.PlayerRemoving:Connect(cleanupPets)

return PetService
