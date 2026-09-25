[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
& (Join-Path $PSScriptRoot 'bootstrap.ps1')
$tools = Join-Path $root '.tools'
$env:PATH = "$(Join-Path $tools 'go\bin');$(Join-Path $tools 'protoc\bin');$(Join-Path $tools 'bin');$env:PATH"
Push-Location $root
try {
    & (Join-Path $tools 'protoc\bin\protoc.exe') -I proto --go_out=. --go_opt=module=github.com/streaming-live-kalman/filter --go-grpc_out=. --go-grpc_opt=module=github.com/streaming-live-kalman/filter proto/common/v1/common.proto proto/tx/v1/transmitter.proto proto/rx/v1/receiver.proto proto/control/v1/controller.proto
    if ($LASTEXITCODE -ne 0) { throw 'Protocol Buffer generation failed.' }
} finally { Pop-Location }

