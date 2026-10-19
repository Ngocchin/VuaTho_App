param(
    [string]$EmulatorSerial
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Get-Location).Path
$runId = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$relativeReportDir = "reports/android/runs/$runId"
$reportDir = Join-Path $projectRoot $relativeReportDir
$port = if ($env:APPIUM_PORT) { [int]$env:APPIUM_PORT } else { 4723 }
$reportPath = Join-Path $reportDir 'latest-run.md'
$testOutput = Join-Path $reportDir 'wdio-output.log'
$appiumLog = Join-Path $reportDir 'appium.log'
$stdoutLog = Join-Path $reportDir 'appium-stdout.log'
$stderrLog = Join-Path $reportDir 'appium-stderr.log'
$logcatPath = Join-Path $reportDir 'android-runtime-logcat.txt'
$appiumProcess = $null
$emulatorProcess = $null
$ownsAppium = $false
$ownsEmulator = $false
$emulatorCleanup = 'An already-running emulator was left unchanged.'
$runStatus = 'BLOCKED'
$failureReason = ''
$testExitCode = $null
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

function Test-AppiumServer {
    try {
        Invoke-RestMethod -Uri "http://127.0.0.1:$port/status" -TimeoutSec 2 | Out-Null
        return $true
    } catch {
        return $false
    }
}

