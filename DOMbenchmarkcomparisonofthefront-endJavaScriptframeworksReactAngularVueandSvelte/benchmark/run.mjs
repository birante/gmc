#!/usr/bin/env node
/**
 * DOM benchmark harness for the React / Angular / Vue / Svelte to-do apps.
 *
 *   node run.mjs [--skip-build] [--iterations 15] [--warmup 5] [--memory-runs 5]
 *                [--frameworks react,vue,svelte,angular] [--headful]
 *
 * Steps
 *   1. builds each app for production (npm run build; npm install first if needed)
 *   2. serves every dist/ folder with a tiny static server (one port per app)
 *   3. runs a functional smoke test (add / edit / remove) and a DOM-structure check
 *   4. measures each operation N times (after warm-up) in headless Chrome
 *   5. measures JS heap through the Chrome DevTools Protocol
 *   6. writes results/results.json, results/results.md, results/chart.html, results/chart.svg
 */
import { execSync } from 'node:child_process';
import fs from 'node:fs';
import http from 'node:http';
import os from 'node:os';
import zlib from 'node:zlib';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import puppeteer from 'puppeteer';
import { computeExecutablePath, Browser } from '@puppeteer/browsers';
import { PUPPETEER_REVISIONS } from 'puppeteer-core/internal/revisions.js';
import { writeReports } from './report.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const RESULTS_DIR = path.join(__dirname, 'results');

// ---------------------------------------------------------------- CLI options
const argv = process.argv.slice(2);
const opt = (name, def) => {
  const i = argv.indexOf(`--${name}`);
  return i === -1 ? def : argv[i + 1];
};
const flag = (name) => argv.includes(`--${name}`);
const ITERATIONS = Number(opt('iterations', 15));
const WARMUP = Number(opt('warmup', 5));
const MEMORY_RUNS = Number(opt('memory-runs', 5));
const SKIP_BUILD = flag('skip-build');
const HEADFUL = flag('headful');

const ALL_FRAMEWORKS = [
  { key: 'react', label: 'React', dir: 'react', dist: 'react/dist', port: 4101 },
  { key: 'angular', label: 'Angular', dir: 'angular', dist: 'angular/dist/angular/browser', port: 4102 },
  { key: 'vue', label: 'Vue', dir: 'vue', dist: 'vue/dist', port: 4103 },
  { key: 'svelte', label: 'Svelte', dir: 'svelte', dist: 'svelte/dist', port: 4104 },
];
const wanted = opt('frameworks', ALL_FRAMEWORKS.map((f) => f.key).join(',')).split(',');
const FRAMEWORKS = ALL_FRAMEWORKS.filter((f) => wanted.includes(f.key));

/**
 * Operations. `setup` brings the page into the required state (not timed),
 * `button` is the id clicked inside the timed window, `expect` validates the DOM afterwards.
 */
const OPERATIONS = [
  { key: 'render100', label: 'Render 100 tasks', setup: ['clear'], button: 'run-100', expect: { count: 100 } },
  { key: 'render500', label: 'Render 500 tasks', setup: ['clear'], button: 'run-500', expect: { count: 500 } },
  { key: 'render1000', label: 'Render 1000 tasks', setup: ['clear'], button: 'run-1000', expect: { count: 1000 } },
  { key: 'update50', label: 'Update 50 tasks (of 1000)', setup: ['clear', 'run-1000'], button: 'update-50', expect: { count: 1000, firstEndsWith: '!!!' } },
  { key: 'delete50', label: 'Delete 50 tasks (of 1000)', setup: ['clear', 'run-1000'], button: 'delete-50', expect: { count: 950 } },
];

// ---------------------------------------------------------------- helpers
const log = (...a) => console.log('[bench]', ...a);

function sh(cmd, cwd) {
  return execSync(cmd, { cwd, stdio: ['ignore', 'pipe', 'pipe'], encoding: 'utf8' });
}

function stats(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const n = sorted.length;
  const mean = sorted.reduce((s, v) => s + v, 0) / n;
  const median = n % 2 ? sorted[(n - 1) / 2] : (sorted[n / 2 - 1] + sorted[n / 2]) / 2;
  const stdev = Math.sqrt(sorted.reduce((s, v) => s + (v - mean) ** 2, 0) / (n > 1 ? n - 1 : 1));
  const r = (v) => Math.round(v * 100) / 100;
  return { n, mean: r(mean), median: r(median), stdev: r(stdev), min: r(sorted[0]), max: r(sorted[n - 1]), samples: values.map(r) };
}

const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.ico': 'image/x-icon', '.svg': 'image/svg+xml', '.json': 'application/json' };

