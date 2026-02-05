---
name: split
description: Split large revisions into atomic, reviewable commits using manual reconstruction. Use when changes touch multiple unrelated areas, when preparing for code review, or when the user says "split".
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(jj new:*), Bash(jj log:*), Bash(jj st:*), Bash(jj show:*), Bash(jj edit:*), Bash(jj desc:*), Bash(jj abandon:*), Bash(jj bookmark:*), Read, Edit, Write
argument-hint: [optional context or focus area]
disable-model-invocation: true
---

# Atomic Commit Splitting via Manual Reconstruction

Split changes into atomic commits by **rebuilding from the ground up**, not by using split/squash tools.

## The Approach

Instead of using tools to move code between commits:

1. **Keep the messy commit as a reference** (your cheat sheet)
2. **Go back to the parent** (clean slate)
3. **Manually re-implement** each logical change as a new commit
4. **Build layer by layer** - foundation first, dependents on top

This solves the problem of same-file splitting without TUI interaction.

## Context

- Git status: !`git status --porcelain`
- Branch: !`git branch --show-current`
- Changes: !`git diff --stat`
- Recent commits: !`git log --oneline -5`
- Current jj log: !`jj log -n 5`
- Full diff: !`git diff`

## Why Manual Reconstruction (Not split/squash)

| Tool-Based | Manual Reconstruction |
|------------|----------------------|
| Tools move code automatically | You implement code |
| Requires TUI for same-file splits | No TUI needed |
| "Which parts do I exclude?" | "What do I build first?" |
| Passive - code moves as-is | Active - you understand each change |
| Possible merge conflicts | Clean implementation |

## What Makes an Atomic Commit

Each commit must be:

1. **Single-purpose** - Does one logical thing
2. **Compilable** - Builds independently
3. **Bisectable** - Valid checkpoint for debugging
4. **Reviewable** - Understandable in isolation

**The "and" test**: If commit message needs "and", split it.

## Dependency Order (Mandatory)

Build from foundation to top:

```
Layer 1: Shared models/APIs (data classes, interfaces)
    ↓
Layer 2: Repository/Domain (uses new models)
    ↓
Layer 3: ViewModels/Controllers (uses repository)
    ↓
Layer 4: UI (uses ViewModel)
```

You cannot accidentally violate this - code won't compile if you try.

## The Workflow

### Phase 1: Analysis

Examine the messy commit and create a reconstruction plan:

1. **Identify logical changes** - What distinct things were done?
2. **Determine layers** - Which dependency layer is each change?
3. **Group by purpose** - What belongs together?
4. **Order by dependency** - Foundation first

**Output a clear plan:**

```
RECONSTRUCTION PLAN

Reference commit: <change-id>

Commit 1 (Layer 1): <type>(<scope>): <description>
  Files to implement:
  - Model.kt: add new field "url" (lines 15-20 in reference)
  - Event.kt: add new event type (lines 5-10 in reference)

Commit 2 (Layer 3): <type>(<scope>): <description>
  Files to implement:
  - ViewModel.kt: use new event type (lines 45-60 in reference)
  - ViewModel.kt: add loading state (lines 70-85 in reference)

Commit 3 (Layer 4): <type>(<scope>): <description>
  Files to implement:
  - Screen.kt: display loading state (lines 30-50 in reference)
```

### Phase 2: Setup

```bash
# 1. Note the messy commit ID (this is your reference)
jj log -n 1
# Reference: <messy-commit-id>

# 2. Create a bookmark to preserve it
jj bookmark create messy-reference -r @

# 3. Go to parent (clean slate)
jj new @-

# Now you're at parent, ready to build fresh commits
```

### Phase 3: Build Each Commit

For each commit in the plan:

```bash
# 1. Create new empty commit
jj new -m "WIP: <description>"
```

Then **manually implement** the changes for this commit:
- Look at the reference commit (`jj show messy-reference`)
- Read the specific sections noted in the plan
- Type out / implement the changes (don't copy-paste large chunks)
- Verify it compiles

```bash
# 2. After implementing, verify
jj st                    # Check what you've added
jj diff                  # Review your changes

# 3. Update commit message
jj desc -m "<proper commit message>"

# 4. Move to next commit
jj new -m "WIP: <next description>"
```

Repeat for each commit in the plan.

### Phase 4: Cleanup

```bash
# 1. Verify final structure
jj log -n <count>

# 2. Verify each commit compiles (build/test each)

# 3. Abandon the reference commit
jj abandon messy-reference

# 4. Delete the bookmark
jj bookmark delete messy-reference
```

## My Role

I will:

1. **Analyze** the messy commit thoroughly
2. **Create the reconstruction plan** with:
   - Clear commit groupings
   - Dependency order
   - Specific file/line references for each commit
3. **Guide you through setup** (creating bookmark, going to parent)
4. **For each commit**:
   - Tell you what to implement
   - Show you the relevant parts of the reference
   - Help you write the code if needed
   - Verify the result
5. **Handle cleanup** at the end

## Output Format

```
ANALYSIS COMPLETE

Reference commit: abc123 (bookmarked as "messy-reference")

---

RECONSTRUCTION PLAN (3 commits)

1. feat(model): add url field to ValidationEvent
   Layer: 1 (foundation)
   Implement:
   - ValidationEvent.kt: change "ip: String" to "url: String"

   Reference (jj show messy-reference --path ValidationEvent.kt):
   [relevant code snippet]

2. refactor(viewmodel): update event handling
   Layer: 3 (consumer)
   Implement:
   - SavedViewModel.kt: use event.url instead of event.ip
   - ManualViewModel.kt: use event.url instead of event.ip

   Reference snippets:
   [relevant code snippets]

3. feat(ui): add loading indicator
   Layer: 4 (UI)
   Implement:
   - ConnectionScreen.kt: add CircularProgressIndicator when loading

   Reference snippets:
   [relevant code snippets]

---

Ready to begin? I'll set up the reference bookmark and guide you through each commit.
```

## Rules

**Do:**
- Create detailed reconstruction plan with file/line references
- Preserve messy commit as reference (bookmark)
- Guide implementation commit by commit
- Show relevant reference code for each step
- Verify each commit compiles before moving on
- Clean up reference at the end

**Don't:**
- Use jj split or jj squash
- Copy-paste large code blocks (implement instead)
- Skip dependency order verification
- Leave reference commit dangling

## Usage

- `/split` - Analyze current changes and create reconstruction plan
- `/split focus on the refactoring` - Split with specific context

## Additional Resources

See [references/examples.md](references/examples.md) for detailed examples.
