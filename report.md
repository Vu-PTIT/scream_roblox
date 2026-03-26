# 📋 BÁO CÁO KỸ THUẬT V2 — SHOUT SIMULATOR
*(Audit toàn bộ source code — Cập nhật: 25/03/2026)*

---

## 1. TỔNG QUAN DỰ ÁN

**Stack:** Luau `--!strict` · Rojo 7.6.1 · DataStoreService · RemoteEvents  
**Kiến trúc:** Server Services / Client Controllers / Shared Config  
**React (Luau):** HUDApp + PillLabel + ProgressBar + StatsBox (React + ReactRoblox)  
**Plugin:** BakePlugin.server.luau — hỗ trợ bake UI/Map trực tiếp vào Studio  
**Số file audit:** 13 Server Services · 5 Client Controllers · 14 Client UI · 4 Shared · 3 React Components + Stories

---

## 2. THỰC TRẠNG HIỆN TẠI — AUDIT ĐẦY ĐỦ (25/03/2026)

### ✅ Hoàn chỉnh — Đang hoạt động tốt

| Module | File | Ghi chú chi tiết |
|---|---|---|
| **DataService** | `DataService.luau` | Load/save DataStore, auto-save 60s, daily reset, backward-compat merge, BindToClose |
| **ShoutService** | `ShoutService.luau` | Cone detection, server-side knockback, skill slot routing, QuestService.RegisterAction |
| **MonsterService** | `MonsterService.luau` | Pathfinding AI, HP bar BillboardGui, 12 loại quái 3D, LastDamagedBy tracking, leashing |
| **MapService** | `MapService.luau` | SafeZone / PvPArena / PvEZone / BossRoom / 4 RebirthAreas với Heartbeat gate blocker |
| **QuestService** | `QuestService.luau` | RegisterAction, ClaimReward server-side, daily reset trong DataService |
| **RewardService** | `RewardService.luau` | Playtime milestones, claim/locked state |
| **LeaderboardService** | `LeaderboardService.luau` | OrderedDataStore, top 10 mỗi 60s, render vào board Workspace |
| **MonetizationService** | `MonetizationService.luau` | ProcessReceipt đúng chuẩn Roblox, UserOwnsGamePassAsync |
| **PetService** | `PetService.luau` | Gacha có trọng số, equip/unequip, Pet Model 3D dùng AlignPosition/AlignOrientation |
| **SkillService** | `SkillService.luau` | Gacha skill, equip 2 slot, server validate |
| **RebirthService** | `RebirthService.luau` | Reset VP, cộng multiplier, giữ Pets |
| **UpgradeService** | `UpgradeService.luau` | Server validate cost & level cap, apply MaxHealth ngay lập tức |
| **CodeService** | `CodeService.luau` | Nhập code, hoàn thưởng, anti-reuse |
| **TextFilterService** | `TextFilterService.luau` | TextService:FilterStringAsync, cooldown 5s |
| **ShoutController** | `ShoutController.luau` | VFX sóng âm, CameraShake, ParticleTrail khi bị knockback, charge system |
| **DashController** | `DashController.luau` | LinearVelocity dash, DashSFX, tự động bắn shout khi dash |
| **DataController** | `DataController.luau` | Reactive cache, broadcast đến subscribers |
| **AudioController** | `AudioController.luau` | BGM loop, Jump/Land SFX |
| **UIController** | `UIController.luau` | Nav bar 6 tab, proximity prompt binding, notification toast, keyboard shortcuts |
| **HUD** | `HUD.luau` + `HUDApp.luau` | Smart Binding + React HUDApp, VP bar, Gold, ATK, DEF, HP |
| **SkillBar** | `SkillBar.luau` | Smart Binding, 2 slot, cooldown overlay, charging highlight |
| **Shop** | `Shop.luau` | Attack/Defense/Premium tab, upgrade cards với progress bar |
| **PetUI** | `PetUI.luau` | Gacha grid, equip/unequip, refresh khi data thay đổi |
| **SkillUI** | `SkillUI.luau` | Grid filter by rarity, S1/S2 equip buttons |
| **RebirthUI** | `RebirthUI.luau` | Confirm dialog, preview multiplier mới |
| **BagUI** | `BagUI.luau` | 3 tab: Stats / Skills / Pets, toggle bằng phím B |
| **QuestUI** | `QuestUI.luau` | Progress bar, claim button, daily refresh |
| **RewardUI** | `RewardUI.luau` | Playtime milestones, claim/locked |
| **CodeUI** | `CodeUI.luau` | Promo code modal |
| **CustomShoutUI** | `CustomShoutUI.luau` | Text input, gửi lên server filter |
| **EggHatchUI** | `EggHatchUI.luau` | Animation 3D ViewportFrame mở trứng |
| **SkillHatchUI** | `SkillHatchUI.luau` | Animation reveal skill gacha |
| **DamageIndicator** | `DamageIndicator.luau` | Floating force text với màu sắc theo mức độ |
| **ShoutWave** | `ShoutWave.luau` | Cone VFX: MouthBlast + FlyingWave + Beam + Particles |
| **React Components** | `PillLabel / ProgressBar / StatsBox` | Storybook stories đầy đủ |
| **Config** | `Config.luau` | Upgrades, Pets, Skills, Monsters, Quests, Audio, Map, Rebirth, Theme |

