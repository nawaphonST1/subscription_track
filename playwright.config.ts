import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['junit', { outputFile: 'reports/e2e-junit.xml' }],
  ],
  use: {
    baseURL: process.env.API_BASE_URL || 'http://localhost:3000',
    extraHTTPHeaders: {
      'Accept': 'application/json',
    },
  },
  webServer: {
    command: 'node e2e/mock-taskflow-api.mjs',
    url: 'http://localhost:3000/health',
    reuseExistingServer: true,
    timeout: 15000,
  },
});
