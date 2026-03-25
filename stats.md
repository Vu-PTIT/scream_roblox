# Phân Tích Chỉ Số & Nguyên Lý Cơ Bản - Shout Simulator

## 1. Nguyên Lý Tính Toán Chuyên Sâu (Combat Mechanics)

### 1a. Công Thức Tính Sát Thương (Damage / Knockback Force)
Sát thương trong Shout Simulator được thể hiện qua **Lực Đẩy (Knockback Force)**. Lực này quyết định việc quái vật (hoặc người chơi) bị văng xa bao nhiêu, đồng thời cũng chính là lượng "Máu" (HP) bị trừ đi.

**Công thức gốc:**
```lua
Force = (Attacker_ATK * Config.Shout.BaseDamage * ShoutType_DamageMult) / √(Target_DEF)
```

**Trong đó:**
- `Attacker_ATK`: Tổng sức tấn công của người ra đòn (sau khi cộng dồn các chỉ số từ Pet, Rebirth, Upgrade).
- `Config.Shout.BaseDamage`: Hằng số sát thương cơ bản của game (Hiện tại = 15).
- `ShoutType_DamageMult`: Hệ số phụ thuộc vào loại kỹ năng (Shout Type) đang sử dụng. Ví dụ: Normal (x1.0), Circular (x0.8), Focused (x1.5).
- `Target_DEF`: Tổng phòng thủ của mục tiêu bị tấn công.

**Giới hạn lực đẩy (Max Force Cap):**
```lua
FinalForce = math.min(Force, Config.Shout.MaxForce)
```
- `MaxForce` hiện tại được cấu hình = 55. Mục đích của giới hạn này là để quản lý engine vật lý của Roblox, tránh tình trạng nhân vật hoặc quái bị một lực đẩy quá lớn làm đè xuyên địa hình (glitch) hoặc văng bay mất khỏi bản đồ.

---

### 1b. Công Thức Tính Tổng Tấn Công (Total Attack)
Đây là công thức chi phối sức mạnh tổng thể của một người chơi:
```lua
Total_ATK = (BaseATK + Stats_Upgrades) * Rebirth_Multiplier * Total_Pet_Multiplier
```
**Phân tích các biến số:**
- `BaseATK`: Tấn công mặc định của nhân vật cấp 1 (Mặc định = 10).
- `Stats_Upgrades`: Lượng tấn công cộng thẳng từ các lượt nâng cấp mua trong Shop (Từ Microphone và Speaker).
- `Rebirth_Multiplier`: Hệ số nhân từ việc chuyển sinh, công thức là `1 + (Số lần Rebirth * 0.25)`. (Ví dụ: 4 lần Rebirth = hệ số x2.0).
- `Total_Pet_Multiplier`: Là kết quả nhân dồn (tích phân) của tất cả các hệ số Multiplier từ các Pet đang trang bị. (Ví dụ: Có 2 Pet mang hệ số x1.5 và x2.0 => Tổng hệ số từ Pet là x3.0).

---

## 2. Chỉ Số Cụ Thể Của Quái Vật Hiện Tại

Hệ thống quái vật hiện tại được định nghĩa trong `Config.Monsters` và chỉ bao gồm **3 loại** trải đều trên 2 khu vực.

### 2a. Screech Slime
Slime là quái vật cơ bản và yếu nhất game.
- **Vị trí (SpawnZone):** `PvEZone`
- **Chỉ số sinh tồn:**
  - **HP (Máu tối đa):** 50
  - **Defense (Phòng thủ):** 5
  - **Movement Speed:** 8 (Khá nhanh nhẹn)
- **Chỉ số tấn công:**
  - **Attack:** 10
- **Phần thưởng (Loots):**
  - **Gold Drop:** 10 vàng
  - **Egg Drop Chance:** 5% (0.05) tỷ lệ rớt trứng
