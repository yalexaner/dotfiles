# Jira Skill Setup Guide

## Prerequisites

- macOS or Linux
- `python3` (pre-installed on macOS)
- Access to a Jira Server instance

## Step 1: Create config file

Create `~/.claude/jira-config.json` with your instance URLs:

```json
{
  "jira_base": "https://your-jira-instance.example.com",
  "confluence_base": "https://your-confluence-instance.example.com"
}
```

- `jira_base` (required): your Jira Server base URL
- `confluence_base` (optional): your Confluence base URL — if ticket descriptions link to Confluence spec pages, they will be fetched automatically

## Step 2: Create ~/.netrc

The skill authenticates via `~/.netrc` using basic auth (username + password).

Note: Jira Server versions before 8.14 do NOT support Personal Access Tokens, so the regular Jira login password must be used.

```
machine your-jira-instance.example.com
login YOUR_USERNAME
password YOUR_PASSWORD
```

Set permissions (required — some tools refuse to read it if permissions are too open):

```bash
chmod 600 ~/.netrc
```

If your Confluence instance shares the same user directory (common with Atlassian products), the Jira credentials will be reused automatically for Confluence. Otherwise, add a separate entry for the Confluence host.

## Step 3: Verify the connection

```bash
curl -s -o /dev/null -w "%{http_code}" -n "https://your-jira-instance.example.com/rest/api/2/myself"
```

- `200` = auth works
- `401` = wrong credentials, check `~/.netrc`
- `403` = CAPTCHA triggered (see troubleshooting below)

## Step 4: Test the skill script

```bash
python3 ~/.claude/skills/jira/scripts/fetch-ticket.py PROJECT-123
```

Expected: full ticket output with correct Cyrillic/UTF-8 encoding.

## Troubleshooting

### CAPTCHA lockout

Jira Server 8.x triggers CAPTCHA after failed authentication attempts. Once triggered, ALL API requests return 403 with `AUTHENTICATION_DENIED`.

To fix:
1. Open your Jira instance in your browser
2. Log out
3. Log back in (solve CAPTCHA if shown)
4. Retry the skill

**CRITICAL**: do NOT retry failed requests — each 401 failure counts toward the CAPTCHA threshold and can re-trigger the lockout.

### Password change

If you change your Jira password, update `~/.netrc` with the new password.

### Permission denied on ~/.netrc

```bash
chmod 600 ~/.netrc
```

## Security notes

- Never commit `~/.netrc` or `~/.claude/jira-config.json` to version control
- The password is your Jira login password — treat it accordingly
- `~/.netrc` must have 600 permissions (owner read/write only)
- The skill script never prints credentials in its output
