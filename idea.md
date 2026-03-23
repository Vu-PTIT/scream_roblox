# Tài Liệu Thiết Kế & Công Nghệ Dự Án: Shout Simulator

## 1. Tổng quan Dự án (Project Overview)
* **Tên dự kiến:** Shout Simulator / Voice Pushers / Roar Battles
* **Thể loại:** Simulator / Action Brawler trên nền tảng Roblox.
* **Điểm nhấn (USP):** Người chơi sử dụng "Sóng âm" (Tiếng hét) để tạo lực vật lý đẩy văng đối thủ. Lực hét và sức chịu đựng có thể được nâng cấp vô hạn thông qua vòng lặp cày cuốc.

---

## 2. Vòng lặp Gameplay Cốt lõi (Core Game Loop)
1. **Train (Luyện tập):** Hét vào không gian hoặc bia ngắm để tích lũy `Điểm Thanh Quản`.
2. **Upgrade (Nâng cấp):** Dùng điểm để mua Loa, Microphone (Tấn công) hoặc Tai nghe, Giáp cách âm (Phòng thủ).
3. **Fight (Chiến đấu):** Tham gia Đấu trường PvP để đẩy văng người khác, hoặc khu vực PvE tiêu diệt quái vật.
4. **Rebirth (Chuyển sinh):** Reset cấp độ khi đạt đỉnh để đổi lấy hệ số nhân (Multiplier) và mở khóa khu vực mới.

---

## 3. Cơ chế Hệ thống (Key Mechanics)
* **Vật lý Knockback:** Tính toán lực đẩy lùi dựa trên chỉ số Tấn công của người hét và chỉ số Chịu đựng (Độ nặng) của nạn nhân.
* **Tiếng Hét Cá Nhân Hóa (Custom Shout Text):** Người chơi tự đặt câu chữ hiển thị khi hét.
  * *Lưu ý bảo mật:* Bắt buộc chạy qua hệ thống `TextService` của Roblox Server để lọc từ ngữ vi phạm trước khi hiển thị (BillboardGui).
* **Hệ thống Pet (Gacha):** Mở trứng bằng Vàng/Cúp rớt ra từ quái vật để nhận Pet hỗ trợ tăng hệ số cày cuốc.

---

## 4. Hệ Sinh Thái Công Nghệ (Technical Stack)
Để đảm bảo dự án đạt chất lượng "AAA" trên Roblox, dễ bảo trì và mở rộng:

* **Môi trường Lập trình:** Visual Studio Code kết hợp Rojo (Đồng bộ code) và Git/GitHub (Quản lý phiên bản).
* **Ngôn ngữ Lập trình:** Luau (Bật chế độ Strict Type-checking `--!strict`) hoặc Roblox-TS.
* **Framework Giao tiếp:** Knit hoặc Matter (Quản lý luồng dữ liệu Server - Client).
* **Cơ sở dữ liệu (Database):** ProfileService (Chống mất data và hỗ trợ Session Locking).
* **Quản lý Mạng & Vật lý:** * BridgeNet2 (Tối ưu hóa gói tin RemoteEvent chống lag).
  * RaycastHitboxV4 (Tính toán va chạm của luồng sóng âm chính xác).
* **Giao diện (UI/UX):** Fusion hoặc Roact (Tạo UI bằng code, tối ưu chuyển động).
* **Tài nguyên (Art):** Blender 3D (Model vật phẩm, thú cưng) và Moon Animator 2 (Làm hoạt ảnh).

---

## 5. Lộ trình Phát triển (Dev Roadmap)
* **Giai đoạn 1 (Prototype):** Hoàn thiện cơ chế click chuột tạo sóng âm đẩy lùi vật thể.
* **Giai đoạn 2 (Data & Logic):** Thiết lập ProfileService, Knit framework và vòng lặp Train/Upgrade cơ bản.
* **Giai đoạn 3 (World & UI):** Xây dựng Map (Safe Zone, PvP Arena), code UI Shop bằng Fusion.
* **Giai đoạn 4 (Features):** Thêm tính năng "Tiếng hét cá nhân hóa", Pet system và quái vật PvE.
* **Giai đoạn 5 (Polish):** Thêm VFX, âm thanh gây cười, hoạt ảnh và tích hợp Gamepasses (Monetization).