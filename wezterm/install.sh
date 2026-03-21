#!/usr/bin/env bash
# wezterm config install — works on macos, linux, and wsl
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
config_dir="${HOME}/.config/wezterm"

mkdir -p "$config_dir"
cp "$script_dir/wezterm.lua" "$config_dir/wezterm.lua"
echo "installed wezterm.lua to $config_dir"

# remove legacy symlink if it exists
if [ -L "${HOME}/.wezterm.lua" ]; then
  rm "${HOME}/.wezterm.lua"
  echo "removed legacy symlink ~/.wezterm.lua"
fi
