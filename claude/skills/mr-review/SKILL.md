---
name: mr-review
description: Comprehensive GitLab merge request review with architecture analysis, alternative approaches comparison, and code quality checks. Use when reviewing MRs, analyzing code changes, or when user mentions "review", "MR", "merge request", or "code review".
argument-hint: [mr-number or branch-name] [jira-ticket-url]
allowed-tools: Bash(glab mr view *), Bash(glab mr diff *), Bash(glab mr list *), Bash(glab mr issues *), Bash(git branch *), Bash(git log *), Bash(git diff *), Bash(git status *), Bash(git show *), Skill(jira *), Read, Grep, Glob, WebFetch
---

# GitLab Merge Request Review

Perform a comprehensive code review of a GitLab merge request with deep analysis of problem understanding, solution approaches, implementation quality, and architectural fit.

**Important glab CLI rules:**
- There is NO `--state` flag in `glab mr list`. Use `--closed`, `--merged`, `--all`, or default (open)
- The `-s` flag is `--source-branch`, NOT state
- `glab mr view` / `glab mr diff` without arguments use the current branch's MR
- For full command reference, see [references/glab-commands.md](references/glab-commands.md)

## MR Context (Auto-Fetched)

- Current Branch: !`git branch --show-current`
- MR Details: !`glab mr view 2>/dev/null || echo "No MR found for current branch"`

## Arguments

