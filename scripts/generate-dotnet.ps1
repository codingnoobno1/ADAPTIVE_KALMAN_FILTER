[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$project = Join-Path $root 'apps\dotnet\StreamingLiveKalmanFilter.Maui\StreamingLiveKalmanFilter.Maui.csproj'
$output = Join-Path $root 'apps\dotnet\StreamingLiveKalmanFilter.Maui\Generated'

$dotnetCandidates = @(
    (Get-Command dotnet -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
    'C:\Program Files\dotnet\dotnet.exe'
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
if (-not $dotnetCandidates) { throw '.NET SDK was not found on PATH or C:\Program Files\dotnet.' }
$dotnet = $dotnetCandidates[0]

& $dotnet restore $project -p:TargetFrameworks=net10.0-windows10.0.19041.0 --nologo
if ($LASTEXITCODE -ne 0) { throw '.NET restore failed.' }

$nugetPackages = if ($env:NUGET_PACKAGES) { $env:NUGET_PACKAGES } else { Join-Path $env:USERPROFILE '.nuget\packages' }
$toolsRoot = Join-Path $nugetPackages 'grpc.tools'
$toolset = Get-ChildItem -LiteralPath $toolsRoot -Directory |
    Sort-Object { [version]$_.Name } -Descending |
    Select-Object -First 1
if (-not $toolset) { throw 'Grpc.Tools was not restored.' }
$protoc = Join-Path $toolset.FullName 'tools\windows_x64\protoc.exe'
$plugin = Join-Path $toolset.FullName 'tools\windows_x64\grpc_csharp_plugin.exe'
if (-not (Test-Path -LiteralPath $protoc) -or -not (Test-Path -LiteralPath $plugin)) {
    throw 'Windows x64 protoc tools were not found in Grpc.Tools.'
}

New-Item -ItemType Directory -Force $output | Out-Null
& $protoc -I (Join-Path $root 'proto') --csharp_out=$output --grpc_out=$output "--plugin=protoc-gen-grpc=$plugin" `
    (Join-Path $root 'proto\common\v1\common.proto') `
    (Join-Path $root 'proto\tx\v1\transmitter.proto') `
    (Join-Path $root 'proto\rx\v1\receiver.proto') `
    (Join-Path $root 'proto\control\v1\controller.proto')
if ($LASTEXITCODE -ne 0) { throw 'C# protobuf generation failed.' }
Write-Host "C# protobuf clients generated in $output" -ForegroundColor Green
