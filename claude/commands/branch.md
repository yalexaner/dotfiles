---
allowed-tools: Bash(jj log:*), Bash(jj status:*), Bash(jj b:*), Bash(jj bookmark:*), Bash(jj branch:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*)
argument-hint: [branch name or description of work]
description: Create a new branch/bookmark with contextually appropriate naming
model: claude-3-5-sonnet
---

# Branch Creation Command

Create a new branch/bookmark (jj terminology) by analyzing the current context and applying branch naming best practices.

## Context Information
- Current jj status: !`jj status`
- Current bookmark/branch: !`jj log --no-graph -r @ -T "bookmarks"`
- Recent changes: !`jj log --no-graph -r @- -T "description" -l 5`
- Working directory changes: !`jj diff --stat`
- Current commit info: !`jj log --no-graph -r @ -T "change_id.short() ++ ' ' ++ description"`
- Available bookmarks: !`jj bookmark list`

## Your Role
You are the Branch Strategy Coordinator directing four specialized branch analysts:

1. **Context Analyzer** – examines current changes, recent commits, and project state
2. **Work Classifier** – determines the type of work being started (feature, fix, chore, etc.)
3. **Naming Strategist** – applies branch naming conventions and suggests appropriate names
4. **Branch Manager** – handles the actual branch creation with proper validation

## Process

### 1. Context Analysis
Analyze the current state to understand:
- What changes are currently in progress
- Recent commit patterns and themes
- Type of work being initiated
- Project-specific patterns from recent branches
- Any staged or unstaged changes

### 2. Specialized Analysis
- **Context Analyzer**: Parse jj status and recent commits to understand current work context
- **Work Classifier**: Determine work type based on:
  - Current changes in working directory
  - User-provided description: $ARGUMENTS
  - Recent commit patterns
  - Project context from @CLAUDE.md
- **Naming Strategist**: Apply branch naming conventions
- **Branch Manager**: Validate and execute branch creation

### 3. Branch Naming Standards

**Format**: `<type>/<descriptive-name>`

**Type Prefixes**:
- `feature/` or `feat/` - New features or enhancements
- `fix/` or `bugfix/` - Bug fixes
- `hotfix/` - Critical production fixes
- `chore/` - Maintenance, dependency updates, tooling
- `refactor/` - Code refactoring without feature changes
- `docs/` - Documentation-only changes
- `test/` - Test-related changes
- `experiment/` - Experimental or research work
- `spike/` - Investigation or proof-of-concept work

**Naming Conventions**:
- Use kebab-case (lowercase with hyphens)
- Be descriptive but concise (max 50 characters total)
- Include relevant context (component, issue number, etc.)
- Avoid special characters except hyphens
- Use present tense action words

**Examples**:
- `feature/user-authentication`
- `fix/login-validation-error`
- `chore/update-dependencies`
- `refactor/api-client-structure`
- `docs/installation-guide`

### 4. Branch Name Generation Strategy

**Priority Order**:
1. **User-provided name**: If $ARGUMENTS contains a clear branch name, validate and use it
2. **Context-based suggestion**: Analyze current changes to suggest appropriate name
3. **Interactive clarification**: Ask user for work description if context is unclear

**Context Clues**:
- Modified files indicate scope (e.g., changes in `auth/` → `feature/auth-improvements`)
- Commit messages reveal patterns
- Working directory changes suggest work type
- Project structure indicates appropriate scopes

### 5. Validation and Safety
- Ensure branch name follows conventions
- Check for existing bookmark/branch conflicts
- Validate name length and character restrictions
- Confirm work type matches naming pattern
- Handle jujutsu-specific bookmark considerations

### 6. Execution Process
1. **Analyze context** and determine work type
2. **Generate branch name suggestions** with reasoning
3. **Present suggestions** with explanations
4. **Request user confirmation** of final branch name
5. **Execute creation** only after approval: `jj b c <branch-name>`
6. **Confirm successful creation** and next steps

## Output Format

### Context Analysis
- **Current State**: Summary of working directory and recent commits
- **Work Type**: Determined type of work with reasoning
- **Scope**: Identified component/area being worked on
- **Existing Patterns**: Reference to similar recent branches

### Branch Name Suggestions
```
Primary Suggestion: <type>/<descriptive-name>
Reasoning: [Explanation of why this name fits]

Alternative Options:
1. <alternative-name-1>
2. <alternative-name-2>
```

### Execution Plan
- Command to execute: `jj b c <final-branch-name>`
- Confirmation request
- Next recommended steps

## Usage Examples
- `/branch` - Analyze context and suggest branch name
- `/branch user authentication feature` - Create branch for specified work
- `/branch fix-login-bug` - Create branch with provided name (will validate format)
- `/branch feature/dashboard-redesign` - Create branch with full conventional name

## Special Considerations

### Jujutsu (jj) Specifics
- Uses bookmarks instead of traditional git branches
- `jj b c <name>` creates a new bookmark at current commit
- Bookmarks in jj are more flexible than git branches
- Consider the jj workflow when suggesting names

### Project Integration
- Reference @CLAUDE.md for team-specific branch naming conventions
- Consider existing bookmark patterns in the repository
- Adapt to project's preferred type prefixes
- Respect any documented naming standards

### Error Handling
- If bookmark already exists, suggest alternatives
- If context is ambiguous, request clarification
- If no changes detected, explain branch creation timing
- Provide guidance on next steps after branch creation

## Notes
- Always analyze current jj state before suggesting names
- Never execute `jj b c` without explicit user confirmation
- Consider the relationship between current changes and branch purpose
- Suggest descriptive names that clearly indicate the work being done
- Follow team conventions documented in CLAUDE.md when available
- Provide educational feedback about branch naming best practices
