--!strict
-- Config.luau
-- Toàn bộ hằng số và bảng cấu hình gameplay của Shout Simulator
-- Thay đổi tại đây để balance game mà không cần sửa logic

local Types = require(script.Parent.Types)

local Config = {} :: any

-- ============================================================
-- PLAYER DEFAULTS
-- ============================================================
local defaultData: Types.PlayerData = {
	VocalPoints = 0,
	TotalVocalPoints = 0,
	Gold = 0,
	Cups = 0,
	Attack = 10,
	Defense = 10,
	MaxHealth = 100,
	RebirthCount = 0,
	RebirthMultiplier = 1,
	DamageUpgradeLevel = 0,
	HealthUpgradeLevel = 0,
	ArmorUpgradeLevel = 0,
	Pets = {},
	EquippedPetIds = {},
	CustomShoutText = "AAAAHHH!!!",
	PlayTime = 0,
	JoinDate = 0,
	RedeemedCodes = {},
	Quests = {},
	ClaimedQuests = {},
	QuestResetDate = "",
	ClaimedPlaytimeRewards = {},
	Skills = {},
	EquippedSkillIds = {},
	OwnedMovementEffects = { "Default" }, -- Hiệu ứng mặc định luôn có
	EquippedDashEffect = "Default",
	EquippedJumpEffect = "Default",
}
Config.DefaultPlayerData = defaultData

-- ============================================================
-- SHOUT MECHANICS
-- ============================================================
Config.Shout = {
	Cooldown = 0.8, -- giây giữa các lần hét
	BaseDamage = 8, -- (Đã giảm) hệ số nhân sát thương chung (Damage = ATK * Base / DEF)
	BaseForce = 8, -- (Cân bằng với công thức mới)
	KnockbackScaling = 6, -- (Reduced from 15) Cân bằng với công thức mới
	KnockbackRange = 20, -- studs - bán kính cone sóng âm
	VerticalBias = 0.4, -- Tăng một chút để nảy lên rõ nét thay vì trượt ngang
	MaxForce = 150, -- (Reduced from 300) Giới hạn vận tốc để không văng khỏi map
	VocalPointsPerHit = 10,
	VocalPointsPerUse = 4.0,

	-- Hệ thống Gồng lực (Power Charge)
	Charge = {
		MaxTime = 2.0, -- Giây tối đa để đạt max power
		MinTime = 0.3, -- Thời gian tối thiểu để coi là có gồng (dưới mức này là tap)
		Levels = {
			{ Time = 0.0, Mult = 1.0, Color = Color3.fromRGB(255, 255, 255), Name = "Normal" },
			{ Time = 0.6, Mult = 1.8, Color = Color3.fromRGB(100, 200, 255), Name = "Strong" },
			{ Time = 1.2, Mult = 3.5, Color = Color3.fromRGB(255, 200, 50), Name = "Powerful" },
			{ Time = 1.8, Mult = 7.0, Color = Color3.fromRGB(255, 255, 100), Name = "MAX POWER" },
		},
	},

	-- Passive VP (Gain when standing still with pets)
	PassiveVPBase = 2, -- Base VP per second
	PassiveVPInterval = 1.0, -- Seconds between checks
}

Config.ShoutTypes = {
	Normal = {
		Id = "Normal",
		Name = "Normal Shout",
		Range = 25,
		Angle = 55, -- Half angle
		DamageMult = 1.0,
		Cooldown = 0.8,
		Icon = "📢",
	},
	Circular = {
		Id = "Circular",
		Name = "Shockwave",
		Range = 18,
		Angle = 180, -- 360 total
		DamageMult = 0.8,
		Cooldown = 1.5,
		Icon = "🔘",
	},
	Focused = {
		Id = "Focused",
		Name = "Sonic Beam",
		Range = 60,
		Angle = 10, -- Very narrow
		DamageMult = 1.5,
		Cooldown = 2.0,
		Icon = "⚡",
	},
}

-- ============================================================
-- DASH MECHANICS
-- ============================================================
Config.Dash = {
	Cooldown = 2.0, -- thời gian hồi chiêu sau mỗi lần lướt (giây)
	ForceMultiplier = 80, -- Lực đẩy nhân với khối lượng nhân vật để lướt
	Duration = 0.15, -- thời gian duy trì lực lướt (giây)
}

