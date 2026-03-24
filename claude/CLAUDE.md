## General Rules

When asked to do something, DO IT immediately. Do not explain how to do it or wait for confirmation — execute the task. If multiple branches/items need processing, do ALL of them unless explicitly told otherwise.

Never make unverified claims about library internals, build tool behavior, or framework specifics. If unsure, say so or research it first. Do not speculate about SharedFlow buffering, ProGuard behavior, or similar technical details without evidence.

## Version Control

This project uses `jj` (Jujutsu) for version control, NOT git. Always use `jj` commands instead of `git` commands. Key commands: `jj desc`, `jj bookmark`, `jj squash`, `jj log`, `jj new`.

Never use `git commit`, `git add`, or `git push`. Use `jj desc -m "<message>"` to set commit messages. Commit with the `/commit` skill, not manually.

### Rebasing

Three rebase modes — pick the right one:

- **`-b <bookmark>`** — rebase an entire branch/bookmark. Includes all revisions reachable from the bookmark. Use for moving whole branches: `jj rebase -b <bookmark> -d <destination>`
- **`-s <rev>`** — rebase a revision AND all its descendants. The whole subtree moves together. Use when you want to move a rev with everything on top of it.
- **`-r <rev>`** — rebase ONLY the specified revision, descendants stay behind (they get rebased onto the rev's parent). Use for reordering a single rev without moving its children.

Destination flags:
- **`-d` / `--onto`** — place the rev(s) onto the target. Existing children of the target are NOT affected.
- **`-A` / `--insert-after`** — insert after the target. Existing children of the target are rebased onto the inserted rev(s). Use this to insert a rev into the middle of a chain.
- **`-B` / `--insert-before`** — insert before the target. The target and its descendants are rebased onto the inserted rev(s).

Common patterns:
- Move a single rev to a new position in the chain: `jj rebase -r <rev> -A <after-this-rev>`
- Move a rev and all descendants: `jj rebase -s <rev> -d <destination>`
- Move entire branch: `jj rebase -b <bookmark> -d <destination>`

### Counting revisions

When asked about "last N revs": if the working copy (`@`) is empty, skip it and show the next N revs with actual changes. If `@` has changes, include it in the count.

### Analyzing branch/bookmark changes

To see what a branch implements, never use `jj diff --from master --to <branch>` — it shows divergence noise from both sides. Use one of these:

- **Combined diff from fork point (preferred):**
  `jj diff -r 'heads(ancestors(master) & ancestors(<branch>))::<branch>' --stat`
- **Per-revision inspection:**
  `jj diff -r <change_id> --stat` for each revision listed by `jj log -r '::<branch> & ~::master'`

## Git/JJ Operations

When rebasing branches, ALWAYS use the safe duplicate-compare approach: duplicate the branch first, rebase the duplicate, verify against the original, then replace. Never rebase directly on the original branch.

PR and MR descriptions must always be written in English unless explicitly told otherwise. Russian language rules apply ONLY to GitLab MRs when specifically configured, never to GitHub PRs.

## Commits

Follow the Conventional Commits specification. Format: `<type>(<scope>): <subject>`

- Subject: lowercase, imperative mood, max 50 chars, no period
- Body (if needed): blank line, then bullet points with `-`, max 3-5, lowercase, imperative
- Common types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`

## Code Style

Start code comments with lowercase letters (except KDoc/JavaDoc which follow their own conventions).

### C formatting (Linux kernel style)

- **Enums/structs**: opening brace on same line: `enum foo {`
- **Function definitions**: return type on its own line, `{` on its own line:
  ```c
  static int
  my_function(int first_param,
              u_char *second_param,
              size_t third_param)
  {
  ```
- **Control flow** (`if`/`else`/`for`/`while`/`switch`): opening brace on same line (K&R):
  ```c
  if (condition) {
    ...
  } else {
    ...
  }
  ```
- **Always use braces** for `if`/`else`/`for`/`while` bodies, even single-statement ones
- **`switch`**: brace on same line, `case` labels at same indentation level as `switch`:
  ```c
  switch (value) {
  case FOO:
    do_something();
    break;

  default:
    return NULL;
  }
  ```
- **Variable declarations**: all at the top of the function (C89 style), before any code
- **Parameter alignment**: first param on same line as function name, continuation params aligned to opening paren, one param per line
- **No space** between function name and `(`: `foo(` not `foo (`
- **Include grouping**: blank line separating system/library includes from the module's own header
- **Indentation**: 2 spaces for function bodies

## Git/MR Workflow

Before creating commits, branches, or MRs, always show the draft message/description to the user for review first. Never push or create MRs without explicit user approval of the content.

## Code Review & Estimation

When estimating story points or rating severity, hold your ground on initial assessments. If the user pushes back, explain your reasoning rather than immediately capitulating. Conversely, do not over-rate severity on guarded edge cases — only flag issues proportional to real risk.

## Code Review Guidelines

When reviewing MRs, distinguish between the MR author's changes (from the diff) and any local uncommitted changes. Local changes are the user's own brainstorming, not part of the MR. If unsure about ownership, ask.

When asked about specific changes in an MR, focus on the MR diff itself, not the broader codebase.

## Refactoring

When refactoring patterns across a codebase, apply the pattern CONSISTENTLY to ALL instances found during audit. Do not fix some and leave others without explicit user approval.

## Verify Before Acting

Never assume current state when tools can verify it. If you CAN check, you MUST check — never guess.

- Before explaining or acting on a rev: run `jj log --limit 5` to confirm where `@` is
- Before reading/editing a file: verify it exists and which rev context you're in
- Before describing branch state: run `jj log` or `jj status`, don't rely on conversation history
- General rule: conversation context can be stale — tool output is the source of truth

## Tools & CLI

Use `glab` CLI for GitLab operations. Known quirks: use `--state` not `-s` for MR state flags. For diffs, fall back to `git diff` if `glab` raw diff fails. Auto-detect MR from current branch with `glab mr view`.
