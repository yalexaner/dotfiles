---
name: decompose
description: Analyze a Jira ticket, classify complexity, and decompose into implementation steps with multiple approach options. Creates a persistent step file in the project memory directory that guides subsequent /brainstorm runs.
argument-hint: [jira-ticket-key-or-url]
disable-model-invocation: true
allowed-tools: Skill(jira *), Agent, TaskOutput, Read, Grep, Glob, Bash(pwd), Bash(jj log *), Bash(jj diff *), Bash(ls *), Bash(mkdir *), AskUserQuestion, Write, Edit
---

# Ticket Decompose

Analyze a Jira ticket, classify its complexity, explore the codebase for existing patterns, present multiple implementation approaches, and create a persistent step file that guides subsequent `/brainstorm` runs.

> **Critical rule**: Every Bash command must be a standalone call. NEVER combine commands with `||`, `&&`, `|`, or `;`. Handle errors and fallbacks in skill logic — run one command, check its output, then decide what to do next.

> **Language rule**: The decompose file and all output must be in English. Direct quotes from Jira/Confluence may remain in their original language when explicitly quoted.

## Arguments

- **Ticket**: $ARGUMENTS[0] (Jira ticket key like SWITCH-4713 or URL)

## Pre-flight

- Working directory: !`pwd`
- Current state: !`jj log -r @ --no-graph -T 'self.change_id().shortest(8) ++ " " ++ branches' 2>/dev/null || echo "NO_JJ"`

---

## Phase 0: Acquire and Classify

### 0.1 Resolve Ticket

1. If `$ARGUMENTS` contains a Jira ticket key or URL, invoke `/jira` immediately.
2. If no ticket provided, use `AskUserQuestion` to get the ticket key or a manual description.

### 0.2 Extract Requirements

From the Jira ticket (and any linked Confluence pages), extract:
- **Problem statement**: What needs to be done and why
- **Feature list**: Individual features, tables, components, or fixes required
- **Affected areas**: Modules, subsystems, file paths mentioned
- **Keywords**: Function names, struct names, OID branches, CLI commands, patterns
- **Constraints**: Architecture, compatibility, error handling requirements
- **Acceptance criteria**: What "done" looks like for each feature

### 0.3 Classify Complexity

Based on the extracted requirements, classify the ticket:

| Class | Criteria | Action |
|-------|----------|--------|
| **simple** | Single fix or small feature; 1-2 files; one clear path | Suggest `/brainstorm` directly |
| **moderate** | Single feature spanning a few files; mostly clear path | Offer choice: decompose or `/brainstorm` |
| **complex** | Multiple features/components; many files; multiple approaches | Proceed with full decomposition |

### 0.4 Present and Confirm

Present to the user:
- Extracted requirements summary
- Complexity classification with reasoning
- For **simple**: "This ticket is straightforward. I recommend running `/brainstorm {TICKET}` directly. Decompose anyway?"
- For **moderate**: "This ticket has some complexity. Decompose into steps or run `/brainstorm` directly?"
- For **complex**: "This ticket requires decomposition. Proceeding with analysis."

Use `AskUserQuestion` for simple/moderate to let the user decide. For complex, proceed automatically.

---

## Phase 1: Codebase Landscape Analysis

**Goal:** Understand the codebase structure and existing patterns relevant to the ticket. This is lighter than brainstorm's deep analysis — focused on landscape and patterns, not exhaustive tracing.

### 1.1 Design Agent Prompts

Based on extracted requirements, craft prompts for two agents. See [references/agent-prompts.md](references/agent-prompts.md) for templates and guidance.

Each prompt must:
- Include full ticket context (problem, requirements, feature list)
- Name specific files, patterns, and keywords to search for
- Define what to report back
- Request exact file paths and line numbers

Launch two agents:
- **Agent 1 — Landscape Explorer** (`subagent_type: Explore`): maps what exists — files, structures, registrations, similar implementations
- **Agent 2 — Pattern Analyst** (`subagent_type: general-purpose`): studies one deep reference implementation, drafts architecture-faithful approach, notes organic alternatives

### 1.2 Launch Agents

Launch both agents simultaneously in a **single message**, both with `run_in_background: true`.

### 1.3 Wait and Collect

Use `TaskOutput(task_id, block=true, timeout=600000)` for each agent.
- Wait up to 10 minutes per attempt, retry up to 3 times (30 min total)
- After 30 minutes: stop with `TaskStop`, degrade to single-agent findings
- Never stop early — both perspectives are valuable

Do not proceed to Phase 2 until both agents have reported back.

---

## Phase 2: Approach Synthesis

**Goal:** Formulate multiple implementation approaches from agent findings and present them to the user.

### 2.1 Cross-Reference Agent Findings

