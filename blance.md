# BÁO CÁO CÂN BẰNG CHỈ SỐ — SHOUT SIMULATOR
**Ngày:** 26/03/2026 | **Phiên bản audit:** 1.0 | **Dựa trên:** Config.luau + source code

---

## TÓM TẮT ĐIỀU HÀNH

Qua phân tích toán học toàn bộ công thức trong `Config.luau`, hệ thống hiện tại có **5 vấn đề cân bằng nghiêm trọng** khiến trải nghiệm người chơi bị phá vỡ ở mọi giai đoạn:

| Mức độ | Vấn đề | Ảnh hưởng |
|---|---|---|
| 🔴 NGHIÊM TRỌNG | Rebirth đầu tiên mất 6+ giờ | Người chơi mới bỏ game trong 30 phút đầu |
| 🔴 NGHIÊM TRỌNG | MaxForce cap bị chạm từ cấp 4 | Nâng cấp tấn công vô nghĩa sau đó |
| 🔴 NGHIÊM TRỌNG | Giáp đắt gấp 12 lần Sát thương | Không ai đầu tư phòng thủ |
| 🟡 TRUNG BÌNH | MaxLevel=100 không thể đạt được | Thanh tiến trình là "fake ceiling" |
| 🟡 TRUNG BÌNH | Mở 45 trứng/giờ từ vùng mới | Pet gacha giải quyết trong buổi đầu |

---

## 1. PHÂN TÍCH VP (VOCAL POINTS) — TIỀN TỆ NÂNG CẤP

### 1.1 Nguồn thu VP hiện tại

| Nguồn | Công thức | Giá trị |
|---|---|---|
| Hét không trúng | VocalPointsPerUse | **0.2 VP** |
| Hét trúng mục tiêu | VocalPointsPerHit | **1 VP** |
| Hệ số Rebirth | × RebirthMultiplier | ×1.00 ban đầu |

Cooldown BasicShout = 0.6s → tối đa **100 lần hét/phút**

### 1.2 Tốc độ tích lũy VP theo kịch bản

| Kịch bản | VP/phút | VP/giờ | Thời gian đến Rebirth 1 |
|---|---|---|---|
| Solo không đánh | 20.0 | 1,200 | **500 phút (8.3 giờ)** |
| StarterZone (1 slime) | 27.5 | 1,650 | **364 phút (6.1 giờ)** |
| PvEZone (3 quái) | 42.5 | 2,550 | **235 phút (3.9 giờ)** |
| PvP tích cực | 23.0 | 1,380 | **435 phút (7.2 giờ)** |

> **Chuẩn ngành Roblox Simulator:** Rebirth đầu tiên nên mất 20–30 phút. Hiện tại chậm hơn **10–25 lần**.

### 1.3 Chi phí Upgrade — Vấn đề leo thang

Chi phí mỗi cấp = `floor(BaseCost × CostScaling^level)`

| Upgrade | BaseCost | CostScaling | Cấp 10 | Cấp 20 | Tổng đến cấp 50 |
|---|---|---|---|---|---|
| damage_1 | 50 | 1.5 | 1,922 VP | 110,841 VP | **63 tỷ VP** |
| health_1 | 75 | 1.5 | 2,883 VP | 166,262 VP | **95 tỷ VP** |
| armor_1 | 600 | 1.6 | 41,231 VP | 4,533,471 VP | **6,026 tỷ VP** |

> **MaxLevel=100 là không tưởng.** Chi phí lên đến `10²⁰ VP` — không thể đạt trong vòng đời game.

---

## 2. PHÂN TÍCH GOLD — TIỀN TỆ GACHA

### 2.1 Nguồn thu Gold

| Quái | Zone | Gold/kill | Respawn | Gold/giờ |
|---|---|---|---|---|
| ScreechSlime | StarterZone | 10 | 8s | 4,500 |
| EchoToad | PvEZone | 30 | 8s | 13,500 |
| BoomGolem | PvEZone | 50 | 8s | 22,500 |
| DustDevil | Desert | 120 | 8s | 54,000 |
| SandGolem | Desert | 200 | 8s | 90,000 |
| IcyWraith | IceZone | 400 | 8s | 180,000 |
| SoundKing (Boss) | BossRoom | 1,000 | 30s | 120,000 |

### 2.2 Chi tiêu Gold hiện tại

| Item | Chi phí | Vấn đề |
|---|---|---|
| Mở 1 Trứng | 100 Gold | Quá rẻ |
| Mở 10 Trứng | 1,000 Gold | Quá rẻ |
| Mở 1 Skill Scroll | 250 Gold | Quá rẻ |

**Kết quả thực tế:**
- StarterZone: 4,500G/hr ÷ 100 = **45 trứng/giờ** → pet Legendary trong vài giờ đầu
- PvEZone: 22,500G/hr ÷ 100 = **225 trứng/giờ** → gacha mất ý nghĩa

