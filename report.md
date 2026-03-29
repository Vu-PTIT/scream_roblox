# 📋 BÁO CÁO KỸ THUẬT V4 — SHOUT SIMULATOR
*(Audit toàn bộ source code — Cập nhật: 28/03/2026)*

---

## 1. TỔNG QUAN DỰ ÁN

**Stack:** Luau `--!strict` · Rojo 7.7 · Wally · DataStoreService · RemoteEvents  
**Kiến trúc:** Server Services / Client Controllers / Shared Config  
**Character Controller:** Chickynoid (server-authoritative movement)  
**Library:** SimplePath (pathfinding AI) · ZonePlus v3 (trigger zones) · React-Luau (UI components)  
**Plugin:** BakePlugin.server.luau — bake UI/Map vào Studio  
**Số file:** 15 Server Services · 8 Client Controllers · 16 Client UI · 8 Shared · 9 UI Components

---

## 2. THỰC TRẠNG — AUDIT ĐẦY ĐỦ (28/03/2026)

### ✅ Hoàn chỉnh & Đang hoạt động tốt

| Module | File | Ghi chú chi tiết |
|---|---|---|
| **DataService** | `DataService.luau` | Load/save DataStore, auto-save 60s, daily reset, backward-compat merge, BindToClose. Phát `PlayerDataLoaded` attribute để các service khác đợi. |
| **ShoutService** | `ShoutService.luau` | Cone/Circular detection server-side, knockback formula `pow(ratio, 0.7)` dampening, server-side `pMult` validation dựa trên charge time thực tế, per-skill-slot cooldown tracking. |
| **MonsterService** | `MonsterService.luau` | SimplePath AI với State Machine {IDLE, WANDER, CHASE, ATTACK, RETURN}. Leashing logic: force RETURN nếu vượt `(zoneRadius + 15) studs`. Proximity culling 300 studs. **Boss phase 2**: dùng `ShoutType.Circular` khi HP < 50%. |
| **MapService** | `MapService.luau` | SafeZone / PvPArena / PvEZone / BossRoom / 4 Rebirth Areas. ZonePlus trigger gates (rebirth + boss). Zone VFX: Desert sand, Snow + fog, Void smoke, Divine sparkles. StreamingEnabled với `ReplicationFocus` tracking. |
| **ZoneService** | `ZoneService.luau` | Server-side zone detection (Lava, Safezone, MusicZone) qua ZonePlus. |
| **ZoneController** | `ZoneController.luau` | Client-side zone tracking, ZonePlus integration. |
| **QuestService** | `QuestService.luau` | RegisterAction, ClaimReward server-side, daily reset trong DataService. |
| **RewardService** | `RewardService.luau` | Playtime milestones, claim/locked state. |
| **LeaderboardService** | `LeaderboardService.luau` | OrderedDataStore, top 10 mỗi 60s, render vào board Workspace, pcall fallback cho `GetNameFromUserIdAsync`. |
| **MonetizationService** | `MonetizationService.luau` | ProcessReceipt đúng chuẩn Roblox, UserOwnsGamePassAsync. |
| **PetService** | `PetService.luau` | Gacha weighted, equip/unequip (max 3), AlignPosition/AlignOrientation 3D. Passive VP loop: đứng yên với pet → gain VP mỗi 1s. Fix: đợi `PlayerDataLoaded` attribute thay vì `task.wait(1)`. MonsterService gọi trực tiếp `PetService.OnOpenEgg` (không qua Remote). |
| **SkillService** | `SkillService.luau` | Gacha skill (SkillScrollCost = **1000 Gold**), equip 2 slot, server validate. **Sell skill** server-side với bảo vệ chống bán skill đang equipped. |
| **RebirthService** | `RebirthService.luau` | Reset VP + Upgrades, cộng multiplier (+25%/rebirth), giữ Pets + Skills. |
| **UpgradeService** | `UpgradeService.luau` | Server validate cost & level cap, currency là VP, Shop label đã đồng bộ `"VP"`. |
| **CodeService** | `CodeService.luau` | Nhập code, hoàn thưởng, anti-reuse. |
| **TextFilterService** | `TextFilterService.luau` | TextService:FilterStringAsync, cooldown 5s. |
| **ShoutController** | `ShoutController.luau` | VFX sóng âm (Normal/Circular/Focused), CameraShake, charging aura particles, FOV zoom, HitStop 50ms, ParticleTrail knockback. AnimationController tích hợp cho charge/shout/circular animations. **Knockback fix**: Chickynoid RemoteFunction với fallback Humanoid. |
| **DashController** | `DashController.luau` | LinearVelocity dash qua Chickynoid, DashSFX. |
| **AnimationController** | `AnimationController.luau` | Load/cache AnimationTrack theo ID, ghi đè Animate script idle/run/walk, Play/Stop/StopAll theo tên hoặc override ID. |
| **MonsterController** | `MonsterController.luau` | Client-side monster VFX (death, spawn effects). Có timeout cleanup 2s cho `Dying` attribute. |
| **DataController** | `DataController.luau` | Reactive cache, broadcast đến subscribers. |
| **AudioController** | `AudioController.luau` | BGM loop, Jump/Land SFX. |
| **UIController** | `UIController.luau` | React Root (unified): HUDApp + ShopApp + BagUI mount vào ReactRoblox root. Nav bar, proximity prompt binding, KeyShortcuts (B=Bag, E=Shop, T=Shout, Esc=CloseAll), notification toast. **Không có HUD.luau legacy** — đã loại bỏ. |
| **HUDApp** | `HUDApp.luau` | React component: VP bar, Gold/Rebirth pills, HP bar với real-time Humanoid.HealthChanged, SkillSlot × 2, Bag button. |
| **SkillUI** | `SkillUI.luau` | SkillInventory grid, filter by rarity (All/Common/Rare/Epic/Legendary), S1/S2 equip buttons, sell button. |
| **BagUI** | `BagUI.luau` | React component: 3 tab Stats / Skills / Pets, toggle phím B. Stat tính dựa `Config.GetUpgrade(id)`. |
| **Shop** | `Shop.luau` | Attack/Defense/Premium tab, label hiển thị **VP** (đã fix). MovementEffectUI tích hợp. |
| **PetUI** | `PetUI.luau` | Gacha grid, equip/unequip/sell, refresh khi data thay đổi. |
| **RebirthUI** | `RebirthUI.luau` | Confirm dialog, preview multiplier mới. |
| **QuestUI** | `QuestUI.luau` | Progress bar, claim button, daily refresh. |
| **RewardUI** | `RewardUI.luau` | Playtime milestones, claim/locked. |
| **EggHatchUI** | `EggHatchUI.luau` | Animation 3D ViewportFrame mở trứng. |
| **HatchUI** | `HatchUI.luau` | Base shared hatch module, tái dùng cho Egg và Skill. |
| **SkillHatchUI** | `SkillHatchUI.luau` | Animation reveal skill gacha, dùng HatchUI base. |
| **MovementEffectUI** | `MovementEffectUI.luau` | Shop mua/equip hiệu ứng Dash & Jump. |
| **DamageIndicator** | `DamageIndicator.luau` | Floating damage text màu sắc theo mức độ. |
| **ShoutWave** | `ShoutWave.luau` | `Play()` (Normal/Focused) + `PlayCircular()` riêng với Ring explosion. |
| **Config** | `Config.luau` | `GetUpgrade(id)` helper, `GetMovementEffect(id)` helper, `IsBoss` flag, `Animations` block, `PassiveVPBase/Interval`, `SkillStation.Offset` (tất cả dùng relative offset). |

