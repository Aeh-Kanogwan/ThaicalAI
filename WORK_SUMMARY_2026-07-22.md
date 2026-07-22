# CalThai AI — สรุปงาน (เช้าวันที่ 22 ก.ค. 2026)

> เรียบเรียงโดย Friday สำหรับเจ้านายอ่านตอนเช้า — สรุปสิ่งที่ทำคืนที่ผ่านมา, สถานะจริง, ช่องว่างที่ยังเหลือ และแผนต่อ

---

## 1. TL;DR

- **Backend รันได้จริง + ทดสอบผ่านครบ** — มี **unit/integration test 63 ตัว ผ่านหมด (63/63)** ✅
- **AI สแกนอาหาร** ทำงานครบ pipeline (mock → match ฐานข้อมูล → คิดแคล/มาโคร) และรองรับ **4 provider**: Claude (ค่าเริ่มต้น), OpenAI, Gemini, Typhoon
- **แก้บั๊กจริง 1 จุด**: วันเปลี่ยนเป็นเวลาไทย (Asia/Bangkok) แล้ว
- **โค้ดขึ้น GitHub แล้ว**: https://github.com/Aeh-Kanogwan/ThaicalAI
- **โค้ด Flutter ผ่าน `flutter analyze` สะอาด 0 issues** (ติดตั้ง Flutter 3.44.7 + แก้ 1 compile error ที่เจอแล้ว)
- **ยังไม่ครบ 2 เรื่องหลัก**: (1) ฐานข้อมูลอาหารไทยยังน้อย+แหล่งอ้างอิงหลักต่อไม่ได้ (2) แอป Flutter ยัง **รันบน emulator/มือถือ** ไม่ได้ (Android toolchain ยังไม่พร้อม) — แต่โค้ดคอมไพล์ผ่านแล้ว

---

## 2. สิ่งที่ทำเสร็จคืนนี้

### 2.1 Backend (Node + TypeScript + Fastify + Prisma + PostgreSQL)
- REST API v1 ครบทุก endpoint ตาม `docs/API_CONTRACT.md`: auth, profile+BMR/TDEE, foods search, **scan**, meal logs, water/exercise/weight, quota
- รันจริงบนเครื่องผ่าน Docker Postgres (พอร์ต 5433) — ทดสอบ end-to-end ผ่าน: login → ตั้งโปรไฟล์ (BMR 1649 / TDEE 2556) → ค้นหา "กะเพรา" → สแกน (เจอ ข้าวผัดกะเพราไก่+ไข่ดาว, match DB) → paywall 402 เมื่อครบ 3 รูปฟรี → บันทึกมื้อ → สรุปแคลรายวัน

### 2.2 Vision AI — เชื่อมของจริง 4 provider (สลับผ่าน `VISION_PROVIDER`)
| Provider | สถานะ | หมายเหตุ |
|---|---|---|
| **Claude** (ค่าเริ่มต้น) | โค้ดพร้อม + คีย์ตั้งใน `.env` แล้ว | ใช้ official SDK, structured JSON output, default `claude-opus-4-8` (สลับ `claude-haiku-4-5` เพื่อคุมต้นทุนได้) |
| OpenAI (gpt-4o-mini) | โค้ดพร้อม | ใส่ `OPENAI_API_KEY` ถ้าจะใช้ |
| Gemini (1.5-flash) | โค้ดพร้อม | ใส่ `GEMINI_API_KEY` ถ้าจะใช้ |
| Typhoon (SCB 10X) | โค้ดพร้อม | OpenAI-compatible สลับ base URL (hosted / local Docker) ได้ |
| mock | ใช้ dev | คืนเมนูไทยจำลอง ไม่ต้องมีคีย์ |

> ⚠️ **ยังไม่ได้ยิงทดสอบ Claude ตัวจริง** — ผมเลี่ยงการเรียก API ที่คิดเงินในบัญชีคุณตอนกลางคืนแบบไม่มีคนดู วิธีทดสอบอยู่ในข้อ 6

### 2.3 แก้บั๊ก timezone (เจอระหว่างทดสอบจริง)
- เดิม: วันเปลี่ยนคิดเป็น UTC → คนไทยกินตอนเที่ยงคืนกว่า log ไปตกวันก่อนหน้า
- แก้: คิดวันเป็น **Asia/Bangkok (+07:00 คงที่, ไทยไม่มี DST)** ทั้ง meal log / water / weight / โควตา VIP รายวัน — ยืนยันด้วยเทสต์แล้ว

