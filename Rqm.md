# Requirements Specification: AI-Powered Thai Food Calorie Tracker App

## 1. Project Overview
พัฒนาแอปพลิเคชันนับแคลอรีและติดตามโภชนาการด้วย AI รองรับทั้ง **iOS** และ **Android** โดยเน้นจุดขายที่ **"การสแกนรูปภาพอาหารไทย/สตรีทฟู้ดได้แม่นยำ"** ในราคาที่เข้าถึงง่าย (99 THB/เดือน)

* **Target Tech Stack:** Cross-platform (Flutter หรือ React Native)
* **Core Value Proposition:** ถ่ายรูปแป๊บเดียวรู้แคล ไม่ต้องพิมพ์หาชื่ออาหาร เน้นเมนูไทย สตรีทฟู้ด และร้านสะดวกซื้อ

---

## 2. System Architecture & Vision AI Strategy

ไม่จำเป็นต้องฝึกฝน/เทรน (Train) AI Vision Model ใหม่ตั้งแต่ต้น ให้ใช้โครงสร้างแบบ Hybrid Architecture เพื่อประหยัดต้นทุนและพัฒนาได้เร็ว:

[ User Takes Photo ] 
        │
        ▼
[ API Request: Vision AI (GPT-4o-mini / Gemini 1.5 Flash) ]
        │
        ▼ (Returns JSON: Food items, estimated portions)
[ Match Items with Internal Thai Food Database ]
        │
        ▼ (Fetches exact Calories & Macros: Protein, Carbs, Fat)
[ Output to App UI & Save to User Daily Log ]

### Prompt Strategy for Vision AI:
* ส่งภาพเข้า Vision API พร้อม System Prompt ให้คืนค่ากลับมาเป็น **Structured Data (JSON)**
* ระบุรายการอาหารที่พบในภาพ, ปริมาณโดยประเมิน (เช่น 1 จาน / 0.5 ถ้วย) และระดับความมั่นใจ (Confidence Score)

---

## 3. Core Features Requirements

### 3.1 AI Food Recognition & Logging (Hero Feature)
* **Multi-Item Detection:** แยกแยะอาหารมากกว่า 1 อย่างในจานเดียวกันได้ (เช่น ข้าวผัด + ไข่ดาว + น้ำซุป)
* **Portion Estimator:** ผู้ใช้สามารถปรับขนาดเสิร์ฟได้ง่าย (จานเล็ก / จานปกติ / จานพิเศษ หรือระบุเป็นกรัม)
* **Barcode Scanner:** รองรับการสแกนบาร์โค้ดสินค้าในร้านสะดวกซื้อ (ใช้ Open Food Facts / Internal DB)
* **Manual Log & Search:** พิมพ์ค้นหาและบันทึกอาหารเองได้ตามปกติ

### 3.2 Core Nutrition Tracker
* **Smart BMR/TDEE Calculator:** คำนวณแคลอรีเป้าหมายประจำวันตามข้อมูลผู้ใช้ (น้ำหนัก, ส่วนสูง, เพศ, อายุ, ระดับการออกกำลังกาย และเป้าหมาย)
* **Macro Breakdown:** แสดงสัดส่วน **คาร์โบไฮเดรต / โปรตีน / ไขมัน** แยกตามมื้อและรวมประจำวัน
* **Water & Exercise Log:** บันทึกการดื่มน้ำ และการเผาผลาญจากการออกกำลังกาย

### 3.3 Data & Progress Analytics
* **Weight Tracker:** กราฟบันทึกน้ำหนักและสัดส่วน พร้อมระบบอัปโหลดรูป Before/After
* **Daily Quota Manager:** ระบบจัดการสิทธิ์การสแกน AI ตามประเภทสมาชิก (เช่น Free สแกนได้ 3 รูปแรก / VIP สแกนได้ 10 รูป/วัน)

### 3.4 Integration & Widgets
* **iOS:** Integration กับ Apple Health, รองรับ Lock Screen & Home Screen Widgets
* **Android:** Integration กับ Google Fit / Health Connect, รองรับ Android Home Screen Widgets

---

## 4. Thai Food Database Structure

ฐานข้อมูลอาหารตั้งต้น (Core DB) ให้ทำ Data Scraping / Cleaning จากแหล่งข้อมูล **สถาบันโภชนาการ มหาวิทยาลัยมหิดล (Thai FCD)** และ **กรมอนามัย** โดยออกแบบ Schema ดังนี้:

### Table Schema: `foods`
CREATE TABLE foods (
    id SERIAL PRIMARY KEY,
    name_th VARCHAR(255) NOT NULL,
    name_en VARCHAR(255),
    keywords TEXT[], -- ["กะเพรา", "กระเพรา", "ผัดกะเพรา"] เพื่อใช้อัลกอริทึม Match คำจาก AI
    calories INT NOT NULL,
    protein FLOAT NOT NULL,
    fat FLOAT NOT NULL,
    carbs FLOAT NOT NULL,
    sodium FLOAT,
    serving_size VARCHAR(100) DEFAULT '1 จาน',
    is_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

---

## 5. Business & Paywall Model

* **Freemium Tier:** 
  * ใช้ฟีเจอร์พื้นฐาน พิมพ์ค้นหา บันทึกน้ำหนัก ฟรี
  * ให้โควตาสแกน AI ฟรี **3 รูปแรก** (เพื่อทดลองใช้งาน)
* **VIP Subscription:** 
  * **99 THB / เดือน** หรือ **890 THB / ปี**
  * สิทธิ์สแกน AI **5-10 ครั้ง/วัน** (คุม Cost ของ Vision API ไว้ที่ประมาณ 3.60 THB/คน/เดือน)
  * สรุป Nutrition Insights และไร้โฆษณา

---

## 6. Action Items for Dev / Claude

1. **Phase 1 (MVP):** Design Database, Setup App UI/UX, Implement Vision API Integration (GPT-4o-mini/Gemini Flash) + Thai Food DB (Top 300-500 popular items)
2. **Phase 2:** Barcode Scanner Integration, Apple Health / Google Fit Sync, Payment Gateway (In-App Purchase via RevenueCat)
3. **Phase 3:** Widgets, Gamification (Streak/Badges), Community Share Feature