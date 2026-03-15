---
name: mr-audit
description: >-
  Triple-model MR review that runs Claude Code, Codex skill-based, and Codex built-in reviews
  in parallel, cross-validates findings against the codebase, and produces a unified
  confidence-tiered report. Use when you want a thorough multi-perspective merge request review.
argument-hint: [mr-number] [jira-ticket]
disable-model-invocation: true
allowed-tools: Bash(codex exec *), Bash(which *), Bash(glab mr view *), Bash(glab mr diff *), Bash(glab mr list *), Bash(git log *), Bash(git diff *), Bash(jj log *), Bash(jj show *), Bash(jq *), Read, Grep, Glob, Skill(mr-review *), Skill(jira *)
---

# Triple-Model MR Review

Run three independent reviews in parallel — Claude Code (`/mr-review`), Codex skill-based (`$mr-review`), and Codex built-in code review — then cross-validate findings against the codebase and compile a single confidence-tiered report.

> **Critical rule**: Every Bash tool call must be a standalone command. NEVER combine commands with `||`, `&&`, `|`, or `;`. Handle errors and fallbacks in skill logic — run one command, check its output, then decide what to do next. Compound commands break the permission system and will trigger approval prompts. This rule applies to Bash tool calls only — `!`command`` pre-flight blocks are preprocessing and may use shell operators freely.

> **Language rule**: The entire report must be written in English. All findings, explanations, suggestions, architecture assessments, and questions must be in English. The only exception is direct quotes from source materials (reviewer comments, MR descriptions, Jira tickets) — these may remain in their original language when explicitly quoted.

## Pre-flight

- Codex installed: !`which codex 2>/dev/null || echo "NOT_FOUND"`
- Current bookmark: !`jj log -r 'ancestors(@) & bookmarks()' --limit 1 --no-graph -T 'bookmarks.join(", ")' 2>/dev/null`
- Working directory: !`pwd`
- JJ status: !`jj log -r @ --no-graph -T 'self.change_id().shortest(8) ++ " " ++ branches' 2>/dev/null || echo "NO_JJ"`
- MR info: !`glab mr view 2>/dev/null || echo "NO_MR"`

## Arguments

- **MR Identifier**: $ARGUMENTS[0] (MR number, branch name, or empty for current branch)
- **Jira Ticket**: $ARGUMENTS[1] (optional — key like STB-1417 or URL)

---

## Phase 0: Resolve MR & Jira Context

All three reviews need the same MR and Jira ticket. Resolve both upfront so every review gets consistent input.

### 0.1 Determine MR

Use this priority:
1. $ARGUMENTS[0] if provided — use as MR number or branch name
2. Pre-flight MR info — if it found an MR for the current branch, use that
3. **If neither works**: Run `glab mr list -P 10` (lists open MRs by default, limited to 10) and present the list to the user to pick from
4. If no open MRs exist — abort, nothing to review

**Important**: `glab mr list` has no `--state` flag — see [references/glab-flags.md](references/glab-flags.md) for correct flags.

### 0.2 Fetch MR Details

Run this exact command:

    glab mr view {MR_NUMBER} -F json

Parse these fields from the JSON output:
- `source_branch` — the MR's source branch
- `target_branch` — the MR's target branch
- `title` — MR title
- `description` — MR description
- `author.username` — MR author

Do NOT use `glab api`, pipes, or any other command to get this information.

### 0.3 Verify Working Copy

All three reviews read files from the local working tree. If the checkout doesn't match the MR source branch, reviews will analyze wrong code.

1. Get the current bookmark from pre-flight
2. Compare it with the MR `source_branch` (from Phase 0.2)
3. If they match — working copy is correct
4. If they don't match or pre-flight returned empty — warn the user and ask whether to proceed or switch first. Do NOT switch automatically.

### 0.4 Extract Jira Ticket

Use this priority:
1. $ARGUMENTS[1] if provided
2. Extract from MR title (pattern: `[A-Z]+-\d+`, e.g. "STB-1417 [OTAUpdater]..." or "STB-1343: Доработка...")
3. Extract from MR description or branch name
4. **Ask the user** for the Jira ticket key or URL — it is acceptable if the user has no ticket, proceed without

### 0.5 Check Codex

If pre-flight shows `NOT_FOUND`, set mode to **Claude-Only** and skip to Phase 1C. Refer user to [references/SETUP.md](references/SETUP.md) for installation.

### 0.6 Build Output Paths

Derive the project name from the last segment of the working directory path (pre-flight). Use it for uniqueness across parallel runs:
- Codex skill review: `/tmp/codex-mr-review-{PROJECT}-{MR_NUMBER}.md`
- Codex built-in raw JSONL: `/tmp/codex-builtin-raw-{PROJECT}-{MR_NUMBER}.jsonl`

The Codex built-in review text is extracted from the JSONL via `jq` at processing time — no separate file needed.
- Codex built-in review: `/tmp/codex-builtin-review-{PROJECT}-{MR_NUMBER}.md`

---

## Phase 1: Launch Three Parallel Reviews

Launch all three simultaneously. Make 1A and 1B as background Bash calls, then invoke 1C as a foreground skill.

### 1A: Codex Skill Review (background)

Run with `run_in_background=true`. This uses the `$mr-review` Codex skill which mirrors Claude's structured review with glab and Jira context.

```bash
codex exec -s danger-full-access -C "$PWD" \
  -o "/tmp/codex-mr-review-{PROJECT}-{MR_NUMBER}.md" \
  '$mr-review {MR_NUMBER}'
```

