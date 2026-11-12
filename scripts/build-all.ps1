[CmdletBinding()]
param(
    [switch]$SkipApps,
    [switch]$SkipTests,
    [switch]$SkipCodegen
)
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

if (-not $SkipCodegen) {
    & (Join-Path $PSScriptRoot 'generate.ps1')
    & (Join-Path $PSScriptRoot 'generate-dart.ps1')
    & (Join-Path $PSScriptRoot 'generate-dotnet.ps1')
}

$localGo = Join-Path $root '.tools\go\bin\go.exe'
if (-not (Test-Path -LiteralPath $localGo) -and -not (Get-Command go -ErrorAction SilentlyContinue)) {
    & (Join-Path $PSScriptRoot 'bootstrap.ps1')
}
$go = Resolve-Tool 'go' @($localGo)
$bin = Join-Path $root 'bin'
New-Item -ItemType Directory -Force $bin | Out-Null
Push-Location $root
try {
    & $go mod tidy
    if (-not $SkipTests) { & $go test ./...; if ($LASTEXITCODE -ne 0) { throw 'Go tests failed.' } }
    foreach ($name in 'controller','receiver','sender') { & $go build -trimpath -buildvcs=false -o (Join-Path $bin "$name.exe") "./server/$name"; if ($LASTEXITCODE -ne 0) { throw "Go build failed for $name." } }
    foreach ($tool in 'labctl','datagen','mediagen') { & $go build -trimpath -buildvcs=false -o (Join-Path $bin "$tool.exe") "./cmd/$tool"; if ($LASTEXITCODE -ne 0) { throw "Go build failed for $tool." } }
    if (-not $SkipApps) {
        $dart = Resolve-Tool 'dart' @('C:\flutter\bin\dart.bat', 'C:\tools\flutter\bin\dart.bat')
        $flutter = Resolve-Tool 'flutter' @('C:\flutter\bin\flutter.bat', 'C:\tools\flutter\bin\flutter.bat')
        $dotnet = Resolve-Tool 'dotnet' @('C:\Program Files\dotnet\dotnet.exe')

        Push-Location (Join-Path $root 'sdk\dart\livekalman_sdk')
        try {
            & $dart pub get
            & $dart analyze
            if ($LASTEXITCODE -ne 0) { throw 'Dart SDK analysis failed.' }
        } finally { Pop-Location }
        Push-Location (Join-Path $root 'apps\flutter\signal_monitor')
        try {
            & $flutter pub get
            & $flutter analyze
            if ($LASTEXITCODE -ne 0) { throw 'Flutter analysis failed.' }
            if (-not $SkipTests) {
                & $flutter test
                if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
            }
            & $flutter build windows --debug
            if ($LASTEXITCODE -ne 0) { throw 'Flutter Windows build failed.' }
        } finally { Pop-Location }
        & $dotnet build (Join-Path $root 'apps\dotnet\StreamingLiveKalmanFilter.Maui\StreamingLiveKalmanFilter.Maui.csproj') -p:TargetFrameworks=net10.0-windows10.0.19041.0 -f net10.0-windows10.0.19041.0 --nologo
        if ($LASTEXITCODE -ne 0) { throw '.NET MAUI build failed.' }
    }
    Write-Host 'All requested targets built successfully.' -ForegroundColor Green
} finally { Pop-Location }
