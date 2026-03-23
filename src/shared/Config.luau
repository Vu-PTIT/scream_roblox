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
	Gold                = 0,
	Cups                = 0,
	Attack              = 10,
	Defense             = 10,
	RebirthCount        = 0,
	RebirthMultiplier   = 1,
	AttackUpgradeLevel  = 0,
	SpeakerUpgradeLevel = 0,
	DefenseUpgradeLevel = 0,
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
	CurrentShoutType    = "Normal",
}
Config.DefaultPlayerData = defaultData

-- ============================================================
-- SHOUT MECHANICS
-- ============================================================
Config.Shout = {
	Cooldown          = 0.8,   -- giây giữa các lần hét
	BaseDamage        = 15,    -- hệ số nhân sát thương chung (Damage = ATK * Base / DEF)
	BaseForce         = 15,    -- (Đã giảm mạnh) lực đẩy cơ bản 
	KnockbackScaling  = 10,    -- (Đã giảm mạnh) hệ số nhân (ATK / DEF) cho lực văng
	KnockbackRange    = 20,    -- studs - bán kính cone sóng âm
	ConeAngle         = 55,    -- độ - góc nửa-cone khi lan sóng
	VerticalBias      = 0.5,   -- tăng một chút để nảy lên rõ nét thay vì trượt ngang
	MaxForce          = 55,    -- (Đã giảm mạnh) giới hạn vận tốc tối đa để tránh văng bay màu khỏi màn hình
	VocalPointsPerHit = 1,
	VocalPointsPerUse = 0.2,

	-- Hệ thống Gồng lực (Power Charge)
	Charge = {
		MaxTime = 2.0, -- Giây tối đa để đạt max power
		MinTime = 0.3, -- Thời gian tối thiểu để coi là có gồng (dưới mức này là tap)
		Levels = {
			{ Time = 0.0, Mult = 1.0, Color = Color3.fromRGB(255, 255, 255), Name = "Normal" },
			{ Time = 0.6, Mult = 1.5, Color = Color3.fromRGB(100, 200, 255), Name = "Strong" },
			{ Time = 1.2, Mult = 2.2, Color = Color3.fromRGB(255, 200, 50),  Name = "Powerful" },
			{ Time = 1.8, Mult = 3.5, Color = Color3.fromRGB(255, 255, 100), Name = "MAX POWER" },
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
	BossRoom = {
		Position = Vector3.new(-200, 0, 0),
		Size     = Vector3.new(150, 1, 150),
	}
}

-- ============================================================
-- AUDIO (SFX & BGM)
-- Dùng rbxasset:// (file built-in của Roblox) để tránh lỗi "asset type mismatch"
-- Muốn dùng âm thanh khác: Vào Toolbox → Audio → copy ID → đổi thành rbxassetid://ID
-- ============================================================
Config.Audio = {
	BGM       = "rbxassetid://183784928",                                       -- BGM sôi động (Action Music)
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
		Id          = "microphone_1",
		DisplayName = "Basic Microphone",
		Category    = "Attack",
		BaseCost    = 50,
		CostScaling = 1.5,
		StatPerLevel = 5,
		MaxLevel    = 50,
		Icon        = "rbxassetid://5905055047",
	},
	{
		Id          = "speaker_1",
		DisplayName = "Super Bass Speaker",
		Category    = "Attack",
		BaseCost    = 500,
		CostScaling = 1.6,
		StatPerLevel = 15,
		MaxLevel    = 30,
		Icon        = "rbxassetid://8050965706",
	},
	{
		Id          = "headphone_1",
		DisplayName = "Noise Cancelling Headphones",
		Category    = "Defense",
		BaseCost    = 75,
		CostScaling = 1.5,
		StatPerLevel = 4,
		MaxLevel    = 50,
		Icon        = "rbxassetid://515329329",
	},
	{
		Id          = "armor_1",
		DisplayName = "Sonic Armor",
		Category    = "Defense",
		BaseCost    = 600,
		CostScaling = 1.6,
		StatPerLevel = 12,
		MaxLevel    = 30,
		Icon        = "rbxassetid://2703816766",
	},
}
Config.Upgrades = upgradesData

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
-- MONSTERS
-- ============================================================
local monstersData: { Types.MonsterConfig } = {
	{
		Id             = "ScreechSlime",
		DisplayName    = "Screech Slime",
		MaxHP          = 50,
		Attack         = 10,
		Defense        = 5,
		MovementSpeed  = 8,
		GoldDrop       = 10,
		EggDropChance  = 0.05,
		SpawnZone      = "PvEZone",
	},
	{
		Id             = "BoomGolem",
		DisplayName    = "Boom Golem",
		MaxHP          = 200,
		Attack         = 30,
		Defense        = 20,
		MovementSpeed  = 5,
		GoldDrop       = 50,
		EggDropChance  = 0.20,
		SpawnZone      = "PvEZone",
	},
	{
		Id             = "SoundKing",
		DisplayName    = "Sound King",
		MaxHP          = 1000,
		Attack         = 100,
		Defense        = 60,
		MovementSpeed  = 3,
		GoldDrop       = 300,
		EggDropChance  = 0.75,
		SpawnZone      = "BossRoom",
	},
}
Config.Monsters = monstersData

Config.MonsterRespawnTime = 15  -- giây

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
		{ Id = 12345678, Name = "Auto Train", Price = 150, Icon = "rbxassetid://5905055047", Type = "Gamepass" }, -- TODO: Thay Gamepass ID thật (Auto Train)
		{ Id = 87654321, Name = "VIP (x2 Stats)", Price = 399, Icon = "rbxassetid://8050965706", Type = "Gamepass" }, -- TODO: Thay Gamepass ID thật (VIP)
	},
	DevProducts = {
		{ Id = 10000001, Name = "+1,000 Gold", Price = 50, Icon = "rbxassetid://2703816766", Type = "DevProduct" }, -- TODO: Thay DevProduct ID thật (Gold gói nhỏ)
		{ Id = 10000002, Name = "+5,000 Gold", Price = 200, Icon = "rbxassetid://2703816766", Type = "DevProduct" }, -- TODO: Thay DevProduct ID thật (Gold gói lớn)
	}
}

