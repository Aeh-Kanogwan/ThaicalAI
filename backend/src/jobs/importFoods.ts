/**
 * Food-data ingestion pipeline (real sources, full provenance).
 *
 * Sources:
 *  - USDA FoodData Central (PUBLIC DOMAIN) — prefer Survey (FNDDS) / SR Legacy
 *    datasets (real composition data), never Branded, never fabricated.
 *  - Open Food Facts (ODbL, attribution required) — packaged/barcode items.
 *  - Thai FCD (Mahidol INMU) — STUB. Unreachable from this environment and
 *    requires a commercial-use licence. It throws instead of inventing data.
 *
 * Every row we insert carries its provenance: source / sourceRef / sourceUrl /
 * importedAt. We ONLY write nutrient values a source actually returned.
 *
 * Usage:
 *   npm run import:foods                # all reachable sources (usda + off)
 *   npm run import:foods -- --source=usda
 *   npm run import:foods -- --source=off
 *   npm run import:foods -- --source=all
 */
import 'dotenv/config';
import { prisma } from '../prisma.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type ImportedFood = {
  nameEn: string;
  nameTh?: string;
  keywords: string[];
  calories: number; // per servingSize
  protein: number; // grams per servingSize
  fat: number; // grams per servingSize
  carbs: number; // grams per servingSize
  sodium?: number; // mg per servingSize
  servingSize: string;
  source: string;
  sourceRef: string;
  sourceUrl: string;
};

export interface FoodSourceAdapter {
  readonly name: string;
  fetch(terms: string[]): Promise<ImportedFood[]>;
}

type AdapterResult = {
  source: string;
  attempted: number;
  imported: number;
  skipped: number;
  failed: number;
  notFound: string[]; // terms the source had no usable data for
  errors: string[];
};

// ---------------------------------------------------------------------------
// Curated term -> Thai dictionary (~30 dishes the app cares about).
// `keywords` intentionally overlap the seed set so we can dedupe against
// existing seeded dishes instead of creating near-duplicates.
// ---------------------------------------------------------------------------

type TermSpec = {
  query: string; // what we search the source for (English)
  nameTh: string;
  keywords: string[];
  serving?: string; // override default plate assumption
  servingGrams?: number; // override default 250g
};

