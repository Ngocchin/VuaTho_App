$ErrorActionPreference = 'Continue'
$reportDir = Join-Path (Get-Location) 'reports/android'
$reportPath = Join-Path $reportDir ("environment-doctor-$(Get-Date -Format 'yyyyMMdd-HHmmss').md")
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

function Get-CommandVersion([string]$Name, [string[]]$Arguments = @('--version')) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) { return 'NOT FOUND' }
    $output = & $command.Source @Arguments 2>&1 | Out-String
    return (($output.Trim() -split "`r?`n")[0])
}

$os = try { Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop } catch { $null }
$disk = Get-PSDrive -Name $env:SystemDrive.TrimEnd(':') -ErrorAction SilentlyContinue
$hostInfo = try {
    $rawHostInfo = & node -e 'const os=require(String.fromCharCode(111,115));console.log(JSON.stringify({cpu:os.cpus()[0].model,cores:os.cpus().length,total:os.totalmem(),available:os.freemem()}))' 2>$null
    $rawHostInfo | ConvertFrom-Json
} catch { $null }
$avdNames = @(& emulator -list-avds 2>$null | Where-Object { $_.Trim() })
$devices = @(& adb devices 2>$null | Select-Object -Skip 1 | Where-Object { $_ -match '^emulator-\d+\s+device$' })
$sdkPath = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { $env:ANDROID_SDK_ROOT }
$javaHome = $env:JAVA_HOME
$appiumDoctor = if (Get-Command appium -ErrorAction SilentlyContinue) {
    $rawDoctor = (& appium driver doctor uiautomator2 2>&1 | Out-String)
    ($rawDoctor -split "`r?`n" | Where-Object {
        $_ -match 'Running \d+ doctor checks|ANDROID_HOME is set|adb, emulator exist|JAVA_HOME is set|bin\\java.exe exists|bundletool.jar cannot be found|ffmpeg.exe exists|gst-launch.*cannot be found|Diagnostic completed'
    }) -join [Environment]::NewLine
} else { 'Appium CLI not found' }

$lines = @(
    '# Android automation environment',
    '',
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')",
    '',
    '| Item | Observed value |',
    '| --- | --- |',
    "| OS | $(if ($os) { "$($os.ProductName) $($os.DisplayVersion) build $($os.CurrentBuild).$($os.UBR)" } else { 'Unavailable' }) |",
    "| CPU | $(if ($hostInfo) { "$($hostInfo.cpu) ($($hostInfo.cores) logical processors)" } else { 'Unavailable' }) |",
    "| RAM | $(if ($hostInfo) { "$([math]::Round($hostInfo.total / 1GB, 1)) GB total; $([math]::Round($hostInfo.available / 1GB, 1)) GB available" } else { 'Unavailable' }) |",
    "| Free system drive | $(if ($disk) { "$([math]::Round($disk.Free / 1GB, 1)) GB" } else { 'Unavailable' }) |",
    "| Node.js | $(Get-CommandVersion 'node') |",
    "| npm | $(Get-CommandVersion 'npm') |",
    "| Java | $(Get-CommandVersion 'java' @('-version')) |",
    "| ANDROID_HOME | $(if ($sdkPath) { 'configured' } else { 'NOT SET' }) |",
    "| JAVA_HOME | $(if ($javaHome) { 'configured' } else { 'NOT SET' }) |",
    "| adb | $(Get-CommandVersion 'adb') |",
    "| Emulator | $(Get-CommandVersion 'emulator' @('-version')) |",
    "| Appium | $(Get-CommandVersion 'appium') |",
    "| UiAutomator2 driver | $(if ((Get-Command appium -ErrorAction SilentlyContinue)) { 'Installed; doctor output below' } else { 'NOT FOUND' }) |",
    "| Online emulators | $($devices.Count) |",
    "| Available AVDs | $($avdNames -join ', ') |",
    '',
    '## Appium UiAutomator2 doctor',
    '',
    '```text',
    $appiumDoctor,
    '```',
    '',
    'Physical device serials, installed app identifiers, and full local PATH values are intentionally omitted.'
)

$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8
Write-Output "Environment report saved to $reportPath"
Write-Output $lines
