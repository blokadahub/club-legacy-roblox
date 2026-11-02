#!/usr/bin/env bash
# Ferramentas oficiais fixadas; sem modificar dependências do jogo original.
set -euo pipefail
tools_dir=${1:-/tmp/cl27-tools}
mkdir -p "$tools_dir/luau" "$tools_dir/rojo-7.7.1"
download_dir=$(mktemp -d)
trap 'rm -rf "$download_dir"' EXIT
curl --fail --location --silent --show-error https://github.com/luau-lang/luau/releases/download/0.745/luau-ubuntu.zip --output "$download_dir/luau.zip"
curl --fail --location --silent --show-error https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip --output "$download_dir/rojo.zip"
echo "186e5ddaa2b048ebc7390c11ed1b00c04e7d3beaffed429250329e3575d2ece2  $download_dir/luau.zip" | sha256sum --check
echo "00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4  $download_dir/rojo.zip" | sha256sum --check
unzip -oq "$download_dir/luau.zip" -d "$tools_dir/luau"
unzip -oq "$download_dir/rojo.zip" -d "$tools_dir/rojo-7.7.1"
"$tools_dir/rojo-7.7.1/rojo" --version