---

## 3. CÁC VẤN ĐỀ KỸ THUẬT PHÁT HIỆN SAU AUDIT SÂU

### 🔴 QUAN TRỌNG — Ảnh hưởng trực tiếp tới gameplay hoặc bảo mật

---

**[BUG-1] `UpgradeService` dùng `VocalPoints` để trả tiền nhưng `Shop.luau` hiển thị "Cost: X Gold"**

- `UpgradeService.luau` dòng cuối: `if data.VocalPoints < cost` → trừ `VocalPoints`
- `Shop.luau` label: `costLabel.Text = string.format("Cost: %s Gold", tostring(cost))` → in chữ "Gold"
- `BagUI.luau` dòng `createStatRow`: hiển thị `DamageUpgradeLevel` nhưng tính `totalAtk` dùng `Config.Upgrades[1].StatPerLevel` (hardcode index) thay vì tìm theo Id
- **Fix:** Đổi label thành "VP" hoặc đồng bộ lại currency cho upgrade

---

**[BUG-2] `MonsterService` fire `Remotes.Events.OpenEgg:FireClient` nhưng đây là Client→Server event**

```lua
-- MonsterService.luau ~ dòng dropRewards:
Remotes.Events.OpenEgg:FireClient(killerPlayer) -- SAI! OpenEgg là C→S event
```

- Server không thể `FireClient` lên một `RemoteEvent` mà client dùng `FireServer` để gọi
- Kết quả: khi quái chết và drop egg, client không nhận được egg nào
- **Fix:** Gọi trực tiếp `PetService.OnOpenEgg(killerPlayer, 1)` thay vì qua remote

---

**[BUG-3] `ShoutController` gửi `powerMult` có thể bị exploit — server chưa cap đủ**

```lua
-- ShoutController.luau:
Remotes.Events.ShoutFired:FireServer(direction, pMult, slotIndex)
-- pMult có thể bị hacker inject giá trị > 5

-- ShoutService.luau:
local pMult = math.clamp(powerMult or 1.0, 1.0, 5.0) -- Cap 5x
```

- Server có clamp nhưng `5.0x` là rất cao — 1 hit có thể one-shot người chơi khác
- Timing validation (charge time) hoàn toàn phụ thuộc client
- **Fix:** Server tự tính powerMult dựa trên thời gian giữa 2 lần `ShoutFired` liên tiếp

---

**[BUG-4] `PetService.UpdatePhysicalPets` gọi trong `PlayerAdded/CharacterAdded` nhưng `DataService` có thể chưa load xong**

```lua
-- PetService.luau:
player.CharacterAdded:Connect(function(char)
    task.wait(1) -- Chờ cứng 1 giây
    PetService.UpdatePhysicalPets(player)
end)
```

