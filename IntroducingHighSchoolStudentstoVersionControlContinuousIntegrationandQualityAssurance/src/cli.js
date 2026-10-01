#!/usr/bin/env node
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { Gradebook } from './gradebook.js';
import { formatReport } from './format.js';

const DEFAULT_DATA = fileURLToPath(new URL('../data/sample-class.json', import.meta.url));

/**
 * Runs the CLI. Returns the exit code so it can be tested without exiting the process.
 * Usage: gradebook [path/to/class.json] [--json]
 * @param {string[]} argv
 * @param {{ log?: (msg: string) => void, error?: (msg: string) => void }} [io]
 */
export async function run(argv, io = {}) {
  const log = io.log ?? console.log;
  const error = io.error ?? console.error;
  const asJson = argv.includes('--json');
  const fileArg = argv.find((arg) => !arg.startsWith('--'));
  const file = fileArg ? path.resolve(fileArg) : DEFAULT_DATA;

  try {
    const data = JSON.parse(await readFile(file, 'utf8'));
    const report = Gradebook.fromJSON(data).report();
    log(asJson ? JSON.stringify(report, null, 2) : formatReport(report));
    return 0;
  } catch (err) {
    error(`gradebook: ${err.message}`);
    return 1;
  }
}

// Only run when executed directly (not when imported by tests).
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  process.exitCode = await run(process.argv.slice(2));
}
