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

  if ! grep -Fq 'brew shellenv' "$shell_profile" 2>/dev/null; then
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

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    say "Starship already installed"
    return
  fi

  say "Installing Starship..."
  if ! brew install starship; then
    warn "Starship install failed, retrying once..."
    sleep 2
    brew install starship
  fi

  if ! command -v starship >/dev/null 2>&1; then
    error "Starship installation failed"
    exit 1
  fi

  say "Starship installed successfully"
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

link_starship_config() {
  local script_dir repo_root
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd "$script_dir/../.." && pwd)"

  local toml_source="$repo_root/starship/starship.toml"
  local script_source="$repo_root/starship/jj-prompt.sh"

  if [[ ! -f "$toml_source" ]]; then
    error "Starship config not found at: $toml_source"
    exit 1
  fi

  if [[ ! -f "$script_source" ]]; then
    error "jj-prompt.sh not found at: $script_source"
    exit 1
  fi

  say "Copying Starship configuration..."

  # Copy starship.toml → ~/.config/starship.toml
  # Uses copy instead of symlink because jj changes working copy contents
  # when switching revisions, which would break symlinks
  mkdir -p "$HOME/.config"
  local toml_target="$HOME/.config/starship.toml"
  if [[ -e "$toml_target" && ! -L "$toml_target" ]]; then
    local backup="$toml_target.bak.$(date +%Y%m%d%H%M%S)"
    warn "Backing up existing config to $backup"
    mv "$toml_target" "$backup"
  fi
  rm -f "$toml_target"
  cp "$toml_source" "$toml_target"
  info "Copied config to $toml_target"

  # Copy jj-prompt.sh → ~/.config/starship/jj-prompt.sh
  mkdir -p "$HOME/.config/starship"
  local script_target="$HOME/.config/starship/jj-prompt.sh"
  if [[ -e "$script_target" && ! -L "$script_target" ]]; then
    local backup="$script_target.bak.$(date +%Y%m%d%H%M%S)"
    warn "Backing up existing script to $backup"
    mv "$script_target" "$backup"
  fi
  rm -f "$script_target"
  cp "$script_source" "$script_target"
  chmod +x "$script_target"
  info "Copied script to $script_target"

  say "Starship configuration copied successfully"
}

setup_shell_init() {
  local zshrc="$HOME/.zshrc"
  local init_line='eval "$(starship init zsh)"'

  if grep -Fq "$init_line" "$zshrc" 2>/dev/null; then
    say "Starship shell init already present in $zshrc"
    return
  fi

  say "Adding Starship init to $zshrc..."
  echo "" >> "$zshrc"
  echo "# starship prompt" >> "$zshrc"
  echo "$init_line" >> "$zshrc"
  info "Added starship init to $zshrc"
}

verify_installation() {
  say "Verifying installation..."

  if ! command -v starship >/dev/null 2>&1; then
    error "Starship not found in PATH"
    return 1
  fi

  if [[ ! -f "$HOME/.config/starship.toml" ]]; then
    error "Starship config not found"
    return 1
  fi

  if [[ ! -f "$HOME/.config/starship/jj-prompt.sh" ]]; then
    error "jj-prompt.sh not found"
    return 1
  fi

  if ! grep -Fq 'eval "$(starship init zsh)"' "$HOME/.zshrc" 2>/dev/null; then
    error "Starship shell init not found in ~/.zshrc"
    return 1
  fi

  say "Installation verified successfully"
  return 0
}

main() {
  say "Starting Starship installation for macOS..."

  ensure_brew
  install_starship
  install_font
  link_starship_config
  setup_shell_init

  if verify_installation; then
    say "Installation completed successfully!"
    info "Restart your terminal or run: eval \"\$(starship init zsh)\""
  else
    error "Installation verification failed"
    exit 1
  fi
}

# Run main function with all arguments
main "$@"
