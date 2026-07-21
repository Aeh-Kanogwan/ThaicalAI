# CalThai AI 🥗

AI-powered Thai food calorie tracker — ถ่ายรูปแป๊บเดียวรู้แคล เน้นเมนูไทย/สตรีทฟู้ด

Monorepo:

| Path | Stack | Runs here now? |
|------|-------|----------------|
| `backend/` | Node + TypeScript + Fastify + Prisma + PostgreSQL | ✅ Yes (Docker) |
| `mobile/`  | Flutter (iOS + Android) | ⏳ ต้องติดตั้ง Flutter SDK ก่อน |
| `docs/`    | API contract & specs | — |

## Quick start — Backend

```bash
# 1. Start Postgres
docker compose up -d db

# 2. Backend
cd backend
cp .env.example .env
npm install
npx prisma migrate dev --name init
npm run seed          # seed Thai food DB
npm run dev           # http://localhost:4000
```

Health check: `GET http://localhost:4000/health`

## Mobile (later — needs Flutter SDK)

```bash
cd mobile
flutter pub get
flutter run
```
Set API base URL in `mobile/lib/config.dart`.

## Docs
- [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) — REST API v1
- [`Rqm.md`](Rqm.md) — requirements
- [`UI Style.txt`](UI%20Style.txt) — brand & design system
