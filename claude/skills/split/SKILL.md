---
name: split
description: Split large revisions into atomic, reviewable commits using manual reconstruction. Use when changes touch multiple unrelated areas, when preparing for code review, or when the user says "split".
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(jj new:*), Bash(jj log:*), Bash(jj st:*), Bash(jj show:*), Bash(jj edit:*), Bash(jj desc:*), Bash(jj abandon:*), Bash(jj bookmark:*), Read, Edit, Write, Skill(commit:*)
argument-hint: [optional context or focus area]
disable-model-invocation: true
---

# Atomic Commit Splitting

Automatically split changes into atomic commits, or commit directly if no split needed.

## Context

- Git status: !`git status --porcelain`
- Changes: !`git diff --stat`
- Recent commits: !`git log --oneline -5`
- Current jj log: !`jj log -n 5`
- Full diff: !`git diff`

## Execution Mode: Fully Automatic

**No user interaction unless truly blocked.**

1. Analyze changes silently
2. Decide: split or single commit
3. Execute automatically
4. Report result at the end

## Decision: Split or Not?

**No split needed (single commit) when:**
- All changes serve one logical purpose
- Files are tightly coupled (reference each other)
- The "and" test passes (message doesn't need "and")
- Same layer/component

**Split needed when:**
- Mixed unrelated changes (bug fix + feature)
- Different layers that could be independent
- Independent changes in same file
- Message would need "and"

## If No Split Needed

Immediately call `/commit` and report:

```
Done: 1 commit created
```

## If Split Needed

### Atomic Commit Criteria

Each commit must be:
- **Single-purpose** - one logical thing
- **Compilable** - builds independently
- **Bisectable** - valid checkpoint for debugging

### Dependency Order

Build foundation first:

```
Layer 1: Models/APIs → Layer 2: Domain → Layer 3: ViewModels → Layer 4: UI
```

### Reconstruction Workflow

1. **Bookmark reference**: `jj bookmark create messy-reference -r @`
2. **Go to parent**: `jj new @-`
3. **For each commit** (in dependency order):
   - `jj new` - create empty commit
   - Implement the changes for this commit using Edit/Write tools
   - Call `/commit` to generate message
4. **Cleanup**: `jj abandon messy-reference && jj bookmark delete messy-reference`
5. **Report**:
   ```
   Done: N commits created
   1. <commit message>
   2. <commit message>
   ...
   ```

## When to Stop and Ask

Only stop for user input when:
- Cannot determine logical groupings
- Ambiguous dependency order
- Conflicting requirements in user context

In these cases, briefly explain the blocker and ask for clarification.

## Rules

**Do:**
- Execute fully automatically
- Call `/commit` for each revision (it handles messages)
- Report only the final result
- Use Edit/Write to implement changes during reconstruction

**Don't:**
- Generate commit messages (let /commit do it)
- Explain analysis in detail
- Ask for confirmation
- Show intermediate steps
- Use jj split or jj squash commands

## Usage

- `/split` - Analyze and split/commit automatically
- `/split focus on the refactoring` - Split with specific context