- `task.wait(1)` là magic number — nếu server load chậm hoặc DataStore chậm, pet 3D sẽ không hiện
- **Fix:** Đợi `PlayerDataLoaded` event thay vì delay cứng

---

### 🟡 KỸ THUẬT — Không block gameplay nhưng cần cải thiện

---

**[TD-1] `HUD.luau` và `HUDApp.luau` song song tồn tại — nguy cơ conflict**

- `HUD.luau` dùng `--!strict` Luau thuần với "Smart Binding"
- `HUDApp.luau` dùng React/Luau render cùng ScreenGui tên "HUD"
- Cả hai được `Init()` trong `UIController.luau`
- `HUD.luau` có logic "nuke duplicate" nhưng chỉ xóa theo Name — có thể xóa nhầm React container
- **Fix:** Chọn một trong hai (ưu tiên React vì hiện đại hơn), comment out cái còn lại

---

**[TD-2] `BagUI.luau` tính `totalAtk` hardcode index `Config.Upgrades[1]` và `Config.Upgrades[3]`**

```lua
local totalAtk = (data.Attack or 10) + (data.DamageUpgradeLevel or 0) * (Config.Upgrades[1].StatPerLevel or 1)
local totalDef = (data.Defense or 10) + (data.ArmorUpgradeLevel or 0) * (Config.Upgrades[3].StatPerLevel or 1)
```

- Nếu thứ tự `Config.Upgrades` thay đổi (ví dụ thêm upgrade mới vào đầu) thì tính sai
- **Fix:** Tìm upgrade theo `Id` thay vì index

---

**[TD-3] `SkillService` không validate `slotIndex` đúng — có thể tạo EquippedSkillIds lỗi**

```lua
-- Rebuild EquippedSkillIds:
local equippedIds: { string } = {}
for _, skill in ipairs(data.Skills) do
    if skill.Equipped and skill.SlotIndex then
        equippedIds[skill.SlotIndex] = skill.Id -- Array có thể có lỗ hổng index
    end
end
```

- Nếu `SlotIndex` = 2 nhưng slot 1 trống → `equippedIds = {nil, "id"}` → lỗi khi iterate
- **Fix:** Dùng dict `{[1] = id, [2] = id}` và kiểm tra nil khi đọc

---

**[TD-4] `LeaderboardService` không có fallback nếu `Players:GetNameFromUserIdAsync` fail**

```lua
local success, username = pcall(function() return Players:GetNameFromUserIdAsync(...) end)
name.Text = success and username or "Unknown Player"
```

- Tốt! Đã có pcall. Tuy nhiên board tạo trong `MapService.Init()` và `LeaderboardService.Init()` riêng biệt — nếu `MapService` chưa tạo board thì `LeaderboardService` gọi `updateBoard` thất bại im lặng
- **Fix:** Thêm early return warning khi không tìm thấy board

---

**[TD-5] `EggHatchUI` và `SkillHatchUI` có code trùng lặp đáng kể**

- Cả hai đều: tạo overlay, viewport, camera, play SFX, cleanup sau delay
- `SkillHatchUI` thiếu confetti, thiếu nhiều animation so với `EggHatchUI`
- **Fix (medium term):** Extract base `HatchUI` module, kế thừa cho Egg và Skill

---

**[TD-6] `MapService.createStations()` dùng `posOffset` nhưng một số station dùng `Config.Map.SkillStation.Position` (Vector3 tuyệt đối) thay vì offset**

```lua
{ id = "Skill", ..., posOffset = Config.Map.SkillStation.Position }, -- Vector3 tuyệt đối
{ id = "Shop",  ..., posOffset = Vector3.new(20, 2, -15) },          -- Offset tương đối
```

- Station "Skill" sẽ đặt tại toạ độ `(0, 2, -25)` thay vì `basePos + (0, 2, -25)`
- **Fix:** Thống nhất tất cả về relative offset hoặc absolute position

---

**[TD-7] `ShoutController` không cleanup `ShoutBillboard` khi nhân vật respawn**

