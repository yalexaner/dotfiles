# claude code installer

> cross-platform installer for claude code configuration. execute this file with claude code to set up everything automatically.

install my claude code configuration. execute all steps below autonomously.

## what gets installed

- `settings.json` — permissions, statusline, hooks (os-adapted)
- `skills/` — commit, split, mr-review
- `scripts/statusline.js` — windows-only statusline script
- `MAX_THINKING_TOKENS` environment variable

## done when

- `~/.claude/settings.json` is installed and os-appropriate
- all skills from `skills/` exist in `~/.claude/skills/`
- `MAX_THINKING_TOKENS=31999` is in the shell profile
- on windows: `~/.claude/statusline.js` exists

## step 1: detect environment

determine the operating system:
- run `uname -s` or check `$OSTYPE` or `$env:OS`
- detect: **macos**, **linux**, or **windows** (msys/git bash/powershell)
- report what you detect before proceeding

## step 2: back up existing settings

if `~/.claude/settings.json` exists:
- create `~/.claude/settings.json.backup`
- report whether backup was created or skipped

## step 3: install settings

### macos / linux
copy `settings.json` from this directory directly to `~/.claude/settings.json`. no modifications needed — this is the primary platform.

### windows
copy `settings.json` to `~/.claude/settings.json` but apply these patches:

1. **remove the `hooks` key entirely** — the hooks use `osascript` and `terminal-notifier` which are macos-only
2. **replace the `statusLine` value** with:
   ```json
   {
     "type": "command",
     "command": "node C:\\Users\\<USERNAME>\\.claude\\statusline.js"
   }
   ```
   replace `<USERNAME>` with the actual windows username (from `$env:USERNAME` or `whoami`)
3. **remove `enabledPlugins`** if it contains macos-specific plugins (like `clangd-lsp`)
4. **add `alwaysThinkingEnabled: true`** if not already present

use a json-aware approach (read, parse, modify, write) — do not use string replacement.

## step 4: install skills

copy all skill directories from `skills/` in this repo to `~/.claude/skills/`:
- `commit/` — jujutsu conventional commits
- `split/` — atomic commit splitting
- `mr-review/` — gitlab merge request review

rules:
- preserve any existing skills in `~/.claude/skills/` that are not in this repo
- overwrite matching skills with the repo version

## step 5: install windows statusline script

**windows only** — skip on macos/linux.

copy `scripts/statusline.js` to `~/.claude/statusline.js`.

## step 6: configure environment variable

add `MAX_THINKING_TOKENS=31999` to the appropriate shell profile.

### bash (~/.bashrc)
```bash
# claude code extended thinking
export MAX_THINKING_TOKENS=31999
```

### zsh (~/.zshrc)
```bash
# claude code extended thinking
export MAX_THINKING_TOKENS=31999
```

### powershell ($PROFILE)
```powershell
# claude code extended thinking
$env:MAX_THINKING_TOKENS = "31999"
```

rules:
- check if the export already exists before adding
- append to the end of the file

## step 7: verify installation

confirm everything succeeded:

1. `~/.claude/settings.json` exists and contains:
   - `permissions` object with allow rules
   - `statusLine` object
   - on macos: `hooks` object present
   - on windows: no `hooks`, statusline points to node script

2. skills exist:
   - `~/.claude/skills/commit/SKILL.md`
   - `~/.claude/skills/mr-review/SKILL.md`
   - `~/.claude/skills/split/SKILL.md`

3. on windows: `~/.claude/statusline.js` exists

4. environment variable is in shell profile

report results for each check.

## troubleshooting

### settings not taking effect
restart claude code after changing settings.json.

### statusline not showing on windows
- verify `node` is in PATH: `where node`
- verify `jj.exe` is in PATH: `where jj.exe`
- verify `~/.claude/statusline.js` exists
- the statusline runs through **cmd.exe**, not bash — `jj` won't work, must use `jj.exe`

### hooks not working on windows
hooks are removed on windows by design. the macos hooks use `osascript` and `terminal-notifier` which don't exist on windows.

### environment variable not available
shell profile changes require a new terminal session. run `source ~/.bashrc` (or equivalent) to apply immediately.

EXECUTE NOW: detect my environment, install the configuration, and verify everything works.
