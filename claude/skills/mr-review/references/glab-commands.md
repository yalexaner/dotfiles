# glab CLI Reference

Quick reference for GitLab CLI commands used in MR reviews.

---

## glab mr view

View MR details (title, description, author, labels, etc.)

```bash
# View MR for current branch
glab mr view

# View specific MR by number
glab mr view 123

# View MR by branch name
glab mr view feature/my-branch

# Include comments and discussions
glab mr view --comments

# Include system logs (assignments, label changes, etc.)
glab mr view --system-logs

# Output as JSON
glab mr view --output json
```

---

## glab mr diff

View code changes in an MR.

```bash
# Diff for current branch's MR
glab mr diff

# Diff for specific MR
glab mr diff 123

# Raw diff (for piping to other tools)
glab mr diff --raw

# Without colors (for parsing)
glab mr diff --color=never
```

---

## glab mr list

List merge requests in the project.

```bash
# List open MRs (default)
glab mr list

# List all MRs
glab mr list --all

# List closed MRs
glab mr list --closed

# List merged MRs
glab mr list --merged

# Filter by source branch
glab mr list --source-branch=feature/my-branch

# Filter by author
glab mr list --author=username

# Filter by assignee
glab mr list --assignee=@me

# Filter by reviewer
glab mr list --reviewer=@me

# Filter by label
glab mr list --label=needs-review

# Output as JSON
glab mr list --output json

# Limit results
glab mr list --per-page 10
```

**Note:** There is NO `--state` flag. Use `--closed`, `--merged`, `--all`, or default (open).

---

## glab mr issues

Get related issues for an MR.

```bash
glab mr issues 123
```

---

## Common Patterns

### Find MR for current branch
```bash
# Simply run without arguments
glab mr view
glab mr diff
```

### Get full MR context for review
```bash
# 1. Get MR metadata
glab mr view --output json

# 2. Get comments
glab mr view --comments

# 3. Get diff
glab mr diff --color=never
```
