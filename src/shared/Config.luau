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
	VocalPoints         = 0,
	TotalVocalPoints    = 0,
	Gold                = 0,
	Cups                = 0,
	Attack              = 10,
	Defense             = 10,
	MaxHealth           = 100,
	RebirthCount        = 0,
	RebirthMultiplier   = 1,
	DamageUpgradeLevel  = 0,
	HealthUpgradeLevel  = 0,
	ArmorUpgradeLevel   = 0,
	Pets                = {},
	EquippedPetIds      = {},
	CustomShoutText     = "AAAAHHH!!!",
	PlayTime            = 0,
	JoinDate            = 0,
	RedeemedCodes       = {},
	Quests              = {},
	ClaimedQuests       = {},
	QuestResetDate      = "",
	ClaimedPlaytimeRewards = {},
	Skills              = {},
	EquippedSkillIds    = {},
}
Config.DefaultPlayerData = defaultData

-- ============================================================
-- SHOUT MECHANICS
-- ============================================================
Config.Shout = {
	Cooldown          = 0.8,   -- giây giữa các lần hét
	BaseDamage        = 8,     -- (Đã giảm) hệ số nhân sát thương chung (Damage = ATK * Base / DEF)
	BaseForce         = 15,    -- (Đã giảm mạnh) lực đẩy cơ bản 
	KnockbackScaling  = 10,    -- (Đã giảm mạnh) hệ số nhân (ATK / DEF) cho lực văng
	KnockbackRange    = 20,    -- studs - bán kính cone sóng âm
	ConeAngle         = 55,    -- độ - góc nửa-cone khi lan sóng
	VerticalBias      = 0.5,   -- tăng một chút để nảy lên rõ nét thay vì trượt ngang
	MaxForce          = 45,    -- (Đã giảm thêm) giới hạn vận tốc tối đa để tránh văng bay màu khỏi màn hình
	VocalPointsPerHit = 5,
	VocalPointsPerUse = 2.0,

	-- Hệ thống Gồng lực (Power Charge)
	Charge = {
		MaxTime = 2.0, -- Giây tối đa để đạt max power
		MinTime = 0.3, -- Thời gian tối thiểu để coi là có gồng (dưới mức này là tap)
		Levels = {
			{ Time = 0.0, Mult = 1.0, Color = Color3.fromRGB(255, 255, 255), Name = "Normal" },
			{ Time = 0.6, Mult = 1.8, Color = Color3.fromRGB(100, 200, 255), Name = "Strong" },
			{ Time = 1.2, Mult = 3.5, Color = Color3.fromRGB(255, 200, 50),  Name = "Powerful" },
			{ Time = 1.8, Mult = 7.0, Color = Color3.fromRGB(255, 255, 100), Name = "MAX POWER" },
		}
	}
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
	}
}

-- ============================================================
-- DASH MECHANICS
-- ============================================================
Config.Dash = {
	Cooldown     = 2.0,   -- thời gian hồi chiêu sau mỗi lần lướt (giây)
	ForceMultiplier = 80, -- Lực đẩy nhân với khối lượng nhân vật để lướt
	Duration     = 0.15,  -- thời gian duy trì lực lướt (giây)
}

-- ============================================================
-- MAP (Environment)
-- ============================================================
Config.Map = {
	SafeZone = {
		Position = Vector3.new(0, 0, 0),
		Size     = Vector3.new(100, 1, 100), -- Diện tích SafeZone 100x100
	},
	PvPArena = {
		Position = Vector3.new(0, 0, 150),
		Size     = Vector3.new(200, 1, 200), -- Cực rộng cho đã tay
	},
	PvEZone = {
		Position = Vector3.new(200, 0, 0),
		Size     = Vector3.new(150, 1, 150),
	},
	StarterZone = {
		Position = Vector3.new(0, 0, -100), -- Khu riêng cho newbie
		Size     = Vector3.new(100, 1, 100),
	},
	BossRoom = {
		Position = Vector3.new(-200, 0, 0),
		Size     = Vector3.new(150, 1, 150),
	},
	IceBossRoom = {
		Position = Vector3.new(-400, 0, 0),
		Size     = Vector3.new(150, 1, 150),
	},
	SkillStation = {
		Offset = Vector3.new(0, 2, -25), -- Opposite of Rebirth station
		Size     = Vector3.new(6, 4, 6),
	}
}

