---
name: split
description: Split large revisions into atomic, reviewable commits. Use when changes touch multiple unrelated areas, when preparing for code review, or when the user says "split".
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(jj new:*), Bash(jj log:*), Bash(jj st:*), Bash(jj show:*), Bash(jj edit:*), Bash(jj desc:*), Bash(jj abandon:*), Bash(jj rebase:*), Read, Edit, Write, Skill(commit:*)
argument-hint: [optional context or focus area]
disable-model-invocation: true
---

# Atomic Commit Splitting

Automatically split changes into atomic commits, or commit directly if no split needed.

## Context

- Changes: !`git diff --stat`
- Current jj log: !`jj log -n 5`
- Full diff: !`git diff`

## Execution: Fully Automatic

1. Analyze changes silently
2. If single commit → call `/commit` → output "Done: 1 commit"
3. If split needed → create ALL commits → verify → cleanup → output result

## Decision: Split or Not?

**No split needed when:**
- All changes serve one logical purpose
- Files are tightly coupled
- Same layer/component

**Split needed when:**
- Mixed unrelated changes
- Different independent features
- Message would need "and"

## If No Split Needed

Call `/commit`, then output:
```
Done: 1 commit
```

## If Split Needed

### Expected Result

```
BEFORE:
Parent (abc) → Messy (@) with changes A+B

AFTER:
Parent (abc) → Commit1 (A) → Commit2 (B)
No messy commit, no bookmarks, no empty commits
```

### Workflow

1. **Note IDs** (no bookmarks!)
   ```bash
   jj log -r @   # messy-id
   jj log -r @-  # parent-id
   ```

2. **Go to parent**
   ```bash
   jj new <parent-id>
   ```

3. **For EACH planned commit** (don't stop after first!):
   - Implement changes using Edit/Write
   - Call `/commit`
   - Then `jj new` for next commit (except after last one)

4. **Safety check** - rebase messy onto last commit:
   ```bash
   jj rebase -r <messy-id> -d @
   jj diff -r <messy-id>
   ```
   If empty → all changes moved correctly
   If has changes → something was missed

5. **Cleanup** (only if messy is empty):
   ```bash
   jj abandon <messy-id>
   ```

6. **Output**:
   ```
   Done: N commits
   1. <message>
   2. <message>
   ```

### Dependency Order

Build foundation first:
```
Layer 1: Models/APIs → Layer 2: Domain → Layer 3: ViewModels → Layer 4: UI
```

## Rules

**Do:**
- Create ALL planned commits (not just the first one!)
- Call `/commit` for each revision
- Rebase messy as safety check
- Abandon messy only if empty
- Output only final result

**Don't:**
- Create bookmarks
- Create empty commits
- Stop after first commit
- Leave messy commit or empty commits
- Generate commit messages (use /commit)

## Error: Safety Check Failed

If messy not empty after rebase:
```
WARNING: Not all changes were moved

Remaining changes:
<jj diff -r messy-id output>

Please review manually.
```

## Usage

- `/split` - Analyze and split/commit automatically
