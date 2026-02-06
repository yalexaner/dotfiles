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
