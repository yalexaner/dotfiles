# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles repository containing configuration for Claude AI, PowerShell, and WezTerm. Configurations are cross-platform (Windows/WSL, macOS, Linux).

## Version Control Workflow

This repository uses a hybrid Git/Jujutsu (JJ) workflow:

- **Analysis**: Use Git commands (`git status`, `git diff`, `git log`, `git branch`)
- **Commits**: Use Jujutsu with `jj desc -m "<message>"` - never use `git commit` or `git add`
- **WSL context**: Prefix commands with `.exe` when needed (e.g., `git.exe`, `jj.exe`)

## Claude Skills

### `/commit` - Commit with Jujutsu
Analyzes git changes and creates conventional commit messages with jj.

Location: `.claude/skills/commit/`

Usage:
```
/commit                    # analyze and commit all changes
/commit auth refactor      # provide context for the commit
```

### `/review-mr` - GitLab MR Review
Comprehensive merge request review with architecture analysis and code quality checks.

Location: `claude/skills/review-mr/`

Requires: `glab` CLI for GitLab integration

Usage:
```
/review-mr 123                                    # review MR by number
/review-mr 123 https://jira.company.com/PROJ-456  # with Jira context
/review-mr                                        # review current branch's MR
```

## Commit Message Format

Strictly follow lowercase Conventional Commits:

```
<type>(<scope>): <subject>

- bullet point if needed
- another bullet point
```

**Rules:**
- All lowercase (type, scope, subject, body)
- Subject: imperative mood, max 50 chars, no period
- Body bullets: start with `-`, max 3-5 points
- Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `style`, `ci`, `build`, `deps`, `security`

## Code Style

- Comments should be lowercase (except KDoc/JavaDoc following their respective guidelines)

## Installation

macOS WezTerm:
```bash
./scripts/macos/install-wezterm.sh
```

Manual installation:
```bash
# skills
cp -r .claude/skills ~/.claude/

# claude config
cp claude/CLAUDE.md claude/settings.json ~/.claude/

# skills requiring non-hidden path
cp -r claude/skills ~/.claude/
```

## Key Directories

| Directory | Purpose |
|-----------|---------|
| `.claude/skills/` | Claude skills (commit) |
| `claude/skills/` | Claude skills (review-mr) |
| `claude/` | Claude guidelines and settings |
| `powershell/` | PowerShell profile with utilities |
| `wezterm/` | Terminal config (Catppuccin Mocha, JetBrainsMono) |
| `scripts/macos/` | macOS automation scripts |
