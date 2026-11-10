#!/usr/bin/env bash
# check-scripts.sh — the four workspace scripts must agree about where the
# workspace is, and .gitignore must cover the place they agree on.
#
# They did not. `sync.ps1` joined "workspace" to the scripts directory, so a
# sync created scripts/workspace while `build-all.ps1`, `bump-hcs.ps1` and
# `sync.sh` all looked at ../workspace from the same starting point — the second
# step of the documented flow could not find what the first step had just made.
# `.gitignore` ignores `/workspace/` (anchored to the repository root), so the
# misplaced tree was not ignored either.
#
#   bash tests/check-scripts.sh     # exit 0 = they agree
set -u
cd "$(dirname "$0")/.." || exit 1

problems=0
fail() { printf 'FAIL: %s\n' "$*" >&2; problems=$((problems + 1)); }

# Every expression that names the workspace, as written in the scripts.
expect_ok() {  # name, expression
  case "$2" in
    '..\workspace'|'../workspace') ;;
    *) fail "$1 resolves the workspace to '$2', expected ../workspace from scripts/" ;;
  esac
}

sync_sh=$(grep -E '^WS=' scripts/sync.sh | head -1)
[ -n "$sync_sh" ] || fail "could not read WS= from scripts/sync.sh"
case "$sync_sh" in
  *'/../workspace"') ;;
  *) fail "sync.sh points the workspace at '$sync_sh'" ;;
esac

sync_ps=$(grep -oE 'Join-Path \$root "[^"]+"' scripts/sync.ps1 | head -1 | sed 's/.*"\(.*\)"/\1/')
expect_ok sync.ps1 "$sync_ps"

for f in build-all.ps1 bump-hcs.ps1; do
  expr=$(grep -oE 'Join-Path \$root "[^"]+"' "scripts/$f" | head -1 | sed 's/.*"\(.*\)"/\1/')
  case "$expr" in
    '..\workspace\ziptastic') ;;
    *) fail "$f points at '$expr', expected ..\\workspace\\ziptastic" ;;
  esac
done

# The path they agree on must be ignored, or a sync shows up as untracked files.
grep -qx '/workspace/' .gitignore || fail ".gitignore does not ignore the workspace"

if [ "$problems" -eq 0 ]; then
  echo "scripts agree: workspace at ../workspace, ignored by .gitignore"
  exit 0
fi
printf '\n%d problem(s) found.\n' "$problems" >&2
exit 1