function serve(dir, port) {
  const server = http.createServer((req, res) => {
    const urlPath = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    let file = path.join(dir, urlPath);
    if (!file.startsWith(dir) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) file = path.join(dir, 'index.html');
    res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store' });
    fs.createReadStream(file).pipe(res);
  });
  return new Promise((resolve) => server.listen(port, '127.0.0.1', () => resolve(server)));
}

function gzipSizeOfDir(dir) {
  // total raw + gzip size of the JS shipped to the browser
  let raw = 0, gz = 0;
  const walk = (d) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (p.endsWith('.js')) {
        const buf = fs.readFileSync(p);
        raw += buf.length;
        gz += zlib.gzipSync(buf, { level: 9 }).length;
      }
    }
  };
  walk(dir);
  return { jsRawKB: +(raw / 1024).toFixed(1), jsGzipKB: +(gz / 1024).toFixed(1) };
}

function versions(fw) {
  const read = (pkg) => {
    try { return JSON.parse(fs.readFileSync(path.join(ROOT, fw.dir, 'node_modules', pkg, 'package.json'), 'utf8')).version; } catch { return null; }
  };
  const map = { react: ['react', 'react-dom'], angular: ['@angular/core'], vue: ['vue'], svelte: ['svelte'] };
  return Object.fromEntries([...map[fw.key], 'vite', '@angular/build'].map((p) => [p, read(p)]).filter(([, v]) => v));
}

// ---------------------------------------------------------------- in-page code
// Injected into every page. `measure` returns two numbers for one click:
//
//  * update (primary metric): performance.now() from button.click() until the
//    framework has patched the DOM *and* the browser has recalculated style and
//    layout for it. The framework flush is awaited with setTimeout(0): React 19,
//    Vue 3 and Svelte 5 flush in a microtask, zoneless Angular schedules change
//    detection with setTimeout(0) racing requestAnimationFrame - a timer queued
//    after the click runs after all of those. Reading document.body.offsetHeight
//    then forces the synchronous style + layout pass. Paint is not included.
//  * frame (secondary): time until the next frame has been produced
//    (requestAnimationFrame + setTimeout(0)). It includes waiting for the next
//    vsync, so it is quantised to ~16.7 ms frames and mostly shows whether an
//    operation fits in one frame.
//
// The row count is checked at the end of the timed window so an asynchronous
// render cannot escape the measurement.
const IN_PAGE = () => {
  const nextPaint = () => new Promise((r) => requestAnimationFrame(() => setTimeout(r, 0)));
  const macrotask = () => new Promise((r) => setTimeout(r, 0));
  window.__bench = {
    nextPaint,
    async settle() { await nextPaint(); await nextPaint(); },
    async measure(id) {
      const btn = document.getElementById(id);
      if (!btn) throw new Error(`button #${id} not found`);
      const t0 = performance.now();
      btn.click();
      await macrotask();
      void document.body.offsetHeight; // force style + layout
      const t1 = performance.now();
      const rowsAtT1 = document.querySelectorAll('#task-list > li');
      const countAtT1 = rowsAtT1.length;
      const firstAtT1 = rowsAtT1[0]?.querySelector('.task-name')?.textContent ?? '';
      await nextPaint();
      const t2 = performance.now();
      return { update: t1 - t0, frame: t2 - t0, countAtT1, firstAtT1 };
    },
    async click(id) { document.getElementById(id).click(); await this.settle(); },
    state() {
      const rows = document.querySelectorAll('#task-list > li');
      const first = rows[0]?.querySelector('.task-name')?.textContent ?? null;
      return { count: rows.length, first, label: document.getElementById('task-count')?.textContent.trim() };
    },
  };
};

async function openApp(browser, fw) {
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 900 });
  const cdp = await page.createCDPSession();
  await cdp.send('Performance.enable');
  await page.goto(`http://127.0.0.1:${fw.port}/`, { waitUntil: 'networkidle0' });
  await page.waitForSelector('#run-1000');
  await page.evaluate(IN_PAGE);
  await page.evaluate(() => window.__bench.settle());
  return { page, cdp };
}

async function gc(cdp) {
  await cdp.send('HeapProfiler.collectGarbage');
  await cdp.send('HeapProfiler.collectGarbage');
}

async function metrics(cdp) {
  const { metrics } = await cdp.send('Performance.getMetrics');
  return Object.fromEntries(metrics.map((m) => [m.name, m.value]));
}