-- ============================================================
-- LOCALIZATION (English)
-- ============================================================
Config.Localization = {
	HUD = {
		VocalPointsTitle = "VOCAL POINTS",
		GoldFormat = "💰 %s Gold",
		RebirthFormat = "⭐ Rebirth: %d (x%.2f)",
		AttackLabel = "⚔️ Attack: %d",
		DefenseLabel = "🛡️ Defense: %d",
	},
	Shop = {
		Title = "🛒 UPGRADE SHOP",
		TabAttack = "⚔️ Attack",
		TabDefense = "🛡️ Defense",
		TabPremium = "⭐ Premium",
		LevelFormat = "Level: %d / %d  |  +%d per level",
		CostFormat = "💰 Cost: %s Gold",
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
		NotEnoughGold = "💰 Not enough gold! Need %d Gold for %d eggs",
		GetPets = "🥚 Received: %s",
		PetNotFound = "❌ Pet not found!",
		MaxPetsEquipped = "⚠️ Maximum %d pets equipped!",
		RebirthNeeded = "🔄 Need %d more Vocal Points to Rebirth!",
		RebirthSuccess = "⭐ Rebirth successful! New multiplier: x%.2f",
		UpgradeNotFound = "❌ Upgrade does not exist!",
		MaxLevelReached = "⚠️ Max level reached!",
		NotEnoughGoldUpgrade = "💰 Not enough gold! Need %d Gold",
		UpgradeSuccess = "✅ Upgraded %s to Level %d!",
	},
}

-- ============================================================
-- THEME (Solid Dark Mode & Flat 3D)
-- ============================================================
Config.Theme = {
	-- Base Panels
	Background = Color3.fromRGB(35, 37, 50),         -- #232532
	SecondaryBackground = Color3.fromRGB(21, 22, 32), -- #151620
	Transparency = 0,
	CornerRadius = UDim.new(0, 8),
	StrokeThickness = 0,
	StrokeColor = Color3.fromRGB(0, 0, 0),
	
	-- Navigation Buttons (Base, Shadow Bottom)
	BtnShopBase = Color3.fromRGB(84, 101, 139),    -- #54658B
	BtnShopShadow = Color3.fromRGB(61, 75, 105),   -- #3D4B69
	
	BtnPetsBase = Color3.fromRGB(218, 185, 117),   -- #DAB975
	BtnPetsShadow = Color3.fromRGB(189, 159, 99),  -- #BD9F63
	
	BtnRebirthBase = Color3.fromRGB(194, 91, 91),  -- #C25B5B
	BtnRebirthShadow = Color3.fromRGB(158, 68, 68),-- #9E4444
	
	BtnShoutBase = Color3.fromRGB(129, 160, 95),   -- #81A05F
	BtnShoutShadow = Color3.fromRGB(105, 133, 75), -- #69854B
	
	BtnCodeBase = Color3.fromRGB(158, 92, 189),
	BtnCodeShadow = Color3.fromRGB(119, 65, 145),
	
	BtnRewardBase = Color3.fromRGB(240, 140, 65),
	BtnRewardShadow = Color3.fromRGB(200, 110, 45),
	
	BtnQuestBase = Color3.fromRGB(65, 185, 140),
	BtnQuestShadow = Color3.fromRGB(45, 145, 100),

	-- Text Colors
	TextMain = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 210),
	TextMuted = Color3.fromRGB(120, 120, 150),
	TextGold = Color3.fromRGB(241, 183, 67),       -- #F1B743
	TextBlue = Color3.fromRGB(108, 152, 198),      -- #6C98C6

	-- Keep these for legacy compatibility in other UI modules
	PrimaryGradient = { Color3.fromRGB(84, 101, 139), Color3.fromRGB(84, 101, 139) },
	SecondaryGradient = { Color3.fromRGB(218, 185, 117), Color3.fromRGB(218, 185, 117) },
	SuccessGradient = { Color3.fromRGB(129, 160, 95), Color3.fromRGB(129, 160, 95) },
	RebirthGradient = { Color3.fromRGB(194, 91, 91), Color3.fromRGB(194, 91, 91) },
}


return Config
