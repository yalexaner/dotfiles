---
name: ralphex-implement
description: >-
  Run ralphex on a plan, wait for completion, then verify the output.
  Examines rev history, runs tests, and produces a report.
  Use /ralphex-finalize after to clean up revs for PR.
argument-hint: [plan-path]
disable-model-invocation: true
allowed-tools: Bash(ralphex *), Bash(jj *), Bash(which *), Bash(pwd), Bash(ls *), Bash(tail *), Bash(cat /tmp/*), Bash(wc *), Bash(go test *), Bash(go vet *), Bash(/usr/local/go/bin/go *), Bash(cargo test *), Bash(npm test *), Bash(npx *), Bash(./gradlew *), Bash(make test*), Skill(commit *)
---

# Ralphex Implement

Run ralphex to implement a plan, verify the output, and report results.
After this skill completes, run `/ralphex-finalize` to clean up revs for PR.

> **Critical rule**: Every Bash tool call must be a standalone command. NEVER combine
> commands with `||`, `&&`, `|`, or `;`. Handle errors and fallbacks in skill logic.

> **Important**: The ralphex CLI command is `ralphex {PLAN_PATH}` (positional argument).
> Do NOT use `ralphex --plan {PLAN_PATH}` — that flag is for interactive plan *creation*,
> not implementation.

> **jj workspace limitation**: ralphex requires a `.git` directory and cannot run in
> jj workspaces (they only have `.jj`). Always run from the main/colocated repo directory.

## Pre-flight

- Ralphex installed: !`which ralphex 2>/dev/null || echo "NOT_FOUND"`
- Working directory: !`pwd`
- Current jj state: !`jj log -n 10 2>/dev/null || echo "NO_JJ"`
- Existing plans: !`ls docs/plans/*.md 2>/dev/null || echo "NO_PLANS"`
- Completed plans: !`ls docs/plans/completed/*.md 2>/dev/null || echo "NONE"`

## Arguments

- **Plan path**: $ARGUMENTS[0] (optional — path to plan file)

---

## Phase 0: Resolve Plan

### 0.1 Determine which plan to implement

Use this priority:
1. $ARGUMENTS[0] if provided — use as plan path directly
2. If exactly one plan file in `docs/plans/` (not `completed/`) — use that plan
3. If multiple non-completed plans exist — ask user which one to implement
4. If no plans found — abort: "No plans found. Run /ralphex-plan first."

### 0.2 Validate plan

1. Read the plan file — verify it has implementation steps with checkboxes
2. Store the plan path for later reference

### 0.3 Create fresh working rev

If the current rev (`@`) has uncommitted changes:
1. Run `/commit` to commit current changes
2. Run `jj new` to get a fresh working copy

---

## Phase 1: Run Ralphex

### 1.1 Launch ralphex in background

Run with `run_in_background=true`, redirecting output to a log file:

```bash
ralphex {PLAN_PATH} > /tmp/ralphex-implement-{TIMESTAMP}.log 2>&1
```

Where `{TIMESTAMP}` is the current unix timestamp for uniqueness.

**IMPORTANT**: The command is `ralphex {PLAN_PATH}` — the plan file is a POSITIONAL
argument. Do NOT use `--plan` flag (that creates plans, not implements them).

Store the log file path for later.

### 1.2 Wait for completion

The background task will notify when done — do NOT poll or sleep.
Ralphex can take 30min to 2hrs. If the user asks for status, read the log file tail.

After 2hrs without completion: stop the task, report partial progress.

### 1.3 Analyze ralphex output

Read the log file tail and check:
- Whether ralphex completed successfully or failed
- Any errors or warnings

If ralphex failed — report the error to the user and stop.

---

## Phase 2: Verify Implementation

### 2.1 Examine rev history

```bash
jj log --limit 30
```

For each rev created by ralphex, check:
```bash
jj diff -r {REV_ID} --stat
```

### 2.2 Run tests

Detect the project's test command by checking for:
- `go.mod` → `go test ./...` (try `go` first, fall back to `/usr/local/go/bin/go`)
- `Cargo.toml` → `cargo test`
- `package.json` → `npm test` or the `test` script
- `build.gradle.kts` / `build.gradle` → `./gradlew test`
- `Makefile` with `test` target → `make test`
- Otherwise — ask user for the test command

Run the detected test command. If tests fail — report to user and stop.

### 2.3 Read all source files

Launch a subagent (`subagent_type: Explore`) to read all implementation files and verify:
- Code quality and correctness
- Whether implementation matches the plan
- Any obvious issues

Report findings (do NOT fix issues).

---

## Phase 3: Report

Output a structured report:

```
## Ralphex Implementation Report

### Summary
- Plan: {plan_path}
- Status: {success/failed}
- Revs created: {count}
- Tests: {pass/fail}
- Log: {log_file_path}

### Rev History (ralphex output)
{rev_id} — {description}
  └─ {files changed summary}
...

### Code Review
{findings from explore subagent, or "No issues found"}

### Next Step
Run `/ralphex-finalize` to restructure revs, remove artifacts, and prepare for PR.
```

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Ralphex not installed | Abort with install instructions |
| No plan found | Abort: "Run /ralphex-plan first" |
| Ralphex failed | Report error from logs, stop |
| Tests fail after implementation | Report failures, stop |
| 2hr ralphex timeout | Stop ralphex, report partial progress |

---

## Usage

```bash
/ralphex-implement                              # auto-detect plan
/ralphex-implement docs/plans/2026-03-15-foo.md # specific plan
```