-- ============================================================
-- MAP (Environment)
-- ============================================================
Config.Map = {
	SafeZone = {
		Position = Vector3.new(0, 0, 0),
		Size = Vector3.new(100, 1, 100), -- Diện tích SafeZone 100x100
	},
	PvPArena = {
		Position = Vector3.new(0, 0, 150),
		Size = Vector3.new(200, 1, 200), -- Cực rộng cho đã tay
	},
	PvEZone = {
		Position = Vector3.new(200, 0, 0),
		Size = Vector3.new(150, 1, 150),
	},
	StarterZone = {
		Position = Vector3.new(0, 0, -100), -- Khu riêng cho newbie
		Size = Vector3.new(100, 1, 100),
	},
	BossRoom = {
		Position = Vector3.new(-200, 0, 0),
		Size = Vector3.new(150, 1, 150),
	},
	IceBossRoom = {
		Position = Vector3.new(-400, 0, 0),
		Size = Vector3.new(150, 1, 150),
	},
	SkillStation = {
		Offset = Vector3.new(0, 2, -25), -- Opposite of Rebirth station
		Size = Vector3.new(6, 4, 6),
	},
}

-- ============================================================
-- AUDIO (SFX & BGM)
-- Dùng rbxassetid:// (file ID tham chiếu từ Roblox library) để đảm bảo hoạt động trên Live servers
-- Muốn dùng âm thanh khác: Vào Toolbox → Audio → copy ID → đổi thành rbxassetid://ID
-- ============================================================
Config.Audio = {
	BGM = "rbxassetid://1837618405", -- Action Music
	ShoutSFX = "rbxassetid://138090596", -- Fixed: Valid sound ID for shout (Explosion/Impact)
	DashSFX = "rbxassetid://12222124", -- Swoosh effect
	ImpactSFX = "rbxassetid://134012322", -- Soft impact
	JumpSFX = "rbxassetid://12222225",
	LandSFX = "rbxassetid://12222152",

	-- Gacha / Egg SFX (Real assets)
	EggShakeSFX = "rbxassetid://12222070",
	EggFlashSFX = "rbxassetid://12222132",
	EggHatchNormalSFX = "rbxassetid://12222225",
	EggHatchEpicSFX = "rbxassetid://12222090",
}

-- ============================================================
-- KNOCKBACK FORMULA
-- force = (attacker.Attack * Shout.BaseDamage) / (target.Defense ^ 0.5)
-- Capped tại Shout.MaxForce
-- ============================================================

-- ============================================================
-- UPGRADES
-- ============================================================
local upgradesData: { Types.UpgradeConfig } = {
	{
		Id = "damage_1",
		DisplayName = "Sonic Power",
		Category = "Attack",
		BaseCost = 50,
		CostScaling = 1.3,
		StatPerLevel = 5,
		MaxLevel = 30,
		Icon = "rbxassetid://5905055047",
	},
	{
		Id = "health_1",
		DisplayName = "Vitality Boost",
		Category = "Defense",
		BaseCost = 75,
		CostScaling = 1.3,
		StatPerLevel = 20,
		MaxLevel = 30,
		Icon = "rbxassetid://515329329",
	},
	{
		Id = "armor_1",
		DisplayName = "Knockback Resistance",
		Category = "Defense",
		BaseCost = 80,
		CostScaling = 1.3,
		StatPerLevel = 10,
		MaxLevel = 30,
		Icon = "rbxassetid://2703816766",
	},
}
Config.Upgrades = upgradesData

-- Helper to find upgrade by ID
function Config.GetUpgrade(id: string): Types.UpgradeConfig?
	for _, upgrade in ipairs(Config.Upgrades) do
		if upgrade.Id == id then
			return upgrade
		end
	end
	return nil
end

-- ============================================================
-- REBIRTH
-- ============================================================
Config.Rebirth = {
	VocalPointsRequired = 10000, -- điểm cần thiết để rebirth
	MultiplierPerRebirth = 0.25, -- +25% mỗi lần rebirth (cộng dồn)
	AreaUnlockThresholds = { -- mở khu vực mới khi đạt rebirth count
		[1] = "Desert",
		[3] = "IceZone",
		[7] = "VoidRealm",
		[15] = "HeavenlyStage",
	},
}

-- ============================================================
-- PETS
-- ============================================================
local petsData: { Types.PetConfig } = {
	{
		PetType = "SoundPup",
		DisplayName = "Sound Pup",
		Rarity = "Common",
		Multiplier = 1.05,
		ModelId = "rbxassetid://6031280882",
		Icon = "rbxassetid://5318182907",
	},
	{
		PetType = "EchoFox",
		DisplayName = "Echo Fox",
		Rarity = "Rare",
		Multiplier = 1.12,
		ModelId = "rbxassetid://6031280882",
		Icon = "rbxassetid://5299499872",
	},
	{
		PetType = "SonicCat",
		DisplayName = "Sonic Cat",
		Rarity = "Rare",
		Multiplier = 1.25,
		ModelId = "rbxassetid://6031280882",
		Icon = "rbxassetid://5299499696",
	},
	{
		PetType = "BoomBear",
		DisplayName = "Boom Bear",
		Rarity = "Epic",
		Multiplier = 1.50,
		ModelId = "rbxassetid://6031280882",
		Icon = "rbxassetid://5318182907",
	},
	{
		PetType = "SoundDragon",
		DisplayName = "Sound Dragon",
		Rarity = "Legendary",
		Multiplier = 2.00,
		ModelId = "rbxassetid://6031280882",
		Icon = "rbxassetid://5299499696",
	},
}
Config.Pets = petsData