// ---------------------------------------------------------------- smoke test
async function smokeTest(browser, fw) {
  const { page } = await openApp(browser, fw);
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  const s = () => page.evaluate(() => window.__bench.state());
  const check = (cond, msg) => { if (!cond) throw new Error(`[${fw.key}] smoke test failed: ${msg}`); };

  // add
  await page.type('#task-name', 'Buy milk');
  await page.select('#task-priority', 'high');
  await page.click('#add-task');
  await page.evaluate(() => window.__bench.settle());
  let st = await s();
  check(st.count === 1 && st.first === 'Buy milk', `add -> ${JSON.stringify(st)}`);
  check((await page.$eval('#task-list > li .badge', (e) => e.textContent.trim())) === 'high', 'priority shown');
  check((await page.$eval('#task-name', (e) => e.value)) === '', 'input cleared after add');

  // edit
  await page.click('#task-list > li .edit');
  await page.evaluate(() => window.__bench.settle());
  const editValue = await page.$eval('#task-list > li .edit-name', (e) => e.value);
  check(editValue === 'Buy milk', `edit input pre-filled (${editValue})`);
  await page.$eval('#task-list > li .edit-name', (e) => { e.value = ''; });
  await page.type('#task-list > li .edit-name', 'Buy oat milk');
  await page.select('#task-list > li .edit-priority', 'low');
  await page.click('#task-list > li .save');
  await page.evaluate(() => window.__bench.settle());
  st = await s();
  check(st.first === 'Buy oat milk', `edit name -> ${st.first}`);
  check((await page.$eval('#task-list > li .badge', (e) => e.className)) === 'badge priority-low', 'edit priority');

  // DOM structure signature of one row (view mode) - must be identical across frameworks
  const signature = await page.evaluate(() => {
    const sig = (el) => el.tagName.toLowerCase() + '.' + [...el.classList].sort().join('.') +
      '[' + [...el.attributes].map((a) => a.name).filter((n) => n.startsWith('data-') || n === 'id').sort().join(',') + ']' +
      (el.children.length ? '(' + [...el.children].map(sig).join(' ') + ')' : '');
    return sig(document.querySelector('#task-list > li'));
  });

  // remove
  await page.click('#task-list > li .remove');
  await page.evaluate(() => window.__bench.settle());
  st = await s();
  check(st.count === 0, 'remove');
  check(!!(await page.$('[data-testid="empty"]')), 'empty state');

  // benchmark buttons
  for (const op of OPERATIONS) {
    for (const b of op.setup) await page.evaluate((id) => window.__bench.click(id), b);
    await page.evaluate((id) => window.__bench.click(id), op.button);
    st = await s();
    check(st.count === op.expect.count, `${op.key} count ${st.count}`);
    check(st.label === `${op.expect.count} tasks`, `${op.key} label ${st.label}`);
  }
  check(errors.length === 0, `page errors: ${errors.join('; ')}`);
  await page.close();
  return signature;
}

// ---------------------------------------------------------------- benchmarks
async function benchOperation(browser, fw, op) {
  const { page, cdp } = await openApp(browser, fw);
  const samples = [];
  const frames = [];
  for (let i = 0; i < WARMUP + ITERATIONS; i++) {
    for (const b of op.setup) await page.evaluate((id) => window.__bench.click(id), b);
    await gc(cdp); // keep GC pauses from previous iterations out of the timed window
    await page.evaluate(() => window.__bench.settle());
    const m = await page.evaluate((id) => window.__bench.measure(id), op.button);
    if (m.countAtT1 !== op.expect.count) throw new Error(`${fw.key}/${op.key}: expected ${op.expect.count} rows at end of timed window, got ${m.countAtT1}`);
    if (op.expect.firstEndsWith && !m.firstAtT1.endsWith(op.expect.firstEndsWith)) throw new Error(`${fw.key}/${op.key}: update not visible at end of timed window`);
    if (i >= WARMUP) { samples.push(m.update); frames.push(m.frame); }
  }
  await page.close();
  return { ...stats(samples), frame: stats(frames) };
}

async function benchMemory(browser, fw) {
  const runs = { ready: [], rows1000: [], afterUpdateDelete: [], afterClear: [], nodes1000: [] };
  for (let r = 0; r < MEMORY_RUNS; r++) {
    const { page, cdp } = await openApp(browser, fw);
    const heap = async () => { await gc(cdp); return (await metrics(cdp)).JSHeapUsedSize / 1024 / 1024; };
    runs.ready.push(await heap());
    await page.evaluate(() => window.__bench.click('run-1000'));
    runs.rows1000.push(await heap());
    runs.nodes1000.push((await metrics(cdp)).Nodes);
    await page.evaluate(() => window.__bench.click('update-50'));
    await page.evaluate(() => window.__bench.click('delete-50'));
    runs.afterUpdateDelete.push(await heap());
    await page.evaluate(() => window.__bench.click('clear'));
    runs.afterClear.push(await heap());
    await page.close();
  }
  const med = (a) => stats(a);
  return {
    unit: 'MB (JSHeapUsedSize after forced GC)',
    ready: med(runs.ready),
    rows1000: med(runs.rows1000),
    afterUpdateDelete: med(runs.afterUpdateDelete),
    afterClear: med(runs.afterClear),
    domNodes1000: med(runs.nodes1000),
  };
}

