/**
 * Daily food-import scheduler (OPTIONAL, NOT auto-started by the API server).
 *
 * Runs the importer once per day at 23:59 Asia/Bangkok. Run it as a separate
 * process / container, or prefer an OS-level cron in production:
 *
 *   npm run import:foods:daily        # long-running node-cron process
 *
 * See docs/DATA_SOURCES.md for details.
 */
import 'dotenv/config';
import cron from 'node-cron';
import { spawn } from 'node:child_process';

const SCHEDULE = '59 23 * * *'; // 23:59 every day
const TIMEZONE = 'Asia/Bangkok';

function runImport() {
  const startedAt = new Date().toISOString();
  console.log(`[scheduler] triggering food import at ${startedAt} (${TIMEZONE})`);

  // Run the importer as its own tsx process so a crash can't kill the scheduler.
  const child = spawn('npx', ['tsx', 'src/jobs/importFoods.ts', '--source=all'], {
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });

  child.on('exit', (code) => {
    console.log(`[scheduler] import finished with exit code ${code}`);
  });
}

if (!cron.validate(SCHEDULE)) {
  console.error(`[scheduler] invalid cron expression: ${SCHEDULE}`);
  process.exit(1);
}

console.log(`[scheduler] started. Food import scheduled at "${SCHEDULE}" (${TIMEZONE}).`);
console.log('[scheduler] leave this process running, or use an OS cron instead. Ctrl+C to stop.');

cron.schedule(SCHEDULE, runImport, { timezone: TIMEZONE });