### 2.4 Unit / Integration Tests (Vitest) — **63 ผ่าน**
- `nutrition.test.ts` (17) — BMR/TDEE/เป้าแคล/มาโคร ทุกเคส
- `dates.test.ts` (7) — ล็อกบั๊ก timezone Bangkok
- `_shared.test.ts` (18) — parser JSON ของ Vision (เคสขอบ)
- `quota.test.ts` (6) — ตรรกะโควตา
- `mock.test.ts` (5) — mock provider
- `api.test.ts` (10) — integration ผ่าน fastify.inject: health, auth, profile, scan+paywall, log+summary (ล้างข้อมูลทดสอบทิ้งทุกครั้ง)

### 2.5 ท่อดึงข้อมูลอาหาร (food ingestion) + provenance
- เพิ่มคอลัมน์แหล่งที่มา (`source`, `sourceRef`, `sourceUrl`, `importedAt`) — ทุก record ตรวจย้อนได้
- `npm run import:foods` ดึงจากแหล่งที่เข้าถึงได้จริง + มี scheduler รายวัน (`node-cron`, 23:59 น.) ไว้ให้
- เอกสาร `backend/docs/DATA_SOURCES.md` อธิบายแหล่ง/ลิขสิทธิ์

### 2.6 Flutter — static analysis ผ่านสะอาด
- ติดตั้ง Flutter 3.44.7 stable (ที่ `C:\src\flutter`) แล้วรัน `flutter pub get` + `flutter analyze`
- เจอ **1 compile error จริง** (`ApiClient` ไม่ได้ import ใน `auth_state.dart`) + 1 warning + lint ย่อย → **แก้หมดแล้ว** ตอนนี้ `flutter analyze` = **No issues found!** แปลว่าโค้ด Dart 40+ ไฟล์คอมไพล์ผ่าน (เหลือแค่ Android toolchain เพื่อรัน emulator)
- รัน **`flutter test` ผ่านครบ 6/6** (models: ScanResult/Quota/ActivityLevel, widgets: CalorieRing/MacroCard) — แก้ test 1 ตัวที่ assert RichText ผิด (`findRichText: true`)

---

## 3. สถานะฐานข้อมูลอาหาร (ตอบคำถามเจ้านายตรงๆ)

**ยังไม่ครบ** — ปัจจุบันมี **47 เมนู**: `seed` 44 (AI เขียนค่าประมาณ), `OpenFoodFacts` 2 (สินค้าแพ็กเกจจริง มีบาร์โค้ด), `USDA FNDDS` 1 (Chicken curry ค่าจริง)

**ทำไมยังไม่ครบ:**
- **Thai FCD (ม.มหิดล)** = แหล่งไทยที่น่าเชื่อถือสุด แต่ **ต่อจากเครื่องนี้ไม่ติดเลย** (curl 000) + มีเงื่อนไขลิขสิทธิ์เชิงพาณิชย์ → ดึงอัตโนมัติไม่ได้
- **USDA** = ปลอดลิขสิทธิ์ + ต่อติด แต่ DEMO_KEY ติด rate limit หนัก (ได้แค่ 1 เมนู) — ต้องขอ **USDA API key ฟรี** แล้วรันซ้ำ
- **Open Food Facts** = เปิด (ODbL) แต่เป็นสินค้าแพ็กเกจ ไม่ใช่อาหารปรุงสด

> สรุป: เมนูสตรีทฟู้ดไทยแท้ยัง **ไม่ครบตามเป้า Rqm (300–500)** และแถวที่ import มาถูกตั้ง `isVerified=false` ควรถือเป็นข้อมูลชั่วคราวจนกว่าจะจัดการสิทธิ์/ช่องทาง Thai FCD ได้

---

## 4. ช่องว่างที่ยังเหลือ (Gap Analysis)