**Important**: Do NOT use `--full-auto` — it overrides sandbox to workspace-write, blocking network access needed for `glab` and Jira.

### 1B: Codex Built-in Code Review (background)

Run with `run_in_background=true`. This is Codex's own review engine — pure code diff analysis without MR/Jira context. A different angle.

**Step 1** — capture raw JSONL output (background):

```bash
codex exec review --base {TARGET_BRANCH} --full-auto --json > "/tmp/codex-builtin-raw-{PROJECT}-{MR_NUMBER}.jsonl"
```

**Step 2** — extract the review text (after background task completes):

```bash
jq -rs '[.[] | select(.type=="item.completed" and .item.type=="agent_message") | .item.text] | last // ""' "/tmp/codex-builtin-raw-{PROJECT}-{MR_NUMBER}.jsonl"
```

The review text is returned as Bash output — do NOT redirect Step 2 output to a file with `>`. Hold it for use in Phase 3. (Step 1 intentionally uses `>` for background capture — this will trigger a one-time permission prompt.)

**Note**: These are two separate Bash calls, not a pipe. See the global rule about standalone commands. See [references/codex-review-bug.md](references/codex-review-bug.md) for why `--json` + `jq` is needed instead of `-o`.

### 1C: Claude Review (foreground)

Invoke the existing skill with both MR and ticket (already resolved in Phase 0):

```
/mr-review {MR_NUMBER} {JIRA_TICKET}
```

If no ticket was found, omit it: `/mr-review {MR_NUMBER}`

---

## Phase 2: Collect Results

After `/mr-review` finishes:

### Waiting for background tasks

Use `TaskOutput` with `block=true` to wait. It long-polls — returns instantly when the task completes, or after the timeout if still running. It does NOT sleep for the full timeout.

For each background task:
1. Call `TaskOutput(task_id, block=true, timeout=600000)` — waits up to 10 min
2. If the task is still running, call `TaskOutput` again (another 10 min)
3. Repeat up to 3 times total (30 min maximum)
4. After 30 min: stop the task with `TaskStop`, skip that source, degrade gracefully

Do NOT stop background tasks before the 30-minute limit. Codex reviews can legitimately take 15-20 minutes on large MRs.

**Fallback**: If `TaskOutput` behaves unexpectedly (hangs, returns no data), check the output files directly with Read. A non-empty output file may indicate completion even if TaskOutput didn't report it.

### Processing results

1. Run the Phase 1B Step 2 `jq` command on the raw JSONL file — the review text comes back as Bash output
2. Read the Codex skill review file: `/tmp/codex-mr-review-{PROJECT}-{MR_NUMBER}.md`
3. You now have all three reviews: Claude (from Phase 1C), Codex skill (from the file), Codex built-in (from jq output)
4. **Degrade gracefully** per source:
   - If a file is missing, empty, or contains error output → exclude that source
   - Note which sources are available for the final report
   - If both Codex sources failed → Claude-Only mode

---

## Phase 3: Cross-Validate & Investigate

This is the core value. Three independent models give three perspectives — overlapping findings have highest confidence.

### 3.1 Classify Findings

For each finding, assign a **consensus tag** and a **severity** per the definitions in [references/report-format.md](references/report-format.md) (see "Consensus tags" and "Severity groups" tables).

Match findings by: same file + same function/area + same type of issue. Similar issues in the same area count as agreement even if wording differs.

For severity conflicts on the same finding: default to the **higher** severity.

### 3.2 Investigate Single-Source Findings

For each finding raised by only one model:

1. **Read the code** at the referenced file:line with surrounding context
2. **Search for related patterns** — callers, similar code, existing tests
3. **Assign a verdict**:
   - **Confirmed** — code investigation supports the finding
   - **Dismissed** — the code is actually correct; explain why (e.g. "handled by caller", "tested in FooTest.kt")
   - **Uncertain** — cannot definitively confirm or dismiss; flag for human review

### 3.3 Merge Explanations

For each finding, combine insights from all sources that flagged it into **one unified explanation**. Do not list per-model assessments — write one coherent description with the best insights from each source.

### 3.4 Merge Architecture & Testing Assessments

Combine architecture and testing opinions from all available sources into unified assessments. Note where sources agree or diverge.

---

## Phase 4: Compile Unified Report

1. Load the report template from [references/report-format.md](references/report-format.md)
2. Fill in all sections following the template and its filling instructions
3. Write everything in English (see Language rule above — only direct quotes may stay in original language)
4. Group findings by severity: Must Fix → Should Fix → Nit
5. Within each group, order by priority (highest impact first)
6. Each finding: `[tag] **summary**` / `file:lines` on separate lines / merged explanation / `→ suggestion`
7. Include file:line references on every finding

### Claude-Only Mode

If Codex was unavailable or both Codex sources failed:
- Omit consensus tags, omit Dismissed section
- Add a note at the top: "**Mode: Claude-Only** — {reason}"
- Use Claude review findings directly, organized by severity

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Codex not installed | Claude-Only mode; refer to [references/SETUP.md](references/SETUP.md) |
| Codex skill review failed | Exclude that source, note reason |
| Codex built-in review failed | Exclude that source, note reason |
| Both Codex sources failed | Claude-Only mode |
| Working copy on wrong branch | Warn user, ask to proceed or switch first |
| MR not found | Abort with clear message |
| No Jira ticket | Proceed without (same as /mr-review) |

---

## Usage

```bash
/mr-audit 43 STB-1417      # MR number + Jira ticket
/mr-audit 43                # MR number, Jira auto-extracted from MR title
/mr-audit                   # Current branch's MR
```
