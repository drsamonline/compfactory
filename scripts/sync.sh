#!/usr/bin/env bash
set -euo pipefail

WS="$(dirname "$0")/../workspace"
mkdir -p "$WS"
cd "$WS"

for url in \
  "https://github.com/drsamonline/HCS.git" \
  "https://github.com/drsamonline/ziptastic.git" \
  "https://github.com/drsamonline/heavenzip.git"
do
  name="$(basename "$url" .git)"
  if [ -d "$name/.git" ]; then
    echo "==> updating $name"
    git -C "$name" pull --ff-only
  else
    echo "==> cloning $name"
    git clone "$url" "$name"
  fi
done

echo
echo "workspace ready at: $WS"
ls -1