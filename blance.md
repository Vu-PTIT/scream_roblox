# BÁO CÁO CÂN BẰNG CHỈ SỐ — SHOUT SIMULATOR
**Ngày:** 29/03/2026 | **Phiên bản audit:** 2.0 | **Cập nhật từ:** Config.luau + source code

---

## TRIẾT LÝ THIẾT KẾ

> **Nguyên tắc cốt lõi:** Người chơi ở map cao nhất cũng chỉ có thể quay gacha **10 lần/giờ** (skill scroll). Đây là hard constraint cho toàn bộ hệ thống gold.

Từ constraint này, mọi giá trị trong tài liệu đều được tính ngược ra.

---

## 1. PHÂN TÍCH NGUỒN THU GOLD THEO ZONE

| Zone | Quái tốt nhất | Gold/kill | Respawn | Gold/giờ thực tế |
|---|---|---|---|---|
| StarterZone | ScreechSlime | 10 | 8s | **4,500** |
| PvEZone | BoomGolem | 50 | 8s | **18,000** |
| Desert | SandGolem | 200 | 8s | **72,000** |
| IceZone ← ENDGAME | IcyWraith | 400 | 8s | **144,000** |
| VoidRealm* | ShadowBeast | 2,500 | 8s | **900,000** |
| HeavenlyStage* | DivineGuardian | 5,000 | 8s | **1,800,000** |

> Gold/giờ thực tế = 80% lý thuyết (trừ di chuyển, giao tranh, uptime). Mốc thiết kế là **IceZone = 144,000 G/hr**.

\* VoidRealm và HeavenlyStage phá vỡ constraint 10 lần/giờ — cần giải pháp riêng ở Phần 5.

---

## 2. GIÁ GACHA — TÍNH NGƯỢC TỪ CONSTRAINT

### 2.1 Skill Scroll Cost

```
Mục tiêu: IceZone (144,000 G/hr) → 10 pulls/hr
SkillScrollCost = 144,000 / 10 = 14,400 → làm tròn = 15,000 G
```

### 2.2 Egg Cost

Pet ít tác động hơn Skill ở endgame → cho phép gấp đôi số lần mở:

```
Mục tiêu: IceZone → 20 egg pulls/hr
EggCostGold = 144,000 / 20 = 7,200 → làm tròn = 7,500 G
```

### 2.3 Bảng kết quả theo zone

| Zone | Gold/giờ | Egg/giờ (7,500G) | Skill/giờ (15,000G) | Cảm giác |
|---|---|---|---|---|
| StarterZone | 4,500 | **0.6** | **0.3** | Gacha là phần thưởng xa |
| PvEZone | 18,000 | **2.4** | **1.2** | ~1 scroll mỗi 50 phút |
| Desert | 72,000 | **9.6** | **4.8** | Khoảng 5 pulls/giờ |
| IceZone | 144,000 | **19.2** | **9.6 ≈ 10** | ✅ Đúng mục tiêu |

---

## 3. GIÁ BÁN PET & SKILL (CẬP NHẬT THEO GIÁ MỚI)

### 3.1 Pet Sell Prices

| Rarity | Giá bán | % so với 1 trứng (7,500G) |
|---|---|---|
| Common | 375 G | 5% |
| Rare | 1,125 G | 15% |
| Epic | 3,000 G | 40% |
| Legendary | 7,500 G | = 1 trứng |

### 3.2 Skill Sell Prices

| Rarity | Giá bán | % so với 1 scroll (15,000G) |
|---|---|---|
| Common | 750 G | 5% |
| Rare | 2,250 G | 15% |
| Epic | 6,000 G | 40% |
| Legendary | 15,000 G | = 1 scroll |

> Nguyên tắc: bán Legendary = nhận lại đúng 1 lần quay. Tạo quyết định có ý nghĩa thay vì bán vô thức.

---

## 4. VP ECONOMY — TIỀN TỆ NÂNG CẤP

*(Giữ nguyên từ audit v1.0, đã được xác nhận)*

### 4.1 Nguồn thu VP

```lua
Config.Shout = {
    VocalPointsPerUse = 4,    -- was 0.2
    VocalPointsPerHit = 10,   -- was 1
}
```

