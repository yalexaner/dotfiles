---
name: jira
description: Fetch and display Jira ticket details. Use when the user mentions a Jira ticket key (like PROJECT-123) or a Jira URL.
argument-hint: [ticket-key or URL]
compatibility: Requires python3, ~/.claude/jira-config.json with base URLs, and ~/.netrc with credentials. Also fetches linked Confluence pages if configured.
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

If the description contains links to Confluence pages, the page content is automatically fetched and appended after the description. Present this content as part of the ticket context.

## Error handling

If the ticket data above contains an error or setup instructions:
- **SETUP REQUIRED**: The script prints full setup instructions. Present them to the user as-is — they contain all the steps needed to configure the skill.
- **403 Forbidden / CAPTCHA**: Tell the user to log into their Jira instance in the browser, solve the CAPTCHA, then retry. Do NOT retry the request.
- **404 Not Found**: The ticket key is invalid or doesn't exist.
- **Auth errors (401)**: The script diagnoses the issue (missing ~/.netrc, missing host entry, wrong credentials) and prints specific guidance. Present it to the user.
- **Connection errors**: The script reports the issue with the configured URL. Present it to the user.
- **Invalid input**: Ask the user for a valid ticket key or URL.
