# VuaTho_App QA Automation

This repository currently contains QA automation scaffolding and a small standalone demo web app. It does not contain Vua Thợ product source code, and the demo is not a simulation of product behavior.

## Runners

- **Web:** TypeScript + Playwright Test. When `BASE_URL` is empty, tests start the local demo app at `http://127.0.0.1:4178` (or `PORT`). When set, `BASE_URL` targets an already-running web app.
- **Native Android:** TypeScript + WebdriverIO + Appium 3 + UiAutomator2. This runner is separate from Playwright. Its smoke test opens Android Settings on an online emulator and verifies the native session package. It does not install or exercise Vua Thợ.

Playwright in this project automates browsers. Native Android automation uses Appium/UiAutomator2; Android WebViews would require an explicitly configured hybrid-app test.

## Requirements

- Node.js 20.19 or newer and npm 10 or newer.
- Chromium installed for browser tests: `npm run install:browsers`.
- For Android: Android SDK platform-tools and emulator, a booted AVD, Java/JDK configured with `JAVA_HOME`, and Appium 3 with the UiAutomator2 driver installed globally.
- To prepare the Android toolchain on a new machine, install Appium and the UiAutomator2 driver using their official instructions, then run `appium driver doctor uiautomator2`. Android tools are deliberately not installed as project dependencies.

The Android environment used for the initial setup reported Windows build 26200, Node.js 22.14.0, Appium 3.1.0, and UiAutomator2 driver 8.7.0. Appium's doctor passed with two optional tools absent (bundletool and GStreamer); they are not required for this smoke test.

## Install and run

```powershell
npm install
npm run install:browsers
npm run lint
npm run typecheck
npm test
```

Android commands (PowerShell on Windows):

```powershell
npm run android:doctor
npm run android:smoke
npm run android:report
```

`android:doctor` writes a timestamped machine-specific diagnostic under ignored `reports/android/`. `android:smoke` selects an online emulator only; if none is online, it starts the existing `Pixel_10_Pro` AVD (or `ANDROID_AVD_NAME`) without wiping its data. It starts Appium on `127.0.0.1` if needed, runs the Settings smoke test, captures diagnostics, and stops only the Appium process it started. It never selects a physical device. A helper-started AVD is shut down gracefully after the run; an emulator that was already running is left untouched.

Each Android execution writes to a new timestamped directory under `reports/android/runs/`, preserving earlier reports and logs. `android:report` generates Allure HTML in a new timestamped directory inside the latest run.

The `android:test` command is intended for the smoke script. The WDIO configuration requires `ANDROID_UDID` to match an emulator serial (`emulator-N`) and hardcodes Android Settings as its only target. Do not repoint it at a Vua Thợ package until an authorized QA build and test scope are confirmed.

## Project layout

- `config/`: Playwright and WebdriverIO configuration plus environment parsing.
- `fixtures/`: shared Playwright setup.
- `pages/`: browser page objects.
- `tests/`: browser demo tests and the isolated native Android smoke test.
- `examples/demo-app/`: deterministic local web target, independent of product behavior.
- `scripts/`: demo server and Android environment/smoke helpers.
- `platforms/android/`: Android runner boundary and extension guidance.
- `docs/e2e-adoption-plan.md`: source-project review, license notes, integration choices, and verification limits.
- `reports/`: generated test results, screenshots, traces, Appium logs, and diagnostic reports; ignored by Git.

## Environment and artifacts

Copy `.env.example` to `.env` when local settings are needed. `REPORT_DIR` can select a separate Playwright artifact directory to preserve earlier reports. Never commit `.env`, credentials, access tokens, passwords, or real user data. Playwright retains trace, screenshot, and video on failure. The Android smoke harness records WebdriverIO/Appium output, AndroidRuntime errors, Allure results, and failure screenshots under `reports/android/`; reports may contain screen content, so inspect them before sharing.

## Test authoring workflow

1. Read the app, user flow, and observable acceptance criteria before writing a test.
2. Keep tests isolated and deterministic; prefer accessible web locators and stable native accessibility identifiers.
3. Use fixtures/page objects for repeated setup and behavior, not as layers without a maintenance reason.
4. Run the focused test first, then lint, typecheck, and the relevant full suite.
5. Inspect report, screenshot, trace, and logs after failures; separate product bugs from test, fixture, and environment issues.
6. Report only executed results as **PASS**, **FAIL**, **BLOCKED**, or **NOT RUN**.

## Reference and reuse

The separation of runner, engine, app target, and test suite is informed by [`tester-army/e2e`](https://github.com/tester-army/e2e). Its repository declares Apache-2.0; this project uses the architecture as a reference and does not copy its source or assets. See [the adoption plan](docs/e2e-adoption-plan.md) for analysis and limits.

## Dependency security

The last `npm audit --omit=optional` still reports 12 High findings through `extract-zip@2.0.1`, a transitive WDIO browser utility dependency. GitHub currently lists no patched release for [GHSA-jmr9-qjv8-65gv](https://github.com/advisories/GHSA-jmr9-qjv8-65gv). The affected archive extraction path is not used by the committed Android Settings smoke, but the package remains installed; the audit is not clean. Do not apply `npm audit fix --force`: it proposes downgrading WDIO to major version 8. See the adoption plan for the other transitive advisories and verified overrides.