-- ============================================================
-- AUDIO (SFX & BGM)
-- Dùng rbxasset:// (file built-in của Roblox) để tránh lỗi "asset type mismatch"
-- Muốn dùng âm thanh khác: Vào Toolbox → Audio → copy ID → đổi thành rbxassetid://ID
-- ============================================================
Config.Audio = {
	BGM       = "rbxassetid://1841154673",                                       -- Action Music
	ShoutSFX  = "rbxassetid://4975549887",                              -- Âm thanh "Shout" vang dội
	DashSFX   = "rbxasset://sounds/switch.wav",         -- Tiếng click/switch (built-in)
	ImpactSFX = "rbxasset://sounds/splat.mp3",          -- Tiếng va chạm bùm (built-in)
	JumpSFX   = "rbxasset://sounds/action_jump.mp3",
	LandSFX   = "rbxasset://sounds/impact_drop.mp3",

	-- Gacha / Egg SFX (Placeholder sử dụng builtin sounds)
	EggShakeSFX       = "rbxasset://sounds/metal.ogg",      -- Tiếng rung
	EggFlashSFX       = "rbxasset://sounds/snap.wav",       -- Tiếng nổ lóe sáng
	EggHatchNormalSFX = "rbxasset://sounds/action_jump.mp3",-- Ra pet thường
	EggHatchEpicSFX   = "rbxasset://sounds/electronicpingshort.mp3", -- Ra pet hiếm
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
		Id          = "damage_1",
		DisplayName = "Sonic Power",
		Category    = "Attack",
		BaseCost    = 150,
		CostScaling = 1.5,
		StatPerLevel = 5,
		MaxLevel    = 100,
		Icon        = "rbxassetid://5905055047",
	},
	{
		Id          = "health_1",
		DisplayName = "Vitality Boost",
		Category    = "Defense",
		BaseCost    = 75,
		CostScaling = 1.5,
		StatPerLevel = 20,
		MaxLevel    = 100,
		Icon        = "rbxassetid://515329329",
	},
	{
		Id          = "armor_1",
		DisplayName = "Knockback Resistance",
		Category    = "Defense",
		BaseCost    = 600,
		CostScaling = 1.6,
		StatPerLevel = 10,
		MaxLevel    = 100,
		Icon        = "rbxassetid://2703816766",
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
	AreaUnlockThresholds = {     -- mở khu vực mới khi đạt rebirth count
		[1]  = "Desert",
		[3]  = "IceZone",
		[7]  = "VoidRealm",
		[15] = "HeavenlyStage",
	},
}

-- ============================================================
-- PETS
-- ============================================================
local petsData: { Types.PetConfig } = {
	{ PetType = "SoundPup",     DisplayName = "Sound Pup",     Rarity = "Common",    Multiplier = 1.05, ModelId = "rbxassetid://6031280882", Icon = "rbxassetid://5318182907" },
	{ PetType = "EchoFox",      DisplayName = "Echo Fox",      Rarity = "Uncommon",  Multiplier = 1.12, ModelId = "rbxassetid://6031280882", Icon = "rbxassetid://5299499872" },
	{ PetType = "SonicCat",     DisplayName = "Sonic Cat",     Rarity = "Rare",      Multiplier = 1.25, ModelId = "rbxassetid://6031280882", Icon = "rbxassetid://5299499696" },
	{ PetType = "BoomBear",     DisplayName = "Boom Bear",     Rarity = "Epic",      Multiplier = 1.50, ModelId = "rbxassetid://6031280882", Icon = "rbxassetid://5318182907" },
	{ PetType = "SoundDragon",  DisplayName = "Sound Dragon",  Rarity = "Legendary", Multiplier = 2.00, ModelId = "rbxassetid://6031280882", Icon = "rbxassetid://5299499696" },
}
Config.Pets = petsData

