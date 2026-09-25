[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
& (Join-Path $PSScriptRoot 'bootstrap.ps1')
$protoc = Join-Path $root '.tools\protoc\bin\protoc.exe'
$pubBin = Join-Path $env:LOCALAPPDATA 'Pub\Cache\bin'
$plugin = Join-Path $pubBin 'protoc-gen-dart.bat'
if (-not (Test-Path -LiteralPath $plugin)) {
    & 'C:\tools\flutter\bin\dart.bat' pub global activate protoc_plugin
    if ($LASTEXITCODE -ne 0) { throw 'Dart protoc plugin installation failed.' }
}
$env:PATH = "$pubBin;$env:PATH"
$output = Join-Path $root 'sdk\dart\livekalman_sdk\lib\src\generated'
New-Item -ItemType Directory -Force $output | Out-Null
Push-Location $root
try {
    & $protoc -I proto --dart_out=grpc:$output proto/common/v1/common.proto proto/tx/v1/transmitter.proto proto/rx/v1/receiver.proto proto/control/v1/controller.proto
    if ($LASTEXITCODE -ne 0) { throw 'Dart Protocol Buffer generation failed.' }
} finally { Pop-Location }

