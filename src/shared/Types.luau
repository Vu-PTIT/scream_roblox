--!strict
-- Types.luau
-- Định nghĩa tập trung tất cả kiểu dữ liệu cho Shout Simulator

export type PetRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"
export type ShoutType = "Normal" | "Circular" | "Focused"
export type SkillRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"


export type PetData = {
	Id: string,           -- Unique ID của pet instance
	PetType: string,      -- Tên loại pet (VD: "SoundDragon")
	Rarity: PetRarity,
	Multiplier: number,   -- Hệ số cày cuốc (VD: 1.2 = +20%)
	Equipped: boolean,
}

export type SkillData = {
	Id: string,
	SkillType: string,
	Rarity: SkillRarity,
	DamageMult: number,
	Cooldown: number,
	Equipped: boolean,
	SlotIndex: number?,   -- 1 hoặc 2
}

export type UpgradeLevel = {
	Level: number,
	StatBonus: number,    -- Giá trị stat thêm vào
}

-- Dữ liệu lưu trữ cho mỗi người chơi
export type PlayerData = {
	-- Tiến trình
	VocalPoints: number,      -- Điểm Thanh Quản (tiền dùng để nâng cấp)
	TotalVocalPoints: number, -- Tổng điểm Thanh Quản (dùng để tính tiến trình Rebirth)
	Gold: number,             -- Tiền thưởng từ quái/arena
	Cups: number,             -- Cúp từ đấu trường PvP

	-- Stats
	Attack: number,           -- Lực đẩy khi hét (base)
	Defense: number,          -- Độ chịu đựng (giảm knockback nhận)
	MaxHealth: number,        -- Máu tối đa

	-- Rebirth
	RebirthCount: number,
	RebirthMultiplier: number, -- Hệ số nhân tổng (áp dụng vào VocalPoints gain)

	-- Upgrades (level đã mua)
	DamageUpgradeLevel: number,   -- Cấp Sát thương (Microphone/Speaker)
	HealthUpgradeLevel: number,   -- Cấp Máu (Tai nghe)
	ArmorUpgradeLevel: number,    -- Cấp Giáp (Giảm văng)

	-- Pets
	Pets: { PetData },
	EquippedPetIds: { string },   -- Tối đa 3

	-- Customization
	CustomShoutText: string,      -- Câu hét cá nhân (đã qua filter)

	-- Skills (thay thế cho CurrentShoutType)
	Skills: { SkillData },
	EquippedSkillIds: { string }, -- Tối đa 2 (2 slot)


	-- Meta
	PlayTime: number,
	JoinDate: number,             -- os.time() lần đầu chơi
	
	-- Feature Base Data (Codes, Quests, Playtime)
	RedeemedCodes: { [string]: boolean },
	Quests: { [string]: number },
	ClaimedQuests: { [string]: boolean },
	QuestResetDate: string,
	ClaimedPlaytimeRewards: { [string]: boolean },
}

-- Config cho từng loại upgrade (dùng trong Config.luau)
export type UpgradeConfig = {
	Id: string,
	DisplayName: string,
	Category: "Attack" | "Defense",
	BaseCost: number,
	CostScaling: number,  -- Cost *= CostScaling mỗi level
	StatPerLevel: number,
	MaxLevel: number,
	Icon: string,         -- rbxassetid
}

-- Config cho từng loại quái vật
export type MonsterConfig = {
	Id: string,
	DisplayName: string,
	MaxHP: number,
	Attack: number,
	Defense: number,
	MovementSpeed: number,
	GoldDrop: number,
	EggDropChance: number,  -- 0.0 → 1.0
	KnockbackResistance: number, -- 0.0 (max far) -> 1.0 (no move)
	SpawnZone: string,      -- Tên khu vực ("PvEZone1", ...)
	IsBoss: boolean?,       -- (Nâng cao) Có phải boss không?
}


-- Config pet template
export type PetConfig = {
	PetType: string,
	DisplayName: string,
	Rarity: PetRarity,
	Multiplier: number,
	ModelId: string,  -- rbxassetid
}

-- Config skill template
export type SkillConfig = {
	SkillType: string,
	DisplayName: string,
	Rarity: SkillRarity,
	ShoutTypeId: string, -- "Normal" | "Circular" | "Focused"
	DamageMult: number,
	Cooldown: number,
	Icon: string,
	Description: string,
	IsBasic: boolean?,
}

-- Shout request từ client lên server
export type ShoutRequest = {
	Direction: Vector3,
	OriginCFrame: CFrame,
}

-- Knockback event data broadcast từ server xuống clients
export type KnockbackEvent = {
	TargetUserId: number,
	Force: Vector3,
	AttackerUserId: number,
}

export type ThemeConfig = {
	Background: Color3,
	SecondaryBackground: Color3,
	Transparency: number,
	CornerRadius: UDim,
	StrokeThickness: number,
	StrokeColor: Color3,
	PrimaryGradient: { Color3 },
	SecondaryGradient: { Color3 },
	SuccessGradient: { Color3 },
	RebirthGradient: { Color3 },
	TextMain: Color3,
	TextSecondary: Color3,
	TextMuted: Color3,
}

return {}
