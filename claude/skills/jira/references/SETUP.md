# Jira Skill Setup Guide

## Prerequisites

- macOS or Linux
- `python3` (pre-installed on macOS)
- `curl` (pre-installed on macOS/Linux)
- Access to the Jira instance at `https://ksu.nag.ru` (self-hosted Jira Server v8.13.4)

## Step 1: Create ~/.netrc

The skill authenticates via `~/.netrc` using basic auth (username + password).

Jira Server 8.13.4 does NOT support Personal Access Tokens (PAT was introduced in 8.14), so the regular Jira login password must be used.

Create the file:

```
machine ksu.nag.ru
login YOUR_USERNAME
password YOUR_PASSWORD
```

Set permissions (required — some tools refuse to read it if permissions are too open):

```bash
chmod 600 ~/.netrc
```

## Step 2: Verify the connection

```bash
curl -s -o /dev/null -w "%{http_code}" -n "https://ksu.nag.ru/rest/api/2/myself"
```

- `200` = auth works
- `401` = wrong credentials, check `~/.netrc`
- `403` = CAPTCHA triggered (see troubleshooting below)

## Step 3: Test the skill script

```bash
python3 ~/.claude/skills/jira/scripts/fetch-ticket.py STB-1417
```

Expected: full ticket output with correct Cyrillic/UTF-8 encoding.

## Troubleshooting

### CAPTCHA lockout

Jira Server 8.x triggers CAPTCHA after failed authentication attempts. Once triggered, ALL API requests return 403 with `AUTHENTICATION_DENIED`.

To fix:
1. Open `https://ksu.nag.ru` in your browser
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

## Optional: jira-cli setup

`brew install jira-cli` provides additional capabilities (sprint listing, issue search, issue creation). The skill itself does NOT use jira-cli because it has a known bug where Cyrillic text is garbled (mojibake).

If you want jira-cli for other purposes, add to `~/.zshrc`:

```bash
export JIRA_API_TOKEN=$(awk '/machine ksu.nag.ru/{found=1} found && /password/{print $2; exit}' ~/.netrc)
```

Then initialize:

```bash
jira init --installation local --server https://ksu.nag.ru --login YOUR_USERNAME --auth-type basic --project STB --board "STB Agile" --force
```

Config is stored at `~/.config/.jira/.config.yml`.

## Security notes

- Never commit `~/.netrc` to version control
- The password is your Jira login password — treat it accordingly
- `~/.netrc` must have 600 permissions (owner read/write only)
- The skill script never prints credentials in its output
