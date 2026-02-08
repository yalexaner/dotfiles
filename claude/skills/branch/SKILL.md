---
name: branch
description: Creates and manages jj bookmarks with conventional branch naming. Analyzes changes to generate descriptive names, moves existing bookmarks forward, and optionally pushes to remote.
disable-model-invocation: true
argument-hint: [branch name or description of work]
allowed-tools: Bash(jj *), Bash(git diff:*), Bash(git log:*)
---

# Branch Management with Jujutsu

Create or update jj bookmarks using conventional naming (`<type>/<description>`).

## Context

- **Current rev:** !`jj log --no-graph -r @ -T 'change_id.short() ++ " " ++ description.first_line()'`
- **Bookmark on @:** !`jj log --no-graph -r @ -T 'local_bookmarks'`
- **Nearest ancestor bookmark:** !`jj log --no-graph -r 'ancestors(@-) & bookmarks()' -T 'local_bookmarks.join(", ") ++ " (" ++ change_id.short() ++ ")\n"' --limit 1`
- **Revs since trunk:** !`jj log -r 'ancestors(@) & ~ancestors(trunk())' -T 'change_id.short() ++ " " ++ description.first_line() ++ "\n"' --no-graph`
- **All bookmarks:** !`jj bookmark list`
- **Working changes:** !`jj diff --stat`
- **User input:** $ARGUMENTS

## Workflow

### 1. Pre-check

If the current rev has no description and has file changes, warn the user:
```
Current revision has changes but no description. Run /commit first.
```
Stop and wait for the user.

### 2. Detect Action

Check "Bookmark on @" from context above:

- **Has bookmark** → go to step 4 (move existing)
- **No bookmark** → go to step 3 (create new)

### 3. Create New Bookmark

Analyze the revs since trunk to understand the work. If needed, read diffs:
```bash
git diff trunk..HEAD --stat
jj log -r 'ancestors(@) & ~ancestors(trunk())' -T 'description ++ "\n---\n"' --no-graph
```

**Determine the name:**
1. If `$ARGUMENTS` contains a full branch name (e.g., `feat/add-auth`), validate and use it
2. If `$ARGUMENTS` describes the work, generate a name from it
3. Otherwise, derive from the change descriptions and file patterns

**Format:** `<type>/<description-in-kebab-case>`

See [conventions reference](references/conventions.md) for type prefixes and naming rules.

**Execute:**
```bash
jj bookmark create <name> -r @
```

Go to step 5.

### 4. Move Existing Bookmark

The bookmark already exists on `@`. Check if there are new revisions beyond the bookmark that need to be included.

If the bookmark is on an ancestor (not on `@` itself), move it forward:
```bash
jj bookmark set <name> -r @
```

If the bookmark is already on `@`, no action needed — skip to step 5.

Go to step 5.

### 5. Create Empty Rev

Create a new empty revision so future changes don't land on the bookmarked rev:
```bash
jj new
```

### 6. Push

Ask the user: "Push `<name>` to remote?"

If yes:
```bash
jj git push -b <name>
```

If no, skip.

## Output

```
Branch <created|moved|unchanged>: <type>/<description>
Revs: <count> revision(s) from trunk
Status: <pushed to remote | local only>
```

## Rules

- **never** push without asking the user first
- **never** use `git branch`, `git checkout`, or `git push` — jj commands only
- **never** create a bookmark if the current rev has uncommitted, undescribed changes
- always lowercase comments and descriptions per project conventions
