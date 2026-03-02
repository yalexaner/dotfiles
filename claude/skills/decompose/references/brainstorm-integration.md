# Brainstorm Integration Specification

This document specifies how `/brainstorm` should be modified to support decompose files. It serves as a specification for changes to the brainstorm skill, not instructions for the decompose skill itself.

## Modified Brainstorm Flow

When `/brainstorm {TICKET}` is invoked:

### 1. Check for Decompose File

Look for `{TICKET}-decompose.md` in the project memory directory.

### 2. No File Found

Run normal brainstorm behavior — completely unchanged from the current implementation.

### 3. File Found

a. Read the entire decompose file.

b. Find the first step with `- [ ] analyzed`.

c. **All steps done**: If all steps have `- [x] analyzed`, report "all steps have been analyzed" and offer to re-run a specific step or exit.

d. **Read current step context**: Parse the `brainstorm-context` HTML comment block for the current step.

e. **Read completed steps' results**: Parse all `brainstorm-result` blocks from steps marked `- [x]`. These provide cross-step awareness.

f. **Use step context as focus area**: The current step's `brainstorm-context` becomes the focus area for brainstorm's agents, replacing any focus area from the user.

g. **Include cross-step context in agent prompts**: Add completed steps' results to agent prompts with instructions like: "Previous steps established these patterns: [results]. Follow them for consistency."

h. **After presenting the report**:
   - Append a compact `brainstorm-result` block under the current step
   - Change `- [ ] analyzed` to `- [x] analyzed`
   - Use the Edit tool to modify the decompose file

i. **Ask the user**: "Continue to next step or stop?"

### 4. Focus Area Override

If the user provides a focus area argument alongside the ticket key (e.g., `/brainstorm SWITCH-4713 mvlanInfoTable`), use that as the focus instead of the decompose file's next step. The decompose file is still read for cross-step context, but the step progression is not advanced.

## Agent Prompt Modifications

When brainstorm runs in decompose-guided mode, its agent prompts should include:

1. **Step context** from the `brainstorm-context` block — this narrows the scope
2. **Cross-step results** from completed steps — this ensures consistency
3. **Pattern guidance**: "This step should follow the patterns established in previous steps"

The agents still do their full analysis (explore + analyst + codex), but scoped to the current step rather than the entire ticket.

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| Decompose file exists but is malformed | Warn user, offer to run brainstorm without decompose guidance |
| Step has dependencies not yet analyzed | Warn user that dependencies are incomplete, proceed anyway |
| User wants to skip a step | Mark it `- [x] analyzed` with a `brainstorm-result` noting "skipped by user" |
| User wants to re-analyze a completed step | Reset `- [x]` to `- [ ]`, remove old `brainstorm-result`, re-run |