- **Đánh giá & Vấn đề:** HP 50 là quá yếu so với sát thương khởi điểm của Newbie (ATK = 10). Nếu áp dụng công thức phía trên, cấp 1 đã có thể deal khoảng ~67 damage `(10 * 15 / √5)`. Điều này khiến Slime luôn bị "1-Hit Kill" và không mang lại cảm giác leo rank (progression). *Đề xuất:* Nâng HP gốc lên khoảng 80 hoặc hạ `BaseDamage`.

---

### 2b. Boom Golem
Golem là quái vật trung cấp, chậm nhưng trâu bò.
- **Vị trí (SpawnZone):** `PvEZone` (Đang bị đặt cùng khu với Screech Slime)
- **Chỉ số sinh tồn:**
  - **HP (Máu tối đa):** 200
  - **Defense (Phòng thủ):** 20
  - **Movement Speed:** 5 (Chậm chạp)
- **Chỉ số tấn công:**
  - **Attack:** 30
- **Phần thưởng (Loots):**
  - **Gold Drop:** 50 vàng
  - **Egg Drop Chance:** 20% (0.20) tỷ lệ rớt trứng
- **Đánh giá & Vấn đề:** Boom Golem có lượng HP gấp 4 và ATK gấp 3 lần Slime, nhưng lại xuất hiện trong cùng một bản đồ với Slime. Một người chơi mới sẽ dính "bẫy" cực mạnh khi vừa chạm trán một con Slime yếu xìu đã phải đụng ngay một Golem tiêu hao gấp đôi HP của họ. *Đề xuất:* Nên tách quái vật này hoặc Slime sang hai Level Zone chuyên biệt.

---

### 2c. Sound King (Boss)
Boss duy nhất của game cho đến thời điểm hiện tại.
- **Vị trí (SpawnZone):** `BossRoom`
- **Chỉ số sinh tồn:**
  - **HP (Máu tối đa):** 1,000
  - **Defense (Phòng thủ):** 60
  - **Movement Speed:** 3 (Rất chậm nhưng nguy hiểm)
- **Chỉ số tấn công:**
  - **Attack:** 100
- **Phần thưởng (Loots):**
  - **Gold Drop:** 300 vàng
  - **Egg Drop Chance:** 75% (0.75) tỷ lệ rớt trứng
- **Đánh giá & Vấn đề:** Phần thưởng rất đáng giá 75% rớt trứng tuy nhiên `BossRoom` hiện tại lại là cánh cửa rộng mở không có rào cản. Bất cứ ai (kể cả Newbie) cũng có thể bước vào và bị "One-Shot". *Đề xuất:* Cần thiết lập vách ngăn yêu cầu (Zone Gating) - Đòi hỏi người chơi vươn tới số lần Rebirth nhất định (ví dụ Rebirth 1 hoặc 2) mới được khiêu chiến Sound King.

---

## 3. Khoảng Trống Nội Dung Vùng Đất (Zone Gap)

Game được thiết kế mang theo một lộ trình dài với hệ thống Rebirth nhưng Quái Vật hiện tại đã bị **đứt gãy lộ trình**. 
Các khu vực dưới đây đã được lập bảng cấu hình sẵn để mở khóa nhưng bên trong lại **trống rỗng, hoàn toàn không có quái vật**:
1. **Desert:** Mở khóa sau khi Rebirth 1 lần.
2. **IceZone:** Mở khóa sau khi Rebirth 3 lần.
3. **VoidRealm:** Mở khóa sau khi Rebirth 7 lần.
4. **HeavenlyStage:** Mở khóa sau khi Rebirth 15 lần.

**Hậu Quả:** Một người mua đủ Vocal Point để chuyển sinh sang Rebirth 1 và vào sa mạc (Desert) sẽ không có quái để cày mốc tiếp theo. Chuyển sinh trở nên vô nghĩa.

**Hướng Giải Quyết:** Sáng tạo gấp rút các mẫu quái vật nối tiếp với cấp số nhân về Máu, Sát thương và Phần Thưởng vàng - Phân bổ thẻ tag `SpawnZone` của chúng đến chính xác 4 vùng đất trên.