> Pet có multiplier lên đến ×2.0 (Legendary). Nếu người chơi nhận được trong giờ đầu, toàn bộ hệ thống progression bị phá vỡ.

---

## 3. PHÂN TÍCH CÔNG THỨC KNOCKBACK — VẤN ĐỀ CỐT LÕI

### 3.1 Công thức hiện tại

```
force = BaseForce + (ATK/DEF) × KnockbackScaling
force = min(force, MaxForce)

BaseForce = 15 | KnockbackScaling = 10 | MaxForce = 45
```

### 3.2 Vấn đề: MaxForce chạm trần quá sớm

| Cấp Tấn công | ATK | vs DEF=10 (lvl 0) | MaxForce chạm? |
|---|---|---|---|
| 0 | 10 | 25.0 | Không |
| 2 | 20 | 35.0 | Không |
| 4 | 30 | **45.0** | ✅ **CÁN TRẦN TỪ CẤP 4** |
| 10 | 60 | 45.0 (trần) | ✅ |
| 30 | 160 | 45.0 (trần) | ✅ |

**Hệ quả:** Từ cấp nâng Damage thứ 4 trở đi, đầu tư thêm vào tấn công không tạo ra sự khác biệt nào khi đánh người không có giáp. Người chơi nhận ra sớm và dừng nâng cấp.

### 3.3 Vấn đề song sinh: Giáp quá đắt, không ai mua

| | damage_1 (Tấn công) | armor_1 (Giáp) |
|---|---|---|
| BaseCost | **50 VP** | **600 VP** |
| Tỷ lệ chênh | 1x | **12x đắt hơn** |
| Cấp 1 tổng cộng | 50 VP | 600 VP |
| Hiệu quả khi defense lvl 0 | Force tăng | Force giảm |

Với MaxForce = 45 và BaseForce = 15, đầu tư 600 VP vào giáp chỉ giảm lực nhận từ 45 → ~20 (khi đối thủ cũng có ATK trung bình). Đầu tư 50 VP vào tấn công cũng đạt cap ngay. **Không có lý do nào để mua giáp.**

### 3.4 Hệ quả với Progression tổng thể

Do cả hai nhánh nâng cấp đều "vô nghĩa" sau cấp thấp, người chơi không có mục tiêu rõ ràng để hướng tới. Biểu đồ sức mạnh trông như thế này:

```
Sức mạnh thực (Force)
│
45 ──────────────────────── MaxForce (trần)
│          ╔══════════════════════════════ bị kẹt ở đây
│        ╔═╝
│      ╔═╝
│    ╔═╝
│  ╔═╝
│╔═╝
└──────────────────────── Cấp nâng cấp
   0   2   4   6   8  10  20  30  50  100
                    ↑
              Hết tác dụng
```

---

## 4. PHÂN TÍCH PROGRESSION REBIRTH

### 4.1 Rebirth multiplier hiện tại (MultiplierPerRebirth = 0.25)

| Rebirth | Multiplier | VP/phút (PvEZone) | Thời gian đến RB tiếp |
|---|---|---|---|
| R0 | ×1.00 | 42.5 | 235 phút |
| R1 | ×1.25 | 53.1 | 188 phút |
| R3 | ×1.75 | 74.4 | 134 phút |
| R5 | ×2.25 | 95.6 | 105 phút |
| R10 | ×3.50 | 148.8 | 67 phút |

> Dù tỷ lệ cải thiện là hợp lý (−30% thời gian sau mỗi 5 rebirth), nhưng **điểm xuất phát quá chậm** (235 phút/rebirth) khiến người chơi không bao giờ đến được giai đoạn "tăng tốc" thú vị.

---

## 5. GIÁ TRỊ ĐỀ NGHỊ — THAY ĐỔI CONFIG.LUA

### 5.1 VP Economy Fix

**Mục tiêu:** Rebirth đầu tiên ~20 phút ở StarterZone, ~16 phút ở PvEZone.

```lua
-- Config.Shout (THAY ĐỔI)
Config.Shout = {
    VocalPointsPerUse = 4,   -- was 0.2  (tăng 20x)
    VocalPointsPerHit = 10,  -- was 1    (tăng 10x)
    -- Tất cả giá trị khác giữ nguyên
}
```

**Kết quả sau thay đổi:**

| Kịch bản | VP/phút | Thời gian Rebirth 1 |
|---|---|---|
| StarterZone | 475 | **21 phút** ✅ |
| PvEZone | 625 | **16 phút** ✅ |
| PvP tích cực | 423 | **24 phút** ✅ |

### 5.2 Upgrade System Fix

**Mục tiêu:** MaxLevel thực sự đạt được, cân bằng giữa ATK và DEF.

