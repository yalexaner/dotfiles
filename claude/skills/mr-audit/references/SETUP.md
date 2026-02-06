# mr-audit Skill Prerequisites

## Required

### Codex CLI

```bash
npm install -g @openai/codex
```

Verify:
```bash
codex --version
```

Log in:
```bash
codex login
```

### glab CLI

GitLab CLI for MR data.

```bash
brew install glab
glab auth login
```

Verify:
```bash
glab mr list
```

### Codex Skills

The mr-audit skill launches Codex with the `$mr-review` skill, which in turn uses `$jira`. Both must be installed in Codex's skill directory.

Check if installed:
```bash
ls ~/.codex/skills/jira/SKILL.md ~/.codex/skills/mr-review/SKILL.md
```

If missing, copy from the dotfiles repo:
```bash
cp -r ~/Projects/dotfiles/claude/skills/jira ~/.codex/skills/
cp -r ~/Projects/dotfiles/claude/skills/mr-review ~/.codex/skills/
```

Or from the Claude system skills:
```bash
cp -r ~/.claude/skills/jira ~/.codex/skills/
cp -r ~/.claude/skills/mr-review ~/.codex/skills/
```

**Important**: The Codex versions of these skills are adapted — they don't use Claude-specific features like `!`command`` auto-execution or `$ARGUMENTS`. If copying from Claude skills, the Codex-adapted versions should already exist in `~/.codex/skills/`. If they don't, see the main README for porting instructions.

### Jira Access (optional)

Required if your MRs reference Jira tickets. See the Jira skill's own setup guide:
- Claude: `~/.claude/skills/jira/references/SETUP.md`
- Codex: `~/.codex/skills/jira/references/SETUP.md`

## Graceful Degradation

The skill works without Codex — it degrades to Claude-Only mode automatically. You'll see a note at the top of the report indicating which sources were used.

| Missing Component | Effect |
|-------------------|--------|
| Codex CLI | Claude-Only mode (no Codex reviews) |
| Codex `mr-review` skill | Codex skill review skipped, built-in review still runs |
| Codex `jira` skill | Codex skill review runs but without Jira context |
| glab CLI | All reviews affected (no MR metadata) |
| Jira access | Reviews proceed without ticket context |