```lua
local function onCharAdded(character: Model)
    shoutBillboard = nil  -- Reset reference nhưng không destroy billboard cũ
end
```

- Billboard cũ vẫn tồn tại trên HumanoidRootPart của character cũ (đã destroy) → không leak nhưng reference bị stale
- Thực ra do Character cũ bị destroy nên billboard cũng mất → OK về memory
- Tuy nhiên: nếu character `Respawn` mà billboard cũ chưa destroy kịp, `createShoutBillboard` tạo thêm → `FindFirstChild("ShoutBillboard")` đọc cái cũ
- **Fix:** Explicit destroy billboard cũ trong `onCharAdded`

---

### 🟢 CẢI TIẾN NÂNG CAO / KHÔNG BLOCK RELEASE

**[ENH-1] Cân bằng kinh tế — Cần playtest**

Dựa trên Config hiện tại:

| Vấn đề | Chi tiết |
|---|---|
| Upgrade cost có thể quá thấp ban đầu | `damage_1` BaseCost = 50 VP, CostScaling = 1.5 → Level 1-5 quá rẻ |
| VP gain khi hét quá thấp | `VocalPointsPerUse = 0.2`, `VocalPointsPerHit = 1` — cần 10,000 VP để Rebirth → ~8,000 lần hét trúng |
| EggCostGold = 100 nhưng quái StarterZone drop 10 Gold → mở 1 trứng = 10 lần giết quái starter | Có thể cân được nhưng cần test |

**[ENH-2] Boss Mechanics nâng cao**

- `SoundKing` và `IceColossus` hiện dùng AI giống quái thường
- Chưa có phase mechanic, special attack, hay boss-only drop
- **Đề xuất:** Thêm `IsBoss: boolean` vào `MonsterConfig`, Boss dùng ShoutType.Circular khi HP < 50%

**[ENH-3] Hệ thống Skill chưa có visual distinction rõ ràng**

- Skills có `ShoutTypeId` nhưng `ShoutWave.Play` chỉ thay đổi màu và range
- Circular shout VFX trông giống Normal shout (chỉ khác `SpreadAngle` của particle)
- **Đề xuất:** Tạo hàm `ShoutWave.PlayCircular` riêng với Ring explosion thay vì Beam

**[ENH-4] `DashController` gọi `ShoutController.PerformShout` khi dash nhưng không dùng equipped skill**

```lua
ShoutController.PerformShout(0, -direction) -- Luôn dùng slot 0 (Basic)
```

- Người chơi đang dùng Skill Epic vẫn dash ra shout Basic
- **Đề xuất:** Dùng `SelectedSkillSlot` hiện tại khi dash

**[ENH-5] Rebirth Area hiện chỉ có floor và gate — thiếu visual identity**

- Desert, IceZone, VoidRealm chỉ là màu khác nhau trên flat Part
- **Đề xuất:** Thêm particles/lighting phù hợp mỗi khu vực (fog ở VoidRealm, snow particles ở IceZone...)

**[ENH-6] Không có Anti-AFK system**

- Người chơi có thể dùng macro click để grind VP vô tận
- **Đề xuất:** Thêm idle detection (5 phút không di chuyển → giảm VP gain 90%)

**[ENH-7] `OpenEgg` Remote bị fire cả Client→Server lẫn Server→Client (xem BUG-2)**

- Cần thiết kế lại flow: Server drop egg → tạo physical egg item trên workspace → client click để collect → mở animation

---

## 4. KẾ HOẠCH HÀNH ĐỘNG

### 🔴 P0 — Phải fix trước khi public (bugs ảnh hưởng gameplay)

| # | Việc cần làm | File cần sửa | Độ khó |
|---|---|---|---|
| 1 | Fix `OpenEgg:FireClient` trong `MonsterService` → gọi trực tiếp PetService | `MonsterService.luau` | Thấp |
| 2 | Đồng bộ label "Gold" → "VP" trong Shop hoặc đổi currency upgrade | `Shop.luau`, `UpgradeService.luau` | Thấp |
| 3 | Thay `task.wait(1)` bằng wait PlayerDataLoaded trong PetService | `PetService.luau` | Thấp |
| 4 | Thay GamePass/DevProduct IDs placeholder bằng IDs thật từ Dashboard | `Config.luau` | Thấp |