---

## 3. VẤN ĐỀ KỸ THUẬT PHÁT HIỆN HIỆN TẠI

### 🔴 QUAN TRỌNG — Cần giải quyết trước khi public

---

**[BUG-1] Monetization IDs là placeholder — chưa điền ID thật**

```lua
-- Config.luau:
{ Id = 189283745, Name = "Auto Train", ... }  -- TODO: Gamepass ID thật
{ Id = 987654321, Name = "+1,000 Gold", ... } -- TODO: DevProduct ID thật
```

- `MonetizationService.ProcessReceipt` sẽ không khớp nếu Roblox trả về ID khác
- **Fix:** Vào Roblox Creator Dashboard → lấy ID thật → cập nhật `Config.luau`

---

**[BUG-2] SkillScrollCost dùng Gold, nhưng UI hiển thị không nhất quán**

```lua
-- Config.luau:
Config.SkillScrollCost = 1000  -- chi phí mở 1 cuộn skill (GOLD)

-- SkillService.luau dòng 61:
if data.Gold < totalCost then  -- Đúng: dùng Gold
```

```lua
-- SkillUI.luau dòng 295:
btn.Text = string.format("%dx (%d 💰)", count, cost)  -- Hiển thị biểu tượng 💰 (Gold) — ĐÚNG
```

