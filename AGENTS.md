# Repository Guidelines

## Project Structure & Module Organization
- Root config: `wezterm.lua` — entry point that `require`s local modules.
- Modules: `modules/` (e.g., `modules/colors.lua`, `modules/keys.lua`, `modules/ui.lua`).
- Assets: `assets/` for images or fonts referenced by the config.
- Local overrides (optional): `local/` for machine- or user-specific snippets ignored by VCS.

## Build, Test, and Development Commands
- `wezterm --version`: verify WezTerm is installed and on PATH.
- `wezterm start --config-file wezterm.lua`: launch WezTerm using this config.
- `WEZTERM_CONFIG_FILE=$(pwd)/wezterm.lua wezterm start`: test with an explicit config file path.
- `wezterm show-config --lua`: print the resolved config to validate structure and defaults.

## Coding Style & Naming Conventions
- Language: Lua (2-space indent, no tabs; UTF-8 files).
- Modules return a table; name files by purpose: `colors.lua`, `keys.lua`, `events.lua`.
- Naming: `snake_case` for locals/fields, `UPPER_SNAKE` for constants, `PascalCase` for module tables when exported.
- Prefer `local` variables/functions; avoid globals. Keep functions small and composable.
- Formatting: if available, run `stylua .` before committing.

## Testing Guidelines
- Smoke test: run `wezterm show-config --lua` to ensure the config evaluates without errors.
- Manual test: `wezterm start --config-file wezterm.lua`, then verify keymaps, colors, and pane/tab behavior.
- Structure tests by scenario in `modules/` and keep side effects behind clearly named helpers (e.g., `apply_keymaps(config)`).

## Commit & Pull Request Guidelines
- Commits: use Conventional Commits, e.g., `feat(keys): add tmux-like splits`, `fix(colors): correct ANSI 5`. Keep messages imperative and scoped.
- PRs: include a short description, screenshots (for UI/theme changes), and steps to validate.
- Link related issues; keep PRs focused and small. Note any platform-specific behavior (Windows/macOS/Linux).

## Security & Configuration Tips
- Do not commit secrets or absolute user paths. Read from env: `os.getenv('VAR')`.
- For host-specific tweaks, branch by hostname: `require('wezterm').hostname()`.
- Prefer relative paths inside the repo; document any external dependencies.

