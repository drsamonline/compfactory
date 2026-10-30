# bump-hcs.ps1 — sync HCS into ziptastic's vendor/hcs/
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$zt = Join-Path $root "..\workspace\ziptastic"

if (-not (Test-Path $zt)) {
    Write-Error "workspace/ziptastic not found. Run scripts/sync.ps1 first."
    exit 1
}

Set-Location $zt
git subtree pull --prefix=vendor/hcs https://github.com/drsamonline/HCS.git main --squash -m "vendor: sync HCS"
git push origin main
Write-Host "HCS synced into ziptastic/vendor/hcs"
