# Split Subagent Prompt Template

Use this as the base prompt when launching a subagent to handle complex splits
(single file with changes belonging to multiple target revs).

---

## Prompt

You are splitting a jj revision that has mixed changes in a single file.

### Context

- **Rev to split**: {REV_ID}
- **Parent rev**: {PARENT_ID}
- **File to split**: {FILE_PATH}
- **Full diff of the file**:
```
{DIFF_OUTPUT}
```

### Target splits

{For each target, describe which changes from the diff belong to it:}

1. **Target rev: {description}**
   - Changes: {describe which hunks/lines belong here}

2. **Target rev: {description}**
   - Changes: {describe which hunks/lines belong here}

### Workflow

1. Note the messy rev ID: `{REV_ID}` and parent: `{PARENT_ID}`

2. Go to parent:
   ```bash
   jj new {PARENT_ID}
   ```

3. For EACH target split:
   - Apply only the changes for this target using Edit/Write tools
   - Read the file first to understand current state
   - Make only the edits that belong to this target
   - Commit with `jj commit -m "{description}"`
   - Run `jj new` for the next split (except after last one)

4. Safety check — rebase messy rev onto last new commit:
   ```bash
   jj rebase -r {REV_ID} -d @
   jj diff -r {REV_ID}
   ```
   - If empty → all changes moved correctly
   - If has changes → something was missed

5. Cleanup (only if messy rev is empty):
   ```bash
   jj abandon {REV_ID}
   ```

### Rules

- Do NOT create bookmarks
- Do NOT create empty commits
- Do NOT stop after first split — create ALL planned commits
- Use `jj commit -m "message"` to commit (NOT git commit)
- When using `jj squash --from X --into Y` with both having descriptions,
  ALWAYS use `-m "message"` flag

### Report back

When done, report:
1. List of new rev IDs created (from `jj log`)
2. What each rev contains (`jj diff -r {ID} --stat` for each)
3. Whether the safety check passed (was the messy rev empty after rebase?)
4. If safety check failed: what changes remain (`jj diff -r {REV_ID}` output)
