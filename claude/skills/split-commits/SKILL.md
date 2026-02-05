---
name: split-commits
description: Split large revisions into atomic, reviewable commits. Use when changes touch multiple unrelated areas, when preparing for code review, or when the user says "split commits".
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(jj split:*), Bash(jj log:*), Bash(jj st:*), Bash(jj show:*), Bash(jj edit:*), Skill(commit:*)
argument-hint: [optional context or focus area]
disable-model-invocation: true
---

# Atomic Commit Splitting

Split current changes into atomic, reviewable commits that support debugging, code review, and clean git history.

## Automated Execution

This skill executes all splitting automatically without confirmation:
- Analyze changes and determine optimal commit structure
- Execute `jj split` commands
- Run `/commit` on each revision
- Verify with `jj log`, `jj st`, `jj show`

## Context

- Git status: !`git status --porcelain`
- Branch: !`git branch --show-current`
- Changes: !`git diff --stat`
- Recent commits: !`git log --oneline -5`
- Full diff: !`git diff`

## What Makes an Atomic Commit

Each commit must be:

1. **Single-purpose** - Does exactly one logical thing
2. **Complete** - Compiles and passes tests independently
3. **Bisectable** - Valid checkpoint for `git bisect` debugging
4. **Reviewable** - Understandable without other commits
5. **Revertable** - Can be rolled back safely

**The "and" test**: If your commit message needs "and", split it.

## When to Split

| Split Into Separate Commits | Keep Together |
|-----------------------------|---------------|
| Bug fix + unrelated feature | Feature + its tests |
| Refactoring + behavior change | Config + code using it |
| Formatting + logic changes | Related model + consumer (if small) |
| Independent changes in same file | Tightly coupled components |
| Different components/features | Single logical unit |

## When NOT to Split

- All changes serve a single, clear purpose
- Splitting would break compilation at any point
- Changes are truly interdependent (can't exist alone)

## Dependency Order (Mandatory)

Commits must be ordered so each one compiles:

```
Layer 1: Shared models/APIs (data classes, interfaces, enums)
    ↓
Layer 2: Repository/Domain (implementations using new models)
    ↓
Layer 3: ViewModels/Controllers (using new repository methods)
    ↓
Layer 4: UI (using ViewModel changes)
```

**Wrong** (breaks build):
```
Commit 1: ViewModel uses event.url  ← API doesn't exist yet!
Commit 2: Add url field to Event   ← Too late
```

**Correct**:
```
Commit 1: Add url field to Event   ← Foundation first
Commit 2: ViewModel uses event.url ← Consumer second
```

## Analysis Process

### 1. Internal Analysis (No Output)

For each changed file, determine:
- Is it a shared model/API? → Must be in earlier commit
- Does it consume new APIs? → Must come after the API commit
- What dependency layer is it?
- Are there independent changes that could be cherry-picked separately?

### 2. Grouping Rules

After ensuring correct dependency order:

1. **Same layer + same component** → Group together
2. **Same layer + related purpose** → Group together
3. **Different layers** → Separate commits
4. **Could be cherry-picked independently** → Consider separating
5. **Unrelated areas** → Separate commits

**Group by WHERE (component), not WHAT (type of change).**

### 3. Commit Size Guidance

- No fixed line count - focus on logical completeness
- Prefer fewer meaningful commits over many tiny ones
- Each should tell part of a coherent story
- Aim for reviewable chunks (roughly 200-400 lines is optimal for review, but logic trumps size)

## Output Format

### If No File Conflicts (Automated):

```
**Proposed commits:**

1. <type>(<scope>): <description>
   - file1.kt
   - file2.kt
   Reason: <why grouped>

2. <type>(<scope>): <description>
   - file3.kt
   Reason: <why separate>

Executing splits...
```

### If File Conflicts (Manual Required):

```
MANUAL SPLITTING REQUIRED

**Proposed commits:**

1. <type>(<scope>): <description>
   - file1.kt
   - file2.kt (partial - specific changes)
   Reason: <explanation>

2. <type>(<scope>): <description>
   - file2.kt (partial - other changes)
   Reason: <explanation>

---

**Files with conflicts:**

**file2.kt:**
- Commit 1: Lines X-Y (what changes)
- Commit 2: Lines A-B (what changes)

---

**Manual split instructions:**

# Commit 1
jj split -i
# Include: file1.kt (all), file2.kt (only X-Y changes)

# Commit 2
jj split -i
# Include: file2.kt (remaining changes)

After splitting, run /commit on each revision.
```

## Execution Steps

1. **Split** with temporary messages:
   ```bash
   jj split file1.kt file2.kt -m "1"
   jj split file3.kt -m "2"
   ```

2. **Verify**:
   ```bash
   jj log -n<count>
   jj st
   jj show <rev>
   ```

3. **Generate messages** (each revision):
   ```bash
   jj edit <rev>
   /commit
   ```

4. **Show result**:
   ```bash
   jj log -n<count>
   ```

## Rules

**Do:**
- Execute `jj split` automatically
- Execute `/commit` automatically
- Verify each step
- Stop if file needs splitting across commits

**Don't:**
- Ask for confirmation
- Use `git commit` or `git add`
- Read files (analyze only diff output)
- Split files appearing in multiple commits (detect and stop)

## Usage

- `/split-commits` - Analyze and split current changes
- `/split-commits focus on the API refactor` - Split with context
