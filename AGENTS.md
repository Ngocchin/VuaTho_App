# Codex guidance

## Project scope and architecture

- This repository is a QA automation scaffold with an independent demo web app. It has no Vua Thợ product source. Never infer or fabricate product behavior from package names, screenshots, or the demo.
- Before changing code, read this file, `README.md`, relevant runner configuration, `docs/e2e-adoption-plan.md`, and the existing tests/page objects for the area being changed.
- Keep the layers small: `config/` for runner and environment configuration, `fixtures/` for shared setup, `pages/` for web page operations, `tests/` for scenarios, and `scripts/` for developer tooling. Add an abstraction when multiple call sites need it or there is a clear maintenance reason.
- Playwright is used for browser/web automation only. Native Android automation uses the separate WebdriverIO + Appium + UiAutomator2 runner. Do not describe Playwright as native Android automation. Hybrid WebView coverage must be scoped and configured explicitly.
- Android tests must target an authorized QA build and emulator unless the user explicitly approves another device. The committed smoke test targets Android Settings only. Never point tests at a production app, real account, or real customer data without an explicit test plan and authorization.

## Requirement-to-test workflow

1. Read the app, available documentation, user flow, and acceptance criteria. Record the evidence for observable expected behavior; ask only when target identity, safety, or expected outcome cannot be established.
2. For each test, keep the chain clear: requirement/source -> test plan -> script -> environment -> execution -> evidence -> report. Never invent requirements from UI appearance alone.
3. Prefer accessible role/label/name locators for web and stable accessibility identifiers or UIAutomator selectors for native Android. Avoid fragile CSS/XPath, fixed sleeps, and coordinate taps where semantic interaction is possible.
4. Keep tests isolated with stable setup and assertions tied to user-visible behavior. Use fixtures/page objects only for repeated setup or operations.
5. Run the focused test first, then `npm run lint`, `npm run typecheck`, and the relevant full suite when appropriate. Web tests use `npm test`; Android smoke uses `npm run android:smoke` and requires an online emulator plus the local Android toolchain.
6. On failure, inspect the actual report, screenshot, trace, Appium output, and AndroidRuntime log. Reproduce where practical; classify product bug versus test/fixture/config/environment failure before changing application behavior.
7. Report each command actually run as **PASS**, **FAIL**, **BLOCKED**, or **NOT RUN**. Never infer PASS from code, configuration, a doctor check, or a test file that was not executed.

## Environment, secrets, and artifacts

- Read `.env.example`. `BASE_URL` selects an already-running web app; when empty, Playwright starts the local demo app. Do not commit `.env`, keys, passwords, tokens, production credentials, or real user data.
- Keep test setup deterministic and free of paid model/API dependencies unless a requirement calls for them and budget/credentials are authorized.
- Preserve Playwright artifacts (`reports/test-results`, screenshots, traces, and video) and Android artifacts (`reports/android`) for diagnosis. Reports can expose screen content; inspect before sharing. Do not overwrite or delete existing reports, user fixtures, or data without checking what is there first.
- Android smoke runs must use an `emulator-*` serial. The helper may start an existing AVD (default `Pixel_10_Pro`) without wiping its data; it must never fall back to a connected physical phone. Do not install an unverified APK, clear app data, grant broad permissions, or interact with Vua Thợ until build identity and test scope are confirmed.
- Android browser and native tests have different runners and reports. Playwright does not validate the native Android path.

## External references and dependencies

- Use `tester-army/e2e` as an architectural/method reference: keep runner, engine, app target, and test suite boundaries understandable; favor deterministic assertions; use model-driven steps only for a justified requirement and verify them deterministically.
- Do not copy source or assets from the reference. Its repository declares Apache-2.0; inspect the license, NOTICE, attribution, brand restrictions, and licenses of each dependency before bringing any external code/assets into this repository.
- Prefer free local tools. Before changing framework versions, check official documentation, runtime requirements, and changelogs. Keep Appium/Android SDK setup explicit and separate from npm project dependencies.
- After dependency changes, run `npm audit --omit=optional`; apply compatible upstream patches, document unpatched advisories, and never use `npm audit fix --force` without reviewing its proposed major-version changes.
- Do not deploy production or merge a pull request without the user's approval.
