# Native Android runner

This platform boundary uses TypeScript, WebdriverIO 9, Appium 3, and the UiAutomator2 driver. Playwright remains the browser runner and does not automate native Android UI. Each smoke execution writes to a timestamped directory under `reports/android/runs/` so earlier evidence is preserved.

The initial smoke test intentionally opens the Android Settings system app on an existing emulator. It verifies that a native Appium session can start and target the expected package. This only validates the toolchain; it is not a Vua Thợ product test.

## Local requirements

- Android SDK `platform-tools` and emulator in `PATH`.
- `ANDROID_HOME` (or `ANDROID_SDK_ROOT`) and `JAVA_HOME` configured.
- A booted Android Virtual Device visible as `emulator-*` in `adb devices`.
- Appium 3 and the UiAutomator2 driver installed globally. Run `appium driver doctor uiautomator2` to inspect prerequisites.
- Project dependencies installed with `npm install`.

`npm run android:smoke` selects an online emulator or starts the installed `Pixel_10_Pro` AVD (override with `ANDROID_AVD_NAME`) without wiping its data. It sets the serial only for the child run, starts Appium on localhost when needed, and stops only the server process it started. AVDs started by the helper are shut down gracefully after the run; pre-existing emulators are left running. Physical devices are excluded. Direct WDIO runs require `ANDROID_UDID=emulator-N` and still target Settings because the app package/activity are fixed in `config/wdio.android.conf.ts`.

## Adding product coverage later

First identify the signed QA build, package/application ID, launch activity, target environment, test account/data, and acceptance criteria from authoritative project documentation or the user. Confirm that the selected package is a QA build before changing capabilities. Do not use a production package, install an unknown APK, clear app data, or store credentials in the repository. Write tests only for verified, observable behavior. Use accessibility IDs or stable native selectors, keep tests independent, and preserve Appium logs/screenshots for diagnosis.

The Android runner can later support a hybrid app by explicitly switching to a verified WebView context. Do not assume the app is a WebView based on its UI.
