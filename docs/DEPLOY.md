# CalThai AI — คู่มือ Deploy

## ภาพรวม

| ส่วน | Platform | ค่าใช้จ่าย | URL ตัวอย่าง |
|---|---|---|---|
| Backend API + Database | **Railway** | Free tier / Hobby $5/เดือน | `https://calthai-api.up.railway.app` |
| Playground (หน้าทดสอบ) | **Vercel** | ฟรี | `https://calthai.vercel.app` |
| Mobile (Flutter) | APK / TestFlight | ฟรี (dev) | แจกไฟล์โดยตรง |

---

## 1. Deploy Backend บน Railway (ทำก่อน)

### สมัคร Railway
1. ไปที่ https://railway.app → **Login with GitHub** (ใช้ account Aeh-Kanogwan)
2. กด **New Project** → **Deploy from GitHub repo** → เลือก `ThaicalAI`

### ตั้งค่า Services
Railway จะสร้าง 2 services:
- **PostgreSQL** — กด "Add Service" → "Database" → "PostgreSQL" → รอสร้าง จะได้ `DATABASE_URL` อัตโนมัติ
- **Web Service** — Railway จะ detect `railway.json` + `Dockerfile` ในโฟลเดอร์ root

> ถ้า Dockerfile ไม่ถูก detect อัตโนมัติ: ไป Settings → Build → เลือก Dockerfile Path = `backend/Dockerfile`

### ตั้ง Environment Variables
ใน Railway → Web Service → **Variables** → เพิ่มทีละตัว:

```
DATABASE_URL        = (คัดลอกจาก PostgreSQL service ที่ Railway สร้างให้)
JWT_SECRET          = (รหัสลับยาวๆ เช่น random string 32 chars)
PORT                = 4000
VISION_PROVIDER     = claude
ANTHROPIC_API_KEY   = sk-ant-api03-...คีย์จริง...
CLAUDE_VISION_MODEL = claude-haiku-4-5
NODE_ENV            = production
```

> **JWT_SECRET**: ใช้ https://generate-secret.vercel.app/32 สร้างให้
> **CLAUDE_VISION_MODEL**: ตั้งเป็น `claude-haiku-4-5` เพื่อคุมต้นทุน (ถูกกว่า Opus ~5 เท่า)

### Deploy
- Railway จะ build + deploy อัตโนมัติทุกครั้งที่ push ขึ้น GitHub (branch main)
- รอ ~3-5 นาทีครั้งแรก
- เช็คว่า OK: เปิด `https://<your-url>.up.railway.app/health` → ต้องเห็น `{"ok":true}`

### Seed ข้อมูลเริ่มต้น (ทำครั้งแรกครั้งเดียว)
ใน Railway → Web Service → **Deploy** → **Shell**:
```bash
npm run seed
```

---

## 2. Deploy Playground บน Vercel

1. ไปที่ https://vercel.com → **Login with GitHub**
2. **New Project** → Import `ThaicalAI` repo
3. Framework Preset: **Other** (ไม่ใช่ Next.js)
4. Root Directory: `.` (root ของ repo)
5. Build Command: (ว่างไว้) | Output Directory: `.` (root)
6. กด **Deploy**

### หลัง deploy เสร็จ
แก้ค่า API base ใน playground ให้ชี้ Railway URL:
- เปิด `playground.html` ในเบราว์เซอร์
- แก้ช่อง **API base** เป็น `https://<your-railway-url>.up.railway.app/api/v1`

หรือจะ hardcode ใน `playground.html` ให้เลยก็ได้ (แจ้งผม จะแก้ให้)

---

## 3. Mobile App (Flutter) — แจก APK

### Build APK (Android)
ต้องติดตั้ง Android toolchain ก่อน (Flutter SDK มีอยู่แล้วที่ `C:\src\flutter`):

```bash
# ติดตั้ง Android Studio จาก https://developer.android.com/studio แล้ว
set PATH=%PATH%;C:\src\flutter\bin
cd C:\Aeh\web_source\ThaicalAI\mobile
flutter pub get

# แก้ API base URL ก่อน build (ให้ชี้ Railway)
# เปิดไฟล์ lib/config.dart และแก้ baseUrl

flutter build apk --release
# ไฟล์จะอยู่ที่: build/app/outputs/flutter-apk/app-release.apk
```

แจกไฟล์ `.apk` ให้ทีม install บน Android ได้โดยตรง (เปิด "Install unknown sources" ก่อน)

### iOS (TestFlight)
ต้องใช้ macOS + Xcode + Apple Developer Account ($99/ปี) — ทำทีหลังได้ครับ

---

## 4. อัปเดตแอปหลัง deploy

**Backend**: แค่ `git push origin main` → Railway rebuild อัตโนมัติ ✅

**Playground**: แค่ `git push origin main` → Vercel redeploy อัตโนมัติ ✅

**Mobile**: ต้อง build + แจกไฟล์ใหม่ทุกครั้ง (Phase 2: ขึ้น App Store จะสะดวกกว่า)

---

## สรุป Environment Variables ทั้งหมด

| Variable | Dev (`.env`) | Production (Railway) |
|---|---|---|
| `DATABASE_URL` | `postgresql://thaical:thaical_dev_pw@localhost:5433/thaical` | จาก Railway PostgreSQL |
| `JWT_SECRET` | `change-me-in-prod-super-secret-key` | Random 32-char string |
| `PORT` | `4000` | `4000` |
| `VISION_PROVIDER` | `claude` | `claude` |
| `ANTHROPIC_API_KEY` | คีย์จริงใน `.env` | ใส่ใน Railway Variables |
| `CLAUDE_VISION_MODEL` | (ค่าเริ่มต้น opus) | `claude-haiku-4-5` |
| `NODE_ENV` | ไม่ต้องตั้ง | `production` |
| `USDA_API_KEY` | `DEMO_KEY` | ขอ key ฟรีที่ fdc.nal.usda.gov |