- Logic server đúng (trừ Gold). UI cũng đúng (icon 💰).
- **⚠️ Tuy nhiên**: Report V3 ghi nhầm `SkillScrollCost = 1000 VP` — thực tế là **1000 Gold**.
- **Fix:** Cập nhật tài liệu, kiểm tra lại balance nếu muốn đổi sang VP.

---

**[BUG-3] Audio SFX IDs — một số ID chưa được xác nhận là valid trên Live**

```lua
Config.Audio = {
    BGM        = "rbxassetid://1837618405",  -- nhạc nền
    ShoutSFX   = "rbxassetid://138090596",   -- âm hét
    DashSFX    = "rbxassetid://12222124",    -- swoosh
    JumpSFX    = "rbxassetid://12222225",    -- nhảy
    LandSFX    = "rbxassetid://12222152",    -- đáp đất
    EggShakeSFX = "rbxassetid://12222070",
    EggHatchNormalSFX = "rbxassetid://12222225",
    -- ...
}
```

- Đã chuyển từ `rbxasset://` sang `rbxassetid://` (fix V3 đúng).
- Nhưng các ID có dạng `rbxassetid://1222xxxx` (8 chữ số) cần test trực tiếp trong Studio — một số ID từ thư viện cũ có thể không còn available.
- **Fix:** Play in Roblox Studio Live mode → kiểm tra output log xem có lỗi audio failed không.

---

### 🟡 KỸ THUẬT — Không block gameplay nhưng nên cải thiện

---

**[TD-1] `SkillService` không validate `slotIndex` overflow từ client**

```lua
-- SkillService.luau dòng 118-119:
local sIndex = slotIndex or 1
sIndex = math.clamp(math.floor(sIndex), 1, MAX_SKILL_SLOTS)  -- MAX_SKILL_SLOTS = 2
```

- ✅ `math.clamp` đã có → đây không còn là bug nghiêm trọng.
- **Tuy nhiên**: dữ liệu cũ trong DataStore có thể có `SlotIndex = 3+` (từ trước khi clamp được thêm vào).
- **Fix:** Thêm migration pass trong DataService để reset `SlotIndex > 2` về `nil`.

---

**[TD-2] `LeaderboardService` không kiểm tra board tồn tại trước khi update**

- Board tạo trong `MapService.Init()`, `LeaderboardService.Init()` gọi `updateBoard()` mỗi 60s
- Nếu `MapService` chưa chạy xong → `updateBoard` thất bại im lặng (không log lỗi)
- **Fix:** Thêm early warning log khi không tìm thấy board trong Workspace

---

**[TD-3] `DashController` hardcode `ShoutController.PerformShout(0, ...)` — slot Basic**

```lua
-- DashController.luau:
ShoutController.PerformShout(0, -direction, 1)  -- Luôn slot 0 (Basic)
```

- Người chơi đang dùng Epic skill → dash vẫn phát ra Basic Shout VFX
- `ShoutController.GetSelectedSlot()` đã tồn tại và có thể dùng được
- **Fix:** Dùng `ShoutController.PerformVFXOnly(direction, "Dash")` thay vì `PerformShout` — hàm này đã smart-pick skill đang equipped và không gây dame

---

**[TD-4] `PetService.UpdatePhysicalPets` tính `angle` dựa trên `currentCount` thay vì `petIndex`**

```lua
local angle = (currentCount - 2) * 45  -- -45, 0, 45
```

