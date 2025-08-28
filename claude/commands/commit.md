---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(jj desc:*)
argument-hint: [optional context or focus area]
description: Analyze git diff and automatically generate & commit conventional message with jj desc (lowercase style)
---

# Commit Message Generation Command (Auto-Commit with Jujutsu)

Generate a conventional commit message by analyzing changes with git commands and automatically committing with jujutsu.

## ⚠️ CRITICAL: MIXED GIT/JUJUTSU WORKFLOW
**Use git commands for analysis, jujutsu ONLY for final commit.**
- ✅ ANALYSIS: Use `git diff`, `git status`, `git log`
- ✅ COMMIT: AUTOMATICALLY execute `jj desc -m "commit message"`
- ❌ NEVER use: `git commit` or `git commit -m`

## Context Information
- Current git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`  
- Staged changes: !`git diff --cached --name-only`
- Working copy changes: !`git diff --stat`
- Recent commits for reference: !`git log --oneline -5`
- Current diff (working copy): !`git diff`
- Current diff (staged): !`git diff --cached`

## Your Role
You are the Commit Message Coordinator directing four specialized commit analysts:

1. **Change Analyzer** – examines code changes and determines the nature and scope of modifications
2. **Type Classifier** – categorizes changes according to Conventional Commits types (feat, fix, chore, etc.)
3. **Scope Identifier** – determines appropriate scope based on affected components or modules
4. **Message Craftsperson** – writes concise, clear commit messages following established standards with lowercase formatting

## Process

### 1. Diff Analysis
Analyze the git diff and git status output to identify:
- All modified, added, and deleted files
- Nature of changes (new features, bug fixes, refactoring, etc.)
- Affected components, modules, or areas
- Breaking changes or significant modifications

### 2. Specialized Analysis
- **Change Analyzer**: Parse git diff for actual code changes and their impact
- **Type Classifier**: Determine appropriate commit type based on change nature:
  - `feat`: New feature or functionality
  - `fix`: Bug fix or error correction  
  - `docs`: Documentation changes only
  - `style`: Code style changes (formatting, missing semicolons, etc.)
  - `refactor`: Code refactoring without feature changes or bug fixes
  - `test`: Adding or modifying tests
  - `chore`: Maintenance tasks, dependency updates, build changes
  - `perf`: Performance improvements
  - `ci`: CI/CD configuration changes
  - `build`: Build system or dependency changes
  - `revert`: Reverting previous commits
  - `deps`: Dependency updates
  - `ops`: Operational components like infrastructure, deployment
  - `security`: Security-related changes
- **Scope Identifier**: Extract relevant scope (component, module, or area affected)
- **Message Craftsperson**: Craft the commit message following these rules

### 3. Commit Message Rules (LOWERCASE STYLE)
Follow these standards strictly:

**Format**: `<type>[optional scope]: <description>`

**Subject Line Standards (LOWERCASE)**:
- **Use lowercase after colon**: "feat(api): add user authentication" (NOT "Add user authentication")
- Use imperative mood with lowercase: "add feature" not "added feature" or "adds feature"
- Keep subject line to 50 characters maximum
- Do not end with a period
- Include lowercase scope in parentheses when applicable: `feat(api): add user authentication`

**Extended Description** (when needed):
- Separate from subject with blank line
- **Use lowercase for all bullet points and sentences**
- Wrap at 72 characters
- Use dash-prefixed bullet points for multiple changes
- Explain what and why, not how
- Include breaking changes with `BREAKING CHANGE:` footer

**Lowercase Examples**:
```
feat(auth): add password reset functionality

- add email validation for reset requests
- implement secure token generation
- update user model with reset timestamp

BREAKING CHANGE: password reset now requires email verification
```

**Context Consideration**:
- Reference project-specific conventions from @CLAUDE.md if available
- Consider user-provided context: $ARGUMENTS
- Maintain consistency with recent commit patterns
- **Always use lowercase formatting for all text after colons and in body**

### 4. Safety and Validation
- Validate that the message follows Conventional Commits specification with lowercase style
- Check for proper BREAKING CHANGE format if applicable
- Ensure scope matches project structure
- Verify imperative mood with lowercase formatting

### 5. Execution Process
1. **Generate the commit message** based on analysis (with lowercase formatting)
2. **Present the message clearly** to the user
3. **Explain the reasoning** behind type, scope, and description choices
4. **Automatically execute** the jujutsu command:
   - ✅ **EXECUTE IMMEDIATELY**: `jj desc -m "commit message"`
   - ❌ **NEVER**: Don't use `git commit -m` or `git add`

## ⚠️ EXECUTION SAFETY RULES

### What TO DO:
- ✅ Use `jj desc -m "lowercase commit message"` automatically without confirmation
- ✅ Analyze changes with `git diff` and `git status`
- ✅ Reference recent history with `git log`

### What NOT TO DO:
- ❌ **NEVER run `git add`**
- ❌ **NEVER run `git commit`** 
- ❌ **NEVER run `git commit -m`**
- ❌ **NEVER stage files** (jujutsu doesn't use staging)

### Remember: Mixed Git/Jujutsu Workflow
- Use git commands to analyze changes (`git diff`, `git status`)
- Working copy changes are tracked by both git and jj
- Use traditional git staging if needed for analysis
- **Automatically execute** `jj desc -m` with generated message (no user confirmation needed)

## Output Format

### Analysis Summary
- **Files Changed**: List of modified files with change types
- **Change Type**: Primary type of change with reasoning
- **Affected Scope**: Component/module scope determination
- **Breaking Changes**: Any breaking changes identified

### Generated Commit Message (LOWERCASE STYLE)
```
<type>[scope]: <lowercase description>

[optional extended description with lowercase bullet points]

[optional footers including BREAKING CHANGE if applicable]
```

### Execution Plan
- **Command to be executed**: `jj desc -m "the generated message"`
- **No confirmation required** - executes automatically
- **Alternative suggestions if needed**

## Usage Examples
- `/commit` - Analyze current changes and generate lowercase commit message
- `/commit focus on API changes` - Generate message with specific focus area  
- `/commit this fixes the login bug` - Generate message with provided context

## Notes
- **Always use lowercase formatting** after colons and in body text
- Use git commands to analyze ALL changes in the working copy and staging area
- If no changes exist, suggest using git add to stage changes first
- If main change cannot be determined clearly, ask user for primary intent
- Follow project-specific commit conventions if defined in CLAUDE.md
- Ensure message is meaningful and follows team standards
- **AUTOMATICALLY execute `jj desc -m` - no confirmation needed**
- Remember: Use git for analysis, `jj desc -m` for automatic committing