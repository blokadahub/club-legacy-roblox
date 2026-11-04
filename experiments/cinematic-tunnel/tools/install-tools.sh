#!/usr/bin/env bash
# Pinned official Linux x86_64 tools, matching the main repository workflow.
set -euo pipefail
tools_dir="${1:-/tmp/cl27-tools}"
mkdir -p "$tools_dir/luau" "$tools_dir/rojo"
curl --fail --location --silent --show-error \
  https://github.com/luau-lang/luau/releases/download/0.745/luau-ubuntu.zip \
  --output "$tools_dir/luau.zip"
printf '%s  %s\n' 186e5ddaa2b048ebc7390c11ed1b00c04e7d3beaffed429250329e3575d2ece2 "$tools_dir/luau.zip" | sha256sum --check
unzip -oq "$tools_dir/luau.zip" -d "$tools_dir/luau"
curl --fail --location --silent --show-error \
  https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip \
  --output "$tools_dir/rojo.zip"
printf '%s  %s\n' 00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4 "$tools_dir/rojo.zip" | sha256sum --check
unzip -oq "$tools_dir/rojo.zip" -d "$tools_dir/rojo"
chmod +x "$tools_dir/luau/luau" "$tools_dir/luau/luau-compile" "$tools_dir/rojo/rojo"