-- Trọng số gacha (tổng = 100)
local gachaWeights: { [string]: number } = {
	Common = 55,
	Rare = 30,
	Epic = 12,
	Legendary = 3,
}
Config.PetGachaWeights = gachaWeights

Config.EggCostGold = 500 -- chi phí mở 1 trứng

-- Giá bán pet thừa (vàng nhận được khi bán)
-- Legendary = đúng bằng giá mở 1 trứng (500)
Config.PetSellPrices = {
	Common    = 15,   -- 3% giá trứng
	Rare      = 50,   -- 10% giá trứng
	Epic      = 125,  -- 25% giá trứng
	Legendary = 500,  -- 1 lần mở trứng
}

-- ============================================================
-- SKILLS
-- ============================================================
local skillsData: { Types.SkillConfig } = {
	{
		SkillType = "BasicShout",
		DisplayName = "Basic Shout",
		Rarity = "Common",
		ShoutTypeId = "Normal",
		DamageMult = 1.0,
		Cooldown = 0.6,
		Icon = "📢",
		Description = "A standard shout.",
		IsBasic = true,
		EffectColor = Color3.fromRGB(0, 255, 255),
	},
	{
		SkillType = "LoudCry",
		DisplayName = "Loud Cry",
		Rarity = "Common",
		ShoutTypeId = "Circular",
		DamageMult = 0.8,
		Cooldown = 1.2,
		Icon = "🗣️",
		Description = "A weak area attack.",
		EffectColor = Color3.fromRGB(200, 200, 200),
	},

	{
		SkillType = "Shockwave",
		DisplayName = "Shockwave",
		Rarity = "Rare",
		ShoutTypeId = "Circular",
		DamageMult = 0.9,
		Cooldown = 1.2,
		Icon = "🔘",
		Description = "Creates a shockwave.",
		EffectColor = Color3.fromRGB(255, 100, 0),
		EffectSize = 1.2,
	},
	{
		SkillType = "PiercingRoar",
		DisplayName = "Piercing Roar",
		Rarity = "Rare",
		ShoutTypeId = "Focused",
		DamageMult = 1.2,
		Cooldown = 1.8,
		Icon = "🗯️",
		Description = "A focused line attack.",
		EffectColor = Color3.fromRGB(255, 255, 100),
	},

	{
		SkillType = "SonicBeam",
		DisplayName = "Sonic Beam",
		Rarity = "Rare",
		ShoutTypeId = "Focused",
		DamageMult = 1.5,
		Cooldown = 1.8,
		Icon = "⚡",
		Description = "A strong focused beam.",
		EffectColor = Color3.fromRGB(100, 150, 255),
		SecondaryColor = Color3.fromRGB(255, 255, 255),
		EffectSize = 1.5,
		AnimationId = "rbxassetid://507305361",
	},
	{
		SkillType = "EchoBurst",
		DisplayName = "Echo Burst",
		Rarity = "Rare",
		ShoutTypeId = "Circular",
		DamageMult = 1.1,
		Cooldown = 1.0,
		Icon = "💥",
		Description = "Fast shockwave.",
		EffectColor = Color3.fromRGB(255, 50, 255),
	},

	{
		SkillType = "TidalRoar",
		DisplayName = "Tidal Roar",
		Rarity = "Epic",
		ShoutTypeId = "Circular",
		DamageMult = 1.4,
		Cooldown = 1.0,
		Icon = "🌊",
		Description = "Powerful area shout.",
		EffectColor = Color3.fromRGB(0, 100, 255),
		SecondaryColor = Color3.fromRGB(100, 200, 255),
		EffectSize = 1.8,
	},
	{
		SkillType = "BeastHowl",
		DisplayName = "Beast Howl",
		Rarity = "Epic",
		ShoutTypeId = "Normal",
		DamageMult = 1.8,
		Cooldown = 0.7,
		Icon = "🐺",
		Description = "Fierce normal shout.",
		EffectColor = Color3.fromRGB(255, 50, 0),
		EffectSize = 1.5,
	},

	{
		SkillType = "DragonScream",
		DisplayName = "Dragon Scream",
		Rarity = "Legendary",
		ShoutTypeId = "Focused",
		DamageMult = 3.0,
		Cooldown = 2.5,
		Icon = "🐉",
		Description = "Ultimate destruction.",
		EffectColor = Color3.fromRGB(255, 0, 0),
		SecondaryColor = Color3.fromRGB(255, 215, 0),
		EffectSize = 2.5,
		AnimationId = "rbxassetid://507304133",
		ChargingAnimationId = "rbxassetid://507304133",
	},
}
Config.Skills = skillsData