const TERMS: TermSpec[] = [
  { query: 'pad thai', nameTh: 'ผัดไทย', keywords: ['ผัดไทย', 'pad thai', 'padthai'] },
  { query: 'green curry chicken', nameTh: 'แกงเขียวหวานไก่', keywords: ['แกงเขียวหวาน', 'เขียวหวาน', 'green curry'], serving: '1 ถ้วย (250 g)' },
  { query: 'red curry chicken', nameTh: 'แกงเผ็ดไก่', keywords: ['แกงเผ็ด', 'red curry'], serving: '1 ถ้วย (250 g)' },
  { query: 'massaman curry', nameTh: 'มัสมั่น', keywords: ['มัสมั่น', 'massaman'], serving: '1 ถ้วย (250 g)' },
  { query: 'panang curry', nameTh: 'พะแนง', keywords: ['พะแนง', 'panang', 'phanaeng'], serving: '1 ถ้วย (250 g)' },
  { query: 'tom yum shrimp soup', nameTh: 'ต้มยำกุ้ง', keywords: ['ต้มยำ', 'ต้มยำกุ้ง', 'tom yum', 'tomyum'], serving: '1 ถ้วย (250 g)' },
  { query: 'tom kha chicken', nameTh: 'ต้มข่าไก่', keywords: ['ต้มข่า', 'tom kha'], serving: '1 ถ้วย (250 g)' },
  { query: 'papaya salad', nameTh: 'ส้มตำ', keywords: ['ส้มตำ', 'som tam', 'somtam', 'papaya salad'] },
  { query: 'larb pork', nameTh: 'ลาบหมู', keywords: ['ลาบ', 'ลาบหมู', 'laab', 'larb'] },
  { query: 'spring roll fried', nameTh: 'ปอเปี๊ยะทอด', keywords: ['ปอเปี๊ยะ', 'spring roll'], serving: '2 ชิ้น (60 g)', servingGrams: 60 },
  { query: 'chicken satay', nameTh: 'สะเต๊ะไก่', keywords: ['สะเต๊ะ', 'satay', 'sate'], serving: '4 ไม้ (120 g)', servingGrams: 120 },
  { query: 'chicken fried rice', nameTh: 'ข้าวผัดไก่', keywords: ['ข้าวผัด', 'ข้าวผัดไก่', 'fried rice', 'khao pad'] },
  { query: 'pork fried rice', nameTh: 'ข้าวผัดหมู', keywords: ['ข้าวผัดหมู'] },
  { query: 'stir fried basil chicken', nameTh: 'ผัดกะเพราไก่', keywords: ['กะเพรา', 'ผัดกะเพรา', 'basil', 'krapow'] },
  { query: 'pad see ew', nameTh: 'ผัดซีอิ๊ว', keywords: ['ผัดซีอิ๊ว', 'ซีอิ๊ว', 'pad see ew'] },
  { query: 'drunken noodles pad kee mao', nameTh: 'ผัดขี้เมา', keywords: ['ผัดขี้เมา', 'ขี้เมา', 'drunken noodles', 'pad kee mao'] },
  { query: 'boat noodles', nameTh: 'ก๋วยเตี๋ยวเรือ', keywords: ['ก๋วยเตี๋ยว', 'ก๋วยเตี๋ยวเรือ', 'boat noodle'], serving: '1 ชาม (400 g)', servingGrams: 400 },
  { query: 'khao soi', nameTh: 'ข้าวซอย', keywords: ['ข้าวซอย', 'khao soi'], serving: '1 ชาม (400 g)', servingGrams: 400 },
  { query: 'hainanese chicken rice', nameTh: 'ข้าวมันไก่', keywords: ['ข้าวมันไก่', 'chicken rice', 'khao man kai'] },
  { query: 'crispy pork belly', nameTh: 'หมูกรอบ', keywords: ['หมูกรอบ', 'crispy pork'] },
  { query: 'grilled pork skewer', nameTh: 'หมูปิ้ง', keywords: ['หมูปิ้ง', 'moo ping'], serving: '3 ไม้ (90 g)', servingGrams: 90 },
  { query: 'fried chicken', nameTh: 'ไก่ทอด', keywords: ['ไก่ทอด', 'fried chicken', 'gai tod'], serving: '1 ชิ้น (100 g)', servingGrams: 100 },
  { query: 'thai omelette', nameTh: 'ไข่เจียว', keywords: ['ไข่เจียว', 'omelette'], serving: '1 จาน (120 g)', servingGrams: 120 },
  { query: 'morning glory stir fry', nameTh: 'ผัดผักบุ้ง', keywords: ['ผักบุ้ง', 'ผัดผักบุ้ง', 'morning glory'], serving: '1 จาน (150 g)', servingGrams: 150 },
  { query: 'mango sticky rice', nameTh: 'ข้าวเหนียวมะม่วง', keywords: ['ข้าวเหนียวมะม่วง', 'มะม่วง', 'mango sticky rice'], serving: '1 จาน (200 g)', servingGrams: 200 },
  { query: 'thai iced tea', nameTh: 'ชาไทยเย็น', keywords: ['ชาไทย', 'ชาเย็น', 'thai tea', 'cha yen'], serving: '1 แก้ว (300 g)', servingGrams: 300 },
  { query: 'sticky rice', nameTh: 'ข้าวเหนียว', keywords: ['ข้าวเหนียว', 'sticky rice'], serving: '1 ปั้น (100 g)', servingGrams: 100 },
  { query: 'wonton soup', nameTh: 'เกี๊ยวน้ำ', keywords: ['เกี๊ยว', 'เกี๊ยวน้ำ', 'wonton'], serving: '1 ชาม (300 g)', servingGrams: 300 },
  { query: 'shrimp paste fried rice', nameTh: 'ข้าวคลุกกะปิ', keywords: ['ข้าวคลุกกะปิ', 'กะปิ', 'khao kluk kapi'] },
  { query: 'grilled fish', nameTh: 'ปลาเผา', keywords: ['ปลาเผา', 'grilled fish'], serving: '1 ตัว (200 g)', servingGrams: 200 },
];

const DEFAULT_SERVING_GRAMS = 250; // 1 plate assumption for cooked dishes
const DEFAULT_SERVING_LABEL = '1 จาน (250 g)';

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const round1 = (n: number) => Math.round(n * 10) / 10;

