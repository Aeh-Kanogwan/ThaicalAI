# Food Data Sources & Provenance

The `foods` table is populated from three kinds of origin, tracked per-row via
provenance columns so we always know where a nutrition value came from.

## Provenance columns (`foods`)

| Column       | Type        | Meaning                                                        |
|--------------|-------------|----------------------------------------------------------------|
| `source`     | `String?`   | `"seed"`, `"USDA FNDDS"`, `"USDA SR Legacy"`, `"OpenFoodFacts"` |
| `sourceRef`  | `String?`   | USDA `fdcId` or Open Food Facts barcode                        |
| `sourceUrl`  | `String?`   | Link back to the original record                               |
| `importedAt` | `DateTime?` | When the row was written by the importer / seed                |

All nullable — pre-existing rows keep working. The 44 original curated rows are
marked `source = "seed"`.

## Sources

### 1. Seed (curated) — `source = "seed"`
44 popular Thai dishes with realistic per-serving values, hand-curated for dev.
These are approximations, not authoritative. See `prisma/seed.ts`.

### 2. USDA FoodData Central — **PUBLIC DOMAIN**
- Endpoint: `https://api.nal.usda.gov/fdc/v1/foods/search`
- We use `USDA_API_KEY` (env), defaulting to `DEMO_KEY`.
  **DEMO_KEY is heavily rate-limited (~30 req/hr, 50/day).** Requests are
  throttled ~1.6s apart and the importer stops gracefully on HTTP 429/403.
  Get a free key: https://fdc.nal.usda.gov/api-key-signup.
- We prefer `Survey (FNDDS)` then `SR Legacy` datasets (real composition data)
  and **never** import `Branded` items here.
- Nutrients are per 100 g; we scale to a documented serving (default 250 g /
  plate, with per-dish overrides — see `TERMS` in `importFoods.ts`) and store
  the assumption in `servingSize` (e.g. `"1 จาน (250 g)"`).
- **Caveat:** USDA "Pad Thai" etc. are US-market recipe approximations, not
  Thai-authentic composition. Treat imported Thai dishes as provisional.

### 3. Open Food Facts — **ODbL (attribution required)**
- Endpoint: `https://world.openfoodfacts.org/cgi/search.pl`
- Product/barcode oriented (packaged goods) — useful for the barcode feature,
  not cooked dishes. Barcode is stored as `sourceRef`; values stored per 100 g.
- Attribution: data © Open Food Facts contributors, licensed under the
  [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/1.0/).

### 4. Thai FCD (Mahidol INMU) — **NOT INCLUDED (stub)**
- `inmu2.mahidol.ac.th` is **unreachable** from this environment (curl → 000)
  and has **commercial-use licensing concerns**.
- The adapter (`ThaiFcdAdapter`) is a clearly-flagged stub that **throws** and
  never fabricates data. The importer prints its status so the gap is visible.
- **Honest limitation:** authentic Thai street-food composition coverage is
  incomplete until Thai FCD access + a commercial-use licence are arranged.

## Running the importer

```bash
# All reachable sources (USDA + OFF); Thai FCD status is printed but not imported
npm run import:foods

# One source only
npm run import:foods -- --source=usda
npm run import:foods -- --source=off
npm run import:foods -- --source=all
```

The importer dedupes so it never duplicates the 44 seeded dishes:
1. exact `(source, sourceRef)` match → update metadata only;
2. existing dish by `nameTh` / overlapping `keywords` → skip (seed nutrition
   is curated and left intact);
3. otherwise insert a new row with `isVerified = false` and full provenance.

## Daily scheduler (optional, NOT auto-started)

`src/jobs/scheduler.ts` uses `node-cron` to run the importer once per day at
**23:59 Asia/Bangkok**. It is **not** started by the API server. Run it as a
separate long-lived process/container, or prefer an OS-level cron:

```bash
npm run import:foods:daily     # long-running node-cron process
```

Production recommendation: use OS cron / a k8s CronJob calling
`npm run import:foods` rather than keeping a node process alive.
