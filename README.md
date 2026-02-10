<p align="center">
  <img alt="Dotfiles Icon" src="./assets/icon.png?v=2" width="240">
  <br/>
</p>

# dotfiles

personal configuration files for development environment setup

## overview

this repository contains configuration files for:

- **claude ai**: ai assistant configuration with custom skills and settings
- **powershell**: comprehensive profile with utility functions and aliases
- **starship**: cross-shell prompt with jj integration and catppuccin mocha theme
- **wezterm**: terminal emulator configuration with custom keybindings and themes

## structure

```
.
├── claude/
│   ├── CLAUDE.md              # ai assistant configuration and guidelines
│   ├── settings.json          # claude permissions and settings
│   └── skills/
│       ├── commit/            # commit message generation skill
│       │   ├── SKILL.md       # main skill instructions
│       │   └── references/
│       │       └── types.md   # conventional commit types reference
│       └── mr-review/         # gitlab merge request review skill
│           ├── SKILL.md       # main skill instructions
│           └── references/
│               └── checklist.md  # detailed review checklists
├── powershell/
│   └── Microsoft.PowerShell_profile.ps1  # powershell profile with utilities
├── starship/
│   ├── starship.toml          # prompt configuration
│   └── jj-prompt.sh           # jujutsu prompt helper script
└── wezterm/
    └── wezterm.lua            # terminal configuration
```

## features

### claude configuration
- **commit skill**: automated commit message generation with jujutsu
  - conventional commits specification (lowercase style)
  - progressive context loading with git diff injection
  - detailed commit types reference
- custom git and jj operation rules
- code commenting guidelines
- **review-mr skill**: comprehensive gitlab mr review with:
  - problem understanding and jira integration
  - alternative approach brainstorming with pros/cons
  - implementation comparison analysis
  - code quality checks (logic, security, performance, dry)
  - architecture and clean code assessment
  - structured review report generation

### powershell utilities
- **md5**: compute file hashes
- **filesize**: display file sizes in various units (bytes, kb, mb, gb, tb)
- **scprm**: secure copy and remove files from remote servers
- **silo** (alias for `Build-And-Sign-Android`): complete android build, sign, and install workflow
- **rm**: enhanced remove command supporting multiple files
- **here/explore**: open file explorer in current directory
- psreadline integration with history-based predictions
- jj version control system autocomplete

### starship prompt
- two-line prompt with connecting line (╭/╰)
- catppuccin mocha color palette
- jj integration: branch display (closest bookmark) and status (dirty/clean + description)
- os icon, directory path, command duration
- vim mode indicator

### wezterm terminal
- catppuccin mocha color scheme
- jetbrainsmono nerd font with ligatures
- comprehensive keybindings for tab and pane management:
  - `alt+t`: new tab
  - `alt+1-9`: switch to tab by number
  - `alt+h/j/k/l`: navigate panes (vim-style)
  - `alt+shift+h/v`: horizontal/vertical splits
  - `alt+shift+arrows`: resize panes
- integrated configuration editing with `ctrl+,`
- quick select patterns for firmware files

## installation

1. clone this repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git
   ```

2. symlink or copy configuration files to their appropriate locations:

   **claude**:
   ```bash
   # copy configuration and skills
   mkdir -p ~/.claude
   cp -r claude/* ~/.claude/
   ```

   **powershell**:
   ```powershell
   # copy to powershell profile location
   copy powershell/Microsoft.PowerShell_profile.ps1 $PROFILE
   ```

   **starship** (macOS):
   ```bash
   bash scripts/macos/install-starship.sh
   ```

   **wezterm**:
   ```bash
   # windows
   mkdir -p ~/.config/wezterm
   cp wezterm/wezterm.lua ~/.config/wezterm/
   ```

3. restart your terminal or reload configurations

## dependencies

### powershell
- powershell 7+
- psreadline module
- jj version control system (for autocomplete)

### starship
- starship prompt
- jj version control system
- zsh shell
- jetbrainsmono nerd font

### wezterm
- wezterm terminal emulator
- jetbrainsmono nerd font

### claude skills
- glab cli (for gitlab mr review skill)

### android development (for silo function)
- android sdk
- adb tools
- custom apk signing setup

## customization

configuration files are designed to be modular and easily customizable:

- modify color schemes in `wezterm.lua`
- add custom functions to the powershell profile
- adjust claude ai behavior through `CLAUDE.md`
- configure permissions in `claude/settings.json`

## license

mit license - see [LICENSE](LICENSE) file for details

## author

Alexander Yachmenev