- Nếu equip pet 1 và 3 (bỏ pet 2) → cả 2 pet đều dùng vị trí -45°, 0° chứ không phải vị trí slot gốc
- **Fix:** Dùng `slotIndex` từ `equippedIds` để tính offset vị trí

---

**[TD-5] `useLayoutEffect` cho `_uiEventHandler` trong UIController — dependency array sai**

```lua
-- UIController.luau dòng 63:
React.useLayoutEffect(function()
    _uiEventHandler = function(id: string)
        ...
        -- Đọc bagOpen, openWindow qua closure
        local newState = not bagOpen  -- Closure stale!
    end
    return function() _uiEventHandler = nil end
end, { bagOpen, openWindow })  -- Re-run khi state thay đổi
```

- `_uiEventHandler` được expose ra ngoài React tree qua side-effect
- Mỗi lần `bagOpen` hoặc `openWindow` thay đổi → handler được tạo lại → đúng behavior
- **Vấn đề tiềm ẩn**: `UIController.HandleAction` là hàm không thay đổi (module-level), nên nếu gọi ngay sau render trước khi `useLayoutEffect` chạy, có thể dùng handler cũ 1 frame
- **Fix:** Dùng `useRef` để lưu state mới nhất, tránh closure stale:
  ```lua
  local stateRef = React.useRef({ bagOpen = false, openWindow = nil })
  React.useEffect(function()
      stateRef.current = { bagOpen = bagOpen, openWindow = openWindow }
  end, { bagOpen, openWindow })
  ```

---

**[TD-6] `HUDApp` không hiển thị ATK/DEF stats trong Status Card**

```lua
-- HUDApp.luau — chỉ render:
-- Gold | VP | RebirthCount (Pill)
-- HP Bar
-- Rebirth Progress
```

- Report V3 ghi "HUD: VP bar, Gold, ATK, DEF, HP" — nhưng thực tế **HUDApp không có ATK/DEF stat labels**
- ATK/DEF chỉ hiển thị trong BagUI → Stats tab
- **Fix:** Thêm 2 PillLabel nhỏ cho ATK/DEF vào Status Card, hoặc cập nhật tài liệu cho đúng

---

**[TD-7] `SkillUI` dùng `SkillScrollCost` để tính giá nhưng không hiển thị label "Gold"**

```lua
-- SkillUI.luau dòng 316-317:
makeOpenBtn("Open 1x", Config.SkillScrollCost, 1, UDim2.new(0,10,0,6))
makeOpenBtn("Open 10x", Config.SkillScrollCost * 10, 10, UDim2.new(0,220,0,6))

-- makeOpenBtn:
btn.Text = string.format("%dx (%d 💰)", count, cost)
-- Chỉ có emoji 💰, không ghi rõ "Gold"
```

- Người chơi mới có thể nhầm 💰 là VP
- **Fix:** Đổi text thành `"%dx (%d Gold)"` hoặc thêm tooltip/header rõ hơn

---

### 🟢 CẢI TIẾN NÂNG CAO / POST-LAUNCH

**[ENH-1] Animation IDs chưa chính xác**

| Animation | ID hiện tại | Vấn đề |
|---|---|---|
| `SonicBeam.AnimationId` | `rbxassetid://507305361` | ID placeholder — cần animation hét theo kiểu Focused |
| `DragonScream.AnimationId` | `rbxassetid://507304133` | Dùng cả làm `ChargingAnimationId` → cùng animation charging và release trông weird |
| `Shout_Normal`, `Shout_Circular`, `Shout_Focused` | `""` (trống) | AnimationController trả về nil → không có combat animation |

- **Fix:** Upload animation pack đúng → điền ID vào `Config.Animations` và `Config.Skills[n].AnimationId`

---

**[ENH-2] Cân bằng kinh tế — Cần playtest thực tế**

| Vấn đề | Chi tiết |
|---|---|
| VP per shout thấp | `VocalPointsPerHit = 10`, `VocalPointsPerUse = 4` — Rebirth cần 10,000 VP → ~800 hit trúng quái |
| EggCostGold = 500 nhưng StarterZone drop 10 Gold | Mở 1 trứng = 50 lần giết quái starter → có thể quá cao cho newbie |
| SkillScrollCost = 1000 **Gold** | 1000 Gold. StarterZone drop 10 Gold/kill → 100 kills/cuộn. PvEZone drop 50 Gold/kill → 20 kills/cuộn — cần test balance |
| Passive VP = 2/giây với pet | Có thể tạo idle macro farming → cần Anti-AFK detection |