-- Trọng số gacha (tổng = 100)
local gachaWeights: { [string]: number } = {
	Common    = 55,
	Uncommon  = 25,
	Rare      = 12,
	Epic      = 6,
	Legendary = 2,
}
Config.PetGachaWeights = gachaWeights

Config.EggCostGold = 100  -- chi phí mở 1 trứng

-- ============================================================
-- SKILLS
-- ============================================================
local skillsData: { Types.SkillConfig } = {
	{ SkillType = "BasicShout",   DisplayName = "Basic Shout",   Rarity = "Common",    ShoutTypeId = "Normal",   DamageMult = 1.0, Cooldown = 0.6, Icon = "📢", Description = "A standard shout.", IsBasic = true },
	{ SkillType = "LoudCry",      DisplayName = "Loud Cry",      Rarity = "Common",    ShoutTypeId = "Circular", DamageMult = 0.8, Cooldown = 1.2, Icon = "🗣️", Description = "A weak area attack." },
	
	{ SkillType = "Shockwave",    DisplayName = "Shockwave",     Rarity = "Uncommon",  ShoutTypeId = "Circular", DamageMult = 0.9, Cooldown = 1.2, Icon = "🔘", Description = "Creates a shockwave." },
	{ SkillType = "PiercingRoar", DisplayName = "Piercing Roar", Rarity = "Uncommon",  ShoutTypeId = "Focused",  DamageMult = 1.2, Cooldown = 1.8, Icon = "🗯️", Description = "A focused line attack." },

	{ SkillType = "SonicBeam",    DisplayName = "Sonic Beam",    Rarity = "Rare",      ShoutTypeId = "Focused",  DamageMult = 1.5, Cooldown = 1.8, Icon = "⚡",  Description = "A strong focused beam." },
	{ SkillType = "EchoBurst",    DisplayName = "Echo Burst",    Rarity = "Rare",      ShoutTypeId = "Circular", DamageMult = 1.1, Cooldown = 1.0, Icon = "💥", Description = "Fast shockwave." },

	{ SkillType = "TidalRoar",    DisplayName = "Tidal Roar",    Rarity = "Epic",      ShoutTypeId = "Circular", DamageMult = 1.4, Cooldown = 1.0, Icon = "🌊", Description = "Powerful area shout." },
	{ SkillType = "BeastHowl",    DisplayName = "Beast Howl",    Rarity = "Epic",      ShoutTypeId = "Normal",   DamageMult = 1.8, Cooldown = 0.7, Icon = "🐺", Description = "Fierce normal shout." },

	{ SkillType = "DragonScream", DisplayName = "Dragon Scream", Rarity = "Legendary", ShoutTypeId = "Focused",  DamageMult = 3.0, Cooldown = 2.5, Icon = "🐉", Description = "Ultimate destruction." },
}
Config.Skills = skillsData

Config.SkillGachaWeights = {
	Common    = 60,
	Uncommon  = 25,
	Rare      = 10,
	Epic      = 4,
	Legendary = 1,
}

Config.SkillScrollCost = 250 -- chi phí mở 1 cuộn skill

