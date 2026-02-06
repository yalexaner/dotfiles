---
name: jira
description: Fetch and display Jira ticket details. Use when the user mentions a Jira ticket key (like STB-1417) or a Jira URL (like https://ksu.nag.ru/browse/STB-1417).
argument-hint: [ticket-key or URL]
compatibility: Requires python3, curl, and ~/.netrc with basic auth credentials for ksu.nag.ru
allowed-tools: Bash(python3 *)
---

# Fetch Jira Ticket

## Ticket Data

!`python3 ~/.claude/skills/jira/scripts/fetch-ticket.py "$ARGUMENTS"`

## Instructions

Present the ticket data above to the user. The data is already fetched and formatted.

Descriptions and comments use **Jira wiki markup** (not Markdown):
- `*bold*`, `_italic_`, `{{monospace}}`
- `{code}...{code}` for code blocks
- `[link text|http://url]` for hyperlinks
- `h1.` through `h6.` for headings

Interpret this markup naturally when presenting.

## Error handling

If the ticket data above contains an error:
- **403 Forbidden**: CAPTCHA is triggered. Tell the user to log into `https://ksu.nag.ru` in their browser, solve the CAPTCHA, then retry. Do NOT retry the request.
- **404 Not Found**: The ticket key is invalid or doesn't exist.
- **Auth not configured**: If the script fails because `~/.netrc` is missing or has no entry for `ksu.nag.ru`, refer the user to [references/SETUP.md](references/SETUP.md) for setup instructions.
- **Invalid input**: Ask the user for a valid ticket key or URL.
