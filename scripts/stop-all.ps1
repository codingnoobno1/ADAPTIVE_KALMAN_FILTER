[CmdletBinding()]
param([switch]$Quiet)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$run = Join-Path $root 'run'; $bin = (Join-Path $root 'bin')
if (-not (Test-Path -LiteralPath $run)) { return }
foreach ($name in 'controller','receiver','sender') {
    $pidFile = Join-Path $run "$name.pid"
    if (-not (Test-Path -LiteralPath $pidFile)) { continue }
    $idText = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    if ($idText -match '^\d+$') {
        $process = Get-Process -Id ([int]$idText) -ErrorAction SilentlyContinue
        if ($process -and $process.Path -and $process.Path.StartsWith($bin,[StringComparison]::OrdinalIgnoreCase)) { Stop-Process -Id $process.Id; if (-not $Quiet) { Write-Host "Stopped $name (PID $idText)" } }
    }
    Remove-Item -LiteralPath $pidFile -Force
}

# Also clean project-owned orphan/legacy processes after the tx/rx ->
# sender/receiver rename. The path check prevents touching unrelated programs.
foreach ($name in 'controller','receiver','sender','rx','tx') {
    Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Path -and $_.Path.StartsWith($bin,[StringComparison]::OrdinalIgnoreCase)) {
            Stop-Process -Id $_.Id
            if (-not $Quiet) { Write-Host "Stopped project process $name (PID $($_.Id))" }
        }
    }
}
