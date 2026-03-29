--!strict
-- SkillService.luau
-- Server-side: Skill Gacha & Equip system 

local _Players = game:GetService("Players")
local Shared  = game.ReplicatedStorage.Shared
local Config  = require(Shared.Config)
local Types   = require(Shared.Types)
local Remotes = require(Shared.Remotes)

local DataService: any = nil
task.defer(function()
	DataService = require(script.Parent.DataService)
end)

local SkillService = {}

-- Build weighted rarity pool for gacha
local RarityPool: { Types.SkillRarity } = {}
for rarity, weight in pairs(Config.SkillGachaWeights) do
	for _ = 1, weight do
		table.insert(RarityPool, rarity :: Types.SkillRarity)
	end
end

local SkillsByRarity: { [Types.SkillRarity]: { Types.SkillConfig } } = {
	Common = {}, Rare = {}, Epic = {}, Legendary = {}
}

for _, cfg in ipairs(Config.Skills) do
	if not cfg.IsBasic then
		table.insert(SkillsByRarity[cfg.Rarity], cfg)
	end
end

local function rollSkill(): Types.SkillData
	local rarityRoll = RarityPool[math.random(1, #RarityPool)]
	local pool = SkillsByRarity[rarityRoll :: Types.SkillRarity]
	local skillCfg = pool[math.random(1, #pool)]

	local skill: Types.SkillData = {
		Id         = tostring(math.random(100000, 999999)) .. "_s_" .. os.time(),
		SkillType  = skillCfg.SkillType,
		Rarity     = rarityRoll :: Types.SkillRarity,
		DamageMult = skillCfg.DamageMult,
		Cooldown   = skillCfg.Cooldown,
		Equipped   = false,
		SlotIndex  = nil,
	}
	return skill
end

local function onOpenSkillScroll(player: Player, quantity: number)
	if not DataService then return end
	quantity = math.clamp(math.floor(quantity), 1, 10)

	local data = DataService.GetData(player) :: Types.PlayerData?
	if not data then return end

	local totalCost = Config.SkillScrollCost * quantity
	if data.Gold < totalCost then
		Remotes.Events.Notification:FireClient(player, string.format(Config.Localization.Notifications.NotEnoughGold, totalCost, quantity))
		return
	end

	DataService.UpdateField(player, "Gold", data.Gold - totalCost)

	local newSkills: { Types.SkillData } = {}
	for _ = 1, quantity do
		table.insert(newSkills, rollSkill())
	end

	local freshData = DataService.GetData(player) :: Types.PlayerData?
	if freshData then
		for _, skill in ipairs(newSkills) do
			table.insert(freshData.Skills, skill)
		end
		DataService.UpdateField(player, "Skills", freshData.Skills)
	end

	Remotes.Events.SkillScrollResult:FireClient(player, newSkills :: any)

	local rarityNames = {}
	for _, s in ipairs(newSkills) do
		local cfgName = s.SkillType
		for _, cfg in ipairs(Config.Skills) do
			if cfg.SkillType == s.SkillType then
				cfgName = cfg.DisplayName
				break
			end
		end
		table.insert(rarityNames, s.Rarity .. " " .. cfgName)
	end
	Remotes.Events.Notification:FireClient(player, string.format(Config.Localization.Notifications.GetSkills, table.concat(rarityNames, ", ")))
end

local MAX_SKILL_SLOTS = 5

local function onSetSkillEquipped(player: Player, skillId: string, equipped: boolean, slotIndex: number?)
	if not DataService then return end
	local data = DataService.GetData(player) :: Types.PlayerData?
	if not data then return end

	local targetSkill: Types.SkillData? = nil
	for _, skill in ipairs(data.Skills) do
		if skill.Id == skillId then
			targetSkill = skill
			break
		end
	end

	if not targetSkill then
		Remotes.Events.Notification:FireClient(player, Config.Localization.Notifications.SkillNotFound)
		return
	end

	if equipped then
		local sIndex = slotIndex or 1
		sIndex = math.clamp(math.floor(sIndex), 1, MAX_SKILL_SLOTS)

		-- Find if another skill is already equipped in this slot and unequip it
		for _, skill in ipairs(data.Skills) do
			if skill.Equipped and skill.SlotIndex == sIndex then
				skill.Equipped = false
				skill.SlotIndex = nil
			end
		end

		targetSkill.Equipped = true
		targetSkill.SlotIndex = sIndex
	else
		targetSkill.Equipped = false
		targetSkill.SlotIndex = nil
	end

	-- Rebuild EquippedSkillIds (Using fixed slots to avoid sparse arrays in DataStore)
	local equippedIds: { string } = { "", "", "", "", "" }
	for _, skill in ipairs(data.Skills) do
		if skill.Equipped and skill.SlotIndex then
			equippedIds[skill.SlotIndex] = skill.Id
		end
	end

	DataService.UpdateFields(player, {
		Skills           = data.Skills,
		EquippedSkillIds = equippedIds,
	})
end

local function onSellSkill(player: Player, skillId: string)
	if not DataService then return end
	local data = DataService.GetData(player) :: Types.PlayerData?
	if not data then return end

	local targetSkill: Types.SkillData? = nil
	local targetIndex: number? = nil
	for i, skill in ipairs(data.Skills) do
		if skill.Id == skillId then
			targetSkill = skill
			targetIndex = i
			break
		end
	end

	if not targetSkill or not targetIndex then
		Remotes.Events.Notification:FireClient(player, Config.Localization.Notifications.SkillNotFound)
		return
	end

	if targetSkill.Equipped then
		Remotes.Events.Notification:FireClient(player, Config.Localization.Notifications.SellSkillEquipped)
		return
	end

	local sellPrice = Config.SkillSellPrices[targetSkill.Rarity] or 50
	
	table.remove(data.Skills, targetIndex)
	
	DataService.UpdateFields(player, {
		Skills = data.Skills,
		Gold = data.Gold + sellPrice
	})
	
	local cfgName = targetSkill.SkillType
	for _, cfg in ipairs(Config.Skills) do
		if cfg.SkillType == targetSkill.SkillType then
			cfgName = cfg.DisplayName
			break
		end
	end
	
	local popupName = targetSkill.Rarity .. " " .. cfgName
	Remotes.Events.Notification:FireClient(player, string.format(Config.Localization.Notifications.SellSkill, popupName, sellPrice))
end

Remotes.Events.OpenSkillScroll.OnServerEvent:Connect(function(player: Player, ...)
	local args = { ... }
	local qty = args[1]
	if type(qty) == "number" then
		onOpenSkillScroll(player, qty)
	end
end)

Remotes.Events.SetSkillEquipped.OnServerEvent:Connect(function(player: Player, ...)
	local args = { ... }
	local skillId = args[1]
	local equip   = args[2]
	local slot    = args[3]
	if type(skillId) == "string" and type(equip) == "boolean" then
		onSetSkillEquipped(player, skillId, equip, type(slot) == "number" and slot or nil)
	end
end)

Remotes.Events.SellSkill.OnServerEvent:Connect(function(player: Player, ...)
	local args = { ... }
	local skillId = args[1]
	if type(skillId) == "string" then
		onSellSkill(player, skillId)
	end
end)

return SkillService
