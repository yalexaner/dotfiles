# Effective Subagent Prompt Patterns

## Explore Agent (subagent_type: Explore)

Best for: finding all instances of something, mapping code structure, understanding patterns.

### Template

```
I need a very thorough analysis of [SYSTEM/FEATURE] in this codebase.
The goal is [GOAL FROM TICKET].

Please do the following:

1. Find ALL [DEFINITIONS/MACROS/TYPES] related to [PATTERN] — list every single one
   with its value/location.

2. Find ALL places where these are used. List each function and how it uses them.

3. For each [ITEM], determine:
   - [SPECIFIC QUESTION 1]
   - [SPECIFIC QUESTION 2]
   - [SPECIFIC QUESTION 3]

4. Check for [EDGE CASES / SPECIAL PATTERNS].

5. Look for any other files beyond [OBVIOUS FILES] that are affected.

6. Check [MECHANISM / PROTOCOL / SERIALIZATION] — how does it actually work?

Be very thorough — this is a [SCOPE] task and I need a complete inventory.
```

### Key qualities:
- Uses numbered action items
- Asks for complete inventory, not samples
- Specifies what "thorough" means concretely
- Mentions files to look beyond the obvious ones

---

## Independent Analyst (subagent_type: general-purpose)

Best for: tracing logic, finding bugs, verifying correctness, risk assessment.

### Template

```
You are acting as an independent code analyst for [TASK]. Your analysis will be
compared against another analyst's findings to catch anything missed.

## Task Context
[FULL TICKET DESCRIPTION — problem, requirements, constraints]

## Your Mission

Do a COMPREHENSIVE analysis:

1. **Find every [PATTERN]** in the codebase. List each one with its value.

2. **For each [ITEM], trace through the code** to see exactly what happens.
   Verify whether [SPECIFIC CLAIM / EXPECTED BEHAVIOR] is correct.

3. **Identify [RISK CATEGORY]** — [what to look for and why].

4. **Analyze [MECHANISM]** — [specific technical question].

5. **Search for [BROADER PATTERNS]** that might be related but not obviously named.

6. **Check [CONSUMERS / CALLERS / DEPENDENTS]** to understand full impact.

Provide a structured report with:
- Complete inventory of all [ITEMS]
- Risk assessment for each (low/medium/high)
- Recommended approach for each
- Any edge cases or gotchas discovered
```

### Key qualities:
- Frames as "independent analyst" for cross-validation mindset
- Asks for structured output with risk levels
- Requests broader search beyond the obvious
- Asks about consumers/impact, not just definitions

---

## Tips from Practice

1. **Include the full problem context** — agents don't see the conversation.
   Copy the ticket description, constraints, and any prior findings into the prompt.

2. **Name specific files** when you know them — don't make the agent waste
   time finding the obvious starting points.

3. **Ask different questions** from each agent — overlapping coverage is fine
   for cross-validation, but each agent should also have unique angles.

4. **Request evidence format** — "list exact file paths and line numbers"
   makes the output much more useful for verification.

5. **Set expectations on output** — "provide a structured report with..."
   prevents agents from returning a wall of unstructured text.
