import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '../..');
const serverReportsDir = path.join(__dirname, 'reports');
const serverCoverageDir = path.join(__dirname, 'coverage');
const rootReportsDir = path.join(rootDir, 'reports');
const rootCoverageDir = path.join(rootDir, 'coverage');

const rawArgs = process.argv.slice(2);

// Check if coverage is requested
const hasCoverage = rawArgs.includes('--coverage') || process.env.CI !== undefined;

// Filter out Jest-specific CLI flags that vitest CLI rejects
const ignoredFlags = new Set(['--reporters=jest-junit', '--coverage']);
const extraArgs = rawArgs.filter(arg => !ignoredFlags.has(arg) && !arg.startsWith('--reporters='));

// Locate vitest binary (cross-platform)
const isWindows = process.platform === 'win32';
const vitestBin = path.join(
  __dirname,
  'node_modules',
  '.bin',
  isWindows ? 'vitest.cmd' : 'vitest'
);

const vitestArgs = ['run'];

if (extraArgs.length > 0) {
  vitestArgs.push(...extraArgs);
} else {
  vitestArgs.push('src');
}

// JUnit reporting configuration
vitestArgs.push(
  '--reporter=default',
  '--reporter=junit',
  '--outputFile.junit=reports/junit.xml'
);

// Coverage configuration (Cobertura + LCOV + text)
if (hasCoverage) {
  vitestArgs.push(
    '--coverage',
    '--coverage.reporter=text',
    '--coverage.reporter=cobertura',
    '--coverage.reporter=lcov',
    '--coverage.reportsDirectory=coverage'
  );
}

fs.mkdirSync(serverReportsDir, { recursive: true });
fs.mkdirSync(serverCoverageDir, { recursive: true });

function syncReportsToRoot() {
  try {
    fs.mkdirSync(rootReportsDir, { recursive: true });
    const serverJunit = path.join(serverReportsDir, 'junit.xml');
    const rootJunit = path.join(rootReportsDir, 'junit.xml');
    if (fs.existsSync(serverJunit)) {
      fs.copyFileSync(serverJunit, rootJunit);
      console.log(`[test-runner] Copied ${serverJunit} -> ${rootJunit}`);
    }
  } catch (err) {
    console.warn('[test-runner] Could not sync JUnit report to root:', err.message);
  }

  try {
    fs.mkdirSync(rootCoverageDir, { recursive: true });
    const serverCobertura = path.join(serverCoverageDir, 'cobertura-coverage.xml');
    const rootCobertura = path.join(rootCoverageDir, 'cobertura-coverage.xml');
    if (fs.existsSync(serverCobertura)) {
      fs.copyFileSync(serverCobertura, rootCobertura);
      console.log(`[test-runner] Copied ${serverCobertura} -> ${rootCobertura}`);
    }
    const serverLcov = path.join(serverCoverageDir, 'lcov.info');
    const rootLcov = path.join(rootCoverageDir, 'lcov.info');
    if (fs.existsSync(serverLcov)) {
      fs.copyFileSync(serverLcov, rootLcov);
      console.log(`[test-runner] Copied ${serverLcov} -> ${rootLcov}`);
    }
  } catch (err) {
    console.warn('[test-runner] Could not sync Coverage report to root:', err.message);
  }
}

// Execute vitest
const executable = isWindows ? `"${vitestBin}"` : vitestBin;
const child = spawn(executable, vitestArgs, {
  cwd: __dirname,
  stdio: 'inherit',
  shell: true,
  env: {
    ...process.env,
    NODE_ENV: 'test',
  },
});

child.on('close', (code) => {
  syncReportsToRoot();
  process.exit(code ?? 0);
});

child.on('error', (err) => {
  console.error('[test-runner] Failed to spawn vitest:', err);
  syncReportsToRoot();
  process.exit(1);
});
