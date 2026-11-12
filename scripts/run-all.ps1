[CmdletBinding()]
param(
    [string]$Config = 'configs/local.json',
    [ValidateSet('none','flutter','maui')][string]$Dashboard = 'none'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$configPath = (Resolve-Path (Join-Path $root $Config)).Path
$bin = Join-Path $root 'bin'; $logs = Join-Path $root 'logs'; $run = Join-Path $root 'run'
foreach ($path in $bin,$logs,$run) { New-Item -ItemType Directory -Force $path | Out-Null }
foreach ($name in 'controller','receiver','sender') { if (-not (Test-Path -LiteralPath (Join-Path $bin "$name.exe"))) { throw "Missing bin\$name.exe. Run scripts\build-all.ps1 first." } }
& (Join-Path $PSScriptRoot 'stop-all.ps1') -Quiet

foreach ($name in 'controller','receiver','sender') {
    $exe = Join-Path $bin "$name.exe"; $stdout = Join-Path $logs "$name.out.log"; $stderr = Join-Path $logs "$name.err.log"
    $p = Start-Process -FilePath $exe -ArgumentList '--config', $configPath -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    Set-Content -LiteralPath (Join-Path $run "$name.pid") -Value $p.Id
    Write-Host "Started $name (PID $($p.Id))"
    Start-Sleep -Milliseconds 450
}

if ($Dashboard -eq 'flutter') {
    $flutter = @(
        (Get-Command flutter -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        'C:\flutter\bin\flutter.bat',
        'C:\tools\flutter\bin\flutter.bat'
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
    if (-not $flutter) { throw 'Flutter SDK was not found on PATH, C:\flutter\bin, or C:\tools\flutter\bin.' }
    Start-Process -FilePath $flutter -ArgumentList 'run','-d','windows' -WorkingDirectory (Join-Path $root 'apps\flutter\signal_monitor') -WindowStyle Hidden
} elseif ($Dashboard -eq 'maui') {
    $dotnet = @(
        (Get-Command dotnet -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        'C:\Program Files\dotnet\dotnet.exe'
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
    if (-not $dotnet) { throw '.NET SDK was not found on PATH or C:\Program Files\dotnet.' }
    Start-Process -FilePath $dotnet -ArgumentList 'run','-p:TargetFrameworks=net10.0-windows10.0.19041.0','-f','net10.0-windows10.0.19041.0','--project',(Join-Path $root 'apps\dotnet\StreamingLiveKalmanFilter.Maui\StreamingLiveKalmanFilter.Maui.csproj') -WorkingDirectory $root -WindowStyle Hidden
}
Write-Host 'Streaming stack is live. Controller dashboard feed: http://127.0.0.1:8080/api/v1/events' -ForegroundColor Green
Write-Host "Logs: $logs"
