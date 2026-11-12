[CmdletBinding()]
param(
    [switch]$SkipFlutterBuild,
    [switch]$SkipMauiBuild,
    [switch]$SkipE2E,
    [string]$Python = 'python'
)
# Runs the same verification gates locally that .github/workflows/ci.yml enforces.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Resolve-Tool([string]$Name, [string[]]$Fallbacks) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($candidate in $Fallbacks) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    throw "Required tool '$Name' was not found on PATH or fallback locations: $($Fallbacks -join ', ')"
}

$localGo = Join-Path $root '.tools\go\bin\go.exe'
$localGofmt = Join-Path $root '.tools\go\bin\gofmt.exe'
if (-not (Test-Path -LiteralPath $localGo) -and -not (Get-Command go -ErrorAction SilentlyContinue)) {
    & (Join-Path $PSScriptRoot 'bootstrap.ps1')
}
$go = Resolve-Tool 'go' @($localGo)
$gofmt = Resolve-Tool 'gofmt' @($localGofmt)

Push-Location $root
try {
    Write-Host '=== [1/5] Go Format, Vet & Unit Tests (Pure-Go ONNX) ===' -ForegroundColor Cyan
    $unformatted = & $gofmt -s -l cmd pkg server shared
    if ($unformatted) {
        throw "Unformatted Go files:`n$($unformatted -join "`n")"
    }
    $env:CGO_ENABLED = '0'
    & $go vet ./...
    if ($LASTEXITCODE -ne 0) { throw 'go vet failed.' }
    & $go test ./...
    if ($LASTEXITCODE -ne 0) { throw 'Go unit tests failed.' }

    Write-Host '=== [2/5] Build Go Servers & CLI Tools ===' -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'build-servers.ps1') -SkipTests

    if (-not $SkipE2E) {
        Write-Host '=== [3/5] Live 3-Node Stack E2E Verification ===' -ForegroundColor Cyan
        & (Join-Path $PSScriptRoot 'stop-all.ps1') -Quiet
        & $Python (Join-Path $PSScriptRoot 'verify_e2e.py') --root $root --bin-dir bin --config configs/local-impaired.json
        if ($LASTEXITCODE -ne 0) { throw 'Live 3-node E2E verification failed.' }
    } else {
        Write-Host '=== [3/5] Skipping Live E2E (-SkipE2E) ===' -ForegroundColor DarkGray
    }

    Write-Host '=== [4/5] Dart SDK & Flutter App Checks ===' -ForegroundColor Cyan
    $dart = Resolve-Tool 'dart' @('C:\flutter\bin\dart.bat', 'C:\tools\flutter\bin\dart.bat')
    $flutter = Resolve-Tool 'flutter' @('C:\flutter\bin\flutter.bat', 'C:\tools\flutter\bin\flutter.bat')
    Push-Location (Join-Path $root 'sdk\dart\livekalman_sdk')
    try {
        & $dart pub get
        & $dart analyze --fatal-infos
        if ($LASTEXITCODE -ne 0) { throw 'Dart SDK analysis failed.' }
    } finally { Pop-Location }

    Push-Location (Join-Path $root 'apps\flutter\signal_monitor')
    try {
        & $flutter pub get
        & $flutter analyze
        if ($LASTEXITCODE -ne 0) { throw 'Flutter analysis failed.' }
        & $flutter test
        if ($LASTEXITCODE -ne 0) { throw 'Flutter widget tests failed.' }
        if (-not $SkipFlutterBuild) {
            & $flutter build windows --debug
            if ($LASTEXITCODE -ne 0) { throw 'Flutter Windows build failed.' }
        }
    } finally { Pop-Location }

    if (-not $SkipMauiBuild) {
        Write-Host '=== [5/5] .NET 10 MAUI Studio Windows Build ===' -ForegroundColor Cyan
        $dotnet = Resolve-Tool 'dotnet' @('C:\Program Files\dotnet\dotnet.exe')
        & $dotnet build (Join-Path $root 'apps\dotnet\StreamingLiveKalmanFilter.Maui\StreamingLiveKalmanFilter.Maui.csproj') `
            -p:TargetFrameworks=net10.0-windows10.0.19041.0 `
            -f net10.0-windows10.0.19041.0 `
            --nologo
        if ($LASTEXITCODE -ne 0) { throw '.NET MAUI Windows build failed.' }
    } else {
        Write-Host '=== [5/5] Skipping .NET MAUI Build (-SkipMauiBuild) ===' -ForegroundColor DarkGray
    }

    Write-Host 'All local CI gates PASSED.' -ForegroundColor Green
} finally {
    Pop-Location
}