try {
    $adb = Get-Command adb -ErrorAction Stop
    $onlineEmulators = @(& $adb.Source devices | Select-Object -Skip 1 | ForEach-Object {
        if ($_ -match '^(emulator-\d+)\s+device(?:\s|$)') { $Matches[1] }
    })
    if ($EmulatorSerial) {
        if ($EmulatorSerial -notmatch '^emulator-\d+$' -or $EmulatorSerial -notin $onlineEmulators) {
            throw 'EmulatorSerial must identify an online emulator. Physical devices are not eligible for this smoke test.'
        }
        $deviceSerial = $EmulatorSerial
    } elseif ($onlineEmulators.Count -gt 0) {
        $deviceSerial = $onlineEmulators[0]
    } else {
        $avds = @(& emulator -list-avds 2>$null | Where-Object { $_.Trim() })
        $avdName = if ($env:ANDROID_AVD_NAME) { $env:ANDROID_AVD_NAME } elseif ('Pixel_10_Pro' -in $avds) { 'Pixel_10_Pro' } else { $null }
        if (-not $avdName -or $avdName -notin $avds) {
            throw 'No online emulator or configured AVD was found. Set ANDROID_AVD_NAME to an installed AVD. Physical devices are intentionally excluded.'
        }
        $emulatorCommand = Get-Command emulator -ErrorAction Stop | Select-Object -First 1
        $emulatorProcess = Start-Process -FilePath $emulatorCommand.Source -ArgumentList @('-avd', $avdName, '-no-window', '-no-boot-anim') -WindowStyle Hidden -PassThru
        $ownsEmulator = $true
        $emulatorCleanup = 'The helper started an AVD; graceful shutdown is pending.'
        for ($attempt = 0; $attempt -lt 90; $attempt++) {
            $onlineEmulators = @(& $adb.Source devices | Select-Object -Skip 1 | ForEach-Object {
                if ($_ -match '^(emulator-\d+)\s+device(?:\s|$)') { $Matches[1] }
            })
            if ($onlineEmulators.Count -gt 0) { $deviceSerial = $onlineEmulators[0]; break }
            Start-Sleep -Seconds 2
        }
        if (-not $deviceSerial) { throw "AVD '$avdName' did not connect to ADB within 180 seconds." }
    }

    $bootReady = $false
    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        $bootState = (& $adb.Source -s $deviceSerial shell getprop sys.boot_completed 2>$null | Out-String).Trim()
        if ($bootState -eq '1') { $bootReady = $true; break }
        Start-Sleep -Seconds 2
    }
    if (-not $bootReady) { throw 'The selected emulator did not finish booting within 120 seconds.' }

    if (-not (Test-AppiumServer)) {
        $node = Get-Command node -ErrorAction Stop
        $globalRoot = (& npm root -g | Out-String).Trim()
        $appiumEntry = Join-Path $globalRoot 'appium/build/lib/main.js'
        if (-not (Test-Path -LiteralPath $appiumEntry)) {
            throw "Appium CLI entrypoint was not found under the global npm directory: $globalRoot"
        }
        $quotedAppiumEntry = '"' + $appiumEntry + '"'
        $quotedAppiumLog = '"' + $appiumLog + '"'
        $appiumProcess = Start-Process -FilePath $node.Source -ArgumentList @(
            $quotedAppiumEntry,
            '--address', '127.0.0.1',
            '--port', "$port",
            '--log', $quotedAppiumLog,
            '--log-level', 'info'
        ) -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
        $ownsAppium = $true

        $serverReady = $false
        for ($attempt = 0; $attempt -lt 30; $attempt++) {
            if (Test-AppiumServer) { $serverReady = $true; break }
            if ($appiumProcess.HasExited) { throw "Appium exited before becoming ready. See $relativeReportDir/appium-stderr.log." }
            Start-Sleep -Seconds 1
        }
        if (-not $serverReady) { throw "Appium did not become ready on 127.0.0.1:$port within 30 seconds." }
    }

    $env:ANDROID_UDID = $deviceSerial
    $env:ANDROID_DEVICE_NAME = 'Android Emulator'
    $env:ANDROID_REPORT_DIR = $relativeReportDir
    $runStatus = 'NOT RUN'
    & npm run android:test 2>&1 | Tee-Object -FilePath $testOutput
    $testExitCode = $LASTEXITCODE
    $runStatus = if ($testExitCode -eq 0) { 'PASS' } else { 'FAIL' }
    if ($testExitCode -ne 0) { $failureReason = "WebdriverIO exited with code $testExitCode." }
} catch {
    $failureReason = $_.Exception.Message
    Write-Error $failureReason
} finally {
    if ($deviceSerial) {
        try {
            & adb -s $deviceSerial logcat -d -v brief AndroidRuntime:E '*:S' 2>$null |
                Set-Content -LiteralPath $logcatPath -Encoding UTF8
            if (-not (Test-Path -LiteralPath $logcatPath)) {
                'Logcat collection did not return output in this run.' | Set-Content -LiteralPath $logcatPath -Encoding UTF8
            }
        } catch {
            "Logcat collection failed: $($_.Exception.Message)" | Set-Content -LiteralPath $logcatPath -Encoding UTF8
        }
    }
    if ($ownsAppium -and $appiumProcess -and -not $appiumProcess.HasExited) {
        Stop-Process -Id $appiumProcess.Id -Force -ErrorAction SilentlyContinue
    }
    if ($ownsEmulator -and $deviceSerial) {
        try {
            & adb -s $deviceSerial emu kill 2>$null | Out-Null
            if ($emulatorProcess) { $null = $emulatorProcess.WaitForExit(15000) }
            $emulatorCleanup = 'The helper-started AVD received a graceful shutdown request; its data was not wiped.'
        } catch {
            $emulatorCleanup = 'Graceful shutdown was not confirmed; the helper-started AVD may remain online.'
        }
    } elseif ($ownsEmulator) {
        $emulatorCleanup = 'The AVD started by the helper did not connect to ADB, so automatic shutdown was not possible.'
    }

    $lines = @(
        '# Android smoke test report',
        '',
        "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')",
        "Status: **$runStatus**",
        'Target: `com.android.settings` on an Android emulator',
        "Emulator lifecycle: $emulatorCleanup",
        "Test exit code: $(if ($null -eq $testExitCode) { 'NOT RUN' } else { $testExitCode })",
        "Failure/blocker: $(if ($failureReason) { $failureReason } else { 'None' })",
        '',
        'Artifacts (local and ignored by Git):',
        "- ``$relativeReportDir/wdio-output.log``",
        "- ``$relativeReportDir/appium.log`` (when this script starts Appium)",
        "- ``$relativeReportDir/android-runtime-logcat.txt``",
        "- ``$relativeReportDir/screenshots/`` (failed test screenshots)",
        "- ``$relativeReportDir/allure-results/``"
    )
    $lines | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Write-Output "Android smoke report saved to $reportPath"
}

if ($runStatus -eq 'FAIL') { exit 1 }
if ($runStatus -eq 'BLOCKED') { exit 2 }