Config.SkillGachaWeights = {
	Common = 55,
	Rare = 28,
	Epic = 12,
	Legendary = 5,
}

Config.SkillScrollCost = 1000 -- chi phí mở 1 cuộn skill

-- Giá bán skill thừa (vàng nhận được khi bán)
-- Legendary = đúng bằng giá mở 1 cuộn skill (SkillScrollCost = 1000)
Config.SkillSellPrices = {
	Common    = 50,   -- 5% giá cuộn
	Rare      = 200,  -- 20% giá cuộn
	Epic      = 500,  -- 50% giá cuộn
	Legendary = 1000, -- = 1 lần mở cuộn (SkillScrollCost)
}

-- ============================================================
-- MOVEMENT EFFECTS (Hiệu ứng Dash & Jump riêng biệt với Skills)
-- Người chơi có thể mua và trang bị cho từng loại di chuyển
-- ============================================================
local movementEffectsData: { any } = {
	-- === MẸU ĐỊN GIẢN (MẶC ĐỊNH - FREE) ===
	{
		Id = "Default",
		DisplayName = "Basic Trail",
		Description = "Hiệu ứng mặc định của tất cả.",
		Icon = "💨",
		Rarity = "Common",
		Cost = 0,
		IsFree = true,
		ApplyTo = "Both", -- "Dash", "Jump", "Both"
		Dash = {
			Color = Color3.fromRGB(200, 200, 255),
			Power = 20,
			EffectSize = 0.8,
			UsesCircular = false,
		},
		Jump = {
			Color = Color3.fromRGB(200, 200, 255),
			Power = 15,
			EffectSize = 0.5,
		},
	},

	-- === Lửa (Common) ===
	{
		Id = "Fire",
		DisplayName = "Inferno Rush",
		Description = "Vệt qua như một ngọn lửa!",
		Icon = "🔥",
		Rarity = "Common",
		Cost = 500,
		ApplyTo = "Both",
		Dash = {
			Color = Color3.fromRGB(255, 120, 20),
			Power = 25,
			EffectSize = 1.0,
			UsesCircular = false,
		},
		Jump = {
			Color = Color3.fromRGB(255, 150, 30),
			Power = 18,
			EffectSize = 0.7,
		},
	},

	-- === Băng (Common) ===
	{
		Id = "Ice",
		DisplayName = "Frost Step",
		Description = "Lạnh giá như băng tờ.",
		Icon = "❄️",
		Rarity = "Common",
		Cost = 500,
		ApplyTo = "Both",
		Dash = {
			Color = Color3.fromRGB(100, 220, 255),
			Power = 22,
			EffectSize = 1.0,
			UsesCircular = false,
		},
		Jump = {
			Color = Color3.fromRGB(150, 230, 255),
			Power = 16,
			EffectSize = 0.7,
		},
	},

	-- === Điện (Rare) ===
	{
		Id = "Thunder",
		DisplayName = "Thunder Dash",
		Description = "Nhanh như tấm sét!",
		Icon = "⚡",
		Rarity = "Rare",
		Cost = 1500,
		ApplyTo = "Both",
		Dash = {
			Color = Color3.fromRGB(255, 255, 50),
			Power = 30,
			EffectSize = 1.2,
			UsesCircular = false,
		},
		Jump = {
			Color = Color3.fromRGB(255, 240, 80),
			Power = 22,
			EffectSize = 0.9,
		},
	},

	-- === Bong bóng nước (Rare) ===
	{
		Id = "Aqua",
		DisplayName = "Aqua Surge",
		Description = "Trào dâng như sóng nước.",
		Icon = "🌊",
		Rarity = "Rare",
		Cost = 1500,
		ApplyTo = "Both",
		Dash = {
			Color = Color3.fromRGB(0, 150, 255),
			Power = 28,
			EffectSize = 1.2,
			UsesCircular = true, -- Dùng dạng Circular VFX
		},
		Jump = {
			Color = Color3.fromRGB(50, 180, 255),
			Power = 20,
			EffectSize = 0.9,
		},
	},

	-- === Đất (Rare) ===
	{
		Id = "Earth",
		DisplayName = "Tremor Stomp",
		Description = "Mỗi nhảy là một trận động đất nhỏ!",
		Icon = "🚧",
		Rarity = "Rare",
		Cost = 3500,
		ApplyTo = "Both",
		Dash = {
			Color = Color3.fromRGB(180, 120, 60),
			Power = 35,
			EffectSize = 1.4,
			UsesCircular = true,
		},
		Jump = {
			Color = Color3.fromRGB(200, 140, 70),
			Power = 25,
			EffectSize = 1.1,
		},
	},

	-- === Rồng (Rare) ===
	{
		Id = "Dragon",
		DisplayName = "Dragon Burst",
		Description = "Rong bay với năng lượng của rồng!",
		Icon = "🐉",
		Rarity = "Rare",
		Cost = 4000,
		ApplyTo = "Both",
		Dash = {
			Color = Color3.fromRGB(255, 80, 0),
			Power = 40,
			EffectSize = 1.5,
			UsesCircular = false,
		},
		Jump = {
			Color = Color3.fromRGB(255, 100, 20),
			Power = 28,
			EffectSize = 1.2,
		},
	},

	-- === Cosmos/Vũ trụ (Epic) ===
	{
		Id = "Cosmic",
		DisplayName = "Cosmic Shift",
		Description = "Vượt qua cả không gian!",
		Icon = "✨",
		Rarity = "Epic",
		Cost = 8000,
		ApplyTo = "Both",
		Dash = {
			Color = Color3.fromRGB(200, 100, 255),
			Power = 50,
			EffectSize = 1.8,
			UsesCircular = true,
		},
		Jump = {
			Color = Color3.fromRGB(220, 130, 255),
			Power = 35,
			EffectSize = 1.4,
		},
	},

	-- === Thần sét Phượng Hoàng (Legendary) ===
	{
		Id = "Phoenix",
		DisplayName = "Phoenix Blaze",
		Description = "Bất diệt như Phượng Hoàng!",
		Icon = "🔴",
		Rarity = "Legendary",
		Cost = 20000,
		ApplyTo = "Both",
		Dash = {
			Color = Color3.fromRGB(255, 200, 50),
			Power = 70,
			EffectSize = 2.0,
			UsesCircular = false,
		},
		Jump = {
			Color = Color3.fromRGB(255, 220, 80),
			Power = 50,
			EffectSize = 1.6,
		},
	},

	-- === Void/Hố đen (Legendary) ===
	{
		Id = "Void",
		DisplayName = "Void Rift",
		Description = "Xé toạc cả vũ trụ khi di chuyển!",
		Icon = "⚫",
		Rarity = "Legendary",
		Cost = 25000,
		ApplyTo = "Both",
		Dash = {
			Color = Color3.fromRGB(80, 0, 160),
			Power = 80,
			EffectSize = 2.2,
			UsesCircular = true,
		},
		Jump = {
			Color = Color3.fromRGB(100, 20, 180),
			Power = 60,
			EffectSize = 1.8,
		},
	},
}
Config.MovementEffects = movementEffectsData

