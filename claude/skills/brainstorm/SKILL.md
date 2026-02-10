---
name: brainstorm
description: Deep-dive analysis of a Jira ticket with parallel codebase exploration. Fetches ticket requirements, launches Claude subagents and Codex in parallel to analyze related code, cross-references findings, and presents a structured report. Use when starting work on a new ticket, investigating a problem, or planning an implementation.
argument-hint: [jira-ticket-key-or-url] [optional focus area]
disable-model-invocation: true
allowed-tools: Skill(jira *), Task, Read, Grep, Glob, Bash(pwd), Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(codex exec *), Bash(which *), Bash(jq *), AskUserQuestion, EnterPlanMode
metadata:
  compatibility: Codex CLI optional (npm i -g @openai/codex). Degrades gracefully to Claude-only if Codex is unavailable.
---

# Ticket Brainstorm

Deep-dive analysis of a Jira ticket: fetch requirements, explore the codebase with parallel Claude agents and Codex, cross-reference findings, and present a structured report.

## Context

- **Working directory:** !`pwd`
- **User input:** $ARGUMENTS

## Phase 0: Acquire Ticket Context

**Goal:** Get the Jira ticket requirements as the foundation for all analysis.

### 0.0 Check Codex Availability

Run `which codex` to determine if Codex CLI is installed. If the command fails or returns empty, Codex is unavailable — proceed Claude-only for the rest of the session.

### 0.1 Resolve Ticket

1. If `$ARGUMENTS` contains a Jira ticket key (e.g., `SWITCH-2945`) or URL (e.g., `https://ksu.nag.ru/browse/SWITCH-2945`), invoke the `/jira` skill immediately:
   ```
   /jira <ticket-key-or-url>
   ```

2. If `$ARGUMENTS` does not contain a ticket key or URL, ask the user:
   ```
   Use AskUserQuestion with options:
   - "I have a Jira ticket" → then ask for the key/URL and invoke /jira
   - "No Jira ticket" → ask user to describe the problem/feature manually
   ```

3. If using manual description: ask the user to provide:
   - What is the problem or feature?
   - What areas of the codebase are involved?
   - Any constraints or requirements?

### 0.2 Extract Key Information

From the Jira ticket (or manual description), extract and summarize:
- **Problem statement**: What needs to be done and why
- **Affected areas**: File paths, modules, components mentioned
- **Keywords**: Function names, struct names, macros, patterns to search for
- **Constraints**: Architecture, compatibility, performance requirements
- **Acceptance criteria**: What "done" looks like

Present this summary to the user before proceeding.

---

## Phase 1: Parallel Codebase Analysis

**Goal:** Launch Claude subagents and Codex in parallel to analyze the codebase from independent perspectives. Claude agents are the primary source of truth. Codex provides a third perspective for cross-validation.

### 1.1 Design Agent Prompts

Based on the extracted ticket information, craft **detailed, specific prompts** for each agent. Each prompt must include:
- Full ticket context (problem statement, requirements)
- Specific search targets (file paths, function names, patterns)
- What to analyze and what to report back
- Instruction to be thorough and list exact file paths and line numbers

See [references/agent-prompts.md](references/agent-prompts.md) for prompt templates.

### 1.2 Launch All Agents

Launch all agents simultaneously in a **single message** (all in parallel):

**Agent 1 — Claude Explore** (`subagent_type: Explore`, `run_in_background: true`):
Focus on finding all related code:
- All relevant definitions, macros, constants, types
- All usages and call sites
- File structure and dependencies
- Patterns and conventions in the codebase

**Agent 2 — Claude Analyst** (`subagent_type: general-purpose`, `run_in_background: true`):
Perform independent deep analysis:
- Trace through the code logic end-to-end
- Verify correctness of existing implementation
- Identify bugs, edge cases, risks
- Assess architecture and patterns
- Evaluate the impact of proposed changes
- Look for things the first agent might miss

**Agent 3 — Codex** (Bash, `run_in_background: true`):
Launch only if step 0.0 confirmed Codex is installed. If unavailable, skip and work Claude-only.

Derive `{PROJECT}` from the last path segment of the working directory and `{TICKET}` from the ticket key.

**Security note:** Codex runs with `-s danger-full-access`, granting unrestricted filesystem and process access. This is necessary for deep codebase analysis but grants broader privileges than the Claude agents. All Codex findings are verified in Phase 2 before inclusion.

```bash
codex exec -s danger-full-access -C "$PWD" \
  -o "/tmp/codex-brainstorm-{PROJECT}-{TICKET}.md" \
  '{CODEX_PROMPT}'
```

The `{CODEX_PROMPT}` should be a comprehensive analysis request similar to Agent 2's prompt, adapted for Codex's style. Include the full ticket context. Ask for:
- Complete inventory of all related code with file paths
- Analysis of correctness, bugs, edge cases
- Recommendations for implementation
- Structured report format

**Optional Agent 4+** — Launch additional Claude agents when:
- The ticket spans multiple subsystems (one agent per subsystem)
- There are both "find code" and "understand protocol/format" aspects

### 1.3 Wait and Collect

Wait for all agents to complete:
1. Use `TaskOutput` to collect Claude agent results as they finish
2. When the Codex background Bash task completes, read its output file:
   `/tmp/codex-brainstorm-{PROJECT}-{TICKET}.md`
3. If the Codex output file is empty or contains errors, note it and proceed Claude-only

Do not proceed to Phase 2 until all agents have reported back.

---

## Phase 2: Synthesis and Cross-Reference

**Goal:** Combine findings from all sources into a unified, verified analysis. Claude agents are the primary authority. Codex findings are supplementary.

