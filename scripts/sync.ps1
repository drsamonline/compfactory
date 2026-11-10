# sync.ps1 — materialise the full CHCE workspace
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
# The workspace lives at the repository root, where build-all.ps1 and
# bump-hcs.ps1 look for it (..\workspace) and where sync.sh puts it. It used
# to be joined to $root, the scripts directory, so a sync materialised
# scripts/workspace - which .gitignore's anchored /workspace/ does not cover.
$ws = Join-Path $root "..\workspace"
New-Item -ItemType Directory -Force -Path $ws | Out-Null
Set-Location $ws

$repos = @(
    "https://github.com/drsamonline/HCS.git",
    "https://github.com/drsamonline/ziptastic.git",
    "https://github.com/drsamonline/heavenzip.git"
)

foreach ($url in $repos) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($url)
    if (Test-Path (Join-Path $name ".git")) {
        Write-Host "==> updating $name"
        git -C $name pull --ff-only
    } else {
        Write-Host "==> cloning $name"
        git clone $url $name
    }
}

Write-Host ""
Write-Host "workspace ready at: $ws"
Get-ChildItem -Directory | Select-Object -ExpandProperty Name
