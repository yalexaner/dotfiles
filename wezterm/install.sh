#!/usr/bin/env bash
# wezterm config install — works on macos, linux, and wsl
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
config_dir="${HOME}/.config/wezterm"

mkdir -p "$config_dir"
cp "$script_dir/wezterm.lua" "$config_dir/wezterm.lua"
echo "installed wezterm.lua to $config_dir"

# back up legacy config if it exists
if [ -e "${HOME}/.wezterm.lua" ] || [ -L "${HOME}/.wezterm.lua" ]; then
  mv "${HOME}/.wezterm.lua" "${HOME}/.wezterm.lua.bak"
  echo "backed up ~/.wezterm.lua to ~/.wezterm.lua.bak"
fi
