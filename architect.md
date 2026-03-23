# Shout Simulator – Kiến Trúc Kỹ Thuật

> **Phiên bản:** 2.0 | **Ngày:** 2026-03-23  
> **Stack:** Luau `--!strict` · Rojo 7.6.1 · DataStoreService · Roblox RemoteEvents

---

## 1. Tổng Quan Kiến Trúc

```
┌─────────────────────────────────────────────────────┐
│                   ROBLOX GAME SERVER                │
│                                                     │
│  ServerScriptService/Server/                        │
│  ├── init.server.luau           ← Entry point       │
│  └── Services/                                      │
│      ├── DataService.luau       ← Save/Load data    │
│      ├── ShoutService.luau      ← Combat physics    │
│      ├── UpgradeService.luau    ← Shop logic        │
│      ├── PetService.luau        ← Gacha system      │
│      ├── RebirthService.luau    ← Prestige reset    │
│      ├── MonsterService.luau    ← PvE spawn/AI      │
│      └── TextFilterService.luau ← Roblox compliance │
│                                                     │
│  ReplicatedStorage/Shared/                          │
│  ├── Types.luau                 ← All type defs     │
│  ├── Config.luau        ← ★ ĐIỂM MỞ RỘNG CHÍNH ★  │
│  ├── Remotes.luau               ← Remote registry   │
│  └── VFX/                                           │
│      └── ShoutWave.luau         ← Cone wave VFX     │
│                                                     │
│  StarterPlayer/StarterPlayerScripts/Client/         │
│  ├── init.client.luau           ← Client entry      │
│  ├── Controllers/                                   │
│  │   ├── DataController.luau    ← Reactive cache    │
│  │   ├── ShoutController.luau   ← Input + VFX       │
│  │   └── UIController.luau      ← UI orchestrator   │
│  └── UI/                                            │
│      ├── HUD.luau               ← VocalPoints, stats│
│      ├── Shop.luau              ← Upgrade store     │
│      ├── PetUI.luau             ← Pet gacha grid    │
│      ├── RebirthUI.luau         ← Prestige confirm  │
│      ├── SkillBar.luau          ← Skill selector    │
│      └── CustomShoutUI.luau     ← Shout text input  │
└─────────────────────────────────────────────────────┘
```

> **Quy tắc vàng:** Mọi thay đổi về nội dung game (thêm pet, quái, skill, upgrade) chỉ cần sửa **`Config.luau`** và **`Types.luau`**. Logic không cần sửa.

---

## 2. Hướng Dẫn Mở Rộng Nhanh

### 2a. Thêm Pet Mới

**Chỉ sửa `Config.luau` → `Config.Pets`**

```lua
-- Thêm vào cuối bảng petsData:
{ PetType = "ThunderWolf",  DisplayName = "Thunder Wolf",  Rarity = "Epic",      Multiplier = 1.60, ModelId = "rbxassetid://XXXXX", Icon = "rbxassetid://XXXXX" },
{ PetType = "VoidSerpent",  DisplayName = "Void Serpent",  Rarity = "Legendary", Multiplier = 2.50, ModelId = "rbxassetid://XXXXX", Icon = "rbxassetid://XXXXX" },
```

**Checklist:**
- [ ] Thêm entry vào `Config.Pets` (PetType, DisplayName, Rarity, Multiplier, ModelId, Icon)
- [ ] Đảm bảo tổng `Config.PetGachaWeights` vẫn = 100 nếu thêm rarity mới
- [ ] Nếu thêm rarity mới (VD: "Mythic"): thêm vào `export type PetRarity` trong `Types.luau`

**Không cần đụng:** `PetService.luau`, `PetUI.luau` — hệ thống tự đọc từ Config.

---

### 2b. Thêm Skill (Shout Type) Mới

**Chỉ sửa `Config.luau` → `Config.ShoutTypes`**

```lua
-- Thêm entry mới vào Config.ShoutTypes:
Explosive = {
    Id         = "Explosive",
    Name       = "Explosive Roar",
    Range      = 30,
    Angle      = 90,       -- Half-angle: tổng 180° (rộng hơn Normal)
    DamageMult = 1.2,
    Cooldown   = 1.8,
    Icon       = "💥",
},
```

**Checklist:**
- [ ] Thêm entry vào `Config.ShoutTypes`
- [ ] Thêm Id vào `export type ShoutType` trong `Types.luau`
  ```lua
  -- Trước:
  export type ShoutType = "Normal" | "Circular" | "Focused"
  -- Sau:
  export type ShoutType = "Normal" | "Circular" | "Focused" | "Explosive"
  ```
