[CmdletBinding()]
param(
    # Python that has the nanopb generator: pip install nanopb
    [string]$Python = 'python'
)
# Regenerates the nanopb C code used by the ESP32 firmware and its host test
# into examples/esp32/platformio/lib/lk_media (common/v1, rx/v1). Field size
# limits come from proto/**/*.options. Run after changing receiver.proto or
# common.proto, and commit the result (like gen/ for Go).
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$out = Join-Path $root 'examples\esp32\platformio\lib\lk_media'
$env:PATH = "$(Join-Path $root '.tools\protoc\bin');$env:PATH"
Push-Location $root
try {
    & $Python -m nanopb.generator.nanopb_generator -I proto -D $out proto/common/v1/common.proto proto/rx/v1/receiver.proto
    if ($LASTEXITCODE -ne 0) { throw 'nanopb generation failed (pip install nanopb, and run scripts/bootstrap.ps1 for protoc).' }
} finally { Pop-Location }