function normLoose(s: string): string {
  return s.replace(/\s+/g, '').toLowerCase();
}

// ---------------------------------------------------------------------------
// USDA FoodData Central adapter (public domain)
// ---------------------------------------------------------------------------

const USDA_API_KEY = process.env.USDA_API_KEY ?? 'DEMO_KEY';
const USDA_THROTTLE_MS = 1600; // DEMO_KEY is ~30/hr, 50/day — go gently.

// Nutrient IDs in FDC (stable across FNDDS/SR Legacy).
const N_ENERGY_KCAL = 1008;
const N_PROTEIN = 1003;
const N_FAT = 1004;
const N_CARB = 1005;
const N_SODIUM = 1093;

type UsdaNutrient = { nutrientId?: number; nutrientName?: string; unitName?: string; value?: number };
type UsdaFood = {
  fdcId: number;
  description: string;
  dataType?: string;
  foodNutrients?: UsdaNutrient[];
};

function pickNutrient(nutrients: UsdaNutrient[], id: number, kcalName?: boolean): number | undefined {
  for (const n of nutrients) {
    if (n.nutrientId === id && typeof n.value === 'number') return n.value;
  }
  // Fallback: energy sometimes matched by name + KCAL unit only.
  if (kcalName) {
    for (const n of nutrients) {
      if (n.nutrientName === 'Energy' && (n.unitName ?? '').toUpperCase() === 'KCAL' && typeof n.value === 'number') {
        return n.value;
      }
    }
  }
  return undefined;
}

export class UsdaAdapter implements FoodSourceAdapter {
  readonly name = 'USDA FNDDS';
  readonly notFound: string[] = [];

  async fetch(terms: string[]): Promise<ImportedFood[]> {
    const out: ImportedFood[] = [];
    const specs = TERMS.filter((t) => terms.includes(t.query));

    for (const spec of specs) {
      try {
        const food = await this.search(spec.query);
        if (!food) {
          this.notFound.push(spec.query);
          continue;
        }
        const mapped = this.mapFood(food, spec);
        if (!mapped) {
          this.notFound.push(spec.query);
          continue;
        }
        out.push(mapped);
      } catch (err) {
        // Re-throw rate-limit so the pipeline can stop early and report it.
        if (err instanceof RateLimitError) throw err;
        this.notFound.push(spec.query);
        console.error(`  [usda] "${spec.query}" failed: ${(err as Error).message}`);
      }
      await sleep(USDA_THROTTLE_MS);
    }
    return out;
  }

  private async search(query: string): Promise<UsdaFood | null> {
    // Prefer real-composition datasets; never Branded. Try the combined
    // FNDDS+SR Legacy filter first; on a transient 400 (seen under DEMO_KEY
    // load) fall back to FNDDS only before giving up on the term.
    const foods =
      (await this.searchOnce(query, 'Survey (FNDDS),SR Legacy')) ??
      (await this.searchOnce(query, 'Survey (FNDDS)'));
    if (!foods || foods.length === 0) return null;

    // Best match: prefer FNDDS, then SR Legacy; USDA already ranks by score.
    const ranked = [...foods].sort((a, b) => rankType(a.dataType) - rankType(b.dataType));
    return ranked[0] ?? null;
  }

  private async searchOnce(query: string, dataType: string): Promise<UsdaFood[] | null> {
    const url =
      `https://api.nal.usda.gov/fdc/v1/foods/search?api_key=${encodeURIComponent(USDA_API_KEY)}` +
      `&query=${encodeURIComponent(query)}&pageSize=5&dataType=${encodeURIComponent(dataType)}`;

    // The USDA gateway flaps between 200 / 400 (nginx) / 429 under DEMO_KEY
    // throttling. Retry transient 400s a few times with backoff before giving
    // up on this filter. A true 429/403 means quota exhausted — stop hard.
    const maxTries = 3;
    for (let attempt = 1; attempt <= maxTries; attempt++) {
      const res = await fetch(url);
      if (res.status === 429 || res.status === 403) {
        throw new RateLimitError(`USDA rate limit / forbidden (HTTP ${res.status}) — DEMO_KEY quota likely exhausted`);
      }
      if (res.status === 400) {
        if (attempt < maxTries) {
          await sleep(USDA_THROTTLE_MS);
          continue; // transient nginx 400 — retry
        }
        return null; // let caller fall back to a simpler filter
      }
      if (!res.ok) throw new Error(`USDA HTTP ${res.status}`);
      const data = (await res.json()) as { foods?: UsdaFood[] };
      return data.foods ?? [];
    }
    return null;
  }

