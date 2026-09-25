[CmdletBinding()]
param(
    [switch]$SkipApps,
    [switch]$SkipTests
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
& (Join-Path $PSScriptRoot 'generate.ps1')
& (Join-Path $PSScriptRoot 'generate-dart.ps1')
$go = Join-Path $root '.tools\go\bin\go.exe'
$bin = Join-Path $root 'bin'
New-Item -ItemType Directory -Force $bin | Out-Null
Push-Location $root
try {
    & $go mod tidy
    if (-not $SkipTests) { & $go test ./...; if ($LASTEXITCODE -ne 0) { throw 'Go tests failed.' } }
    foreach ($name in 'controller','receiver','sender') { & $go build -trimpath -o (Join-Path $bin "$name.exe") "./server/$name"; if ($LASTEXITCODE -ne 0) { throw "Go build failed for $name." } }
    & $go build -trimpath -o (Join-Path $bin 'labctl.exe') './cmd/labctl'
    if ($LASTEXITCODE -ne 0) { throw 'Go build failed for labctl.' }
    if (-not $SkipApps) {
        Push-Location (Join-Path $root 'sdk\dart\livekalman_sdk')
        try {
            & 'C:\tools\flutter\bin\dart.bat' pub get
            & 'C:\tools\flutter\bin\dart.bat' analyze
            if ($LASTEXITCODE -ne 0) { throw 'Dart SDK analysis failed.' }
        } finally { Pop-Location }
        Push-Location (Join-Path $root 'apps\flutter\signal_monitor')
        try {
            & 'C:\tools\flutter\bin\flutter.bat' pub get
            & 'C:\tools\flutter\bin\flutter.bat' analyze
            if ($LASTEXITCODE -ne 0) { throw 'Flutter analysis failed.' }
            & 'C:\tools\flutter\bin\flutter.bat' test
            if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
            & 'C:\tools\flutter\bin\flutter.bat' build windows --debug
            if ($LASTEXITCODE -ne 0) { throw 'Flutter Windows build failed.' }
        } finally { Pop-Location }
        & 'C:\Program Files\dotnet\dotnet.exe' build (Join-Path $root 'apps\dotnet\StreamingLiveKalmanFilter.Maui\StreamingLiveKalmanFilter.Maui.csproj') -f net10.0-windows10.0.19041.0
        if ($LASTEXITCODE -ne 0) { throw '.NET MAUI build failed.' }
    }
    Write-Host 'All requested targets built successfully.' -ForegroundColor Green
} finally { Pop-Location }
