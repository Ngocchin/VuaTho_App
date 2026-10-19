import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = fileURLToPath(new URL('../', import.meta.url));
const configuredReportDir = process.env.ANDROID_REPORT_DIR?.trim();
const resultsDir = configuredReportDir
  ? path.resolve(projectRoot, configuredReportDir)
  : path.join(projectRoot, 'reports', 'android');
const appiumPort = Number(process.env.APPIUM_PORT ?? 4723);
const emulatorSerial = process.env.ANDROID_UDID;

if (!Number.isInteger(appiumPort) || appiumPort < 1 || appiumPort > 65_535) {
  throw new Error('APPIUM_PORT must be an integer between 1 and 65535.');
}

if (!emulatorSerial || !/^emulator-\d+$/.test(emulatorSerial)) {
  throw new Error('Set ANDROID_UDID to an online emulator serial. Physical devices are excluded from this smoke suite.');
}

export const config: WebdriverIO.Config = {
  runner: 'local',
  specs: [path.join(projectRoot, 'tests', 'android', '**', '*.spec.ts')],
  maxInstances: 1,
  capabilities: [
    {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:deviceName': process.env.ANDROID_DEVICE_NAME ?? 'Android Emulator',
      'appium:udid': emulatorSerial,
      'appium:appPackage': 'com.android.settings',
      'appium:appActivity': 'com.android.settings.Settings',
      'appium:noReset': true,
      'appium:forceAppLaunch': true,
      'appium:newCommandTimeout': 90,
    },
  ],
  hostname: '127.0.0.1',
  port: appiumPort,
  path: '/',
  logLevel: 'warn',
  framework: 'mocha',
  reporters: [
    'spec',
    [
      'allure',
      {
        outputDir: path.join(resultsDir, 'allure-results'),
        disableWebdriverStepsReporting: true,
        disableWebdriverScreenshotsReporting: false,
      },
    ],
  ],
  mochaOpts: {
    timeout: 60_000,
  },
  waitforTimeout: 10_000,
  connectionRetryTimeout: 120_000,
  connectionRetryCount: 1,
  async afterTest(test, _context, { error }) {
    if (!error) return;

    const safeName = test.title.replace(/[^a-z0-9_-]+/gi, '-').slice(0, 80) || 'failed-test';
    const screenshotPath = path.join(resultsDir, 'screenshots', `${Date.now()}-${safeName}.png`);
    await mkdir(path.dirname(screenshotPath), { recursive: true });
    await browser.saveScreenshot(screenshotPath);
  },
};
