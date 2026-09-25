[CmdletBinding()]
param(
    [string]$GoVersion = '1.25.1',
    [string]$ProtocVersion = '31.1'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$tools = Join-Path $root '.tools'
$downloads = Join-Path $tools 'downloads'
New-Item -ItemType Directory -Force $tools, $downloads, (Join-Path $tools 'bin') | Out-Null

$goExe = Join-Path $tools 'go\bin\go.exe'
$goRoot = Join-Path $tools 'go'
if ((Test-Path -LiteralPath $goRoot) -and -not (Test-Path -LiteralPath (Join-Path $goRoot 'src\fmt\print.go'))) {
    if (-not $goRoot.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing to remove Go outside project.' }
    try { Remove-Item -LiteralPath $goRoot -Recurse -Force }
    catch {
        $quarantine = Join-Path $tools ("go-incomplete-" + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
        Move-Item -LiteralPath $goRoot -Destination $quarantine
        Write-Warning "Moved an interrupted Go extraction to $quarantine"
    }
}
if (-not (Test-Path -LiteralPath $goExe)) {
    $zip = Join-Path $downloads "go$GoVersion.windows-amd64.zip"
    Write-Host "Downloading Go $GoVersion..."
    Invoke-WebRequest "https://go.dev/dl/go$GoVersion.windows-amd64.zip" -OutFile $zip
    $extractLog = Join-Path $downloads 'go-extract.log'
    & tar.exe -xf $zip -C $tools 2> $extractLog
    if (-not (Test-Path -LiteralPath (Join-Path $goRoot 'src\fmt\print.go'))) { throw "Go archive extraction failed. See $extractLog" }
}

$protocExe = Join-Path $tools 'protoc\bin\protoc.exe'
if (-not (Test-Path -LiteralPath $protocExe)) {
    $zip = Join-Path $downloads "protoc-$ProtocVersion-win64.zip"
    $temp = Join-Path $tools 'protoc-expand'
    Write-Host "Downloading protoc $ProtocVersion..."
    Invoke-WebRequest "https://github.com/protocolbuffers/protobuf/releases/download/v$ProtocVersion/protoc-$ProtocVersion-win64.zip" -OutFile $zip
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
    Expand-Archive -LiteralPath $zip -DestinationPath $temp -Force
    Move-Item -LiteralPath $temp -Destination (Join-Path $tools 'protoc')
}

$env:GOBIN = Join-Path $tools 'bin'
$env:PATH = "$(Split-Path $goExe);$(Split-Path $protocExe);$env:GOBIN;$env:PATH"
if (-not (Test-Path -LiteralPath (Join-Path $env:GOBIN 'protoc-gen-go.exe'))) { & $goExe install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.9; if ($LASTEXITCODE -ne 0) { throw 'protoc-gen-go installation failed.' } }
if (-not (Test-Path -LiteralPath (Join-Path $env:GOBIN 'protoc-gen-go-grpc.exe'))) { & $goExe install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1; if ($LASTEXITCODE -ne 0) { throw 'protoc-gen-go-grpc installation failed.' } }
Write-Host "Toolchain ready: $goExe"