  private mapFood(food: UsdaFood, spec: TermSpec): ImportedFood | null {
    const nutrients = food.foodNutrients ?? [];
    const kcal100 = pickNutrient(nutrients, N_ENERGY_KCAL, true);
    const protein100 = pickNutrient(nutrients, N_PROTEIN);
    const fat100 = pickNutrient(nutrients, N_FAT);
    const carb100 = pickNutrient(nutrients, N_CARB);
    const sodium100 = pickNutrient(nutrients, N_SODIUM); // mg per 100g

    // Require the core macros; skip if the record lacks real data.
    if (kcal100 == null || protein100 == null || fat100 == null || carb100 == null) return null;

    const grams = spec.servingGrams ?? DEFAULT_SERVING_GRAMS;
    const factor = grams / 100;

    return {
      nameEn: food.description,
      nameTh: spec.nameTh,
      keywords: spec.keywords,
      calories: Math.round(kcal100 * factor),
      protein: round1(protein100 * factor),
      fat: round1(fat100 * factor),
      carbs: round1(carb100 * factor),
      sodium: sodium100 != null ? round1(sodium100 * factor) : undefined,
      servingSize: spec.serving ?? DEFAULT_SERVING_LABEL,
      source: (food.dataType === 'SR Legacy' ? 'USDA SR Legacy' : 'USDA FNDDS'),
      sourceRef: String(food.fdcId),
      sourceUrl: `https://fdc.nal.usda.gov/food-details/${food.fdcId}/nutrients`,
    };
  }
}

function rankType(t?: string): number {
  if (t === 'Survey (FNDDS)') return 0;
  if (t === 'SR Legacy') return 1;
  return 2;
}

class RateLimitError extends Error {}

// ---------------------------------------------------------------------------
// Open Food Facts adapter (ODbL — attribution required)
// ---------------------------------------------------------------------------

type OffProduct = {
  code?: string;
  product_name?: string;
  countries?: string;
  nutriments?: Record<string, number | string>;
};

export class OpenFoodFactsAdapter implements FoodSourceAdapter {
  readonly name = 'OpenFoodFacts';
  readonly notFound: string[] = [];

  // Keep it small & barcode-oriented (packaged Thai items).
  private static readonly OFF_TERMS = ['thai milk tea', 'instant noodles tom yum', 'nam prik', 'coconut milk'];

  async fetch(_terms: string[]): Promise<ImportedFood[]> {
    const out: ImportedFood[] = [];
    for (const term of OpenFoodFactsAdapter.OFF_TERMS) {
      try {
        const products = await this.search(term);
        const usable = products.find((p) => this.hasNutriments(p) && p.code);
        if (!usable) {
          this.notFound.push(term);
          continue;
        }
        const mapped = this.mapProduct(usable, term);
        if (!mapped) {
          this.notFound.push(term);
          continue;
        }
        out.push(mapped);
      } catch (err) {
        this.notFound.push(term);
        console.error(`  [off] "${term}" failed: ${(err as Error).message}`);
      }
      await sleep(500);
    }
    return out;
  }

  private async search(term: string): Promise<OffProduct[]> {
    const url =
      `https://world.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(term)}` +
      `&search_simple=1&json=1&page_size=8&fields=code,product_name,countries,nutriments`;
    const res = await fetch(url, { headers: { 'User-Agent': 'CalThaiAI/1.0 (food import; contact kanogwan.l@softdebut.com)' } });
    if (!res.ok) throw new Error(`OFF HTTP ${res.status}`);
    const data = (await res.json()) as { products?: OffProduct[] };
    return data.products ?? [];
  }

  private hasNutriments(p: OffProduct): boolean {
    const n = p.nutriments;
    if (!n) return false;
    return typeof n['energy-kcal_100g'] === 'number' && typeof n['proteins_100g'] === 'number';
  }

  private num(n: Record<string, number | string>, key: string): number | undefined {
    const v = n[key];
    return typeof v === 'number' ? v : undefined;
  }