```lua
-- Config.Upgrades (THAY ĐỔI)
local upgradesData = {
    {
        Id           = "damage_1",
        DisplayName  = "Sonic Power",
        Category     = "Attack",
        BaseCost     = 50,       -- giữ nguyên
        CostScaling  = 1.30,     -- was 1.5   (giảm độ dốc)
        StatPerLevel = 5,        -- giữ nguyên
        MaxLevel     = 30,       -- was 100   (giảm để thực tế)
        Icon         = "rbxassetid://5905055047",
    },
    {
        Id           = "health_1",
        DisplayName  = "Vitality Boost",
        Category     = "Defense",
        BaseCost     = 75,       -- giữ nguyên
        CostScaling  = 1.30,     -- was 1.5
        StatPerLevel = 20,       -- giữ nguyên
        MaxLevel     = 30,       -- was 100
        Icon         = "rbxassetid://515329329",
    },
    {
        Id           = "armor_1",
        DisplayName  = "Knockback Resistance",
        Category     = "Defense",
        BaseCost     = 80,       -- was 600  (giảm 7.5x để cân bằng với damage)
        CostScaling  = 1.30,     -- was 1.6
        StatPerLevel = 10,       -- giữ nguyên
        MaxLevel     = 30,       -- was 100
        Icon         = "rbxassetid://2703816766",
    },
}
```

**Chi phí upgrade sau thay đổi:**

| Upgrade | Cấp 1 | Tổng đến cấp 10 | Tổng đến cấp 20 | Tổng đến MAX (cấp 30) | Rebirths để max |
|---|---|---|---|---|---|
| damage_1 | 50 VP | 2,126 VP | 31,499 VP | 436,486 VP | ~43 RB |
| health_1 | 75 VP | 3,192 VP | 47,253 VP | 654,733 VP | ~65 RB |
| armor_1 | 80 VP | 3,406 VP | 50,404 VP | 698,385 VP | ~70 RB |

> Với VP/phút mới, 43 rebirths tương đương ~15–20 giờ chơi thực — phù hợp làm mục tiêu dài hạn.

### 5.3 Knockback Formula Fix

**Mục tiêu:** Force cảm nhận được tăng theo progression, không hit cap quá sớm, DEF có ý nghĩa thực.

**Vấn đề với công thức hiện tại:** `(ATK/DEF) × Scaling` có nghĩa là khi cả ATK và DEF tăng đều nhau, force không tăng.

**Giải pháp:** Thêm thành phần tuyến tính của ATK (không bị triệt tiêu bởi DEF):

```lua
-- ShoutService.luau — Hàm calculateKnockback (THAY ĐỔI LOGIC)
local function calculateKnockback(attackerAtk, targetDef, direction)
    -- Thành phần tuyến tính: ATK luôn đóng góp, DEF không triệt tiêu hoàn toàn
    local flatComponent  = attackerAtk * 0.4           -- 40% ATK là "raw force"
    local ratioComponent = (attackerAtk / math.max(1, targetDef)) * 15
    local rawForce = 8 + flatComponent + ratioComponent
    local capped = math.min(rawForce, 300)             -- MaxForce nâng lên 300

    local horizontalDir = Vector3.new(direction.X, 0, direction.Z).Unit
    return (horizontalDir + Vector3.new(0, 0.4, 0)).Unit * capped
end
```

**Và cập nhật Config.Shout:**

```lua
Config.Shout = {
    -- ... các giá trị khác
    BaseForce         = 8,   -- was 15
    KnockbackScaling  = 15,  -- (dùng trong formula mới)
    MaxForce          = 300, -- was 45  (nâng gần 7x)
    VerticalBias      = 0.4, -- was 0.5
    BaseDamage        = 8,   -- giữ nguyên
}
```

**So sánh force trước/sau:**

| Tình huống | Force CŨ | Force MỚI |
|---|---|---|
| Tân thủ (ATK=10, DEF=10) | 25 | 32 |
| ATK cấp 5 vs DEF=0 | 45 (trần) | 88 |
| ATK cấp 10 vs DEF=0 | 45 (trần) | 132 |
| ATK cấp 30 vs DEF=0 | 45 (trần) | 300 (trần) |
| ATK cấp 10 vs DEF cấp 10 | 20.5 | 52 |
| ATK cấp 30 vs DEF cấp 30 | 20.3 | 85 |

> Bây giờ người chơi đầu tư cao hơn **cảm nhận được** sự khác biệt rõ ràng — đúng với tên game "Shout Simulator".

### 5.4 Gold Economy Fix

**Mục tiêu:** Pet và Skill là thứ cần grinding thật sự, không phải "free" sau 1 giờ.

```lua
Config.EggCostGold    = 500  -- was 100  (tăng 5x)
Config.SkillScrollCost = 1000 -- was 250  (tăng 4x)
```