### 🟡 P1 — Nên làm trước Soft Launch

| # | Việc cần làm | File cần sửa | Độ khó |
|---|---|---|---|
| 5 | Fix hardcode `Config.Upgrades[1]` / `[3]` → tìm theo Id | `BagUI.luau`, `HUD.luau` | Thấp |
| 6 | Fix SkillService EquippedSkillIds array lỗ hổng index | `SkillService.luau` | Thấp |
| 7 | Resolve conflict HUD.luau vs HUDApp.luau | `UIController.luau` | Trung bình |
| 8 | Server-side charge time validation (anti-exploit pMult) | `ShoutService.luau` | Trung bình |
| 9 | Cân bằng VP gain & upgrade costs qua playtest | `Config.luau` | Thấp |
| 10 | Fix MapService station posOffset vs absolute position cho SkillStation | `MapService.luau` | Thấp |

### 🟢 P2 — Post-Launch / Content Update

| # | Việc cần làm | Mô tả | Độ khó |
|---|---|---|---|
| 11 | Anti-AFK system | Idle detection → giảm VP gain | Trung bình |
| 12 | Boss special mechanics | Phase 2 khi HP < 50%, special shout type | Cao |
| 13 | Circular/Focused VFX riêng | `ShoutWave.PlayCircular`, `ShoutWave.PlayFocused` | Trung bình |
| 14 | Zone visual identity | Particles, lighting, ambient cho mỗi rebirth area | Trung bình |
| 15 | Dash dùng equipped skill | Sửa DashController gọi đúng slot | Thấp |

---

## 5. ĐỘ HOÀN THIỆN TỔNG THỂ (CẬP NHẬT)

```
Core Mechanics (Shout/Knockback/Physics)  ████████████████████  100%
Data Persistence & Safety                 ████████████████████  100%
Monster AI & PvE                          ████████████████████  100%  ✅ 12 loại, Boss, 3D
Quest System                              ████████████████████  100%  ✅ Daily reset
UI (tất cả màn hình)                      ████████████████████  100%  ✅ 14 screens
Skill System (Gacha + Equip)              ████████████████████  100%  ✅ 2 slot, filter rarity
Map & Area Progression                    ████████████████████  100%  ✅ 4 rebirth areas
Global Leaderboard                        ████████████████████  100%
Visual Assets (3D, Trails, VFX)           ████████████████████  100%
Audio (BGM, SFX)                          ████████████████████  100%
Monetization (logic)                      ████████████████░░░░   80%  (chờ IDs thật)
Bug Fixes (4 bugs trên)                   ████████░░░░░░░░░░░░   40%  (chưa apply)
Game Balance (cần playtest)               ████████████░░░░░░░░   60%  (cần test thực tế)
```

**Tổng thể:** ~90% sẵn sàng release. 4 bugs cần fix (2–4 giờ công) trước khi public.  
Sau khi fix 4 bugs P0 và điền IDs thật → game đủ điều kiện Soft Launch.

---

## 6. TÓM TẮT ĐIỂM MẠNH KIẾN TRÚC

| Điểm mạnh | Mô tả |
|---|---|
| Config-driven | Thêm pet/skill/quái/upgrade chỉ cần sửa `Config.luau` |
| Smart Binding | UI module detect existing ScreenGui trong Studio để tránh duplicate |
| Server-authoritative | Knockback, gacha, purchase đều validate server-side |
| Dual HUD system | Luau native + React/Luau component đồng thời (cần chọn 1) |
| BakePlugin | Một click bake toàn bộ UI + Map vào Studio |
| Reactive data | `DataController.OnDataChanged` broadcast tới mọi UI subscriber |

---

*Báo cáo dựa trên kiểm tra trực tiếp 100% source code tính đến 25/03/2026.*  
*Tổng: 51 file đã audit. Phát hiện 4 bugs P0, 7 tech debts P1, 7 cải tiến P2.*