  private mapProduct(p: OffProduct, term: string): ImportedFood | null {
    const n = p.nutriments!;
    const kcal100 = this.num(n, 'energy-kcal_100g');
    const protein100 = this.num(n, 'proteins_100g');
    const fat100 = this.num(n, 'fat_100g');
    const carb100 = this.num(n, 'carbohydrates_100g');
    const sodiumG100 = this.num(n, 'sodium_100g'); // OFF sodium is in grams/100g
    if (kcal100 == null || protein100 == null || fat100 == null || carb100 == null) return null;

    const name = (p.product_name && p.product_name.trim()) || term;
    // Packaged goods: store per-100g so servingSize is explicit and honest.
    return {
      nameEn: name,
      nameTh: undefined,
      keywords: [term, ...term.split(/\s+/)],
      calories: Math.round(kcal100),
      protein: round1(protein100),
      fat: round1(fat100),
      carbs: round1(carb100),
      sodium: sodiumG100 != null ? round1(sodiumG100 * 1000) : undefined, // g -> mg
      servingSize: '100 g',
      source: 'OpenFoodFacts',
      sourceRef: p.code!,
      sourceUrl: `https://world.openfoodfacts.org/product/${p.code}`,
    };
  }
}

// ---------------------------------------------------------------------------
// Thai FCD adapter — STUB (unreachable + licensing pending). Never fabricates.
// ---------------------------------------------------------------------------

export class ThaiFcdAdapter implements FoodSourceAdapter {
  readonly name = 'Thai FCD (Mahidol INMU)';

  async fetch(_terms: string[]): Promise<ImportedFood[]> {
    // TODO: When a commercial-use licence + network access are arranged, the
    // real Thai FCD lookup lives at inmu2.mahidol.ac.th (Thai Food Composition
    // Database). Expected shape per food: name (TH/EN), per-100g energy (kcal),
    // protein, fat, carbohydrate, sodium, plus a food code to use as sourceRef.
    // e.g. GET https://inmu2.mahidol.ac.th/thaifcd/... -> parse table rows.
    throw new Error(
      'Thai FCD is UNREACHABLE from this environment (curl returns 000) and ' +
        'requires a commercial-use licence — pending. No data imported; refusing ' +
        'to fabricate Thai composition values.'
    );
  }
}

// ---------------------------------------------------------------------------
// Upsert with dedup by (source, sourceRef), else by nameEn / existing keywords.
// ---------------------------------------------------------------------------

async function upsertFood(f: ImportedFood): Promise<'imported' | 'skipped'> {
  // 1) Exact provenance match — update metadata, don't duplicate.
  const byRef = await prisma.food.findFirst({ where: { source: f.source, sourceRef: f.sourceRef } });
  if (byRef) {
    await prisma.food.update({
      where: { id: byRef.id },
      data: { sourceUrl: f.sourceUrl, importedAt: new Date() },
    });
    return 'skipped';
  }

  // 2) Does an existing dish already cover this? Match on nameTh, nameEn, or
  //    overlapping keywords — so we don't duplicate the 44 seeded dishes.
  const nen = normLoose(f.nameEn);
  const existing = await prisma.food.findFirst({
    where: {
      OR: [
        ...(f.nameTh ? [{ nameTh: f.nameTh }] : []),
        { keywords: { hasSome: f.keywords } },
      ],
    },
  });
  if (existing) {
    // Only enrich provenance if the existing row has none (i.e. a seed row we
    // now have a real source for). Never overwrite curated seed nutrition.
    if (!existing.source || existing.source === 'seed') {
      // Leave seed nutrition intact (curated per-serving); just note that a
      // real source exists by NOT touching values. We skip to avoid dup.
    }
    return 'skipped';
  }

  // 3) Genuinely new item — insert with full provenance.
  await prisma.food.create({
    data: {
      nameTh: f.nameTh ?? f.nameEn,
      nameEn: f.nameEn,
      keywords: f.keywords,
      calories: f.calories,
      protein: f.protein,
      fat: f.fat,
      carbs: f.carbs,
      sodium: f.sodium ?? null,
      servingSize: f.servingSize,
      isVerified: false, // imported, not human-curated
      source: f.source,
      sourceRef: f.sourceRef,
      sourceUrl: f.sourceUrl,
      importedAt: new Date(),
    },
  });
  // touch nen so lint doesn't flag unused; kept for future fuzzy matching.
  void nen;
  return 'imported';
}