function Config.GetMovementEffect(id: string): any?
	for _, effect in ipairs(Config.MovementEffects) do
		if effect.Id == id then
			return effect
		end
	end
	return nil
end

-- ============================================================
-- MONSTERS
-- ============================================================
-- KnockbackResistance: 0 (bay xa) -> 1 (không bị đẩy)
local monstersData: { Types.MonsterConfig } = {
	-- Starter Zone
	{
		Id = "ScreechSlime",
		DisplayName = "Screech Slime",
		MaxHP = 80,
		Attack = 5,
		Defense = 2,
		KnockbackResistance = 0.1,
		MovementSpeed = 13,
		GoldDrop = 10,
		EggDropChance = 0.03,
		SpawnZone = "StarterZone",
		AggroRange = 25,
	},
	-- PvE Zone
	{
		Id = "BoomGolem",
		DisplayName = "Boom Golem",
		MaxHP = 400,
		Attack = 30,
		Defense = 20,
		KnockbackResistance = 0.5,
		MovementSpeed = 11,
		GoldDrop = 50,
		EggDropChance = 0.15,
		SpawnZone = "PvEZone",
		AggroRange = 28,
	},
	{
		Id = "EchoToad",
		DisplayName = "Echo Toad",
		MaxHP = 150,
		Attack = 15,
		Defense = 8,
		KnockbackResistance = 0.2,
		MovementSpeed = 15,
		GoldDrop = 30,
		EggDropChance = 0.08,
		SpawnZone = "PvEZone",
		AggroRange = 25,
	},
	-- Desert (Rebirth 1)
	{
		Id = "DustDevil",
		DisplayName = "Dust Devil",
		MaxHP = 800,
		Attack = 45,
		Defense = 30,
		KnockbackResistance = 0.3,
		MovementSpeed = 15,
		GoldDrop = 120,
		EggDropChance = 0.20,
		SpawnZone = "Desert",
		AggroRange = 30,
	},
	{
		Id = "SandGolem",
		DisplayName = "Sand Golem",
		MaxHP = 1500,
		Attack = 60,
		Defense = 45,
		KnockbackResistance = 0.6,
		MovementSpeed = 11,
		GoldDrop = 200,
		EggDropChance = 0.30,
		SpawnZone = "Desert",
		AggroRange = 30,
	},
	-- IceZone (Rebirth 3)
	{
		Id = "IcyWraith",
		DisplayName = "Icy Wraith",
		MaxHP = 3000,
		Attack = 90,
		Defense = 70,
		KnockbackResistance = 0.4,
		MovementSpeed = 14,
		GoldDrop = 400,
		EggDropChance = 0.35,
		SpawnZone = "IceZone",
		AggroRange = 35,
	},
	{
		Id = "FrostGiant",
		DisplayName = "Frost Giant",
		MaxHP = 6000,
		Attack = 120,
		Defense = 90,
		KnockbackResistance = 0.7,
		MovementSpeed = 11,
		GoldDrop = 700,
		EggDropChance = 0.45,
		SpawnZone = "IceZone",
		AggroRange = 35,
	},
	-- VoidRealm (Rebirth 7)
	{
		Id = "VoidSerpent",
		DisplayName = "Void Serpent",
		MaxHP = 15000,
		Attack = 200,
		Defense = 150,
		KnockbackResistance = 0.5,
		MovementSpeed = 15,
		GoldDrop = 1500,
		EggDropChance = 0.60,
		SpawnZone = "VoidRealm",
		AggroRange = 40,
	},
	{
		Id = "ShadowBeast",
		DisplayName = "Shadow Beast",
		MaxHP = 30000,
		Attack = 280,
		Defense = 200,
		KnockbackResistance = 0.8,
		MovementSpeed = 13,
		GoldDrop = 2500,
		EggDropChance = 0.70,
		SpawnZone = "VoidRealm",
		AggroRange = 40,
	},
	-- HeavenlyStage (Rebirth 15)
	{
		Id = "DivineGuardian",
		DisplayName = "Divine Guardian",
		MaxHP = 80000,
		Attack = 450,
		Defense = 300,
		KnockbackResistance = 0.9,
		MovementSpeed = 14,
		GoldDrop = 5000,
		EggDropChance = 0.85,
		SpawnZone = "HeavenlyStage",
		AggroRange = 45,
	},
	-- Bosses
	{
		Id = "SoundKing",
		DisplayName = "Sound King",
		MaxHP = 10000,
		Attack = 150,
		Defense = 100,
		KnockbackResistance = 0.85,
		MovementSpeed = 12,
		GoldDrop = 1000,
		EggDropChance = 0.80,
		SpawnZone = "BossRoom",
		IsBoss = true,
		AggroRange = 60,
	},
	{
		Id = "IceColossus",
		DisplayName = "Ice Colossus",
		MaxHP = 50000,
		Attack = 300,
		Defense = 200,
		KnockbackResistance = 0.95,
		MovementSpeed = 11,
		GoldDrop = 3000,
		EggDropChance = 0.90,
		SpawnZone = "IceBossRoom",
		IsBoss = true,
		AggroRange = 100,
	},
}