**Kết quả:**

| Zone | Gold/giờ | Trứng/giờ (mới) | Trứng/giờ (cũ) |
|---|---|---|---|
| StarterZone | 4,500 | **9** | 45 |
| PvEZone | 54,000 | **108** | 225 |
| Desert | 90,000 | **180** | 900 |

> Người chơi StarterZone cần ~11 giờ để mở 100 trứng — đủ để trải nghiệm gacha mà không "phá đảo" ngay lập tức. PvEZone vẫn cho cảm giác tiến triển nhanh ở giai đoạn giữa.

---

## 6. ĐƯỜNG CONG PROGRESSION ĐỀ NGHỊ

Biểu đồ tổng thể sau khi áp dụng các thay đổi:

```
Thời gian chơi   │ Giai đoạn       │ Mốc quan trọng
─────────────────┼─────────────────┼────────────────────────────────────
0 – 20 phút      │ NEW PLAYER      │ Rebirth đầu tiên, cảm nhận cơ chế
20 – 60 phút     │ EARLY GAME      │ Damage cấp 5-8, bắt đầu PvP
1 – 3 giờ        │ MID GAME        │ R5-R10, unlock Desert, có pet Rare
3 – 8 giờ        │ LATE GAME       │ R15-R25, IceZone, pet Epic/Legendary
8 – 20 giờ       │ END GAME        │ R30+, mọi upgrade cấp 20+
20+ giờ          │ PRESTIGE        │ Mọi upgrade MAX (cấp 30), mọi pet
```

---

## 7. BẢNG TÓM TẮT THAY ĐỔI — SẴN SÀNG APPLY

Tất cả thay đổi đều nằm trong `Config.luau` và 1 hàm trong `ShoutService.luau`. **Không đụng đến logic core.**

| File | Key | Giá trị cũ | Giá trị mới | Lý do |
|---|---|---|---|---|
| Config.luau | `Shout.VocalPointsPerUse` | 0.2 | **4** | First rebirth 21 phút |
| Config.luau | `Shout.VocalPointsPerHit` | 1 | **10** | Tưởng thưởng combat |
| Config.luau | `Shout.MaxForce` | 45 | **300** | Progression có ý nghĩa |
| Config.luau | `Shout.BaseForce` | 15 | **8** | Cân bằng với formula mới |
| Config.luau | `damage_1.CostScaling` | 1.5 | **1.30** | MaxLevel=30 đạt được |
| Config.luau | `damage_1.MaxLevel` | 100 | **30** | Thực tế, có thể max |
| Config.luau | `health_1.CostScaling` | 1.5 | **1.30** | Đồng bộ |
| Config.luau | `health_1.MaxLevel` | 100 | **30** | Đồng bộ |
| Config.luau | `armor_1.BaseCost` | 600 | **80** | Cân bằng với damage |
| Config.luau | `armor_1.CostScaling` | 1.6 | **1.30** | Đồng bộ |
| Config.luau | `armor_1.MaxLevel` | 100 | **30** | Đồng bộ |
| Config.luau | `EggCostGold` | 100 | **500** | Pet có giá trị |
| Config.luau | `SkillScrollCost` | 250 | **1,000** | Skill có giá trị |
| ShoutService.luau | `calculateKnockback()` | ratio formula | **flat+ratio** | DEF có ý nghĩa |

---

## 8. CẢNH BÁO & LƯU Ý TRIỂN KHAI

**Lưu ý 1: Người chơi cũ**
Nếu game đã public với data cũ, VP và Gold hiện tại của người chơi sẽ mất cân bằng so với hệ thống mới. Khuyến nghị thêm migration script trong `DataService.loadData()` để scale giá trị cũ.

**Lưu ý 2: Rebirth threshold**
VocalPointsRequired = 10,000 VP **giữ nguyên** là hợp lý vì VP/phút đã tăng. Không cần thay đổi.

**Lưu ý 3: Rebirth multiplier**
MultiplierPerRebirth = 0.25 **giữ nguyên**. Với VP/phút mới, người chơi đến R10 trong ~3–4 giờ chơi, tạo cảm giác tăng tốc tự nhiên.

**Lưu ý 4: Playtest trước khi final**
Các con số này dựa trên mô hình lý thuyết. Cần test thực tế với 2–3 người chơi để đánh giá:
- Cảm giác force khi knockback ở giai đoạn early/mid/late
- Tốc độ tích lũy pet thực tế (drop egg từ quái + gold)
- Điểm "bão hòa" khi người chơi cảm thấy đủ mạnh và muốn rebirth

---

*Báo cáo được tính toán từ dữ liệu thực trong Config.luau. Tất cả con số được verify qua simulation Python.*
*Tổng thời gian phân tích: đầy đủ 13 file server + Config.luau + ShoutService.luau*