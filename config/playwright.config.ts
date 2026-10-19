import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig, devices } from '@playwright/test';
import { env } from './env.js';

const projectRoot = fileURLToPath(new URL('../', import.meta.url));
const configuredReportDir = process.env.REPORT_DIR?.trim();
const reportDir = path.resolve(projectRoot, configuredReportDir || 'reports');

export default defineConfig({
  testDir: path.join(projectRoot, 'tests'),
  testIgnore: ['**/android/**'],
  fullyParallel: true,
  forbidOnly: env.isCI,
  retries: env.isCI ? 1 : 0,
  reporter: [
    ['list'],
    ['html', { outputFolder: path.join(reportDir, 'html'), open: 'never' }],
    ['json', { outputFile: path.join(reportDir, 'results.json') }],
  ],
  outputDir: path.join(reportDir, 'test-results'),
  use: {
    baseURL: env.baseURL,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    ...devices['Desktop Chrome'],
  },
  webServer: env.useDemoServer
    ? {
        command: 'node scripts/serve-demo.mjs',
        cwd: projectRoot,
        url: env.baseURL,
        reuseExistingServer: !env.isCI,
        timeout: 15_000,
      }
    : undefined,
});
