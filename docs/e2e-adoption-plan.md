# Đánh giá và kế hoạch áp dụng `tester-army/e2e`

Ngày kiểm tra: 2026-10-19. Nguồn được đọc trên nhánh `main` của repository công khai: [tester-army/e2e](https://github.com/tester-army/e2e). Repository có khoảng 851 commit khi trang GitHub được mở; đây là dự án đang hoạt động, vì vậy chi tiết phiên bản có thể đổi.

## Tóm tắt

`e2e` là test runner TypeScript/Node.js cho kiểm thử end-to-end web và mobile. Nó kết hợp test code, fixture engine, locator/assertion và các bước agent ngôn ngữ tự nhiên. Repo mẫu là một monorepo sản phẩm framework khá lớn, không phải starter app để chép nguyên trạng. Repo GitHub đích [Ngocchin/VuaTho_App](https://github.com/Ngocchin/VuaTho_App) là private và có quyền đọc/ghi qua kết nối hiện tại. Kiểm tra lại thấy nhánh `main` có một commit `Initial commit` chỉ chứa README 12 byte; checkout ban đầu chưa có remote hoặc commit. Không có mã ứng dụng hay dữ liệu khác để giữ lại. Do đó không có stack sản phẩm để xác định hoặc regression baseline.

## 1. Phân tích repository tham khảo

### Kiến trúc và cấu trúc

- Root là monorepo ESM TypeScript dùng pnpm workspace. `package.json` khóa `pnpm@12.3.4`; mã package yêu cầu Node `^22.22.3 || >=24.8.0`.
- `packages/e2e` cung cấp SDK, runner, CLI, config, lập lịch worker/retry, session/report, agent API, locator/assertion, OAuth/model adapters và MCP server.
- `packages/web` là engine trình duyệt dựa trên `playwright-core`; `packages/mobile` là engine iOS/Android dựa trên `agent-device`.
- Các package tích hợp như `kernel`, `lightpanda`, `smol`, `eas`, `limrun`, `testmu` cung cấp browser/device từ nhà cung cấp khác; `github` báo kết quả lên PR; `decision` cung cấp executor cho model.
- `apps/` chứa testbed và benchmark để kiểm thử chính framework bằng cách chạy ứng dụng cục bộ cùng các suite. `examples/` có starter độc lập cho nhiều stack web/mobile. `docs/`, `skills/`, `plugins/` chứa tài liệu và tích hợp tooling.
- `.github/workflows/spec.yml` chạy lint, dead-code, typecheck, kiểm tra tài liệu/metadata, test và cài đặt mới; `agent.yml` chạy suite cần model theo lịch hoặc thủ công do các lần chạy này tốn model call.

### Cách test hoạt động

README mô tả test khai báo bằng `test(...)` và fixture như `app`, `screen`, `agent`. `app.open()` điều hướng tới ứng dụng; `screen.getByRole(...)` và `expect(...)` kiểm tra trạng thái. `agent.act(...)` thao tác bằng ngôn ngữ tự nhiên; `agent.assert(...)` kiểm tra kết quả. Repo nói các bước agent đã được assertion xác minh có thể ghi lại để lần sau replay mà không gọi model cho đến khi ứng dụng thay đổi. Test không có agent step không cần model.

Test thật cần có config chọn engine, URL/command khởi chạy app và test files. Web cần Playwright/browser được cài đặt. Chỉ các test có agent step mới cần model provider/subscription/API key hoặc model chạy local. Có thể khởi tạo cấu hình bằng `npx e2e init`, nhưng cần chọn đúng engine và provider; chưa chạy lệnh này cho workspace đích.

### Dependencies và chi phí

Runner có dependencies như MCP SDK, Zod, CLI/parser utilities và optional peers cho AI SDK/provider. Web engine dùng `playwright-core`; mobile engine cần runtime/toolchain riêng cho simulator/emulator. Chạy browser local có thể tránh phí hosting browser, nhưng model agent thường cần subscription/API key hoặc model local. Không xác minh giá nhà cung cấp trong lần đánh giá này; không giả định mọi provider/CI đều miễn phí. CLI gửi telemetry sử dụng ẩn danh theo README; có thể tắt bằng `E2E_TELEMETRY_DISABLED=1`.

### License và giới hạn tái sử dụng

Repository công khai khai báo Apache License 2.0 tại `LICENSE`; package `e2e` và `@e2e-dev/web` cũng khai báo Apache-2.0. License cho phép dùng, sửa đổi và phân phối theo điều khoản, bao gồm giữ thông báo bản quyền/license, ghi rõ file đã sửa và chuyển tiếp nội dung `NOTICE` liên quan khi phân phối. License không cấp quyền thương hiệu. Mỗi dependency và tài sản vẫn cần kiểm tra license riêng. Kế hoạch này không sao chép mã nguồn hay tài sản từ repo mẫu.

## 2. So sánh với project đích

| Hạng mục | `tester-army/e2e` | Workspace `Vua Thợ App` |
| --- | --- | --- |
| Mã nguồn | Monorepo TypeScript/Node, có runner, engine, testbed và ví dụ | Chưa có source sản phẩm; hiện có harness QA web/Android và app demo độc lập |
| Dependency/build | pnpm workspace, package scripts, Node 22.22.3+ hoặc 24.8+ | npm project with TypeScript, Playwright, WebdriverIO, and separate web/native scripts; app source/build remains absent |
| Test hiện hữu | Unit/integration/framework test và testbed | Playwright demo tests và Appium Settings smoke; chưa có product regression tests |
| Runtime target | Web và mobile, local hoặc hosted provider | Local demo web app and Android Settings emulator smoke; Vua Thợ QA target remains unverified |
| Git | GitHub public, nhánh `main` | Repo private có `main` và một README ban đầu; checkout local được nối vào repo, branch làm việc dựa trên `origin/main` |

Vì repo chưa có app nghiệp vụ, không có regression baseline sản phẩm. Bước triển khai tạo framework E2E và một demo app độc lập làm target kiểm chứng.

## 3. Phương án tích hợp được đề xuất

Khi source ứng dụng đã có mặt:

1. Nhận diện framework, runtime và lệnh chạy; liệt kê các luồng nghiệp vụ quan trọng cùng dữ liệu/đăng nhập test sẵn có.
2. Giữ runner thành dependency kiểm thử riêng, không nhập kiến trúc monorepo framework vào app. Repo đích hiện dùng Playwright Test cho browser và WebdriverIO/Appium/UiAutomator2 cho native Android; không thêm package `e2e` chỉ vì tham khảo.
3. Bắt đầu với smoke test xác định: khởi động app, mở màn hình đã xác minh, kiểm tra accessibility locator và trạng thái quan sát được. Mỗi test cần dữ liệu/reset ổn định và chạy được không cần model.
4. Nếu sau này có yêu cầu dùng agent step cho thao tác khó mô tả bằng locator, đặt assertion xác định ngay sau bước đó và kiểm soát provider, telemetry, credential và chi phí.
5. Chạy browser local và emulator local trước. Không bật dịch vụ hosted hoặc test agent/model làm check bắt buộc cho PR cho tới khi đội quyết định ngân sách, credential, độ ổn định và lịch chạy.
6. Khóa phiên bản tương thích sau khi kiểm tra package engines/peers và tài liệu/changelog chính thức.

Phương án này áp dụng cách phân tầng runner/engine, test xác định trước và agent có kiểm soát của repo mẫu; không sao chép source hoặc CI phức tạp của framework.

## 4. Điều kiện cần trước khi triển khai vào app

- Source app được cung cấp trong workspace và có thể chạy cục bộ bằng lệnh đã xác minh.
- Xác định web/mobile, URL hoặc app entrypoint, phiên bản Node/package manager và cách tạo dữ liệu test.
- Nếu có agent test: chọn provider/model và credential qua secret store; cân nhắc chi phí, telemetry và lưu trữ report.
- Nếu thêm mã/tài sản từ dự án ngoài trong tương lai: kiểm tra lại license, `NOTICE`, attribution và license từng dependency.

## 5. Tích hợp đã triển khai

- Web: `@playwright/test`, TypeScript, Oxlint, demo app local độc lập; khi không đặt `BASE_URL`, runner mở demo ở localhost. Report có HTML/JSON và giữ screenshot/trace/video khi lỗi.
- Native Android: WDIO 9 + Appium 3 + UiAutomator2 qua cấu hình riêng. Settings smoke chỉ xác nhận Appium session có thể mở package Android Settings trên emulator; không chứng minh app Vua Thợ hoạt động.
- Android smoke chỉ chọn serial `emulator-*`, không fallback sang thiết bị vật lý. Nếu chưa có emulator online, helper khởi động AVD sẵn có không xóa dữ liệu. Appium được mở trên localhost khi cần; script chỉ dừng process do chính nó khởi chạy. Mỗi lượt lưu log, screenshot khi fail, Allure results và summary trong thư mục riêng dưới `reports/android/runs/`, bị ignore khỏi Git.
- Mã và assets của repo tham khảo không được sao chép. Phương pháp giữ lại là phân tách runner/app/test, ưu tiên assertion xác định, và chỉ đưa test agent/model vào khi yêu cầu chứng minh nhu cầu.

## 6. Giới hạn hiện tại và kiểm chứng

Repo chưa có source sản phẩm, thông số QA build được xác nhận, test account/dữ liệu, hay acceptance criteria cho luồng Vua Thợ. Một package có hậu tố `.dev` được nhìn thấy trên emulator nhưng danh tính QA chưa được xác minh; package public production không được chọn làm target. Vì vậy chưa chạy test nghiệp vụ Vua Thợ, chưa cài APK, chưa xóa data và chưa đăng nhập.

Kết quả đã thực thi trên 2026-10-19:

- `npm run lint` — **PASS**.
- `npm run typecheck` — **PASS**.
- `npm test` — **PASS**, Playwright demo 2/2 trên dependency sau audit; report mới lưu trong `reports/verification-web-20261019-114400/`.
- `npm run android:doctor` — **PASS**, 0 required fixes; bundletool và GStreamer là 2 mục optional chưa cài. Báo cáo cuối ghi nhận CPU i5-13500, RAM 15.7 GB (3.9 GB available) và 0 emulator online sau cleanup.
- `npm run android:smoke` — lượt đầu **FAIL** vì app đang chạy và capability `noReset` không đưa Settings lên foreground. Sau `forceAppLaunch` và cập nhật dependency, cold-start smoke **PASS**, 1/1; helper tắt graceful AVD do nó khởi chạy.
- `npm run android:report` — **PASS**, Allure HTML sinh từ run cuối. Staging ASCII khắc phục Java CLI trên workspace có dấu tiếng Việt.

Các test web/Android ở trên chỉ xác nhận framework và toolchain; chúng không phải regression test sản phẩm.

### Dependency audit

`npm audit --omit=optional` đã được chạy trực tuyến. Các override có bản vá chính thức đã nâng `basic-ftp` lên 6.2.3, `diff` lên 8.0.3, `serialize-javascript` lên 7.1.2 và Mocha lên 11.7.5; nhánh `braces` không còn trong dependency tree. Audit cuối vẫn **FAIL** với 12 đường dẫn High lặp lại tới `extract-zip@2.0.1`, được kéo vào qua `@puppeteer/browsers@2.13.2` từ WDIO. GitHub Advisory hiện không liệt kê bản vá cho [GHSA-jmr9-qjv8-65gv](https://github.com/advisories/GHSA-jmr9-qjv8-65gv); finding thứ hai liên quan cùng package cũng được báo bởi npm. Không dùng `npm audit fix --force`, vì nó đề xuất hạ WDIO xuống 8.14.6. Android Settings smoke không sử dụng luồng giải nén browser, nhưng package vẫn có trong đồ thị cài đặt và audit không được xem là sạch.