Config.Monsters = monstersData

Config.MonsterRespawnTime = 8 -- giây

-- ============================================================
-- DATA
-- ============================================================
Config.DataSaveInterval = 60 -- auto-save mỗi 60 giây
Config.DataStoreName = "ShoutSimulatorV1"

-- ============================================================
-- CUSTOM SHOUT
-- ============================================================
Config.CustomShout = {
	MaxLength = 40, -- max characters
	Cooldown = 5, -- seconds between changes
	DisplayDuration = 2.5, -- seconds shown above head
}

-- ============================================================
-- REWARDS
-- ============================================================
Config.Rewards = {
	PlaytimeMilestones = {
		{ Time = 300, Reward = { Type = "Gold", Amount = 100 } }, -- 5 minutes
		{ Time = 900, Reward = { Type = "VocalPoints", Amount = 500 } }, -- 15 minutes
		{ Time = 1800, Reward = { Type = "Gold", Amount = 500 } }, -- 30 minutes
	},
}

-- ============================================================
-- QUESTS & MONETIZATION
-- ============================================================
Config.Quests = {
	{
		Id = "Shout200",
		ActionType = "Shout",
		Required = 200,
		Reward = { Type = "VocalPoints", Amount = 500 },
		Title = "Shout 200 times",
	},
	{
		Id = "Hatch10",
		ActionType = "HatchEgg",
		Required = 10,
		Reward = { Type = "Gold", Amount = 500 },
		Title = "Hatch 10 Eggs",
	},
}

