---
name: mr-create
description: Create a GitLab MR with Russian description, trigger CI pipeline, and link to Jira
disable-model-invocation: true
argument-hint: [reference-mr-number]
allowed-tools: Bash(git *), Bash(glab *), Bash(jj *), Bash(python3 *), Read, Grep, Glob
---

# Create Merge Request

Analyze branch changes, draft an MR description in Russian, get user approval, post via `glab`, trigger pipeline, and link cross-repo MRs on Jira.

## Context

```!
git remote get-url origin 2>/dev/null
jj log -r "ancestors(@) & ~ancestors(trunk())" --no-graph -T 'change_id ++ " " ++ description.first_line() ++ "\n"' 2>/dev/null | head -15
```

## 1. Analyze changes

1. `git diff develop...HEAD --stat` and `git log develop..HEAD --oneline` for scope.
2. Read the actual diffs to understand what changed.

## 2. (Optional) Load reference MR

If `$ARGUMENTS` is provided (an MR number), run `glab mr view $ARGUMENTS` to load its structure and wording as a reference for tone and format consistency.

## 3. Gather ticket info

Ask the user for a **Jira ticket** (ID or URL). Fetch the ticket using the `/jira` skill to get the title, description, and any relevant context.

## 4. Investigate the codebase

Before drafting, check if the changes have a broader impact:
- If a function was modified, use `Grep` to find all callers and determine which CLI commands / features are affected.
- If a behavior changed, understand what other paths share that behavior.
- Mention all affected commands/features in the description, not just the obvious one.

## 5. Draft the MR description

### Title format
```
<TICKET-ID>: <adapted title>
```

Keep the Jira ticket intent but adapt for developer audience. Remove tags like `[Easy-Config]`. Don't copy verbatim — synthesize from ticket title, description, and diff context to tell the reviewer what to expect.

### Body structure

Two required sections, one optional:

#### `## Описание`
The *why* and *what* in 2-3 sentences. Not a diff summary, but the story: what problem exists, what decision was made, what this MR does about it.

#### `## Заметки для ревью`
Non-obvious decisions, things intentionally NOT done, risk areas, edge cases. The most valuable section — saves the reviewer from discovering what matters on their own.

#### `## Порядок ревью` (optional)
Suggested reading order — commit order or file reading order.

**Include when:**
- Multiple commits that build on each other
- A foundation change that many files depend on
- Changes span 3+ architectural layers

**Skip when:**
- Single commit, single or tightly coupled files
- All changes are parallel/independent
- Diff is small enough to scan linearly (~100 lines, 3-4 files)

See [references/mr-formats.md](references/mr-formats.md) for examples.

### Wording rules
- Write in Russian.
- Straightforward and technical. No filler, no overly formal phrasing.
- No file-by-file changelog — the reviewer reads the diff.
- No "Связанная задача" section — ticket ID is already in the title.
- Function names and CLI commands in backticks.

## 6. Show draft for review

**CRITICAL:** Present the full MR text (title + description) to the user and wait for explicit approval before posting.

## 7. Post the MR

Only after user approval:

```
glab mr create \
  --source-branch "<current-branch>" \
  --target-branch "<target-branch>" \
  --assignee "a.lyachmenev" \
  --remove-source-branch \
  --title "<title>" \
  --description "<description>"
```

Default target branch is `develop` unless the user specifies otherwise.

Return the MR URL when done.

**Note:** `glab mr create` uses the repo context from the current working directory. If creating a switch-builder MR from the enos directory, it will fail — run from the switch-builder directory instead.

## 8. Pipeline triggering

### enos MR

Pipeline triggers automatically on push. If switch-builder is also involved, add at the end of the MR description body:

```
REF_BUILDER = <switch-builder-branch>
```

Other available variables (only include if different from defaults):
- `REF_SDK` (default: `master`)
- `REF_TESTER` (default: `develop`)
- `REF_FRONTEND` (default: `develop`)

### switch-builder MR (enos MR already exists)

After creating the switch-builder MR:
1. Update the enos MR description to add `REF_BUILDER = <switch-builder-branch>` at the end.
2. Re-run the enos MR pipeline — it picks up the updated description automatically.

### switch-builder MR (no enos MR)

Trigger via scheduler:
```
/opt/homebrew/bin/fish -c "build-pipeline -t <TICKET-ID> -b <builder-branch>"
```

## 9. Monitor pipeline (optional)

Poll the pipeline in the background until it finishes:

```
PIPE_ID=$(glab api "projects/SNR_Switch%2Fenos/pipelines?ref=<branch>&per_page=1" 2>&1 | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

python3 -c "
import subprocess, json, time, sys
while True:
    r = subprocess.run(['glab', 'api', 'projects/SNR_Switch%2Fenos/pipelines/$PIPE_ID'], capture_output=True, text=True)
    st = json.loads(r.stdout)['status']
    if st in ('success', 'failed', 'canceled'):
        print(f'pipeline {st}')
        sys.exit(0 if st == 'success' else 1)
    time.sleep(30)
"
```

Run with `run_in_background: true`.

**Note:** Do NOT use `glab ci status --live` — it exits prematurely on "blocked" or "manual" state during downstream builds.

## 10. Post Jira comment for switch-builder MRs

**Only for switch-builder MRs.** Do not post for enos-only MRs.

After step 9 reports pipeline success, verify both conditions:

1. **Pipeline succeeded** (step 9 exited with code 0).
2. **GitLab Bot comment exists** on the ticket (CI posts an automatic comment with build artifacts):
   ```
   python3 ${CLAUDE_SKILL_DIR}/scripts/jira-check-bot-comment.py <TICKET-ID>
   ```

Only after both are confirmed, post the switch-builder MR link:
```
python3 ${CLAUDE_SKILL_DIR}/scripts/jira-comment.py <TICKET-ID> "switch-builder <MR-URL>"
```

Format: `switch-builder https://develop.nagtech.ru/SNR_Switch/switch-builder/-/merge_requests/<number>`

Do not post duplicate comments — check existing comments for the same URL first.