-- ============================================================
-- MONSTERS
-- ============================================================
local monstersData: { Types.MonsterConfig } = {
	-- Starter Zone
	{
		Id             = "ScreechSlime",
		DisplayName    = "Screech Slime",
		MaxHP          = 80,
		Attack         = 5,
		Defense        = 2,
		MovementSpeed  = 13,
		GoldDrop       = 10,
		EggDropChance  = 0.03,
		SpawnZone      = "StarterZone",
	},
	-- PvE Zone
	{
		Id             = "BoomGolem",
		DisplayName    = "Boom Golem",
		MaxHP          = 400,
		Attack         = 30,
		Defense        = 20,
		MovementSpeed  = 11,
		GoldDrop       = 50,
		EggDropChance  = 0.15,
		SpawnZone      = "PvEZone",
	},
	{
		Id             = "EchoToad",
		DisplayName    = "Echo Toad",
		MaxHP          = 150,
		Attack         = 15,
		Defense        = 8,
		MovementSpeed  = 15,
		GoldDrop       = 30,
		EggDropChance  = 0.08,
		SpawnZone      = "PvEZone",
	},
	-- Desert (Rebirth 1)
	{
		Id             = "DustDevil",
		DisplayName    = "Dust Devil",
		MaxHP          = 800,
		Attack         = 45,
		Defense        = 30,
		MovementSpeed  = 15,
		GoldDrop       = 120,
		EggDropChance  = 0.20,
		SpawnZone      = "Desert",
	},
	{
		Id             = "SandGolem",
		DisplayName    = "Sand Golem",
		MaxHP          = 1500,
		Attack         = 60,
		Defense        = 45,
		MovementSpeed  = 11,
		GoldDrop       = 200,
		EggDropChance  = 0.30,
		SpawnZone      = "Desert",
	},
	-- IceZone (Rebirth 3)
	{
		Id             = "IcyWraith",
		DisplayName    = "Icy Wraith",
		MaxHP          = 3000,
		Attack         = 90,
		Defense        = 70,
		MovementSpeed  = 14,
		GoldDrop       = 400,
		EggDropChance  = 0.35,
		SpawnZone      = "IceZone",
	},
	{
		Id             = "FrostGiant",
		DisplayName    = "Frost Giant",
		MaxHP          = 6000,
		Attack         = 120,
		Defense        = 90,
		MovementSpeed  = 11,
		GoldDrop       = 700,
		EggDropChance  = 0.45,
		SpawnZone      = "IceZone",
	},
	-- VoidRealm (Rebirth 7)
	{
		Id             = "VoidSerpent",
		DisplayName    = "Void Serpent",
		MaxHP          = 15000,
		Attack         = 200,
		Defense        = 150,
		MovementSpeed  = 15,
		GoldDrop       = 1500,
		EggDropChance  = 0.60,
		SpawnZone      = "VoidRealm",
	},
	{
		Id             = "ShadowBeast",
		DisplayName    = "Shadow Beast",
		MaxHP          = 30000,
		Attack         = 280,
		Defense        = 200,
		MovementSpeed  = 13,
		GoldDrop       = 2500,
		EggDropChance  = 0.70,
		SpawnZone      = "VoidRealm",
	},
	-- HeavenlyStage (Rebirth 15)
	{
		Id             = "DivineGuardian",
		DisplayName    = "Divine Guardian",
		MaxHP          = 80000,
		Attack         = 450,
		Defense        = 300,
		MovementSpeed  = 14,
		GoldDrop       = 5000,
		EggDropChance  = 0.85,
		SpawnZone      = "HeavenlyStage",
	},
	-- Bosses
	{
		Id             = "SoundKing",
		DisplayName    = "Sound King",
		MaxHP          = 10000,
		Attack         = 150,
		Defense        = 100,
		MovementSpeed  = 12,
		GoldDrop       = 1000,
		EggDropChance  = 0.80,
		SpawnZone      = "BossRoom",
		IsBoss         = true,
	},
	{
		Id             = "IceColossus",
		DisplayName    = "Ice Colossus",
		MaxHP          = 50000,
		Attack         = 300,
		Defense        = 200,
		MovementSpeed  = 11,
		GoldDrop       = 3000,
		EggDropChance  = 0.90,
		SpawnZone      = "IceBossRoom",
		IsBoss         = true,
	},
}
Config.Monsters = monstersData

Config.MonsterRespawnTime = 8  -- giây

-- ============================================================
-- DATA
-- ============================================================
Config.DataSaveInterval = 60      -- auto-save mỗi 60 giây
Config.DataStoreName    = "ShoutSimulatorV1"

-- ============================================================
-- CUSTOM SHOUT
-- ============================================================
Config.CustomShout = {
	MaxLength = 40,  -- max characters
	Cooldown  = 5,   -- seconds between changes
	DisplayDuration = 2.5,  -- seconds shown above head
}