Config.MonetizationProducts = {
	Gamepasses = {
		{ Id = 189283745, Name = "Auto Train", Price = 150, Icon = "rbxassetid://5905055047", Type = "Gamepass" }, 
		{ Id = 271828182, Name = "VIP (x2 Stats)", Price = 399, Icon = "rbxassetid://8050965706", Type = "Gamepass" }, 
	},
	DevProducts = {
		{ Id = 987654321, Name = "+1,000 Gold", Price = 50, Icon = "rbxassetid://2703816766", Type = "DevProduct" }, 
		{ Id = 987654322, Name = "+5,000 Gold", Price = 200, Icon = "rbxassetid://2703816766", Type = "DevProduct" }, 
	},
}

-- ============================================================
-- LOCALIZATION (English)
-- ============================================================
Config.Localization = {
	HUD = {
		VocalPointsTitle = "REBIRTH PROGRESS",
		VocalPointsBalance = "🎙️ VP: %s",
		GoldFormat = "💰 %s Gold",
		RebirthFormat = "⭐ Rebirth: %d (x%.2f)",
		AttackLabel = "⚔️ Damage: %d",
		DefenseLabel = "🛡️ Armor: %d",
		HealthLabel = "❤️ HP: %d",
	},
	Shop = {
		Title = "🛒 UPGRADE SHOP",
		TabAttack = "⚔️ Attack",
		TabDefense = "🛡️ Defense",
		TabPremium = "⭐ Premium",
		LevelFormat = "Level: %d / %d  |  +%d per level",
		CostFormat = "🎙️ Cost: %s VP",
		Buy = "BUY",
		Max = "MAX",
		PriceRobux = "R$ %d",
	},
	Pets = {
		Title = "🐾 PET INVENTORY",
		Equip = "EQUIP",
		Unequip = "UNEQUIP",
		Open1x = "Open 1x (%d 💰)",
		Open10x = "Open 10x (%d 💰)",
		InventoryFull = "Inventory Full!",
	},
	Rebirth = {
		Title = "⭐ REBIRTH",
		Desc = "Confirm Rebirth? You will reset your Vocal Points and Upgrades, but keep your Pets and gain a permanent multiplier!",
		CurrentMult = "Current Multiplier: x%.2f",
		NewMult = "New Multiplier: x%.2f",
		Confirm = "REBIRTH",
		Cancel = "CANCEL",
		NotEnough = "Not enough Vocal Points!",
	},
	CustomShout = {
		Title = "✏️ CUSTOM SHOUT",
		Desc = "Max 40 characters - Auto-filtered",
		Placeholder = "Enter your shout here...",
		Confirm = "CONFIRM",
		Cancel = "CANCEL",
	},
	NavBar = {
		Shop = "🛒 SHOP",
		Pets = "🐾 PETS",
		Rebirth = "⭐ REBIRTH",
		Shout = "✏️ CUSTOM SHOUT",
	},
	CodeUI = {
		Title = "🎁 PROMO CODES",
		Placeholder = "Enter code here...",
		Redeem = "REDEEM",
	},
	RewardUI = {
		Title = "⏱️ PLAYTIME REWARDS",
		Claim = "CLAIM",
		Claimed = "CLAIMED",
		Locked = "LOCKED",
		TimeFormat = "Play %d minutes",
		RewardFormat = "%s %s", -- 100 Gold
	},
	QuestUI = {
		Title = "📜 DAILY QUESTS",
		Progress = "%d / %d",
	},
	Notifications = {
		MonsterKilled = "💀 %s defeated! +%d Gold",
		EggDropped = "🥚 Egg dropped! Opening...",
		NotEnoughGold = "💰 Not enough gold! Need %d Gold for %d items",
		GetPets = "🥚 Received: %s",
		GetSkills = "📜 Received: %s",
		SellSkill = "💰 Sold %s for %d Gold!",
		SellSkillEquipped = "⚠️ Cannot sell equipped skill!",
		SellPet = "💰 Sold %s for %d Gold!",
		SellPetEquipped = "⚠️ Cannot sell equipped pet!",
		PetNotFound = "❌ Pet not found!",
		SkillNotFound = "❌ Skill not found!",
		MaxPetsEquipped = "⚠️ Maximum %d pets equipped!",
		MaxSkillsEquipped = "⚠️ Maximum %d skills equipped!",
		RebirthNeeded = "🔄 Need %d more Vocal Points to Rebirth!",
		RebirthSuccess = "⭐ Rebirth successful! New multiplier: x%.2f",
		UpgradeNotFound = "❌ Upgrade does not exist!",
		MaxLevelReached = "⚠️ Max level reached!",
		NotEnoughGoldUpgrade = "🎙️ Not enough Vocal Points! Need %d VP",
		UpgradeSuccess = "✅ Upgraded %s to Level %d!",
	},
}

