[CmdletBinding()]
param([switch]$Quiet)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$run = Join-Path $root 'run'; $bin = (Join-Path $root 'bin')
if (-not (Test-Path -LiteralPath $run)) { return }
foreach ($name in 'controller','rx','tx') {
    $pidFile = Join-Path $run "$name.pid"
    if (-not (Test-Path -LiteralPath $pidFile)) { continue }
    $idText = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    if ($idText -match '^\d+$') {
        $process = Get-Process -Id ([int]$idText) -ErrorAction SilentlyContinue
        if ($process -and $process.Path -and $process.Path.StartsWith($bin,[StringComparison]::OrdinalIgnoreCase)) { Stop-Process -Id $process.Id; if (-not $Quiet) { Write-Host "Stopped $name (PID $idText)" } }
    }
    Remove-Item -LiteralPath $pidFile -Force
}

