---
name: commit
description: Analyze git changes and create conventional commit messages with jujutsu. Use when committing code, creating commit messages, or when user says "commit".
argument-hint: [optional context or focus]
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(jj commit:*)
---

# Commit with Jujutsu (Conventional Commits, Lowercase)

Analyze changes using git, generate a conventional commit message, and commit with `jj commit`.

## Context

- **Status:** !`git status --porcelain`
- **Branch:** !`git branch --show-current`
- **Staged files:** !`git diff --cached --name-only`
- **Working changes:** !`git diff --stat`
- **Recent commits:** !`git log --oneline -5`
- **User context:** $ARGUMENTS

## Workflow

### 1. Analyze Changes
Read the diffs to understand what changed:
```bash
git diff          # working copy
git diff --cached # staged
```

### 2. Determine Type and Scope
Select the appropriate type based on the nature of changes. See [references/types.md](references/types.md) for the complete list.

Common types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`

Scope should reflect the affected component or module (e.g., `auth`, `api`, `config`).

### 3. Craft the Message

**Format:** `<type>(<scope>): <subject>`

**Rules:**
- Subject: lowercase, imperative mood, max 50 chars, no period
- Body (if needed): blank line, then bullet points with `-`
- Bullets: max 3-5, lowercase, imperative

**Simple change:**
```
fix(auth): resolve token expiration issue
```

**Complex change:**
```
feat(api): add user authentication endpoint

- implement jwt token generation
- add password hashing with bcrypt
- create login and logout routes
```

### 4. Execute

**DO:**
- Execute `jj commit -m "<message>"` immediately

**DO NOT:**
- Never use `git commit`, `git add`, or `git push`
- Never ask for confirmation before committing

### 5. Output

After committing, output only:
```
Commit created: <type>(<scope>): <subject>
```

## Additional Resources

- [Commit types reference](references/types.md) - complete list of types with descriptions
