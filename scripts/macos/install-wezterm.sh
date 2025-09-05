#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

say() { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}Warning:${NC} $*"; }
error() { echo -e "${RED}Error:${NC} $*"; }
info() { echo -e "${BLUE}Info:${NC} $*"; }

# Check if running on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
  error "This installer is for macOS only."
  exit 1
fi

ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    say "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for current session
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    say "Homebrew already installed"
  fi

  # Ensure Homebrew is in shell profile
  local shell_profile
  if [[ "$SHELL" == */zsh ]]; then
    shell_profile="$HOME/.zprofile"
  elif [[ "$SHELL" == */bash ]]; then
    shell_profile="$HOME/.bash_profile"
  else
    shell_profile="$HOME/.profile"
  fi

  if ! grep -qs 'brew shellenv' "$shell_profile" 2>/dev/null; then
    info "Adding Homebrew to $shell_profile"
    if [[ -x /opt/homebrew/bin/brew ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$shell_profile"
    elif [[ -x /usr/local/bin/brew ]]; then
      echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$shell_profile"
    fi
  fi

  # Verify brew is working
  if ! command -v brew >/dev/null 2>&1; then
    error "Homebrew installation failed or not in PATH"
    exit 1
  fi
}

install_wezterm() {
  if brew list --cask wezterm >/dev/null 2>&1; then
    say "WezTerm already installed"
    return
  fi

  say "Installing WezTerm..."
  brew update
  brew install --cask wezterm
  
  if ! brew list --cask wezterm >/dev/null 2>&1; then
    error "WezTerm installation failed"
    exit 1
  fi
  
  say "WezTerm installed successfully"
}

install_font() {
  if brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
    say "JetBrainsMono Nerd Font already installed"
    return
  fi

  say "Installing JetBrainsMono Nerd Font..."
  if ! brew tap | grep -q '^homebrew/cask-fonts$'; then
    say "Adding tap homebrew/cask-fonts"
    brew tap homebrew/cask-fonts || true
  fi
  if brew install --cask font-jetbrains-mono-nerd-font; then
    say "JetBrainsMono Nerd Font installed successfully"
  else
    warn "Failed to install JetBrainsMono Nerd Font (optional)"
  fi
}

link_wezterm_config() {
  local script_dir repo_root source target1 target2
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd "$script_dir/../.." && pwd)"
  source="$repo_root/wezterm/wezterm.lua"

  if [[ ! -f "$source" ]]; then
    error "WezTerm config not found at: $source"
    exit 1
  fi

  say "Linking WezTerm configuration..."

  # Create WezTerm config directory
  mkdir -p "$HOME/.config/wezterm"

  # Link to ~/.config/wezterm/wezterm.lua (primary location)
  target1="$HOME/.config/wezterm/wezterm.lua"
  if [[ -e "$target1" && ! -L "$target1" ]]; then
    local backup="$target1.bak.$(date +%Y%m%d%H%M%S)"
    warn "Backing up existing config to $backup"
    mv "$target1" "$backup"
  fi
  ln -snf "$source" "$target1"
  info "Linked config to $target1"

  # Also link to ~/.wezterm.lua (fallback location)
  target2="$HOME/.wezterm.lua"
  if [[ -e "$target2" && ! -L "$target2" ]]; then
    local backup="$target2.bak.$(date +%Y%m%d%H%M%S)"
    warn "Backing up existing config to $backup"
    mv "$target2" "$backup"
  fi
  ln -snf "$source" "$target2"
  info "Linked config to $target2"

  say "WezTerm configuration linked successfully"
}

verify_installation() {
  say "Verifying installation..."
  
  if ! command -v brew >/dev/null 2>&1; then
    error "Homebrew not found in PATH"
    return 1
  fi
  
  if ! brew list --cask wezterm >/dev/null 2>&1; then
    error "WezTerm not installed"
    return 1
  fi
  
  if [[ ! -L "$HOME/.config/wezterm/wezterm.lua" ]]; then
    error "WezTerm config not linked"
    return 1
  fi
  
  say "Installation verified successfully"
  return 0
}

main() {
  say "Starting WezTerm installation for macOS..."
  
  ensure_brew
  install_wezterm
  install_font
  link_wezterm_config
  
  if verify_installation; then
    say "Installation completed successfully!"
    info "You can now start WezTerm from Applications or run 'open -a WezTerm'"
    info "Your WezTerm config is linked from: $(readlink "$HOME/.config/wezterm/wezterm.lua")"
    # Non-interactive: do not prompt or auto-launch applications
  else
    error "Installation verification failed"
    exit 1
  fi
}

# Run main function with all arguments
main "$@"
