import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';
import { formatReport } from '../src/format.js';
import { run } from '../src/cli.js';

const execFileAsync = promisify(execFile);
const CLI = fileURLToPath(new URL('../src/cli.js', import.meta.url));

/** Collects everything the CLI prints. */
function captureIO() {
  const out = [];
  const err = [];
  return { out, err, io: { log: (m) => out.push(m), error: (m) => err.push(m) } };
}

describe('formatReport', () => {
  it('prints a table with PASS/FAIL status', () => {
    const text = formatReport({
      className: 'Math',
      studentCount: 2,
      classAverage: 72.5,
      passRate: 50,
      rows: [
        { rank: 1, name: 'Awa', average: 95, letter: 'A', passing: true },
        { rank: 2, name: 'Moussa', average: 50, letter: 'F', passing: false },
      ],
    });
    assert.match(text, /Class: Math/);
    assert.match(text, /Pass rate: 50%/);
    assert.match(text, /Awa\s+95\.00\s+A\s+PASS/);
    assert.match(text, /Moussa\s+50\.00\s+F\s+FAIL/);
  });

  it('handles an empty class', () => {
    const text = formatReport({ className: 'Empty', studentCount: 0, classAverage: null, passRate: null, rows: [] });
    assert.match(text, /Class average: n\/a/);
    assert.match(text, /Pass rate: n\/a/);
    assert.match(text, /No scores recorded yet\./);
  });
});

describe('cli run()', () => {
  it('prints the sample class by default', async () => {
    const { out, io } = captureIO();
    const code = await run([], io);
    assert.equal(code, 0);
    assert.match(out[0], /Grade 10 - Computer Science/);
  });

  it('prints JSON with --json', async () => {
    const { out, io } = captureIO();
    const code = await run(['--json'], io);
    assert.equal(code, 0);
    const report = JSON.parse(out[0]);
    assert.equal(report.studentCount, 4);
    assert.equal(report.rows[0].name, 'Awa');
  });

  it('reads a custom file and reports errors with exit code 1', async () => {
    const dir = await mkdtemp(path.join(tmpdir(), 'gradebook-'));
    try {
      const good = path.join(dir, 'good.json');
      const bad = path.join(dir, 'bad.json');
      await writeFile(good, JSON.stringify({ className: 'Art', students: { Lena: [100] } }));
      await writeFile(bad, '{ not json');

      const ok = captureIO();
      assert.equal(await run([good], ok.io), 0);
      assert.match(ok.out[0], /Lena/);

      const ko = captureIO();
      assert.equal(await run([bad], ko.io), 1);
      assert.match(ko.err[0], /^gradebook: /);
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });

  it('reports a missing file', async () => {
    const { err, io } = captureIO();
    assert.equal(await run(['does-not-exist.json'], io), 1);
    assert.match(err[0], /ENOENT/);
  });

  it('works when executed as a real process', async () => {
    const { stdout } = await execFileAsync(process.execPath, [CLI]);
    assert.match(stdout, /Class average:/);
  });
});
