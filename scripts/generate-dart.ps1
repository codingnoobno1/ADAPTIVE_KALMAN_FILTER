[CmdletBinding()]
param(
    [string]$ProtocPluginVersion = '25.1.0'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

$protocCmd = Get-Command protoc -ErrorAction SilentlyContinue
if ($protocCmd) {
    $protoc = $protocCmd.Source
} else {
    & (Join-Path $PSScriptRoot 'bootstrap.ps1')
    $protoc = Join-Path $root '.tools\protoc\bin\protoc.exe'
}

$dartCandidates = @(
    (Get-Command dart -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
    'C:\flutter\bin\dart.bat',
    'C:\tools\flutter\bin\dart.bat'
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
if (-not $dartCandidates) { throw 'Dart SDK was not found on PATH, C:\flutter\bin, or C:\tools\flutter\bin.' }
$dart = $dartCandidates[0]

$pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } elseif ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'Pub\Cache' } else { Join-Path $HOME '.pub-cache' }
$pubBin = Join-Path $pubCache 'bin'
& $dart pub global activate protoc_plugin $ProtocPluginVersion
if ($LASTEXITCODE -ne 0) { throw 'Dart protoc plugin installation failed.' }

$pathSep = [System.IO.Path]::PathSeparator
$env:PATH = "$pubBin$pathSep$env:PATH"
$output = Join-Path $root 'sdk/dart/livekalman_sdk/lib/src/generated'
New-Item -ItemType Directory -Force $output | Out-Null
Push-Location $root
try {
    & $protoc -I proto "--dart_out=grpc:$output" proto/common/v1/common.proto proto/tx/v1/transmitter.proto proto/rx/v1/receiver.proto proto/control/v1/controller.proto
    if ($LASTEXITCODE -ne 0) { throw 'Dart Protocol Buffer generation failed.' }
} finally { Pop-Location }