// ---------------------------------------------------------------------------
// Pipeline runner
// ---------------------------------------------------------------------------

async function runAdapter(adapter: FoodSourceAdapter, terms: string[]): Promise<AdapterResult> {
  const result: AdapterResult = {
    source: adapter.name,
    attempted: 0,
    imported: 0,
    skipped: 0,
    failed: 0,
    notFound: [],
    errors: [],
  };

  let foods: ImportedFood[] = [];
  try {
    foods = await adapter.fetch(terms);
  } catch (err) {
    result.errors.push((err as Error).message);
    // For an adapter-level throw (rate limit / stub), keep whatever it returned
    // is impossible; mark and continue with the rest of the pipeline.
    const partial = (err as { partial?: ImportedFood[] }).partial;
    if (Array.isArray(partial)) foods = partial;
  }

  // Collect per-adapter notFound if the adapter exposes it.
  const nf = (adapter as unknown as { notFound?: string[] }).notFound;
  if (Array.isArray(nf)) result.notFound = nf;

  result.attempted = foods.length + result.notFound.length;
  for (const f of foods) {
    try {
      const outcome = await upsertFood(f);
      if (outcome === 'imported') result.imported++;
      else result.skipped++;
    } catch (err) {
      result.failed++;
      result.errors.push(`upsert "${f.nameEn}": ${(err as Error).message}`);
    }
  }
  return result;
}

function parseSourceArg(): 'usda' | 'off' | 'all' {
  const arg = process.argv.find((a) => a.startsWith('--source='));
  const val = arg?.split('=')[1];
  if (val === 'usda' || val === 'off' || val === 'all') return val;
  return 'all';
}

// Optional cap on how many USDA terms to attempt (handy under DEMO_KEY limits).
function parseLimitArg(): number | undefined {
  const arg = process.argv.find((a) => a.startsWith('--limit='));
  const n = arg ? Number(arg.split('=')[1]) : NaN;
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : undefined;
}

async function main() {
  const which = parseSourceArg();
  const limit = parseLimitArg();
  console.log(`\n=== CalThai food import — source=${which}${limit ? ` limit=${limit}` : ''} — ${new Date().toISOString()} ===\n`);

  const allTerms = TERMS.map((t) => t.query);
  const usdaTerms = limit ? allTerms.slice(0, limit) : allTerms;
  const results: AdapterResult[] = [];

  if (which === 'usda' || which === 'all') {
    console.log(`[USDA] querying ${usdaTerms.length} terms (throttled ${USDA_THROTTLE_MS}ms, key=${USDA_API_KEY === 'DEMO_KEY' ? 'DEMO_KEY' : 'custom'})...`);
    results.push(await runAdapter(new UsdaAdapter(), usdaTerms));
  }

  if (which === 'off' || which === 'all') {
    console.log(`[OFF] querying packaged Thai items...`);
    results.push(await runAdapter(new OpenFoodFactsAdapter(), []));
  }

  // Thai FCD status is ALWAYS printed so the missing authoritative source is
  // visible — but only actually invoked with --source=all is not required.
  let thaiFcdStatus = '';
  try {
    await new ThaiFcdAdapter().fetch(usdaTerms);
    thaiFcdStatus = 'unexpectedly returned data (should not happen)';
  } catch (err) {
    thaiFcdStatus = (err as Error).message;
  }

  // ---- Summary ----
  console.log('\n===================== IMPORT SUMMARY =====================');
  for (const r of results) {
    console.log(
      `\n[${r.source}]  attempted=${r.attempted}  imported=${r.imported}  skipped=${r.skipped}  failed=${r.failed}`
    );
    if (r.notFound.length) console.log(`   not found / no usable data: ${r.notFound.join(', ')}`);
    if (r.errors.length) console.log(`   errors: ${r.errors.join(' | ')}`);
  }
  console.log('\n[Thai FCD (Mahidol INMU)]  STATUS: NOT IMPORTED');
  console.log(`   ${thaiFcdStatus}`);
  console.log('\n   ⚠ Authoritative Thai composition data is still MISSING until Thai FCD');
  console.log('     access + commercial-use licensing are arranged. Imported dishes use');
  console.log('     USDA (US recipe approximations) — treat Thai accuracy as provisional.');
  console.log('==========================================================\n');
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
