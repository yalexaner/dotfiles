---
name: mr-audit
description: >-
  Triple-model MR review that runs Claude Code, Codex skill-based, and Codex built-in reviews
  in parallel, cross-validates findings against the codebase, and produces a unified
  confidence-tiered report. Use when you want a thorough multi-perspective merge request review.
argument-hint: [mr-number] [jira-ticket]
disable-model-invocation: true
allowed-tools: Bash(codex exec *), Bash(which *), Bash(glab mr view *), Bash(glab mr diff *), Bash(glab mr list *), Bash(git branch *), Bash(git log *), Bash(git diff *), Bash(jj log *), Bash(jj show *), Bash(jq *), Read, Grep, Glob, Skill(mr-review *), Skill(jira *)
metadata:
  compatibility: Requires codex CLI (npm i -g @openai/codex), glab CLI, and Codex skills (jira, mr-review) in ~/.codex/skills/. See references/SETUP.md. Degrades gracefully to Claude-only if Codex is unavailable.
---

# Triple-Model MR Review

Run three independent reviews in parallel — Claude Code (`/mr-review`), Codex skill-based (`$mr-review`), and Codex built-in code review — then cross-validate findings against the codebase and compile a single confidence-tiered report.

## Pre-flight

- Codex installed: !`which codex 2>/dev/null || echo "NOT_FOUND"`
- Current branch: !`git branch --show-current`
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
3. **If neither works**: Run `glab mr list` (lists open MRs by default) and present the list to the user to pick from
4. If no open MRs exist — abort, nothing to review

**Important**: `glab mr list` has no `--state` flag — see [references/glab-flags.md](references/glab-flags.md) for correct flags.

### 0.2 Fetch MR Details

Once the MR is determined, run `glab mr view {MR_NUMBER}` (if not already in pre-flight) to get the full title, description, author, source branch, and target branch.

### 0.3 Verify Working Copy

All three reviews read files from the local working tree. If the checkout doesn't match the MR source branch, reviews will analyze wrong code.

1. Compare the MR **source branch** (from 0.2) with the current branch (from pre-flight)
2. If using jj (pre-flight JJ status is not `NO_JJ`): check that the current jj revision is on or descends from the MR source branch. Use `jj log` to verify.
3. **If mismatched**: Warn the user that their working copy is on a different branch and ask whether to proceed anyway or switch first. Do NOT switch automatically — the user may have uncommitted work.

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
- Codex built-in raw: `/tmp/codex-builtin-raw-{PROJECT}-{MR_NUMBER}.jsonl`
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
jq -rs '[.[] | select(.type=="item.completed" and .item.type=="agent_message") | .item.text] | last // ""' "/tmp/codex-builtin-raw-{PROJECT}-{MR_NUMBER}.jsonl" > "/tmp/codex-builtin-review-{PROJECT}-{MR_NUMBER}.md"
```

**Note**: The pipe is split into two steps because Claude Code's Bash tool breaks pipe operators — see [references/codex-review-bug.md](references/codex-review-bug.md) for why `--json` + `jq` is needed instead of `-o`.

### 1C: Claude Review (foreground)

Invoke the existing skill with both MR and ticket (already resolved in Phase 0):

```
/mr-review {MR_NUMBER} {JIRA_TICKET}
```

If no ticket was found, omit it: `/mr-review {MR_NUMBER}`

---

## Phase 2: Collect Results

After `/mr-review` finishes:

1. Check if both Codex background tasks have completed
2. If either is still running, wait for completion
3. Run the Phase 1B Step 2 `jq` extraction on the raw JSONL file to produce the final review file
4. Read both output files:
   - `/tmp/codex-mr-review-{PROJECT}-{MR_NUMBER}.md`
   - `/tmp/codex-builtin-review-{PROJECT}-{MR_NUMBER}.md`
5. **Degrade gracefully** per source:
   - If a file is missing, empty, or contains error output → exclude that source
   - Note which sources are available for the final report
   - If both Codex sources failed → Claude-Only mode

---

## Phase 3: Cross-Validate & Investigate

This is the core value. Three independent models give three perspectives — overlapping findings have highest confidence.

### 3.1 Classify Findings

For each finding, assign two things:

**Consensus tag** — how many sources flagged it:

| Tag | Meaning |
|-----|---------|
| `[all]` | All available sources agree |
| `[2/3]` | Two of three sources agree |
| `[confirmed]` | Single source, verified by code investigation |
| `[uncertain]` | Single source, could not confirm or dismiss |

**Severity** — how bad it is:

| Severity | Use for |
|----------|---------|
| **Must Fix** | Bugs, missing safety nets, production breakage |
| **Should Fix** | Code quality, duplication, maintainability |
| **Nit** | Style, naming, minor inconsistencies |

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
3. Group findings by severity: Must Fix → Should Fix → Nit
4. Within each group, order by priority (highest impact first)
5. Each finding: `[tag] **summary**` / `file:lines` on separate lines / merged explanation / `→ suggestion`
6. Include file:line references on every finding

### Claude-Only Mode

If Codex was unavailable or both Codex sources failed:
- Omit consensus tags, omit Dismissed section
- Add a note at the top: "**Mode: Claude-Only** — {reason}"
- Use Claude review findings directly, organized by severity

---

## Phase 5: Preserve & Fork

After the report is output, preserve this session as a review reference and offer to fork for follow-up work.

1. Run `/rename` with a descriptive name:
   ```
   /rename REVIEW {TICKET} MR!{MR_NUMBER} {short MR title}
   ```
   Example: `/rename REVIEW STB-1417 MR!3 Fix InstallDeviceOpenError`

2. Tell the user the session has been renamed, then suggest:
   ```
   Run /fork to start a new session with this review as context.
   ```

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