| Kịch bản | VP/phút | Thời gian Rebirth 1 |
|---|---|---|
| StarterZone (~40% hit) | 475 | **21 phút** ✅ |
| PvEZone | 625 | **16 phút** ✅ |
| AFK hoàn toàn | 240 | **42 phút** (có thể chấp nhận) |

### 4.2 Chi phí Upgrade

```lua
local upgradesData = {
    { Id="damage_1", BaseCost=50,  CostScaling=1.30, MaxLevel=30 },
    { Id="health_1", BaseCost=75,  CostScaling=1.30, MaxLevel=30 },
    { Id="armor_1",  BaseCost=80,  CostScaling=1.30, MaxLevel=30 },
}
```

| Upgrade | Cấp 10 | Cấp 20 | Cấp MAX (30) | Rebirth cần |
|---|---|---|---|---|
| damage_1 | 2,126 VP | 31,499 VP | 436,486 VP | ~43 RB |
| armor_1 | 3,406 VP | 50,404 VP | 698,385 VP | ~70 RB |

### 4.3 Knockback Formula

```lua
-- ShoutService.luau
local function calculateKnockback(attackerAtk, targetDef, direction, resistance)
    local res = resistance or 0
    local flatComponent  = attackerAtk * 0.2
    local baseRatio      = attackerAtk / math.max(1, targetDef)
    local ratioComponent = math.pow(baseRatio, 0.7) * Config.Shout.KnockbackScaling
    local rawForce = (Config.Shout.BaseForce + flatComponent + ratioComponent) * (1 - res)
    local capped = math.min(rawForce, Config.Shout.MaxForce)
    local horizontalDir = Vector3.new(direction.X, 0, direction.Z).Unit
    return (horizontalDir + Vector3.new(0, Config.Shout.VerticalBias, 0)).Unit * capped
end
```

```lua
Config.Shout = {
    BaseForce        = 8,    -- was 15
    KnockbackScaling = 6,    -- was 10
    MaxForce         = 150,  -- was 45
    VerticalBias     = 0.4,
    BaseDamage       = 8,
}
```

---

## 5. VẤN ĐỀ VOIDREALM & HEAVENLYSTAGE

VoidRealm (ShadowBeast 900k G/hr) và HeavenlyStage (1.8M G/hr) phá vỡ constraint 10 pulls/hr nếu dùng giá tĩnh. **Hai giải pháp khả thi:**

### Giải pháp A — Shop riêng theo zone (khuyến nghị)
Tạo NPC shop trong VoidRealm và HeavenlyStage với giá riêng:

| Zone | SkillScrollCost | EggCostGold |
|---|---|---|
| StarterZone → IceZone | 15,000 G | 7,500 G |
| VoidRealm | 90,000 G | 45,000 G |
| HeavenlyStage | 180,000 G | 90,000 G |

### Giải pháp B — Gold sink toàn server
Thêm cơ chế tiêu gold khác ở zone cao (nâng cấp vũ khí, mua buff tạm thời) để gold không tích lũy vào gacha.

> **Hiện tại (ngắn hạn):** Chưa có gì thay đổi ở VoidRealm/HeavenlyStage vì chúng yêu cầu 7–15 rebirth — người chơi sẽ mất nhiều tháng để đến đó. Đây là vấn đề cần xử lý trước khi ra mắt zone đó.

---

## 6. BUG: PET MULTIPLIER DÙNG HAI CÔNG THỨC KHÁC NHAU

### Hiện tại (bug)
- `ShoutService.luau` dùng **product**: `petMult *= pet.Multiplier` → 3 Legendary = ×8
- `PetService.luau` passive VP dùng **sum**: `petBonus += (Multiplier - 1)` → 3 Legendary = ×2.5

### Fix: Thống nhất về sum mode + cap

```lua
-- ShoutService.luau — hàm getTotalAttack
local petBonus = 0
for _, petData in ipairs(data.Pets) do
    if petData.Equipped then
        petBonus += (petData.Multiplier - 1)
    end
end
local petMult = math.min(1 + petBonus, 3.0)  -- hard cap ×3

-- PetService.luau — passive VP (giữ nguyên sum, thêm cap)
local petMult = math.min(1 + petBonus, 2.5)  -- passive cap thấp hơn
```

**Kết quả:** R10 + 3 Legendary = 3.5 × 3.0 = ×10.5 tổng (thay vì ×28 với bug cũ).

---

## 7. ĐƯỜNG CONG PROGRESSION TỔNG THỂ