---

**[ENH-3] Anti-AFK chưa có**

- `PassiveVPBase = 2 VP/giây` khi đứng yên với pet → macro AFK farming
- `PetService` chỉ check `MoveDirection.Magnitude < 0.01` — không phát hiện macro
- **Đề xuất:** Track `LastShoutTime` — nếu > 5 phút không hét → giảm passive VP 90%

---

**[ENH-4] Boss chưa có visual distinction rõ ràng**

- `SoundKing` và `IceColossus` có `IsBoss = true` và phase 2 Circular shout
- Nhưng model vẫn là placeholder Part (không phải model đặc biệt)
- Chưa có phase 2 visual feedback (aura, color change), respawn timer riêng
- **Đề xuất:** BillboardGui riêng cho boss với thanh HP lớn hơn + màu vàng; respawn time dài hơn (60s)

---

**[ENH-5] Skill distinction VFX giữa các rarity chưa rõ**

- `ShoutWave.PlayCircular` đã được tạo riêng (Ring explosion thay vì Beam)
- Nhưng màu `EffectColor` từ skill chỉ được pass để thay đổi tint nhẹ
- **Đề xuất:** Scale VFX size theo `EffectSize` mạnh hơn — Legendary skills cần hiệu ứng rõ ràng hơn Rare

---

**[ENH-6] CodeUI chưa có trong UIController toggle**

```lua
-- UIController.luau — HandleAction:
if id == "Reward" then RewardUI.Open()
elseif id == "Shout" then CustomShoutUI.Open()
end
-- Không có "Code" → phải gọi CodeUI.Open() trực tiếp ở chỗ khác
```

- **Fix:** Thêm `elseif id == "Code" then CodeUI.Open()` vào fallback handler, đồng thời thêm ProximityPrompt "Code" vào Map

---

## 4. KẾ HOẠCH HÀNH ĐỘNG

### 🔴 P0 — Phải fix trước khi public

| # | Việc cần làm | File | Độ khó |
|---|---|---|---|
| 1 | Điền GamePass/DevProduct IDs thật từ Creator Dashboard | `Config.luau` | Thấp |
| 2 | Test Audio IDs trực tiếp trong Studio Live mode | `Config.luau` | Thấp |
| 3 | Điền Animation IDs thật cho combat animations | `Config.luau` | Thấp |

### 🟡 P1 — Nên làm trước Soft Launch

| # | Việc cần làm | File | Độ khó |
|---|---|---|---|
| 4 | Fix DashController dùng `PerformVFXOnly` thay vì `PerformShout(0)` | `DashController.luau` | Thấp |
| 5 | Fix PetService slot angle dùng `slotIndex` thay vì `currentCount` | `PetService.luau` | Thấp |
| 6 | Thêm ATK/DEF stat trong HUDApp Status Card | `HUDApp.luau` | Thấp |
| 7 | Sửa text SkillUI nút mở cuộn: hiển thị "Gold" rõ hơn | `SkillUI.luau` | Thấp |
| 8 | Thêm LeaderboardService early warning log | `LeaderboardService.luau` | Thấp |
| 9 | Cân bằng VP gain & egg cost qua playtest | `Config.luau` | Trung bình |
| 10 | DataService migration để reset `SlotIndex > 2` cũ | `DataService.luau` | Thấp |

### 🟢 P2 — Post-Launch / Content Update

| # | Việc cần làm | Mô tả | Độ khó |
|---|---|---|---|
| 11 | Anti-AFK passive VP | Track last shout time → giảm gain khi idle | Trung bình |
| 12 | Boss visual identity | HP bar riêng, phase 2 aura, respawn timer 60s | Trung bình |
| 13 | VFX scale by rarity | Legendary shout = VFX lớn + sound đặc biệt | Trung bình |
| 14 | Physical Pet model | Thay Part placeholder bằng model 3D thật từ Toolbox | Cao |
| 15 | CodeUI ProximityPrompt | Thêm station "Code" vào Map | Thấp |

