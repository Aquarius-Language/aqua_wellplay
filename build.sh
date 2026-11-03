#!/usr/bin/env bash
# Builds aqua_wellplay into a distribution folder on Linux (see build.ps1 for the layout):
#   ./build.sh path/to/aqua path/to/folder
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
aqua=${1:?"usage: build.sh path/to/aqua output-folder"}
output=$(mkdir -p "${2:?"usage: build.sh path/to/aqua output-folder"}" && cd -- "$2" && pwd)
work=$(mktemp -d)
# Only this repository's own locks (machine-specific); the library submodules keep theirs.
trap 'rm -rf "$work"; rm -f "$root/aqua.lock.json" "$root/frontend/aqua.lock.json"' EXIT
# The libraries are submodules (libraries/README.md): fetch them when a clone has not.
for library in Aqua_Embedded_LSP_Editor Aqua_JSON-RPC; do
    if [ ! -f "$root/libraries/$library/aqua.toml" ]; then git -C "$root" submodule update --init --recursive; break; fi
done
# A Bottle cache of its own: the libraries never meet other copies of the same versions.
export AQUA_BOTTLE_HOME="$work/bottles"
rm -f "$root/aqua.lock.json" "$root/frontend/aqua.lock.json"
rm -rf "$output/wellplay"
mkdir -p "$output/wellplay"
echo "aqua_wellplay: frontend (web)"
"$aqua" build "$root/frontend" --target web -o "$output/wellplay/site"
cp -r "$root/kernel" "$output/wellplay/kernel"
cp -r "$root/examples" "$output/wellplay/examples"
echo "aqua_wellplay: server (standalone executable)"
"$aqua" build "$root" --target linux -o "$work/server/aqua_wellplay"
cp "$work/server/aqua_wellplay" "$output/aqua_wellplay"
echo "aqua_wellplay: $output/aqua_wellplay"
