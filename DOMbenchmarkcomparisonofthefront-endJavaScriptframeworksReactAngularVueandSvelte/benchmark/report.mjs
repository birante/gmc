/**
 * Turns results.json into results.md, chart.html (Chart.js from CDN) and chart.svg (static).
 * Can be run on its own:  node report.mjs   (re-reads results/results.json)
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Categorical colors, fixed order (one per framework, never by rank).
const COLORS = {
  react: { light: '#2a78d6', dark: '#3987e5' },
  angular: { light: '#eb6834', dark: '#d95926' },
  vue: { light: '#1baf7a', dark: '#199e70' },
  svelte: { light: '#eda100', dark: '#c98500' },
};

const fmt = (v, d = 2) => Number(v).toFixed(d);

function panels(results) {
  const fws = Object.keys(results.frameworks);
  const list = results.operations.map((op) => ({
    key: op.key,
    title: `${op.label} (median ms)`,
    unit: 'ms',
    values: fws.map((fw) => results.frameworks[fw].timings[op.key]),
  }));
  list.push({
    key: 'memory',
    title: 'JS heap with 1000 tasks (median MB)',
    unit: 'MB',
    values: fws.map((fw) => results.frameworks[fw].memory.rows1000),
  });
  return { fws, list };
}

function markdown(results) {
  const { meta, frameworks, operations } = results;
  const fws = Object.keys(frameworks);
  const L = [];
  L.push('# Benchmark results', '');
  L.push(`- Date: ${meta.date}`);
  L.push(`- Browser: ${meta.browser} (${meta.headless ? 'headless' : 'headful'}), Node ${meta.node}`);
  L.push(`- Machine: ${meta.cpu}, ${meta.cores} cores, ${meta.ramGB} GB RAM, ${meta.os}`);
  L.push(`- ${meta.iterations} measured iterations per operation after ${meta.warmup} warm-up iterations; memory: ${meta.memoryRuns} fresh page loads`);
  L.push(`- Timing: ${meta.timing}`);
  L.push(`- Row DOM structure identical across frameworks: ${meta.domStructureIdentical ? 'yes' : 'NO'}`);
  L.push('');
  L.push('## Update time per operation - median in ms (lower is better)', '');
  L.push('Click -> DOM patched -> style + layout done (primary metric). Best value in bold.', '');
  L.push(`| Operation | ${fws.map((f) => frameworks[f].label).join(' | ')} |`);
  L.push(`|---|${fws.map(() => '---:').join('|')}|`);
  for (const op of operations) {
    const meds = fws.map((f) => frameworks[f].timings[op.key].median);
    const best = Math.min(...meds);
    L.push(`| ${op.label} | ${meds.map((m) => (m === best ? `**${fmt(m)}**` : fmt(m))).join(' | ')} |`);
  }
  L.push('');
  L.push('## Time per operation - mean ± standard deviation (min-max) in ms', '');
  L.push(`| Operation | ${fws.map((f) => frameworks[f].label).join(' | ')} |`);
  L.push(`|---|${fws.map(() => '---:').join('|')}|`);
  for (const op of operations) {
    L.push(`| ${op.label} | ${fws.map((f) => { const t = frameworks[f].timings[op.key]; return `${fmt(t.mean)} ± ${fmt(t.stdev)} (${fmt(t.min)}-${fmt(t.max)})`; }).join(' | ')} |`);
  }
  L.push('');
  L.push('## Click to next rendered frame - median in ms', '');
  L.push('Includes waiting for the next vsync (~16.7 ms frames at 60 Hz), so values cluster on frame boundaries.', '');
  L.push(`| Operation | ${fws.map((f) => frameworks[f].label).join(' | ')} |`);
  L.push(`|---|${fws.map(() => '---:').join('|')}|`);
  for (const op of operations) {
    L.push(`| ${op.label} | ${fws.map((f) => fmt(frameworks[f].timings[op.key].frame.median)).join(' | ')} |`);
  }
  L.push('');
  L.push('## Memory - JS heap used after forced GC, median MB (lower is better)', '');
  L.push(`| State | ${fws.map((f) => frameworks[f].label).join(' | ')} |`);
  L.push(`|---|${fws.map(() => '---:').join('|')}|`);
  const memRows = [
    ['App loaded (0 tasks)', (m) => fmt(m.ready.median)],
    ['1000 tasks rendered', (m) => fmt(m.rows1000.median)],
    ['Delta for 1000 tasks', (m) => fmt(m.rows1000.median - m.ready.median)],
    ['After update 50 + delete 50', (m) => fmt(m.afterUpdateDelete.median)],
    ['After clear', (m) => fmt(m.afterClear.median)],
    ['DOM nodes with 1000 tasks', (m) => String(Math.round(m.domNodes1000.median))],
  ];
  for (const [label, f] of memRows) L.push(`| ${label} | ${fws.map((fw) => f(frameworks[fw].memory)).join(' | ')} |`);
  L.push('');
  L.push('## Bundle size and versions', '');
  L.push('| Framework | Versions | JS raw (KB) | JS gzip (KB) |');
  L.push('|---|---|---:|---:|');
  for (const f of fws) {
    const e = frameworks[f];
    L.push(`| ${e.label} | ${Object.entries(e.versions).map(([k, v]) => `${k} ${v}`).join(', ')} | ${e.bundle.jsRawKB} | ${e.bundle.jsGzipKB} |`);
  }
  L.push('');
  return L.join('\n');
}

function chartHtml(results) {
  const { fws, list } = panels(results);
  const data = {
    labels: fws.map((f) => results.frameworks[f].label),
    keys: fws,
    colors: fws.map((f) => COLORS[f]),
    panels: list.map((p) => ({ ...p, values: p.values.map((v) => ({ median: v.median, mean: v.mean, stdev: v.stdev, min: v.min, max: v.max })) })),
    meta: results.meta,
  };
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>DOM Benchmark Results</title>
<style>
  :root { color-scheme: light; --surface: #fcfcfb; --card: #ffffff; --border: #e4e3df; --text: #0b0b0b; --text2: #52514e; --grid: #ecebe7; }
  @media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) { color-scheme: dark; --surface: #1a1a19; --card: #222221; --border: #343432; --text: #ffffff; --text2: #c3c2b7; --grid: #2e2e2c; }
  }
  :root[data-theme="dark"] { color-scheme: dark; --surface: #1a1a19; --card: #222221; --border: #343432; --text: #ffffff; --text2: #c3c2b7; --grid: #2e2e2c; }
  * { box-sizing: border-box; }
  body { margin: 0; padding: 24px 16px; background: var(--surface); color: var(--text); font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
  main { max-width: 1100px; margin: 0 auto; }
  h1 { font-size: 1.5rem; margin: 0 0 4px; }
  .sub { color: var(--text2); margin: 0 0 16px; font-size: .9rem; }
  .legend { display: flex; flex-wrap: wrap; gap: 16px; margin-bottom: 16px; color: var(--text2); font-size: .9rem; }
  .legend span::before { content: ""; display: inline-block; width: 12px; height: 12px; border-radius: 3px; margin-right: 6px; vertical-align: -1px; background: var(--c); }
  .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 16px; }
  .card { background: var(--card); border: 1px solid var(--border); border-radius: 10px; padding: 12px 14px; }
  .card h2 { font-size: .95rem; font-weight: 600; margin: 0 0 8px; }
  .card .plot { position: relative; height: 220px; }
  table { border-collapse: collapse; width: 100%; font-size: .85rem; margin-top: 24px; }
  th, td { border-bottom: 1px solid var(--border); padding: 6px 8px; text-align: right; }
  th:first-child, td:first-child { text-align: left; }
  th { color: var(--text2); font-weight: 600; }
  .table-wrap { overflow-x: auto; }
</style>
</head>
<body>
<main>
  <h1>DOM Benchmark Results</h1>
  <p class="sub" id="sub"></p>
  <div class="legend" id="legend"></div>
  <div class="grid" id="grid"></div>
  <div class="table-wrap"><table id="table"></table></div>
</main>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<script>
const DATA = ${JSON.stringify(data)};
const dark = () => getComputedStyle(document.documentElement).colorScheme.includes('dark');
const css = (v) => getComputedStyle(document.documentElement).getPropertyValue(v).trim();
const m = DATA.meta;
document.getElementById('sub').textContent = m.browser + ' · ' + m.cpu + ' · ' + m.iterations + ' iterations after ' + m.warmup + ' warm-up · bars show the median, hover for mean ± stdev';
document.getElementById('legend').innerHTML = DATA.labels.map((l, i) => '<span style="--c:' + DATA.colors[i][dark() ? 'dark' : 'light'] + '">' + l + '</span>').join('');

// direct value labels above each bar (text in ink colour, not series colour)
const valueLabels = { id: 'valueLabels', afterDatasetsDraw(chart) {
  const { ctx } = chart; ctx.save(); ctx.fillStyle = css('--text2'); ctx.font = '12px system-ui'; ctx.textAlign = 'center';
  chart.getDatasetMeta(0).data.forEach((bar, i) => ctx.fillText(chart.data.datasets[0].data[i].toFixed(chart.$unit === 'MB' ? 2 : 1), bar.x, bar.y - 6));
  ctx.restore(); } };

const grid = document.getElementById('grid');
if (window.Chart) {
  for (const p of DATA.panels) {
    const card = document.createElement('div'); card.className = 'card';
    card.innerHTML = '<h2>' + p.title + '</h2><div class="plot"><canvas role="img" aria-label="' + p.title + '"></canvas></div>';
    grid.appendChild(card);
    const chart = new Chart(card.querySelector('canvas'), {
      type: 'bar',
      data: { labels: DATA.labels, datasets: [{ data: p.values.map((v) => v.median), backgroundColor: DATA.colors.map((c) => c[dark() ? 'dark' : 'light']), borderRadius: { topLeft: 4, topRight: 4 }, borderSkipped: 'bottom', maxBarThickness: 48 }] },
      options: {
        maintainAspectRatio: false, layout: { padding: { top: 18 } },
        plugins: { legend: { display: false }, tooltip: { callbacks: { label: (c) => { const v = p.values[c.dataIndex]; return 'median ' + v.median + ' ' + p.unit + ' · mean ' + v.mean + ' ± ' + v.stdev + ' · min ' + v.min + ' · max ' + v.max; } } } },
        scales: { x: { grid: { display: false }, ticks: { color: css('--text2') } }, y: { beginAtZero: true, grid: { color: css('--grid') }, border: { display: false }, ticks: { color: css('--text2') }, title: { display: true, text: p.unit, color: css('--text2') } } },
      },
      plugins: [valueLabels],
    });
    chart.$unit = p.unit;
  }
} else {
  grid.innerHTML = '<p>Chart.js could not be loaded (offline?) - see the table below or chart.svg.</p>';
}

// table view
const t = document.getElementById('table');
t.innerHTML = '<thead><tr><th>Metric (median)</th>' + DATA.labels.map((l) => '<th>' + l + '</th>').join('') + '</tr></thead><tbody>' +
  DATA.panels.map((p) => '<tr><td>' + p.title + '</td>' + p.values.map((v) => '<td>' + v.median.toFixed(2) + '</td>').join('') + '</tr>').join('') + '</tbody>';
</script>
</body>
</html>
`;
}

function chartSvg(results) {
  const { fws, list } = panels(results);
  const cols = 3, pw = 300, ph = 220, gap = 20, top = 70;
  const rows = Math.ceil(list.length / cols);
  const W = cols * pw + (cols + 1) * gap, H = top + rows * (ph + gap) + 10;
  const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;');
  const out = [];
  out.push(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" font-family="system-ui, -apple-system, Segoe UI, Roboto, sans-serif">`);
  out.push(`<rect width="${W}" height="${H}" fill="#fcfcfb"/>`);
  out.push(`<text x="${gap}" y="30" font-size="18" font-weight="600" fill="#0b0b0b">DOM benchmark - median of ${results.meta.iterations} runs (lower is better)</text>`);
  let lx = gap;
  fws.forEach((f) => {
    out.push(`<rect x="${lx}" y="44" width="12" height="12" rx="3" fill="${COLORS[f].light}"/><text x="${lx + 18}" y="54" font-size="13" fill="#52514e">${esc(results.frameworks[f].label)}</text>`);
    lx += 100;
  });
  list.forEach((p, idx) => {
    const x0 = gap + (idx % cols) * (pw + gap), y0 = top + Math.floor(idx / cols) * (ph + gap);
    out.push(`<rect x="${x0}" y="${y0}" width="${pw}" height="${ph}" rx="10" fill="#ffffff" stroke="#e4e3df"/>`);
    out.push(`<text x="${x0 + 12}" y="${y0 + 22}" font-size="13" font-weight="600" fill="#0b0b0b">${esc(p.title)}</text>`);
    const meds = p.values.map((v) => v.median);
    const max = Math.max(...meds) * 1.15 || 1;
    const plotTop = y0 + 48, plotBottom = y0 + ph - 30, plotH = plotBottom - plotTop;
    const slot = (pw - 40) / fws.length, bw = Math.min(44, slot - 12);
    out.push(`<line x1="${x0 + 20}" x2="${x0 + pw - 20}" y1="${plotBottom}" y2="${plotBottom}" stroke="#c9c8c2"/>`);
    meds.forEach((v, i) => {
      const h = (v / max) * plotH, bx = x0 + 20 + i * slot + (slot - bw) / 2, by = plotBottom - h;
      const r = Math.min(4, h / 2);
      out.push(`<path d="M${bx},${plotBottom} V${by + r} Q${bx},${by} ${bx + r},${by} H${bx + bw - r} Q${bx + bw},${by} ${bx + bw},${by + r} V${plotBottom} Z" fill="${COLORS[fws[i]].light}"><title>${esc(results.frameworks[fws[i]].label)}: ${v} ${p.unit}</title></path>`);
      out.push(`<text x="${bx + bw / 2}" y="${by - 6}" font-size="12" text-anchor="middle" fill="#52514e">${v.toFixed(p.unit === 'MB' ? 2 : 1)}</text>`);
      out.push(`<text x="${bx + bw / 2}" y="${plotBottom + 18}" font-size="12" text-anchor="middle" fill="#52514e">${esc(results.frameworks[fws[i]].label)}</text>`);
    });
  });
  out.push('</svg>');
  return out.join('\n');
}

export function writeReports(results, dir) {
  fs.writeFileSync(path.join(dir, 'results.md'), markdown(results));
  fs.writeFileSync(path.join(dir, 'chart.html'), chartHtml(results));
  fs.writeFileSync(path.join(dir, 'chart.svg'), chartSvg(results) + '\n');
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const dir = path.join(path.dirname(fileURLToPath(import.meta.url)), 'results');
  writeReports(JSON.parse(fs.readFileSync(path.join(dir, 'results.json'), 'utf8')), dir);
  console.log('reports regenerated in', dir);
}
