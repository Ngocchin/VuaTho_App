$ErrorActionPreference = 'Stop'
$projectRoot = (Get-Location).Path
$runsRoot = Join-Path $projectRoot 'reports/android/runs'
$latestRun = Get-ChildItem -LiteralPath $runsRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'allure-results') } |
    Sort-Object Name -Descending |
    Select-Object -First 1
if (-not $latestRun) {
    throw 'No Android Allure results exist yet. Run npm run android:smoke first.'
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$results = Join-Path $latestRun.FullName 'allure-results'
$output = Join-Path $latestRun.FullName "allure-html-$timestamp"
$allureDist = Join-Path $projectRoot 'node_modules/allure-commandline/dist'
if (-not (Test-Path -LiteralPath $allureDist)) { throw 'The local Allure CLI distribution is missing. Run npm install first.' }

# Java's Windows launcher does not preserve this workspace's accented path through the Allure .bat wrapper.
# Stage CLI files and results under TEMP, then copy the generated report back to the workspace.
$stage = Join-Path $env:TEMP ("allure-stage-" + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $stage
$stageDist = Join-Path $stage 'dist'
$stageResults = Join-Path $stage 'allure-results'
$stageOutput = Join-Path $stage 'allure-html'
Copy-Item -LiteralPath $allureDist -Destination $stageDist -Recurse
Copy-Item -LiteralPath $results -Destination $stageResults -Recurse
$java = Join-Path $env:JAVA_HOME 'bin/java.exe'
if (-not (Test-Path -LiteralPath $java)) { throw 'JAVA_HOME does not point to a usable Java runtime.' }
$classPath = "$(Join-Path $stageDist 'lib')\*;$(Join-Path $stageDist 'lib/config')"
& $java -classpath $classPath io.qameta.allure.CommandLine generate $stageResults --output $stageOutput
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Copy-Item -LiteralPath $stageOutput -Destination $output -Recurse
Write-Output "Allure HTML report created at $output"