-- ============================================================
-- REWARDS
-- ============================================================
Config.Rewards = {
	PlaytimeMilestones = {
		{ Time = 300, Reward = {Type = "Gold", Amount = 100} },	-- 5 minutes
		{ Time = 900, Reward = {Type = "VocalPoints", Amount = 500} }, -- 15 minutes
		{ Time = 1800, Reward = {Type = "Gold", Amount = 500} }, -- 30 minutes
	}
}

-- ============================================================
-- QUESTS & MONETIZATION
-- ============================================================
Config.Quests = {
	{ Id = "Shout200", ActionType = "Shout", Required = 200, Reward = {Type = "VocalPoints", Amount = 500}, Title = "Shout 200 times" },
	{ Id = "Hatch10", ActionType = "HatchEgg", Required = 10, Reward = {Type = "Gold", Amount = 500}, Title = "Hatch 10 Eggs" },
}

Config.MonetizationProducts = {
	Gamepasses = {
		{ Id = 189283745, Name = "Auto Train", Price = 150, Icon = "rbxassetid://5905055047", Type = "Gamepass" }, -- TODO: Thay Gamepass ID thật (Auto Train)
		{ Id = 271828182, Name = "VIP (x2 Stats)", Price = 399, Icon = "rbxassetid://8050965706", Type = "Gamepass" }, -- TODO: Thay Gamepass ID thật (VIP)
	},
	DevProducts = {
		{ Id = 987654321, Name = "+1,000 Gold", Price = 50, Icon = "rbxassetid://2703816766", Type = "DevProduct" }, -- TODO: Thay DevProduct ID thật (Gold gói nhỏ)
		{ Id = 987654322, Name = "+5,000 Gold", Price = 200, Icon = "rbxassetid://2703816766", Type = "DevProduct" }, -- TODO: Thay DevProduct ID thật (Gold gói lớn)
	}
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
	Background = Color3.fromRGB(21, 22, 32),         -- #151620 (Darker)
	SecondaryBackground = Color3.fromRGB(28, 30, 44), -- #1C1E2C
	PanelTransparency = 0.1,
	CornerRadius = UDim.new(0, 12),
	StrokeThickness = 1.5,
	StrokeColor = Color3.fromRGB(60, 65, 90),
	
	-- Universal Gradients
	PanelGradient = { Color3.fromRGB(30, 32, 45), Color3.fromRGB(20, 22, 35) },
	PrimaryGradient = { Color3.fromRGB(100, 180, 255), Color3.fromRGB(60, 120, 255) },
	SecondaryGradient = { Color3.fromRGB(255, 180, 60), Color3.fromRGB(200, 130, 40) },
	SuccessGradient = { Color3.fromRGB(80, 220, 160), Color3.fromRGB(40, 180, 120) },
	RebirthGradient = { Color3.fromRGB(255, 80, 100), Color3.fromRGB(200, 50, 70) },
	SkillGradient = { Color3.fromRGB(180, 100, 255), Color3.fromRGB(140, 70, 220) },
	
	-- Button Base Styles (Modernized)
	BtnShopBase = Color3.fromRGB(60, 120, 255),    -- #3C78FF
	BtnShopShadow = Color3.fromRGB(40, 80, 200),
	
	BtnPetsBase = Color3.fromRGB(255, 180, 60),    -- #FFB43C
	BtnPetsShadow = Color3.fromRGB(200, 130, 40),
	
	BtnRebirthBase = Color3.fromRGB(255, 80, 100), -- #FF5064
	BtnRebirthShadow = Color3.fromRGB(200, 50, 70),
	
	BtnShoutBase = Color3.fromRGB(100, 220, 100),  -- #64DC64
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
		Common    = Color3.fromRGB(180, 185, 210),
		Uncommon  = Color3.fromRGB(110, 255, 150),
		Rare      = Color3.fromRGB(90, 190, 255),
		Epic      = Color3.fromRGB(210, 120, 255),
		Legendary = Color3.fromRGB(255, 215, 80),
	}
}


return Config
