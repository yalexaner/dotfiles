# Decompose File Format

This document defines the format of the `{TICKET}-decompose.md` file written to the project memory directory.

## Full File Template

```markdown
# {TICKET}: {Title}

## Source
- **Jira**: {URL}
- **Confluence**: {URL} (if linked)
- **Decomposed**: {date}

## Complexity
{classification} — {rationale}

## Approaches

### Approach A: {name} <- chosen
{description}
**Pros**: ...
**Cons**: ...

### Approach B: {name} (recommended)
{description}
**Pros**: ...
**Cons**: ...
**Why recommended**: ...

### Approach C: {name}
{description}
**Pros**: ...
**Cons**: ...

## Steps

### 0. {Infrastructure step name}
- [ ] analyzed
<!-- brainstorm-context
summary: {what this step sets up}
requirements: {from ticket}
known-code: {file paths from agent findings}
pattern: {existing implementation to follow}
notes: {additional context}
-->

### 1. {Step name}
- [ ] analyzed
<!-- brainstorm-context
summary: {what this step implements}
requirements: {specific requirements}
known-code: {relevant file paths}
pattern: {pattern to follow}
cli-commands: {if relevant}
error-handling: {expected error cases}
notes: {additional context}
-->
<!-- depends-on: 0 -->

### 2. {Step name}
- [ ] analyzed
<!-- brainstorm-context
...
-->
<!-- depends-on: 0, 1 -->
```

## Section Details

### Source
Links to the original Jira ticket and any linked Confluence pages. Includes the date the decomposition was created.

### Complexity
One of: `simple`, `moderate`, `complex` — with a brief rationale.

### Approaches
All approaches considered during decomposition. The chosen approach is marked with `<- chosen`. The recommended approach (if different from chosen) is marked with `(recommended)`. Each approach has a description, pros, and cons.

### Steps
Ordered implementation steps. Each step has:
- **Heading**: `### N. {Step name}` — numbered, descriptive name
- **Checkbox**: `- [ ] analyzed` — unchecked until brainstorm completes this step
- **brainstorm-context block**: HTML comment containing structured context for brainstorm's agents
- **depends-on block** (optional): HTML comment listing step numbers this step depends on

### brainstorm-context Fields
All fields are optional — include what's relevant for the step:
- `summary`: 1-2 sentences describing what this step implements
- `requirements`: specific requirements from the ticket for this step
- `known-code`: file paths and functions identified by agents as relevant
- `pattern`: which existing implementation to use as a model
- `cli-commands`: CLI commands involved (for SNMP-to-CLI patterns, etc.)
- `error-handling`: expected error cases and codes
- `notes`: anything else the brainstorm agents should know

---

## Brainstorm Result Format

After `/brainstorm` analyzes a step, it modifies the decompose file:

1. Changes `- [ ] analyzed` to `- [x] analyzed`
2. Appends a `brainstorm-result` block after the `brainstorm-context` block

```markdown
- [x] analyzed
<!-- brainstorm-context
...
-->
<!-- brainstorm-result
- key decisions made
- patterns established
- files created/modified
- functions/structures introduced
- anything next steps should know
-->
```

The result block should be **compact** (5-10 lines). It captures:
- What implementation patterns were decided on
- What files and functions were created or identified for modification
- Any architectural decisions that affect subsequent steps
- Anything the next steps' agents should know for consistency

The full brainstorm report stays in the conversation — only the compact summary goes into the file.
