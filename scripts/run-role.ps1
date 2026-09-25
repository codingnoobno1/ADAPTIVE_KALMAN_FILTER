[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('controller','rx','tx')][string]$Role,
    [string]$Config = 'configs/lan.json'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$exe = Join-Path $root "bin\$Role.exe"
$configPath = (Resolve-Path (Join-Path $root $Config)).Path
if (-not (Test-Path -LiteralPath $exe)) { throw "Missing $exe. Run scripts\build-all.ps1 first." }
Write-Host "Running $Role with $configPath"
& $exe --config $configPath

