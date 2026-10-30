# build-all.ps1 — build ziptastic from the workspace
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$zt = Join-Path $root "..\workspace\ziptastic"

if (-not (Test-Path $zt)) {
    Write-Error "workspace/ziptastic not found. Run scripts/sync.ps1 first."
    exit 1
}

Set-Location $zt
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j
Write-Host "built: $zt\build\ziptastic.exe"