- [ ] `SkillBar.luau` tự render skill mới vì nó dọc `Config.ShoutTypes`
- [ ] `ShoutService.luau` tự áp dụng Range/Angle/DamageMult từ Config

**Không cần đụng:** `ShoutService.luau`, `ShoutController.luau`, `SkillBar.luau`

---

### 2c. Thêm Quái Mới

**Chỉ sửa `Config.luau` → `Config.Monsters`**

```lua
-- Thêm vào cuối bảng monstersData:
{
    Id            = "EchoTitan",
    DisplayName   = "Echo Titan",
    MaxHP         = 500,
    Attack        = 60,
    Defense       = 40,
    MovementSpeed = 6,
    GoldDrop      = 150,
    EggDropChance = 0.40,  -- 40% thả trứng
    SpawnZone     = "PvEZone",
},
```

**Checklist:**
- [ ] Thêm entry vào `Config.Monsters`
- [ ] `SpawnZone` phải khớp với tên khu vực trong `Config.Map` ("PvEZone", "BossRoom",...)
- [ ] `MonsterService.luau` tự spawn/despawn dựa trên danh sách này

**Nếu muốn thêm SpawnZone mới:**
- Thêm khu vực vào `Config.Map`
- Tạo Part trên Workspace có Name tương ứng
- Không cần sửa MonsterService

---

### 2d. Thêm Upgrade Mới

**Chỉ sửa `Config.luau` → `Config.Upgrades`**

```lua
-- Thêm vào cuối bảng upgradesData:
{
    Id           = "amp_1",
    DisplayName  = "Mega Amplifier",
    Category     = "Attack",   -- hoặc "Defense"
    BaseCost     = 1000,
    CostScaling  = 1.7,
    StatPerLevel = 20,
    MaxLevel     = 25,
    Icon         = "rbxassetid://XXXXX",
},
```

**Checklist:**
- [ ] Thêm entry vào `Config.Upgrades`
- [ ] `Category` phải là "Attack" hoặc "Defense" (định nghĩa trong `Types.UpgradeConfig`)
- [ ] `Shop.luau` và `UpgradeService.luau` tự nhận upgrade mới — không cần sửa

---

## 3. Luồng Dữ Liệu (Data Flow)

### 3a. Khi Người Chơi Hét
```
[Client] Click/Space → ShoutController
    → Đọc CurrentShoutType từ DataController
    → ShoutWave.Play(shoutType)     (VFX local, instant)
    → RemoteEvent.ShoutFired:FireServer({ Direction, OriginCFrame })

[Server] ShoutService
    → Validate cooldown (per ShoutType.Cooldown)
    → getTargetsInCone(Range, Angle từ Config.ShoutTypes[type])
    → calculateKnockback() → Apply LinearVelocity
    → DataService.UpdateField("VocalPoints", +N)
    → RemoteEvent.KnockbackOccurred:FireAllClients()

[Client] ShoutController (receive broadcast)
    → CameraShake (nếu bị đánh)
    → ShoutWave.PlayHitEffect()
```

### 3b. Khi Mua Upgrade
```
[Client] Shop.luau → BuyBtn clicked
    → RemoteEvent.PurchaseUpgrade:FireServer(upgradeId)

[Server] UpgradeService
    → Tra Config.Upgrades[upgradeId] → Validate cost & level cap
    → DataService.UpdateFields({ Gold: -cost, [StatKey]: +1 })
    → PlayerDataUpdated fired → Client re-renders Shop & HUD
```

### 3c. Save/Load Lifecycle
```
PlayerAdded → DataService.loadData()
           → DataStore:GetAsync("Player_{userId}")
           → Merge với Config.DefaultPlayerData
           → FireClient(PlayerDataLoaded, data)

Auto-save  → Mỗi 60 giây, DataStore:SetAsync()
PlayerRemoving / BindToClose → DataService.saveData()
```

---

## 4. Công Thức Game (Formulas)

### Knockback
```
force = (attacker.Attack * Config.Shout.BaseDamage * ShoutType.DamageMult)
          / √(target.Defense)
force = min(force, Config.Shout.MaxForce)
finalForce = direction * force + UP * Config.Shout.VerticalBias
```

### Tổng Attack
```
totalATK = (baseATK + upgradeLevel × StatPerLevel) × RebirthMultiplier × PetMultiplier
```

### Pet Multiplier (tích lũy)
```
petMult = pet1.Multiplier × pet2.Multiplier × pet3.Multiplier
```

### Rebirth Multiplier
```
mult = 1 + (rebirthCount × Config.Rebirth.MultiplierPerRebirth)
-- Rebirth 1: ×1.25 | Rebirth 4: ×2.00 | Rebirth 10: ×3.50
```

