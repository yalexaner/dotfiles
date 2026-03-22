#!/usr/bin/env bash
# fish shell environment setup — works on macos, ubuntu/debian, and wsl
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$script_dir/.." && pwd)"

# detect platform
if [[ "$(uname -s)" == "Darwin" ]]; then
    platform="macos"
elif grep -qi "ubuntu\|debian\|pop" /etc/os-release 2>/dev/null; then
    platform="debian"
else
    echo "unsupported platform: $(uname -s)"
    echo "this script supports macos and ubuntu/debian/pop_os"
    exit 1
fi

echo "detected platform: $platform"

# --- package installation ---

install_brew_packages() {
    if ! command -v brew &>/dev/null; then
        echo "installing homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo "installing packages via brew..."
    brew install fish starship bat ripgrep eza fd git-delta tealdeer zoxide fzf jj
}

install_apt_packages() {
    echo "installing packages via apt..."
    sudo apt update -qq
    sudo apt install -y -qq fish bat ripgrep eza fd-find git-delta tealdeer zoxide fzf

    # symlinks for ubuntu naming quirks (batcat -> bat, fdfind -> fd)
    mkdir -p ~/.local/bin
    [ ! -e ~/.local/bin/bat ] && ln -s /usr/bin/batcat ~/.local/bin/bat && echo "symlinked bat"
    [ ! -e ~/.local/bin/fd ] && ln -s "$(which fdfind)" ~/.local/bin/fd && echo "symlinked fd"

    # add ~/.local/bin to fish path if not already there
    fish -c 'fish_add_path ~/.local/bin' 2>/dev/null || true
}

install_starship_standalone() {
    if command -v starship &>/dev/null; then
        echo "starship already installed"
        return
    fi
    echo "installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}

install_jj_cargo() {
    if command -v jj &>/dev/null; then
        echo "jj already installed"
        return
    fi
    if ! command -v cargo &>/dev/null; then
        echo "installing rust toolchain..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    echo "installing jj via cargo..."
    cargo install --locked --bin jj jj-cli
}

if [[ "$platform" == "macos" ]]; then
    install_brew_packages
elif [[ "$platform" == "debian" ]]; then
    install_apt_packages
    install_starship_standalone
    install_jj_cargo
fi

# --- nerd font (macos only, wezterm on windows handles its own font) ---

if [[ "$platform" == "macos" ]]; then
    if ! brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
        echo "installing JetBrainsMono Nerd Font..."
        brew install --cask font-jetbrains-mono-nerd-font
    else
        echo "JetBrainsMono Nerd Font already installed"
    fi
fi

# --- shell configuration ---

# fish config
echo "setting up fish config..."
mkdir -p ~/.config/fish
cp "$script_dir/config.fish" ~/.config/fish/config.fish
echo "installed config.fish"

# catppuccin mocha theme for fish
echo "installing catppuccin mocha theme..."
mkdir -p ~/.config/fish/themes
curl -sS -o ~/.config/fish/themes/'Catppuccin Mocha.theme' \
    https://raw.githubusercontent.com/catppuccin/fish/main/themes/catppuccin-mocha.theme
fish -c 'fish_config theme choose "Catppuccin Mocha"' 2>/dev/null || true
echo "installed catppuccin mocha theme"

# starship config
echo "setting up starship config..."
mkdir -p ~/.config
cp "$repo_dir/starship/starship.toml" ~/.config/starship.toml
echo "installed starship.toml"

# delta config for jj/git diffs
echo "setting up delta..."
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.line-numbers true

# update tldr pages (non-critical, may fail)
if command -v tldr &>/dev/null; then
    echo "updating tldr pages..."
    tldr --update 2>/dev/null || echo "tldr update failed (non-critical)"
fi

# generate fish completions from man pages
echo "generating fish completions..."
fish -c 'fish_update_completions' 2>/dev/null || true

# --- set fish as default shell ---

fish_path="$(which fish)"
if [[ "$SHELL" != "$fish_path" ]]; then
    # ensure fish is in /etc/shells
    if ! grep -q "$fish_path" /etc/shells; then
        echo "adding fish to /etc/shells..."
        echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi
    echo "setting fish as default shell..."
    chsh -s "$fish_path"
    echo "fish set as default shell (restart terminal to apply)"
else
    echo "fish is already default shell"
fi

echo ""
echo "done! restart your terminal."
echo "tools installed: fish, starship, bat, rg, eza, fd, delta, tldr, zoxide, fzf, jj"
