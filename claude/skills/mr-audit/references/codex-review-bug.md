# Codex CLI `exec review` Output Bug

**Status**: Confirmed bug in Codex CLI
**Tracked**: https://github.com/openai/codex/issues/6432

## Why `codex exec review` produces empty output

`ReviewTask::run()` in the source code unconditionally returns `None`. The exec output processor receives `None` as the final message and prints nothing to stdout. The actual review text is streamed via `AgentMessage` events to stderr only (via `eprintln!`). So `2>/dev/null` kills the only place the text appears.

The `-o` / `--output-last-message` flag also doesn't work — it writes an empty file with a warning "no last agent message".

## Working workarounds

### Option 1 — `--json` + `jq` (cleanest, recommended)

```bash
codex exec review --base atv_r/erth/master --full-auto --json \
  | jq -rs '[.[] | select(.type=="item.completed" and .item.type=="agent_message") | .item.text] | last // ""'
```

This captures the structured JSONL stream and extracts only the last agent message (the final review).

### Option 2 — Capture stderr, discard stdout

```bash
codex exec review --base atv_r/erth/master --full-auto 2>&1 1>/dev/null
```

This is messier because stderr also contains progress info, token counts, and other noise mixed in with the review text.

### Option 3 — Capture everything, grep the review out

```bash
codex exec review --base atv_r/erth/master --full-auto 2>&1 | tee review_raw.txt
```

Then manually extract what you need from the file.

## Recommendation

The `--json` + `jq` approach is the cleanest path until OpenAI fixes the bug. The `mr-audit` skill uses a two-step variant of Option 1 in Phase 1B: Step 1 captures the JSONL stream to a temp file (for background execution), then Step 2 extracts the review text with `jq` after the background task completes.