- **MR Identifier**: $ARGUMENTS[0] (MR number, branch name, or empty for current branch)
- **Jira Ticket**: $ARGUMENTS[1] (optional Jira ticket key like STB-1417 or URL like https://ksu.nag.ru/browse/STB-1417)

## Review Process

Execute this review in **7 phases**, producing a structured report at the end.

---

### Phase 0: Collect Missing Context

Before starting the review, check if required context is available:

1. **Jira Ticket**: Resolve the ticket key using this priority:
   1. Use $ARGUMENTS[1] if provided
   2. Extract from MR title (pattern: `[A-Z]+-\d+`, e.g. "STB-1417 [OTAUpdater]..." or "STB-1343: Доработка...")
   3. Extract from MR description or branch name
   4. **Ask the user** for the Jira ticket key or URL
   - It is acceptable if the user has no ticket - proceed without it

---

### Phase 1: Gather Complete Information

**1.1 Fetch MR Data**
```bash
# Get full MR details
glab mr view $0 --output json

# Get complete diff
glab mr diff $0 --color=never --raw

# Get comments and discussions
glab mr view $0 --comments --system-logs
```

**1.2 Fetch Jira Context**
Once you have a Jira ticket key or URL (from arguments, MR description, or user input), invoke the `/jira` skill to fetch full ticket details:
```
/jira <ticket-key-or-url>
```
Extract from the ticket: problem statement, acceptance criteria, requirements, and any relevant comments.

If no Jira ticket is available, rely on the MR description for problem understanding.

**1.3 Analyze Local Changes**
- Read all changed files completely
- Identify the related/existing code that these changes extend or fix
- Understand the current architecture and patterns in affected areas

---

### Phase 2: Problem Understanding

Before looking at the solution, deeply understand the problem:

1. **What is the actual problem/feature?**
   - Extract from Jira ticket or MR description
   - Identify the root cause (for bugs) or user need (for features)

2. **What are the constraints?**
   - Performance requirements
   - Backward compatibility needs
   - Integration points
   - Time/scope constraints

3. **What is the expected outcome?**
   - User-facing behavior changes
   - System behavior changes
   - Success criteria

---

### Phase 3: Alternative Approaches Brainstorm

**Think independently** before reviewing the implementation:

Generate 2-4 alternative approaches to solve this problem. For each approach:

| Approach | Description | Pros | Cons | Complexity | Risk |
|----------|-------------|------|------|------------|------|
| A | ... | ... | ... | Low/Med/High | Low/Med/High |
| B | ... | ... | ... | Low/Med/High | Low/Med/High |
| C | ... | ... | ... | Low/Med/High | Low/Med/High |

**Select the best approach** based on:
- Alignment with existing architecture
- Maintainability and readability
- Performance implications
- Future extensibility
- Risk of introducing bugs

---

### Phase 4: Implementation Comparison

Compare the MR implementation against your best approach:

| Aspect | MR Implementation | Your Best Approach | Assessment |
|--------|-------------------|-------------------|------------|
| Overall Strategy | ... | ... | Same/Different/Partial |
| Key Design Decisions | ... | ... | ... |
| Edge Cases Handled | ... | ... | ... |
| Missing Elements | ... | ... | ... |

**Analysis Questions:**
- Does the MR implementation have something your approach missed?
- Does your approach have something the MR missed?
- Are there hybrid improvements possible?
- Is the MR approach objectively better/worse/equivalent?

---

### Phase 5: Code Quality Analysis

Review the implementation for issues in these categories:

#### 5.1 Logic & Correctness
- [ ] Logic errors or bugs
- [ ] Missing edge cases
- [ ] Race conditions (for concurrent code)
- [ ] Null/undefined handling
- [ ] Off-by-one errors
- [ ] Incorrect assumptions

#### 5.2 Compile/Runtime Issues
- [ ] Type errors
- [ ] Missing imports
- [ ] Undefined variables/methods
- [ ] Resource leaks
- [ ] Memory issues

#### 5.3 DRY & Clean Code
- [ ] Code duplication within the MR
- [ ] Code that duplicates existing utilities/helpers
- [ ] Functions that should use existing abstractions
- [ ] Magic numbers/strings that should be constants

#### 5.4 Naming & Style
- [ ] Variable/function names clarity
- [ ] Consistency with project conventions
- [ ] File/class placement following project structure

#### 5.5 Architecture & Patterns
- [ ] Clean architecture violations (dependency direction)
- [ ] SOLID principle violations
- [ ] Pattern misuse or missed opportunities
- [ ] Layer boundary violations
- [ ] Coupling issues

#### 5.6 Security (See [references/checklist.md](references/checklist.md))
- [ ] Input validation
- [ ] SQL injection risks
- [ ] XSS vulnerabilities
- [ ] Authentication/authorization issues
- [ ] Sensitive data exposure

#### 5.7 Performance
- [ ] Inefficient algorithms (O(n^2) when O(n) possible)
- [ ] N+1 query problems
- [ ] Missing indexes usage
- [ ] Unnecessary computations
- [ ] Memory bloat

#### 5.8 Error Handling
- [ ] Appropriate exception handling
- [ ] Meaningful error messages
- [ ] Graceful degradation
- [ ] Logging adequacy

#### 5.9 Testing
- [ ] Test coverage for new code
- [ ] Edge cases tested
- [ ] Test quality (not just quantity)
- [ ] Integration test needs

---

### Phase 6: Architectural Fit Analysis

Evaluate how well the changes integrate with the existing codebase:

1. **Pattern Consistency**
   - Does it follow existing patterns in the codebase?
   - If introducing new patterns, is it justified?

2. **Dependency Direction**
   - Are dependencies pointing in the correct direction?
   - No domain depending on infrastructure?

3. **Module Boundaries**
   - Are changes in the correct module/package?
   - Any misplaced code?

4. **Interface Design**
   - Are new interfaces consistent with existing ones?
   - Appropriate abstraction level?

5. **Future Maintainability**
   - Will this be easy to modify later?
   - Any technical debt introduced?

---

### Phase 7: Generate Report

Produce a structured report with these sections:

```markdown
# MR Review Report: [MR Title]

## Summary
- **MR**: !xxx (link)
- **Author**: xxx
- **Jira**: xxx (if provided)
- **Review Date**: [date]
- **Overall Assessment**: Approve / Request Changes / Needs Discussion

## Problem Understanding
[Brief description of the problem/feature]

## Approach Analysis

### MR Approach
[Description of how the MR solves the problem]

### Alternative Approaches Considered
[Table of alternatives with pros/cons]

### Comparison Verdict
[Which approach is best and why]

## Code Quality Findings

### Critical Issues (Must Fix)
1. [Issue with file:line reference]

### Major Issues (Should Fix)
1. [Issue with file:line reference]

### Minor Issues (Consider Fixing)
1. [Issue with file:line reference]

### Suggestions (Nice to Have)
1. [Suggestion]

## Architecture Assessment
- **Fit Score**: Good / Acceptable / Poor
- **Notes**: [Any architectural concerns]

## Testing Assessment
- **Coverage**: Adequate / Needs More / Missing
- **Quality**: Good / Acceptable / Poor

## Recommendation
[Final recommendation with specific action items]

## Questions for Author
1. [Any clarifying questions]
```

---

## Additional Resources

- For glab CLI command reference, see [references/glab-commands.md](references/glab-commands.md)
- For detailed security and performance checklists, see [references/checklist.md](references/checklist.md)
- Cross-reference findings with project's architecture documentation if available

## Usage Examples

```bash
# Review MR by number
/mr-review 123

# Review MR with Jira context
/mr-review 123 https://jira.company.com/browse/PROJ-456

# Review current branch's MR
/mr-review

# Review by branch name
/mr-review feature/new-auth
```