```
Thời gian    │ Giai đoạn    │ Mốc quan trọng
─────────────┼──────────────┼────────────────────────────────────
0–20 phút    │ NEW PLAYER   │ Rebirth đầu tiên, học cơ chế
20–60 phút   │ EARLY        │ Damage cấp 5-8, PvP đầu tiên
1–3 giờ      │ MID          │ R5-R10, vào Desert, pet Rare đầu
3–8 giờ      │ LATE         │ R15-R25, IceZone, 10 skill/hr
8–20 giờ     │ END GAME     │ R30+, mọi upgrade cấp 20+
20+ giờ      │ PRESTIGE     │ MAX upgrade, pet Legendary đủ bộ
```

---

## 8. BẢNG THAY ĐỔI CONFIG — SẴN SÀNG APPLY

| File | Key | Giá trị cũ | Giá trị mới | Lý do |
|---|---|---|---|---|
| Config.luau | `EggCostGold` | 500 | **7,500** | 20 egg/hr tại IceZone |
| Config.luau | `SkillScrollCost` | 1,000 | **15,000** | 10 skill/hr tại IceZone |
| Config.luau | `Shout.VocalPointsPerUse` | 0.2 | **4** | Rebirth 21 phút |
| Config.luau | `Shout.VocalPointsPerHit` | 1 | **10** | Thưởng combat |
| Config.luau | `Shout.MaxForce` | 45 | **150** | Progression có ý nghĩa |
| Config.luau | `Shout.BaseForce` | 15 | **8** | Cân bằng formula mới |
| Config.luau | `damage_1.CostScaling` | 1.5 | **1.30** | MaxLevel=30 đạt được |
| Config.luau | `damage_1.MaxLevel` | 100 | **30** | Thực tế |
| Config.luau | `health_1.CostScaling` | 1.5 | **1.30** | Đồng bộ |
| Config.luau | `health_1.MaxLevel` | 100 | **30** | Đồng bộ |
| Config.luau | `armor_1.BaseCost` | 600 | **80** | Cân bằng với damage |
| Config.luau | `armor_1.CostScaling` | 1.6 | **1.30** | Đồng bộ |
| Config.luau | `armor_1.MaxLevel` | 100 | **30** | Đồng bộ |
| Config.luau | `PetSellPrices.Common` | 15 | **375** | 5% giá trứng mới |
| Config.luau | `PetSellPrices.Rare` | 50 | **1,125** | 15% giá trứng mới |
| Config.luau | `PetSellPrices.Epic` | 125 | **3,000** | 40% giá trứng mới |
| Config.luau | `PetSellPrices.Legendary` | 500 | **7,500** | = 1 lần quay |
| Config.luau | `SkillSellPrices.Common` | 50 | **750** | 5% giá scroll mới |
| Config.luau | `SkillSellPrices.Rare` | 200 | **2,250** | 15% |
| Config.luau | `SkillSellPrices.Epic` | 500 | **6,000** | 40% |
| Config.luau | `SkillSellPrices.Legendary` | 1,000 | **15,000** | = 1 lần quay |
| ShoutService.luau | `getTotalAttack()` pet logic | product mode | **sum + cap ×3** | Fix bug, chặn R10 exploit |
| PetService.luau | passive VP pet cap | không có | **cap ×2.5** | Đồng nhất với combat |

---

## 9. CẢNH BÁO TRIỂN KHAI

**Người chơi cũ:** Gold hiện tại cần scale. Thêm vào `DataService.loadData()`:
```lua
-- Migration: scale gold theo tỷ lệ tăng giá (15x trung bình)
if data.JoinDate < PATCH_TIMESTAMP then
    data.Gold = data.Gold * 15
end
```

**Playtest checklist:**
- [ ] Xác nhận IceZone ~ 10 skill pulls/hr thực tế (không phải lý thuyết)
- [ ] Kiểm tra pet cap ×3 không làm mất cảm giác mạnh khi equip Legendary
- [ ] Verify formula knockback ở early/mid/late game (ATK cấp 5, 15, 30)
- [ ] VoidRealm shop chưa có → tắt zone cho đến khi có giải pháp gold sink

---

*Tất cả số liệu được tính từ Config.luau hiện tại. Constraint cốt lõi: 10 skill pulls/giờ tại IceZone.*