// ---------------------------------------------------------------- main
async function main() {
  fs.mkdirSync(RESULTS_DIR, { recursive: true });

  if (!SKIP_BUILD) {
    for (const fw of FRAMEWORKS) {
      const cwd = path.join(ROOT, fw.dir);
      if (!fs.existsSync(path.join(cwd, 'node_modules'))) { log(`npm install (${fw.key})`); sh('npm install', cwd); }
      log(`building ${fw.key} for production...`);
      sh('npm run build', cwd);
    }
  }
  for (const fw of FRAMEWORKS) {
    fw.distAbs = path.join(ROOT, fw.dist);
    if (!fs.existsSync(path.join(fw.distAbs, 'index.html'))) throw new Error(`no build found in ${fw.dist}`);
  }

  const servers = await Promise.all(FRAMEWORKS.map((fw) => serve(fw.distAbs, fw.port)));

  // Use the Chrome for Testing build pinned by Puppeteer (ignores PUPPETEER_EXECUTABLE_PATH
  // so results do not depend on whatever browser happens to be configured globally).
  const cacheDir = path.join(os.homedir(), '.cache', 'puppeteer');
  const executablePath = opt('chrome', computeExecutablePath({ browser: Browser.CHROME, buildId: PUPPETEER_REVISIONS.chrome, cacheDir }));
  const browser = await puppeteer.launch({
    headless: !HEADFUL,
    executablePath,
    args: ['--window-size=1280,900', '--disable-extensions', '--disable-background-timer-throttling', '--disable-renderer-backgrounding'],
  });
  const browserVersion = await browser.version();
  log(`browser: ${browserVersion}`);

  const results = {
    meta: {
      date: new Date().toISOString(),
      browser: browserVersion,
      headless: !HEADFUL,
      node: process.version,
      os: `${os.type()} ${os.release()} (${os.arch()})`,
      cpu: os.cpus()[0]?.model,
      cores: os.cpus().length,
      ramGB: Math.round(os.totalmem() / 1024 ** 3),
      iterations: ITERATIONS,
      warmup: WARMUP,
      memoryRuns: MEMORY_RUNS,
      timing: 'update = performance.now() from button.click() until framework flush (setTimeout 0) + forced style/layout (offsetHeight); frame = until next rendered frame (rAF + setTimeout 0)',
    },
    frameworks: {},
    operations: OPERATIONS.map(({ key, label }) => ({ key, label })),
  };

  try {
    const signatures = {};
    for (const fw of FRAMEWORKS) {
      log(`smoke test ${fw.key}`);
      signatures[fw.key] = await smokeTest(browser, fw);
    }
    const uniq = new Set(Object.values(signatures));
    results.meta.domStructureIdentical = uniq.size === 1;
    results.meta.rowSignatures = signatures;
    log(`row DOM structure identical across frameworks: ${uniq.size === 1}`);
    if (uniq.size !== 1) console.warn(signatures);

    for (const fw of FRAMEWORKS) {
      const entry = { label: fw.label, versions: versions(fw), bundle: gzipSizeOfDir(fw.distAbs), timings: {} };
      for (const op of OPERATIONS) {
        entry.timings[op.key] = await benchOperation(browser, fw, op);
        log(`${fw.key.padEnd(8)} ${op.key.padEnd(11)} median ${entry.timings[op.key].median} ms`);
      }
      entry.memory = await benchMemory(browser, fw);
      log(`${fw.key.padEnd(8)} memory     ready ${entry.memory.ready.median.toFixed(2)} MB, 1000 rows ${entry.memory.rows1000.median.toFixed(2)} MB`);
      results.frameworks[fw.key] = entry;
    }
  } finally {
    await browser.close();
    servers.forEach((s) => s.close());
  }

  fs.writeFileSync(path.join(RESULTS_DIR, 'results.json'), JSON.stringify(results, null, 2) + '\n');
  writeReports(results, RESULTS_DIR);
  log('wrote results/results.json, results/results.md, results/chart.html, results/chart.svg');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
