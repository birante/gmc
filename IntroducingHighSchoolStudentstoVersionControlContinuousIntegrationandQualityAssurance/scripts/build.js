// Simple "build" step for a plain JavaScript project:
// 1. syntax-check every source file with `node --check`
// 2. make sure the CLI actually runs on the sample data
// 3. copy the sources + sample data into dist/ (the "artifact")
import { execFileSync } from 'node:child_process';
import { cpSync, mkdirSync, readdirSync, rmSync, writeFileSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const srcDir = path.join(root, 'src');
const distDir = path.join(root, 'dist');

const files = readdirSync(srcDir).filter((f) => f.endsWith('.js'));
for (const file of files) {
  execFileSync(process.execPath, ['--check', path.join(srcDir, file)], { stdio: 'inherit' });
  console.log(`✔ syntax ok: src/${file}`);
}

execFileSync(process.execPath, [path.join(srcDir, 'cli.js')], { stdio: 'ignore' });
console.log('✔ smoke test: CLI ran successfully on sample data');

rmSync(distDir, { recursive: true, force: true });
mkdirSync(distDir, { recursive: true });
cpSync(srcDir, path.join(distDir, 'src'), { recursive: true });
cpSync(path.join(root, 'data'), path.join(distDir, 'data'), { recursive: true });
const pkg = JSON.parse(readFileSync(path.join(root, 'package.json'), 'utf8'));
writeFileSync(
  path.join(distDir, 'build-info.json'),
  JSON.stringify({ name: pkg.name, version: pkg.version, builtAt: new Date().toISOString(), files }, null, 2),
);
console.log(`✔ build complete: ${files.length} files copied to dist/`);