-- ============================================================
-- THEME (Solid Dark Mode & Flat 3D)
-- ============================================================
Config.Theme = {
	-- Modern Glassmorphism & HSL Tokens
	Background = Color3.fromRGB(28, 30, 42), -- Slightly lighter
	SecondaryBackground = Color3.fromRGB(35, 38, 55),
	PanelTransparency = 0.15,
	CornerRadius = UDim.new(0, 14),
	StrokeThickness = 2,
	StrokeColor = Color3.fromRGB(70, 75, 110),

	-- Universal Gradients
	PanelGradient = { Color3.fromRGB(40, 42, 60), Color3.fromRGB(25, 27, 40) },
	PrimaryGradient = { Color3.fromRGB(100, 180, 255), Color3.fromRGB(60, 120, 255) },
	SecondaryGradient = { Color3.fromRGB(255, 180, 60), Color3.fromRGB(200, 130, 40) },
	SuccessGradient = { Color3.fromRGB(80, 220, 160), Color3.fromRGB(40, 180, 120) },
	RebirthGradient = { Color3.fromRGB(255, 80, 100), Color3.fromRGB(200, 50, 70) },
	SkillGradient = { Color3.fromRGB(180, 100, 255), Color3.fromRGB(140, 70, 220) },

	-- Button Base Styles (Modernized)
	BtnShopBase = Color3.fromRGB(60, 120, 255), -- #3C78FF
	BtnShopShadow = Color3.fromRGB(40, 80, 200),

	BtnPetsBase = Color3.fromRGB(255, 180, 60), -- #FFB43C
	BtnPetsShadow = Color3.fromRGB(200, 130, 40),

	BtnRebirthBase = Color3.fromRGB(255, 80, 100), -- #FF5064
	BtnRebirthShadow = Color3.fromRGB(200, 50, 70),

	BtnShoutBase = Color3.fromRGB(100, 220, 100), -- #64DC64
	BtnShoutShadow = Color3.fromRGB(70, 180, 70),

	BtnCodeBase = Color3.fromRGB(180, 100, 255),
	BtnCodeShadow = Color3.fromRGB(140, 70, 220),

	BtnRewardBase = Color3.fromRGB(255, 140, 60),
	BtnRewardShadow = Color3.fromRGB(210, 100, 40),

	BtnQuestBase = Color3.fromRGB(60, 210, 160),
	BtnQuestShadow = Color3.fromRGB(40, 160, 120),

	-- Text Colors (Clean & Vibrant)
	TextMain = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(200, 205, 230),
	TextMuted = Color3.fromRGB(120, 125, 155),
	TextGold = Color3.fromRGB(255, 215, 60),
	TextBlue = Color3.fromRGB(100, 180, 255),

	-- Rarity Colors (Modernized Glow)
	RarityColors = {
		Common = Color3.fromRGB(180, 185, 210),
		Rare = Color3.fromRGB(90, 190, 255),
		Epic = Color3.fromRGB(210, 120, 255),
		Legendary = Color3.fromRGB(255, 215, 80),
	},
}

-- ============================================================
-- ANIMATIONS (Goku / Battle Style)
-- Thay đổi ID tại đây để dùng bộ animation khác.
-- Lưu ý: Bạn cần sở hữu các animation này hoặc chúng phải là Public.
-- ============================================================
Config.Animations = {
	Enabled = true, -- Tắt nếu muốn dùng animation mặc định của Roblox

	-- Di chuyển & Trạng thái (Phổ biến: Ninja/Combat style)
	Idle = "rbxassetid://180435571", -- Ninja Combat Idle
	Run = "rbxassetid://180426354", -- Ninja Run
	Dash = "rbxassetid://180426354", -- Reuse Run for Dash or specialized
	Jump = "rbxassetid://125750702",  -- Jump / Leap animation

	-- Chiêu thức (Skills)
	Shout_Normal = "rbxassetid://616168019", -- Roar / Power up
	Shout_Focused = "rbxassetid://616163380", -- Force push / Beam
	Shout_Circular = "rbxassetid://616168019", -- Circular explosion / Power up

	-- Đặc biệt
	Charging = "rbxassetid://616168019", -- Gồng nội công
}

return Config
