# Agent Prompt Templates for Decompose

These templates guide the two agents launched in Phase 1. Adapt them to the specific ticket — replace bracketed placeholders with real values from Phase 0.

## Agent 1 — Landscape Explorer

`subagent_type: Explore`, `run_in_background: true`

Best for: mapping what exists, finding all related code, understanding module organization.

### Template

```
Map the codebase landscape for implementing [ticket summary].

1. Find ALL files related to [keywords/affected areas] — list every file path
2. Find data structures, types, and configuration structs used by [subsystem]
3. Find registration/initialization points for [feature type]
4. Find CLI commands and their handlers related to [feature area]
5. List all similar existing implementations (other [feature type] instances)
6. Map the module organization — directories, file naming, header structure

Report a complete inventory with file paths. Do not sample — list everything.
```

### Key qualities:
- Numbered action items for structured exploration
- Asks for complete inventory, not samples
- Covers both the specific area and similar existing implementations
- Maps organizational patterns (naming, directories)

---

## Agent 2 — Pattern Analyst

`subagent_type: general-purpose`, `run_in_background: true`

Best for: deep study of implementation patterns, drafting architecture-faithful approaches, spotting alternatives.

### Template

```
Study how existing features similar to [ticket requirement] are implemented.
The goal is to understand established patterns and draft an implementation approach.

Context: [full ticket description and requirements]

1. Find the MOST RELEVANT existing implementation — the one closest in nature to
   what the ticket requires. Study it deeply.

2. Document the complete implementation pattern:
   - File organization (which files, how named, what goes where)
   - Function naming and structure
   - Registration/initialization flow
   - Data flow and state management
   - Error handling patterns
   - How read and write operations work

3. Draft an implementation approach that faithfully follows this established pattern.
   Be specific: name the files to create/modify, functions to add, registration points.

4. Note any ALTERNATIVE approaches you see naturally emerging — different patterns
   used elsewhere in the codebase, simpler shortcuts, different organizational
   strategies. Don't force alternatives; note them only if they genuinely exist.

Before recommending anything, study the architecture. Your approach must be consistent
with established patterns. Prefer following existing patterns over simpler shortcuts.

Report with exact file paths, line numbers, and code snippets where helpful.
```

### Key qualities:
- Focuses on one deep reference implementation, not broad scanning
- Requests complete pattern documentation (not just "what" but "how")
- Explicitly asks for architecture-faithful approach
- Alternative approaches are organic, not forced
- Demands evidence (file paths, line numbers, snippets)

---

## Prompt Crafting Tips

1. **Include full ticket context** — agents don't see the conversation. Copy the problem
   statement, feature list, keywords, and constraints into the prompt.

2. **Name specific starting points** — if the ticket mentions file paths, function names,
   or OID branches, include them. Don't make the agent rediscover the obvious.

3. **Differentiate the agents** — Agent 1 goes wide (find everything), Agent 2 goes deep
   (understand one pattern thoroughly). Overlap is fine for cross-validation, but each
   agent should have a unique angle.

4. **Request structured output** — "provide a structured report with..." prevents agents
   from returning unstructured text.

5. **Set scope boundaries** — tell each agent what's in scope and what's not, so they
   don't waste turns on tangential code.
