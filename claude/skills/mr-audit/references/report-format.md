# Triple-Model Review Report Template

Replace placeholders with actual data. Adapt sections based on available sources.

---

```markdown
# Triple-Model Review: {MR_TITLE}

**MR**: !{MR_NUMBER} | **Author**: {AUTHOR} | **Branch**: {BRANCH}
**Jira**: {TICKET} | **Date**: {DATE}
**Sources**: {Claude + Codex Skill + Codex Built-in | Claude + Codex Skill | Claude-Only (reason)}

---

## At a Glance

| Metric | Value |
|--------|-------|
| Recommendation | Approve / Request Changes / Needs Discussion |
| Must Fix | {count} |
| Should Fix | {count} |
| Nit | {count} |
| Dismissed (false positives) | {count} |

---

## Findings

All findings from all sources, merged into single assessments. Grouped by severity, ordered by priority within each group.

### Must Fix

[{tag}] **{short summary of the problem}**
`{file}:{lines}`
`{file}:{lines}`
{Free-form explanation. As long as needed to convey the issue clearly.
Merge insights from all sources that flagged this into one coherent description.
Do not attribute assessments to individual models — write one unified explanation.}
→ {suggestion}

### Should Fix

[{tag}] **{short summary}**
`{file}:{lines}`
{explanation}
→ {suggestion}

### Nit

[{tag}] **{short summary}**
`{file}:{lines}`
{explanation}
→ {suggestion}

---

## Dismissed Findings

False positives filtered out during cross-validation. Listed for transparency.

| File:Line | Claim | Dismissal Reason |
|-----------|-------|------------------|
| `file:123` | {what was claimed} | {why it's not an issue} |

---

## Architecture & Approach

### Problem Summary
{What this MR solves, from Jira and MR description}

### Approach Assessment
{Merged view from all sources — do they agree the approach is sound?}

### Alternatives Mentioned
| Approach | Pros | Cons | Source |
|----------|------|------|--------|
| MR's approach | ... | ... | All |
| Alternative A | ... | ... | {who suggested it} |

---

## Testing Assessment

| Aspect | Assessment |
|--------|------------|
| Coverage | {merged assessment from all sources} |
| Quality | {merged assessment} |
| Missing tests | {merged list} |

---

## Questions for Author
1. {question}

---

*Sources: {list active sources}. {N} total findings, {N} dismissed.*
```

---

## Filling Instructions

### Finding format

Each finding follows this structure:
1. `[tag] **summary**` — consensus tag + one-line description of the problem
2. `` `file:lines` `` — each affected file on its own line
3. Free-form explanation — as long as needed, merged from all sources into one unified text
4. `→ suggestion` — what to do about it

### Consensus tags

| Tag | Meaning |
|-----|---------|
| `[all]` | All available sources agreed on this finding |
| `[2/3]` | Two of three sources agreed |
| `[confirmed]` | Only one source flagged it, verified by code investigation |
| `[uncertain]` | Only one source flagged it, could not confirm or dismiss |

### Severity groups

| Group | Use for |
|-------|---------|
| **Must Fix** | Bugs, missing safety nets, things that will break in production |
| **Should Fix** | Code quality, duplication, maintainability risks |
| **Nit** | Style, naming, const correctness, minor inconsistencies |

### Merging explanations

Do NOT list per-model assessments (e.g. "Claude: X, Codex: Y"). Write one merged explanation that combines the best insights from all sources. If sources disagree on severity, use the higher one. The consensus tag already tells the reader how many sources agreed — no need to repeat it in the text.

### Uncertain findings

Place `[uncertain]` findings at the bottom of the severity group they belong to. These are worth the reviewer's attention but could not be definitively confirmed.

### Fewer sources

- If only 2 sources available: `[all]` = both agree, no `[2/3]` tier.
- If Claude-Only: omit consensus tags entirely, omit Dismissed section.

### Architecture & Testing

Merge all source assessments into unified text. Do not include per-source columns — the findings section already covers specific issues. These sections provide the big picture: is the approach sound, and is the testing adequate.