| # | เรื่อง | สถานะ | ใครควรทำ |
|---|---|---|---|
| G1 | **Thai Food DB ไม่ครบ** (47/300-500) + แหล่งหลักต่อไม่ได้ | ค้าง | ต้องตัดสินใจ: ขอลิขสิทธิ์ Thai FCD (งานกฎหมาย) / หาไฟล์ export / จ้างคีย์ข้อมูล |
| G2 | **ยังไม่ทดสอบ Claude ตัวจริง** | ค้าง | รอเจ้านายอนุมัติค่าใช้จ่าย แล้วผมรันให้ (ข้อ 6) |
| G3 | **Flutter mobile รันบน emulator ไม่ได้** | โค้ดผ่าน analyze แล้ว | ติดตั้ง Flutter 3.44.7 + โค้ด Dart `flutter analyze` = 0 issues (แก้ 1 error: `ApiClient` ไม่ได้ import) เหลือแค่ Android toolchain (cmdline-tools โหลดล้มเหลว) + emulator — ทำตอนกลางวัน |
| G4 | **DPIA / PDPA** ก่อน go-live | ยังไม่เริ่ม | เก็บรูปอาหาร+ข้อมูลสุขภาพ (น้ำหนัก/เป้าหมาย) = ข้อมูลส่วนบุคคล ควรให้ทีม legal-data-privacy ประเมิน |
| G5 | **ลิขสิทธิ์ scrape** ข้อมูลโภชนาการเชิงพาณิชย์ | ยังไม่เคลียร์ | ผม flag ไว้แล้ว — ควรให้ legal ยืนยันก่อน production |
| G6 | Payment (RevenueCat) | Phase 2, ยัง stub | ตามแผน |
| G7 | Prisma client binary regen ติด EPERM | เล็กน้อย | หยุด dev server แล้ว `npx prisma generate` (types ถูกต้องแล้ว ไม่กระทบการรัน) |

---

## 5. แผนต่อ (เรียงความสำคัญ)

1. **G2 – ยืนยัน AI จริง**: เจ้านายบอก "ยิงได้" → ผมทดสอบ Claude ด้วยรูปอาหารจริง 1 รูป (แนะนำ haiku คุมต้นทุน) แล้วรายงานผล
2. **G1 – ข้อมูลอาหาร**: ขอ USDA key ฟรี (ดึงเพิ่มได้ทันที ~30 เมนู) + ตัดสินใจเรื่อง Thai FCD (ช่องทาง/ลิขสิทธิ์)
3. **G3 – Flutter**: ติดตั้ง Android Studio + toolchain ตอนกลางวัน แล้ว `flutter pub get` + `flutter analyze` + รัน emulator
4. **G4/G5 – Legal**: ส่งให้ทีมกฎหมายประเมิน DPIA + ลิขสิทธิ์แหล่งข้อมูล ก่อน go-live

---

## 6. วิธีรัน & ทดสอบ (อ้างอิงเร็ว)

```bash
# 1) ฐานข้อมูล
docker compose up -d db

# 2) backend
cd backend
npm install
npx prisma migrate dev
npm run seed          # อาหารไทยเริ่มต้น 44 เมนู
npm run dev           # http://localhost:4000

# 3) รันเทสต์ (63 ตัว)
npm run test

# 4) ดึงข้อมูลอาหารเพิ่ม (ใส่ USDA key จริงใน .env ก่อนเพื่อได้เยอะขึ้น)
npm run import:foods

# 5) ทดสอบ AI จริงด้วย Claude
#    - .env มี ANTHROPIC_API_KEY + VISION_PROVIDER=claude อยู่แล้ว
#    - restart dev server แล้ว POST /api/v1/scan พร้อมรูปอาหารจริง (base64)
#    - คุมต้นทุน: ใส่ CLAUDE_VISION_MODEL=claude-haiku-4-5
```

Test user (seed): `test@calthai.app` / `Test@12345`

---

## 7. หมายเหตุความปลอดภัย
- คีย์ Claude อยู่ใน `backend/.env` (gitignored) เท่านั้น — ตรวจแล้วไม่มีคีย์หลุดในไฟล์ที่ขึ้น git
- แนะนำ: ถ้าคีย์นี้เคยถูกวางเป็น plaintext ที่อื่น ควร rotate เพื่อความชัวร์

*ผมทำงานคืนนี้ตามที่มอบหมาย โค้ดอยู่ในสภาพเรียบร้อย เทสต์เขียว push ขึ้น GitHub แล้วครับ — ตื่นมาอ่านได้เลย 🌤️*
