---
name: ralphex-implement
description: >-
  Launch ralphex task execution on a plan using Kimi (OpenCode) in the background.
  Reports status and log path when complete. Use /ralphex-review after to run
  the review pipeline against a base branch.
argument-hint: [plan-path]
disable-model-invocation: true
allowed-tools: Bash(ralphex *), Bash(jj *), Bash(which *), Bash(pwd), Bash(ls *), Bash(tail *), Bash(cat /tmp/*), Bash(fish -c *)
---

# Ralphex Implement

Launch ralphex task execution on a plan using Kimi (OpenCode), wait for completion,
and report results. After this skill completes, run `/ralphex-review <base-branch>`
to run the review pipeline.

> **Critical rule**: Every Bash tool call must be a standalone command. NEVER combine
> commands with `||`, `&&`, `|`, or `;`. Handle errors and fallbacks in skill logic.

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

## Phase 1: Launch Tasks

Launch `ralphex-tasks-opencode` in the background with a timestamped log:

```bash
log_file="/tmp/ralphex-implement-$(date +%s).log"
fish -c "ralphex-tasks-opencode $plan_path" > "$log_file" 2>&1 &
```

Store the log file path and PID for reference.

Ralphex takes 30min–2hrs. The background task will notify when done — do NOT poll or sleep.
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

If ralphex failed — report the error to the user and stop. Do NOT proceed to review.

---

## Phase 3: Report

Output a structured report:

```
## Ralphex Implementation Report

### Summary
- Plan: {plan_path}
- Status: {success/failed}
- Log: {log_file}

### Next Step
Run `/ralphex-review <base-branch> {plan_path}` to run the review pipeline.
```

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Ralphex not installed | Abort with install instructions |
| No plan found | Abort: "Run /ralphex-plan first" |
| Ralphex failed | Report error from logs, stop |
| 2hr ralphex timeout | Report partial progress, stop |

---

## Usage

```bash
/ralphex-implement                              # auto-detect plan
/ralphex-implement docs/plans/2026-03-15-foo.md # specific plan
```
