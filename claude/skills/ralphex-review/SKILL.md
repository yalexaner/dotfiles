---
name: ralphex-review
description: >-
  Launch ralphex review pipeline against a base branch in the background.
  Accepts base branch and plan path in any order. Reports status and log path
  when complete. Use after /ralphex-implement.
argument-hint: [base-branch] [plan-path]
disable-model-invocation: true
allowed-tools: Bash(ralphex *), Bash(jj *), Bash(which *), Bash(pwd), Bash(ls *), Bash(tail *), Bash(cat /tmp/*), Bash(fish -c *)
---

# Ralphex Review

Launch ralphex review pipeline against a specified base branch, wait for completion,
and report results. Use after `/ralphex-implement`.

> **Critical rule**: Every Bash tool call must be a standalone command. NEVER combine
> commands with `||`, `&&`, `|`, or `;`. Handle errors and fallbacks in skill logic.

> **jj workspace limitation**: ralphex requires a `.git` directory and cannot run in
> jj workspaces (they only have `.jj`). Always run from the main/colocated repo directory.

## Pre-flight

- Ralphex installed: !`which ralphex 2>/dev/null || echo "NOT_FOUND"`
- Working directory: !`pwd`
- Current jj state: !`jj log -n 10 2>/dev/null || echo "NO_JJ"`
- Completed plans: !`ls docs/plans/completed/*.md 2>/dev/null || echo "NONE"`

## Arguments

Accept base branch and plan path in any order:

- If $ARGUMENTS[0] contains `.md` or `/` → it's the plan path, $ARGUMENTS[1] is the branch
- If $ARGUMENTS[1] contains `.md` or `/` → it's the plan path, $ARGUMENTS[0] is the branch
- If only one arg:
  - Contains `.md` or `/` → plan path, ask user for base branch
  - Otherwise → base branch, auto-detect plan from docs/plans/completed/
- If no args:
  - Auto-detect plan from docs/plans/completed/
  - Ask user for base branch

---

## Phase 0: Resolve Arguments

### 0.1 Determine base branch and plan path

1. Examine $ARGUMENTS and classify each:
   - Contains `.md` or `/` → plan path
   - Otherwise → base branch

2. Store `base_branch` and `plan_path` for later use.

3. If ambiguous or missing:
   - Use AskUserQuestion tool to ask for missing values
   - Show context: "Found plan: {plan}. Which base branch to review against?"

---

## Phase 1: Launch Review

Launch `ralphex-review` fish function in the background with a timestamped log:

```bash
log_file="/tmp/ralphex-review-$(date +%s).log"
fish -c "ralphex-review $base_branch $plan_path" > "$log_file" 2>&1 &
```

Store the log file path and PID for reference.

Ralphex review takes 30min–2hrs. The background task will notify when done — do NOT poll or sleep.
If the user asks for status, read the log file tail:

```bash
tail -n 50 "$log_file"
```

After 2hrs without completion: report partial progress and stop.

---

## Phase 2: Check Status

After the background task completes, check the log tail:

```bash
tail -n 100 "$log_file"
```

Determine:
- Whether ralphex completed successfully or failed
- Any errors or warnings in the log

If ralphex failed — report the error to the user and stop. Do NOT proceed to finalize.

---

## Phase 3: Report

Output a structured report:

```
## Ralphex Review Report

### Summary
- Plan: {plan_path}
- Base branch: {base_branch}
- Status: {success/failed}
- Log: {log_file}

### Next Step
Run `/ralphex-finalize` to clean up revision history for PR.
```

---

## Error Handling

| Scenario | Response |
|----------|----------|
| No plan found | Abort: "No completed plan found" |
| Ralphex failed | Report error from logs, stop |
| 2hr ralphex timeout | Report partial progress, stop |

---

## Usage

```bash
/ralphex-review develop                              # auto-detect plan, review against develop
/ralphex-review develop docs/plans/2026-03-15-foo.md # explicit branch and plan
/ralphex-review docs/plans/2026-03-15-foo.md develop # plan first, branch second
```