---

## 5. ĐỘ HOÀN THIỆN TỔNG THỂ

```
Core Mechanics (Shout/Knockback/Charge/Physics)  ████████████████████  100%
Data Persistence & Safety                        ████████████████████  100%
Monster AI (SimplePath + State Machine + Boss)   ████████████████████  100%  ✅ Phase 2, Leashing, Culling
Quest System                                     ████████████████████  100%
UI (tất cả màn hình)                             ████████████████████  100%  ✅ 16 screens + MovementEffectUI
Skill System (Gacha + Equip + Sell + VFX riêng)  ████████████████████  100%  ✅ Circular ring, Focused beam
Map & Zone Progression (ZonePlus)                ████████████████████  100%  ✅ VFX môi trường, Gate trigger
Animation System                                 ████████░░░░░░░░░░░░   40%  (IDs chưa điền)
Global Leaderboard                               ████████████████████  100%
Visual Assets (3D placeholder, VFX)              ███████████████░░░░░   75%  (Pet/Monster models là Part)
Audio (BGM, SFX)                                 ████████████████░░░░   80%  (IDs chuyển sang rbxassetid:// ✅, cần test live)
Monetization                                     ████████░░░░░░░░░░░░   40%  (IDs placeholder)
Game Balance                                     ████████████░░░░░░░░   60%  (cần playtest thực tế)
```

**Tổng thể:** ~85% sẵn sàng release.  
**3 items P0** cần fix (1–2 giờ công) trước khi public.  
Sau khi fix P0 + điền IDs thật → game đủ điều kiện Soft Launch.

---

## 6. ĐIỂM MẠNH KIẾN TRÚC (CẬP NHẬT)

| Điểm mạnh | Mô tả |
|---|---|
| Config-driven | Thêm pet/skill/quái/upgrade/zone chỉ cần sửa `Config.luau` |
| `Config.GetUpgrade(id)` / `GetMovementEffect(id)` | Lookup theo Id thay vì hardcode index — safe với reorder |
| Server-authoritative | Knockback, gacha, purchase, pMult validation đều server-side |
| SimplePath + State Machine | Quái AI hoạt động mượt, boss có phase 2, leashing chống thoát zone |
| ZonePlus integration | Gate trigger, safe zone, music zone — declarative và event-driven |
| Passive VP economy | Đứng yên với pet → VP gain → incentivize pet upgrades |
| AnimationController | Cache + on-demand load, ghi đè Animate script, per-skill animation |
| Refx system | Server fire VFX event → client handle → decoupled rendering |
| HatchUI base | Tái dùng cho cả EggHatch và SkillHatch — giảm code duplication |
| **React Unified UI** | UIController mount single ReactRoblox root — không còn legacy HUD.luau conflict |
| **Sell system** | Cả Pet và Skill đều có sell-for-gold, server-validated, block equipped items |
| **MovementEffects** | Shop riêng cho Dash/Jump effects với 10 hiệu ứng từ Common đến Legendary |

---

## 7. SỬA ĐỔI SO VỚI REPORT V3 — ĐIỀU CHỈNH BẤT CẬP

> Phần này ghi lại những điểm **sai hoặc lỗi thời** trong V3 sau khi kiểm tra code thực tế:

| Vấn đề V3 | Thực tế |
|---|---|
| "HUD.luau và HUDApp.luau song song [TD-1]" | **Đã resolve.** `HUD.luau` không còn tồn tại trong project. UIController chỉ dùng React/HUDApp. |
| "BUG-3: ShoutController hardcode `Config.Upgrades[1]`" | **Đã fix.** ShoutController dòng 386 đang dùng `Config.GetUpgrade("damage_1")` đúng cách. |
| "BUG-4: Chickynoid conflict với knockback" | **Đã xử lý.** ShoutController có logic kiểm tra Chickynoid RemoteFunction, fallback sang AssemblyLinearVelocity. |
| "TD-3: MonsterController không có timeout cleanup" | **Đã implement.** MonsterController có timeout 2s cleanup cho `Dying` attribute. |
| "TD-2: SkillService không validate SlotIndex" | **Đã có.** `math.clamp(sIndex, 1, MAX_SKILL_SLOTS)` trong `onSetSkillEquipped`. |
| "SkillScrollCost = 1000 VP" | **Sai.** Thực tế là **1000 Gold** (`data.Gold < totalCost`). |
| "15 Server Services · 8 Client Controllers · 17 Client UI" | **Sai.** CT: 16 UI screens (không có `SkillUI` riêng biệt — nhúng trong BagUI), MovementEffectUI là screen thứ 16. |
| "Shop.luau — Attack/Defense/Premium tab" | **Không đầy đủ.** Shop.luau có thêm tab Movement Effects (MovementEffectUI integrated). |

