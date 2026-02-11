# glab mr list — correct flags

The `glab mr list` command does NOT have a `--state` flag. Do not guess flags.

## Listing MRs by state

| Command | Result |
|---------|--------|
| `glab mr list` | open MRs (default, no flags needed) |
| `glab mr list --merged` | merged MRs |
| `glab mr list --closed` | closed MRs |
| `glab mr list --all` | all MRs regardless of state |

## Common mistake

The `-s` flag is `--source-branch`, NOT state. Using `-s open` would filter by a branch named "open", not by MR state.

## glab mr view — JSON output

`glab mr view` supports `-F json` (or `--output json`) for structured JSON output. Use this instead of parsing text output. Key fields: `source_branch`, `target_branch`, `title`, `description`, `author.username`.

## glab api — no --jq flag

`glab api` does NOT have a `--jq` flag. To filter JSON from `glab api`, you would need to pipe to `jq` — but piping is forbidden by the global standalone-command rule. Avoid `glab api` entirely; use `glab mr view -F json` instead.