### 2.1 Claude Cross-Reference (Primary)

Compare findings from Claude Agent 1 and Agent 2:
- What did both Claude agents agree on? → **high confidence**, include directly
- What did only one Claude agent find? → verify by reading code, then include if confirmed
- Are there contradictions between Claude agents? → resolve by reading actual code

### 2.2 Codex Cross-Reference (Supplementary)

Review Codex findings with skepticism. For each Codex finding:

**Codex agrees with Claude agents** → Higher confidence. Note agreement.

**Codex found something new** (not in Claude agents' reports):
- This is the key value of Codex — a different perspective catching things Claude missed
- DO NOT include it in the report automatically
- Launch a **verification subagent** (`subagent_type: Explore` or `general-purpose`) to specifically check the Codex claim against the codebase
- Only include in the report if the verification agent confirms it
- Mark as `[codex-verified]` in the report

**Codex contradicts Claude agents**:
- Claude agents are the default authority
- If the contradiction is on a factual matter (e.g., "this function writes X bytes"), launch a verification subagent to read the actual code and determine who is correct
- If the contradiction is on a recommendation/opinion, note both perspectives and let the user decide

**Codex report is empty/broken/nonsensical**:
- Ignore it entirely, proceed with Claude-only findings
- Note in the report: "Codex analysis was unavailable/unreliable"

### 2.3 Verify Critical Claims

For any critical findings (bugs, mismatches, security issues), regardless of source, verify by reading the relevant code directly using Read/Grep. Do not present unverified claims as fact.

### 2.4 Fill Gaps

If cross-referencing reveals gaps, do targeted searches using Grep/Glob/Read directly.

---

## Phase 3: Present Report

**Goal:** Present a clear, actionable report to the user.

### Report Structure

```markdown
## [Ticket Key]: [Ticket Title]

### Problem Summary
[1-3 sentences: what needs to be done and why]

### Codebase Analysis

#### Key Findings
[Numbered list of the most important discoveries, with file:line references]

#### Architecture / Mechanism
[How the relevant code works — serialization, protocols, data flow, etc.]

#### Bugs / Issues Found
[Table or list of any bugs or inconsistencies discovered during analysis]

#### Affected Files
[List of all files that will need changes, grouped by type of change]

### Impact Assessment
- **Scope**: [How many files/functions affected]
- **Risk**: [What could go wrong]
- **Dependencies**: [What else needs to change together]

### Recommendations
[Numbered list of recommended actions, in priority order]

### Open Questions
[Anything that needs clarification before implementation]
```

Adapt this structure to fit the specific ticket. Not all sections are needed for every ticket. Add sections if the analysis warrants it (e.g., "Performance Impact", "Wire Protocol Changes", "Migration Path").

If Codex contributed verified new findings, include a note:
```markdown
### Codex Contributions
[List of findings that Codex uniquely identified and were verified against the code]
```

---

## Phase 4: Next Steps

After presenting the report, ask the user what they want to do next:

```
Use AskUserQuestion with options:
- "Enter plan mode" → Use EnterPlanMode to design an implementation plan
- "Discuss findings" → Continue the conversation to explore findings deeper
- "Done for now" → End the brainstorm session
```

---

## Guidelines

### Prompt Engineering for Subagents

Effective subagent prompts should:
- **Be self-contained**: Include all necessary context (don't assume the agent sees the conversation)
- **Be specific**: Name exact files, functions, patterns to search for
- **Define the deliverable**: Describe what the report should contain
- **Request evidence**: Ask for exact line numbers, file paths, code snippets
- **Set scope**: Tell the agent what's in scope and what's out of scope

See [references/agent-prompts.md](references/agent-prompts.md) for detailed templates.

### Trust Hierarchy

1. **Verified by code** — highest trust. Read the code, confirmed.
2. **Both Claude agents agree** — high trust.
3. **Single Claude agent, verified** — good trust.
4. **Codex agrees with Claude** — reinforced confidence.
5. **Codex unique finding, verified by Claude subagent** — good trust.
6. **Codex unique finding, unverified** — do NOT include. Launch verification first.
7. **Codex contradicts Claude** — investigate. Claude is default authority.

### When to Use More Agents

- Default: 3 agents (Claude Explore + Claude Analyst + Codex)
- If no Codex: 2 agents (Claude Explore + Claude Analyst)
- 4 agents: When the ticket spans clearly separable subsystems
- Verification agents: Launched on-demand in Phase 2 for Codex claims
- Never more than 5 total: diminishing returns

### Quality Checks

Before presenting the report:
- [ ] All critical findings verified against actual code
- [ ] File paths and line numbers are accurate
- [ ] No contradictions between sections
- [ ] Codex-unique findings verified by a Claude subagent before inclusion
- [ ] Recommendations are actionable and specific
- [ ] Open questions are genuine (not things you could have answered)

---

## Rules

- **never** present unverified Codex findings as fact — always verify through a Claude subagent first
- **never** launch more than 5 agents total (including verification agents) — diminishing returns
- **never** skip Phase 2 verification — even if agents agree, verify critical claims against code
- **never** proceed to Phase 3 before all agents have reported back
- **never** include file paths or line numbers without verifying they are accurate

---

## Usage Examples

```bash
# Analyze a Jira ticket (with Codex if available)
/brainstorm SWITCH-2945

# With full URL
/brainstorm https://ksu.nag.ru/browse/SWITCH-2945

# With a focus area
/brainstorm SWITCH-2945 focus on wire protocol compatibility

# Will prompt for ticket if not provided
/brainstorm
```