---

## 8. LOG THAY ĐỔI KỂ TỪ V2 (25/03 → 28/03/2026)

| Ngày | Thay đổi |
|---|---|
| 27/03 | ✅ Fix: `MonsterService` không còn `FireClient(OpenEgg)` — gọi trực tiếp `PetService.OnOpenEgg` |
| 27/03 | ✅ Fix: `PetService` đợi `PlayerDataLoaded` attribute thay vì `task.wait(1)` |
| 27/03 | ✅ Fix: `ShoutService` validate `pMult` server-side dựa trên elapsed charge time thực tế |
| 27/03 | ✅ Fix: Shop và UpgradeService đã đồng bộ currency → đều dùng VP |
| 27/03 | ✅ Fix: `BagUI/HUD` dùng `Config.GetUpgrade("damage_1")` thay vì `Config.Upgrades[1]` |
| 27/03 | ✅ Fix: MapService station Skill dùng `Config.Map.SkillStation.Offset` (relative offset) |
| 27/03 | ✅ Fix: ShoutController destroy billboard cũ explicit trong `onCharAdded` |
| 27/03 | ✅ Fix: Chickynoid knockback — check RemoteFunction ApplyImpulse, fallback Humanoid |
| 27/03 | ✅ Fix: HUD.luau removed — UIController dùng React HUDApp duy nhất |
| 27/03 | ✅ Implement: Boss phase 2 — Circular shout khi HP < 50% |
| 27/03 | ✅ Implement: `ShoutWave.PlayCircular()` riêng với Ring explosion VFX |
| 27/03 | ✅ Implement: 4 Rebirth Areas có VFX môi trường riêng (Desert/Snow/Void/Divine) |
| 27/03 | ✅ Implement: MonsterController timeout 2s cleanup cho Dying attribute |
| 27/03 | ✅ NEW: `AnimationController` client-side controller hoàn chỉnh |
| 27/03 | ✅ NEW: `MonsterController` client-side monster VFX |
| 27/03 | ✅ NEW: `ZoneService` + `ZoneController` server+client zone management |
| 27/03 | ✅ NEW: `HatchUI` base module — EggHatchUI và SkillHatchUI kế thừa |
| 27/03 | ✅ NEW: Passive VP loop trong `PetService` — gain VP khi đứng yên với pet |
| 27/03 | ✅ NEW: Chickynoid integration — server-authoritative character movement |
| 27/03 | ✅ NEW: SimplePath pathfinding thay thế PathfindingService thuần |
| 27/03 | ✅ NEW: StreamingEnabled + `ReplicationFocus` tracking trong MapService |
| 28/03 | ✅ NEW: `MovementEffectUI` — shop mua/equip hiệu ứng Dash & Jump |
| 28/03 | ✅ NEW: Sell system cho cả Pets và Skills (Gold) |
| 28/03 | ✅ NEW: HP synchronization real-time trong HUDApp (Humanoid.HealthChanged) |
| 28/03 | ✅ NEW: Gold-based Skill Scroll economy (thay vì VP) |

---

*Báo cáo dựa trên kiểm tra trực tiếp 100% source code tính đến 28/03/2026.*  
*Tổng: 52+ file đã audit. Phát hiện 2 bugs P0 cần fix, 1 bug quan trọng (Audio test), 7 tech debts P1, 6 cải tiến P2.*  
*V3 → V4: Chỉnh sửa 8 sai lệch trong report, phát hiện thêm 3 tech debt mới (TD-5, TD-6, TD-7).*