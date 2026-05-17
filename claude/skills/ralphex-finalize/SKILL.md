---
name: ralphex-finalize
description: >-
  Clean up revision history after /ralphex-implement and /ralphex-review.
  Restructures revs (split/squash), removes plan artifacts, updates docs,
  and produces a final report ready for PR.
argument-hint: [base-rev]
disable-model-invocation: true
allowed-tools: Bash(jj *), Bash(git diff *), Bash(git status *), Bash(git log *), Bash(which *), Bash(jq *), Bash(go test *), Bash(go vet *), Bash(/usr/local/go/bin/go *), Bash(cargo test *), Bash(npm test *), Bash(npx *), Bash(./gradlew *), Bash(make test*), Bash(ls *), Bash(cat /tmp/*), Bash(pwd), Edit, Write, Skill(commit *)
---

# Ralphex Finalize

Clean up the revision history after `/ralphex-implement` and `/ralphex-review`,
restructure into atomic reviewable commits, and prepare for PR.

> **Critical rule**: Every Bash tool call must be a standalone command. NEVER combine
> commands with `||`, `&&`, `|`, or `;`. Handle errors and fallbacks in skill logic.

> **jj rule**: When using `jj squash --from X --into Y` where both revs have non-empty
> descriptions, ALWAYS use `-m "message"` to avoid opening an editor.

## Pre-flight

- Working directory: !`pwd`
- Current jj state: !`jj log -n 20 2>/dev/null || echo "NO_JJ"`
- Completed plans: !`ls docs/plans/completed/*.md 2>/dev/null || echo "NONE"`

## Arguments

- **Base rev**: $ARGUMENTS[0] (optional — rev ID of the last commit BEFORE ralphex ran.
  If not provided, auto-detect by finding the oldest rev with a ralphex-style description
  or by looking for the most recent bookmark/tagged rev.)

---

## Phase 0: Detect Ralphex Output

### 0.1 Identify ralphex revs

Examine the jj log to find:
1. The **base rev** — the last commit before ralphex ran (either from $ARGUMENTS[0]
   or auto-detected as the parent of the first ralphex-created rev)
2. All revs between the base and `@` — these are ralphex's output

Heuristics for auto-detection:
- Look for a sequence of revs above a bookmark (e.g., `feature/...`) or `master`
- Check `.ralphex/progress/` for the plan name and timestamps
- Look for revs with ralphex-typical patterns: plan checkbox updates, "fix: address
  code review findings", "move completed plan"

### 0.2 Catalog each rev

For each ralphex rev (oldest to newest), record:
- Rev ID
- Current description
- Files changed (`jj diff -r {ID} --stat`)
- Classify: **code**, **test**, **docs**, **plan-artifact**, **review-fix**

Output the catalog for transparency.

---

## Phase 1: Plan Restructuring

### 1.1 Identify target revs

Determine the ideal final rev structure:
- Group changes by logical purpose (feature, component, layer)
- Each target rev should be one atomic, reviewable change
- Tests go with the code they test (not in separate revs)
- Review fixes get squashed into the rev they fix

### 1.2 Create restructuring plan

For each current rev, determine:
- **Keep as-is**: rev is already atomic and correct
- **Split needed**: rev has changes belonging to multiple target revs
- **Squash needed**: rev should be combined with another rev
- **Remove entirely**: rev is pure plan artifact (only plan file changes)

Document the plan before executing. Output the plan for transparency.

---

## Phase 2: Execute Restructuring

### 2.1 Split revs that need splitting

For each rev that needs splitting:

**Simple case** — entire files belong to different targets:
```bash
jj split -r {REV_ID} -m "{description}" -- {file_paths}
```

**Complex case** — a single file has changes for multiple targets:
Launch a subagent (`subagent_type: general-purpose`) with the prompt from
[references/split-subagent-prompt.md](references/split-subagent-prompt.md),
providing it with:
- The rev ID to split
- The file(s) that need partial splitting
- Which changes belong to which target rev
- The full diff of the file (`jj diff -r {REV_ID} -- {FILE_PATH}`)

After the subagent reports back, verify:
```bash
jj log --limit 10
jj diff -r {NEW_REV_ID} --stat
```

### 2.2 Squash revs into their targets

For each rev that should be squashed into another:
```bash
jj squash --from {SOURCE_REV} --into {TARGET_REV} -m "{final description}"
```

**If squash causes conflicts** (cascading conflicts from shared files):
1. Run `jj undo` immediately
2. Fall back to split-first approach:
   - Split the problematic file out of the source rev
   - Squash only the non-conflicting files
   - Handle the problematic file separately
3. If still stuck — report to user and stop

### 2.3 Clean up empty revs

```bash
jj log --limit 20
```

Abandon any empty revs:
```bash
jj abandon {EMPTY_REV_ID}
```

---

## Phase 3: Per-Rev Cleanup (Oldest to Newest)

Go through each remaining rev from oldest to newest. Do NOT skip any rev.

For each rev:

### 3.1 Edit the rev

```bash
jj edit {REV_ID}
```

### 3.2 Remove artifacts

Check for and remove files that should not be in history:
- Plan files: `docs/plans/*.md` and `docs/plans/completed/*.md`
- Ralphex progress: `.ralphex/progress/`
- Any files matching `.gitignore` patterns that got tracked
- Temp files, build artifacts

To remove a file from the rev:
```bash
jj restore --from @- -- {FILE_PATH}
```

### 3.3 Resolve conflicts if any

After removing artifacts, descendant revs may conflict (because they also modified
the removed file). This is expected — continue to the next rev and remove the same
file there too using `jj restore --from @- -- {FILE_PATH}`.

### 3.4 Commit with proper message

Run `/commit` to generate a proper conventional commit message for this rev.

### 3.5 Move to next rev

Repeat steps 3.1–3.4 for each subsequent rev until all are clean.

### 3.6 Final empty rev

After processing all revs, create a fresh working copy:
```bash
jj new
```

---

## Phase 4: Update Project Docs

After all revs are finalized, update project documentation in a new rev.

### 4.1 Update todo.md

Mark completed items from the plan as done (`[x]`). Compare the plan's tasks against
the todo checklist and check off everything that was implemented.

### 4.2 Update spec.md and todo.md with new knowledge

During implementation, ralphex may have made decisions, discovered constraints, or
clarified requirements. Review:
- The completed plan file — extract technical decisions and clarifications
- The implementation code — identify any deviations from the spec
- The ralphex log (if still available in /tmp/) — check for notes about approach changes

Update `docs/spec.md` and `docs/todo.md` with any new information:
- Clarified requirements or behaviors
- Technical decisions made during implementation
- New constraints or limitations discovered
- New todo items discovered but not implemented

### 4.3 Commit the docs update

Run `/commit` to create a rev for the documentation update.

---

## Phase 5: Verify

### 5.1 Run tests

Run the project's test command to ensure restructuring didn't break anything.

Detect test command:
- `go.mod` → `go test ./...` (try `go` first, fall back to `/usr/local/go/bin/go`)
- `Cargo.toml` → `cargo test`
- `package.json` → `npm test`
- `build.gradle.kts` / `build.gradle` → `./gradlew test`
- `Makefile` with `test` target → `make test`

If tests fail — report and stop.

### 5.2 Verify final rev structure

```bash
jj log --limit 20
```

For each rev, verify:
```bash
jj diff -r {REV_ID} --stat
```

Confirm:
- No plan files or artifacts in any rev
- No empty revs
- No conflict markers
- Each rev is atomic and reviewable

---

## Phase 6: Final Report

Output a structured report to the user:

```
## Finalization Complete

### Summary
- Revs: {original count from ralphex} → {final count after restructuring}
- Tests: {pass/fail}
- Artifacts removed: {list of removed plan/progress files}

### Rev Structure
1. {rev_id_short} — {commit_message}
   └─ {files changed summary}
2. {rev_id_short} — {commit_message}
   └─ {files changed summary}
...
N. {rev_id_short} — docs: update todo and spec
   └─ {docs/todo.md, docs/spec.md}

### Docs Updated
- todo.md: {items marked complete}
- spec.md: {changes made, or "no changes needed"}

### Ready for PR
All revs are clean, atomic, and reviewable.
```

---

## Error Handling

| Scenario | Response |
|----------|----------|
| No ralphex revs found | Abort: "No ralphex output detected. Run /ralphex-implement first." |
| Squash causes cascading conflicts | Undo, try split-first approach |
| Split subagent fails safety check | Report remaining changes, stop |
| Tests fail after restructuring | Report failures, stop |

---

## Usage

```bash
/ralphex-finalize              # auto-detect ralphex revs
/ralphex-finalize ozoqmyun     # specify base rev (last rev before ralphex)
```
