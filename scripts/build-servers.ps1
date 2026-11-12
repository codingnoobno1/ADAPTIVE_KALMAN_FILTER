[CmdletBinding()]
param([switch]$SkipTests)
# Builds only the Go servers and labctl into bin\ (no Flutter, .NET or code
# generation needed; generated code is committed). Downloads the project-local
# Go toolchain on first use.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
& (Join-Path $PSScriptRoot 'bootstrap.ps1')
$go = Join-Path $root '.tools\go\bin\go.exe'
$bin = Join-Path $root 'bin'
New-Item -ItemType Directory -Force $bin | Out-Null
Push-Location $root
try {
    $env:CGO_ENABLED = '0'
    if (-not $SkipTests) { & $go test ./...; if ($LASTEXITCODE -ne 0) { throw 'Go tests failed.' } }
    foreach ($name in 'controller','receiver','sender') {
        & $go build -trimpath -buildvcs=false -o (Join-Path $bin "$name.exe") "./server/$name"
        if ($LASTEXITCODE -ne 0) { throw "Go build failed for $name." }
    }
    foreach ($tool in 'labctl','datagen','mediagen') {
        & $go build -trimpath -buildvcs=false -o (Join-Path $bin "$tool.exe") "./cmd/$tool"
        if ($LASTEXITCODE -ne 0) { throw "Go build failed for $tool." }
    }
    Write-Host "Servers built in $bin" -ForegroundColor Green
} finally { Pop-Location }