---

## 5. Bảo Mật (Security)

| Điểm | Cơ chế |
|---|---|
| Knockback | Server-only apply. Client chỉ fire direction, server validate cooldown & tính force |
| Mua đồ | Server kiểm tra Gold, Level cap trước khi apply |
| Custom Shout Text | `TextService:FilterStringAsync()` bắt buộc trước khi broadcast |
| Gacha | Logic roll 100% server-side, client chỉ nhận kết quả |
| Data | DataStoreService, không expose session trực tiếp ra client |

---

## 6. Remote Event Registry

| Remote | Chiều | Payload |
|---|---|---|
| `ShoutFired` | C→S | `ShoutRequest { Direction, OriginCFrame }` |
| `KnockbackOccurred` | S→All | `KnockbackEvent { targetUserId, force, attackerUserId }` |
| `PlayerDataLoaded` | S→C | `data: PlayerData` |
| `PlayerDataUpdated` | S→C | `key: string, value: any` |
| `PurchaseUpgrade` | C→S | `upgradeId: string` |
| `OpenEgg` | C→S | `quantity: number` |
| `EggOpenResult` | S→C | `pets: {PetData}` |
| `SetPetEquipped` | C→S | `petId: string, equipped: bool` |
| `RebirthRequest` | C→S | *(none)* |
| `RebirthResult` | S→C | `success: bool, newMult: number` |
| `SetCustomShout` | C→S | `text: string` |
| `DisplayCustomShout` | S→All | `userId: number, filteredText: string` |
| `Notification` | S→C | `message: string` |
| `ChangeShoutType` | C→S | `shoutType: ShoutType` |

---

## 7. Cấu Hình Tham Khảo Nhanh (Config.luau)

> Không hardcode trong logic. Mọi balance value đều đặt tại đây.

| Nhóm | Key | Default | Ghi chú |
|---|---|---|---|
| `Shout` | `Cooldown` | 0.8s | Cooldown mặc định (override bởi ShoutType) |
| `Shout` | `KnockbackRange` | 20 studs | Range fallback |
| `Shout` | `MaxForce` | 55 | Lực tối đa tránh văng bay |
| `ShoutTypes` | `Normal.Cooldown` | 0.8s | Skill Normal |
| `ShoutTypes` | `Circular.Cooldown` | 1.5s | Skill Shockwave |
| `ShoutTypes` | `Focused.Cooldown` | 2.0s | Skill Sonic Beam |
| `Rebirth` | `VocalPointsRequired` | 10,000 | |
| `Rebirth` | `MultiplierPerRebirth` | +25% | |
| `Data` | `SaveInterval` | 60s | |
| `Pet` | `EggCostGold` | 100 | |
| `Monster` | `MonsterRespawnTime` | 15s | |

---

## 8. Keyboard Shortcuts (Client)

| Key | Action |
|---|---|
| **Click / Space** | Hét (Shout) |
| **1 / 2 / 3** | Chọn Skill (SkillBar) |
| **E** | Mở/đóng Shop |
| **P** | Mở/đóng Pet UI |
| **R** | Mở Rebirth dialog |
| **T** | Đổi câu hét cá nhân |

---

## 9. Quy Ước Đặt Tên

```
Services/       → PascalCase + "Service" suffix (DataService, ShoutService)
Controllers/    → PascalCase + "Controller" suffix
UI/             → PascalCase (HUD, Shop, PetUI, SkillBar)
Shared modules  → PascalCase (Types, Config, Remotes)
Variables       → camelCase  (localPlayer, totalAttack)
Types           → PascalCase (PlayerData, PetData)
Remotes         → PascalCase verb+noun (ShoutFired, PlayerDataLoaded)
Config keys     → PascalCase (ShoutTypes, Monsters, Pets, Upgrades)
```

---

## 10. Roadmap Tiếp Theo

- [ ] **Skill mới**: Thêm "Explosive Roar" (AoE), "Healing Shout" (buff đồng đội)
- [ ] **Pet mới**: ThunderWolf (Epic), VoidSerpent (Legendary), MythicPhoenix (Mythic)
- [ ] **Map zones**: Xây thêm khu Ice Zone, Void Realm khi đủ Rebirth
- [ ] **Monster AI nâng cao**: PathfindingService + Boss mechanics
- [ ] **Gamepass**: Double VP, Auto-Train, Custom Shout Color
- [ ] **Leaderboard**: OrderedDataStore cho bảng xếp hạng VP
- [ ] **VFX nâng cao**: Particle emitters theo Rarity của Pet