Compare the two agents' reports:
- What both found -> high confidence baseline
- What only one found -> note but verify if critical
- Contradictions -> resolve by reading code directly

Build a unified understanding of:
- Available implementation patterns in the codebase
- Relevant existing code and infrastructure
- Key architectural decisions the implementation will require

### 2.2 Formulate Approaches

1. **Anchor approach**: Take Agent 2's architecture-faithful approach as the primary option. This is the "follow established patterns" approach.

2. **Alternative approaches**: Surface alternatives from:
   - Agent 2's own noted alternatives
   - Agent 1's landscape findings (different patterns in different modules, reusable infrastructure)
   - Strategic variations (different grouping, file organization, implementation order)
   - Do NOT invent artificial alternatives. If only 2 genuine approaches exist, present 2.

3. For each approach, provide:
   - **Name**: Short descriptive label
   - **Description**: What the approach does and how
   - **Pros**: Advantages
   - **Cons**: Disadvantages
   - Mark one as **recommended** and explain why

### 2.3 Present and Select

Present all approaches to the user with full descriptions, pros, and cons.

Use `AskUserQuestion` with approach names as options. Output the detailed descriptions as text before asking the question so the user has full context.

### 2.4 Record Choice

Note the chosen approach for Phase 3.

---

## Phase 3: Step Decomposition

**Goal:** Break the chosen approach into concrete implementation steps.

### 3.1 Identify Implementation Units

Based on the chosen approach and ticket requirements:
- List all discrete implementation units (features, tables, components)
- Each unit should be independently implementable and testable
- Each unit should be a reasonable scope for one `/brainstorm` run

### 3.2 Infrastructure Step

If multiple implementation units share common setup (new file boilerplate, shared helpers, branch registration, common data structures), create a **Step 0** for this infrastructure. This step is the foundation all others build on.

### 3.3 Determine Dependencies

For each step, identify:
- What other steps it depends on (must be completed first)
- What steps depend on it
- Which steps are independent and could be done in any order

### 3.4 Generate Step Details

For each step, create a `brainstorm-context` block. See [references/file-format.md](references/file-format.md) for the complete format specification and available fields.

Key fields: `summary`, `requirements`, `known-code`, `pattern`, `cli-commands`, `error-handling`, `notes`. All fields are optional — include what's relevant.

### 3.5 Order Steps

Arrange steps in implementation order:
1. Infrastructure step first (if any)
2. Foundation features before dependent features
3. Independent features in any order — prefer simpler first

---

## Phase 4: Write Decompose File

### 4.1 Determine File Location

Write to the project's auto memory directory (the same directory referenced in the system context for persistent memory files). The file name is `{TICKET}-decompose.md` (e.g., `SWITCH-4713-decompose.md`).

If the memory directory doesn't exist, create it with `mkdir -p`.

### 4.2 Write File

Use the Write tool to create the file. See [references/file-format.md](references/file-format.md) for the complete file template and section details.

### 4.3 Present Summary

After writing the file, present to the user:
- File path
- Number of steps created
- Dependency overview
- Next action: "Run `/brainstorm {TICKET}` to start step-by-step analysis. Each run will analyze the next pending step and mark it complete."

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Jira skill fails | Ask user for manual description |
| Agent launch fails | Retry once; if still fails, degrade to single agent |
| TaskOutput timeout (30 min) | Stop task, proceed with available findings |
| Simple ticket | Suggest `/brainstorm` directly, don't force decomposition |
| Memory directory not found | Create it with `mkdir -p` |
| Decompose file already exists | Ask user: overwrite or keep existing? |
| User cancels approach selection | Exit gracefully, no file written |

---

## Rules

- **never** write the decompose file without the user selecting an approach first
- **never** invent artificial approaches — present only genuinely distinct options
- **never** skip the agent analysis phase — approaches must be grounded in codebase reality
- **never** include step details that weren't informed by agent findings
- **never** modify MEMORY.md — the decompose file is a workflow artifact, not a memory entry
- **always** present the complexity classification before proceeding
- **always** let the user choose the approach via AskUserQuestion
- **always** include an infrastructure step when multiple steps share common setup
- **always** mark dependencies between steps

---

## Additional Resources

- For agent prompt templates and crafting tips, see [references/agent-prompts.md](references/agent-prompts.md)
- For the decompose file format and brainstorm result format, see [references/file-format.md](references/file-format.md)
- For the brainstorm integration specification, see [references/brainstorm-integration.md](references/brainstorm-integration.md)

---

## Usage Examples

```bash
# Decompose a complex ticket
/decompose SWITCH-4713

# With full URL
/decompose https://ksu.nag.ru/browse/SWITCH-4713

# Will prompt for ticket if not provided
/decompose
```
