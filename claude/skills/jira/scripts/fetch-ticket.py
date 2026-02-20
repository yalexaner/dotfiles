#!/usr/bin/env python3
"""Fetch a Jira ticket via REST API and display it in a readable format."""

import base64
import json
import os
import re
import sys
import urllib.request
import urllib.error
import netrc

CONFIG_PATH = os.path.expanduser("~/.claude/jira-config.json")
FIELDS = ",".join([
    "summary", "description", "status", "assignee", "reporter",
    "priority", "issuetype", "comment", "created", "updated",
    "labels", "fixVersions", "components", "subtasks", "parent",
    "issuelinks",
])


def load_config():
    """Load config from ~/.claude/jira-config.json, return dict or None."""
    try:
        with open(CONFIG_PATH, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None


def print_setup_guide(reason):
    """Print full setup instructions when configuration is missing or broken."""
    print(f"SETUP REQUIRED: {reason}")
    print()
    print("The Jira skill needs two things configured:")
    print()
    print(f"## 1. Config file: {CONFIG_PATH}")
    print()
    print("Create the file with your Jira base URL:")
    print()
    print("```json")
    print('{')
    print('  "jira_base": "https://your-jira-instance.example.com"')
    print('}')
    print("```")
    print()
    print("- `jira_base` (required): your Jira Server URL")
    print()
    print("## 2. Credentials: ~/.netrc")
    print()
    print("Add basic auth credentials for your Jira host:")
    print()
    print("```")
    print("machine your-jira-instance.example.com")
    print("login YOUR_USERNAME")
    print("password YOUR_PASSWORD")
    print("```")
    print()
    print("Then set permissions:")
    print()
    print("```bash")
    print("chmod 600 ~/.netrc")
    print("```")
    print()
    print("## 3. Verify")
    print()
    print("```bash")
    print('curl -s -o /dev/null -w "%{http_code}" -n "https://your-jira-instance.example.com/rest/api/2/myself"')
    print("```")
    print()
    print("- 200 = auth works")
    print("- 401 = wrong credentials")
    print("- 403 = CAPTCHA triggered (log into Jira in your browser, solve it, retry)")


def get_jira_host(config):
    """Extract hostname from jira_base URL."""
    return config["jira_base"].replace("https://", "").replace("http://", "").split("/")[0]


def get_auth(host, config):
    """Read credentials from ~/.netrc for the given host, falling back to Jira host."""
    try:
        nrc = netrc.netrc()
        auth = nrc.authenticators(host)
        # fall back to jira host credentials (same auth directory)
        if not auth:
            auth = nrc.authenticators(get_jira_host(config))
        if auth:
            user, _, password = auth
            token = base64.b64encode(f"{user}:{password}".encode()).decode()
            return f"Basic {token}"
    except FileNotFoundError:
        return None
    except netrc.NetrcParseError:
        return None
    return None


def diagnose_auth_error(config, error_code):
    """Diagnose authentication failure and print guidance."""
    jira_host = get_jira_host(config)

    if error_code == 403:
        print(f"ERROR 403: Access denied. CAPTCHA may be triggered.")
        print(f"Log into {config['jira_base']} in your browser, solve CAPTCHA, then retry.")
        print()
        print("CRITICAL: do NOT retry failed requests — each failure counts toward the CAPTCHA threshold.")
        sys.exit(1)

    # check if netrc exists and has an entry
    try:
        nrc = netrc.netrc()
        auth = nrc.authenticators(jira_host)
        if not auth:
            print(f"ERROR {error_code}: authentication failed.")
            print(f"~/.netrc exists but has no entry for '{jira_host}'.")
            print()
            print("Add the following to ~/.netrc:")
            print()
            print(f"machine {jira_host}")
            print("login YOUR_USERNAME")
            print("password YOUR_PASSWORD")
        else:
            print(f"ERROR {error_code}: authentication failed.")
            print(f"~/.netrc has credentials for '{jira_host}' but they were rejected.")
            print("Check that the username and password are correct.")
    except FileNotFoundError:
        print(f"ERROR {error_code}: authentication failed.")
        print("~/.netrc file not found. Create it with your Jira credentials:")
        print()
        print(f"machine {jira_host}")
        print("login YOUR_USERNAME")
        print("password YOUR_PASSWORD")
        print()
        print("Then run: chmod 600 ~/.netrc")
    except netrc.NetrcParseError as e:
        print(f"ERROR {error_code}: authentication failed.")
        print(f"~/.netrc exists but could not be parsed: {e}")

    sys.exit(1)


def extract_key(arg):
    """Extract a Jira ticket key from a URL or plain key."""
    match = re.search(r"/browse/([A-Z]+-\d+)", arg)
    if match:
        return match.group(1)
    match = re.match(r"^[A-Z]+-\d+$", arg.strip())
    if match:
        return match.group(0)
    return None


def fetch_ticket(key, config):
    """Fetch ticket JSON from Jira REST API."""
    jira_base = config["jira_base"]
    jira_host = get_jira_host(config)
    url = f"{jira_base}/rest/api/2/issue/{key}?fields={FIELDS}"
    req = urllib.request.Request(url)

    auth = get_auth(jira_host, config)
    if auth:
        req.add_header("Authorization", auth)

    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print(f"ERROR 404: Ticket {key} not found.")
            sys.exit(1)
        elif e.code in (401, 403):
            diagnose_auth_error(config, e.code)
        else:
            print(f"ERROR {e.code}: {e.reason}")
            sys.exit(1)
    except urllib.error.URLError as e:
        print(f"ERROR: Could not connect to {jira_base}")
        print(f"Reason: {e.reason}")
        print()
        print(f"Check that jira_base in {CONFIG_PATH} is correct and the server is reachable.")
        sys.exit(1)


def safe(obj, *keys, default="None"):
    """Safely traverse nested dicts."""
    for k in keys:
        if isinstance(obj, dict):
            obj = obj.get(k)
        else:
            return default
    return obj if obj is not None else default


def format_ticket(data, config):
    """Format ticket data as readable text."""
    f = data["fields"]
    jira_base = config["jira_base"]

    lines = []
    lines.append(f"# {data['key']}: {f['summary']}")
    lines.append("")
    lines.append(f"**URL**: {jira_base}/browse/{data['key']}")
    lines.append(f"**Type**: {safe(f, 'issuetype', 'name')}")
    lines.append(f"**Status**: {safe(f, 'status', 'name')}")
    lines.append(f"**Priority**: {safe(f, 'priority', 'name')}")
    lines.append(f"**Assignee**: {safe(f, 'assignee', 'displayName')}")
    lines.append(f"**Reporter**: {safe(f, 'reporter', 'displayName')}")
    lines.append(f"**Created**: {f.get('created', 'N/A')}")
    lines.append(f"**Updated**: {f.get('updated', 'N/A')}")

    labels = f.get("labels", [])
    if labels:
        lines.append(f"**Labels**: {', '.join(labels)}")

    components = f.get("components", [])
    if components:
        names = [c["name"] for c in components]
        lines.append(f"**Components**: {', '.join(names)}")

    versions = f.get("fixVersions", [])
    if versions:
        names = [v["name"] for v in versions]
        lines.append(f"**Fix Versions**: {', '.join(names)}")

    parent = f.get("parent")
    if parent:
        lines.append(f"**Parent**: {parent['key']} — {safe(parent, 'fields', 'summary')}")

    # subtasks
    subtasks = f.get("subtasks", [])
    if subtasks:
        lines.append("")
        lines.append(f"## Subtasks ({len(subtasks)})")
        for st in subtasks:
            st_status = safe(st, "fields", "status", "name")
            lines.append(f"- [{st['key']}] {safe(st, 'fields', 'summary')} ({st_status})")

    # issue links
    issue_links = f.get("issuelinks", [])
    if issue_links:
        lines.append("")
        lines.append(f"## Links ({len(issue_links)})")
        for link in issue_links:
            link_type = safe(link, "type", "outward")
            if "outwardIssue" in link:
                target = link["outwardIssue"]
                lines.append(f"- {link_type}: [{target['key']}] {safe(target, 'fields', 'summary')}")
            elif "inwardIssue" in link:
                link_type = safe(link, "type", "inward")
                target = link["inwardIssue"]
                lines.append(f"- {link_type}: [{target['key']}] {safe(target, 'fields', 'summary')}")

    # description
    lines.append("")
    lines.append("## Description")
    lines.append(f.get("description") or "No description.")

    # comments
    comments = f.get("comment", {}).get("comments", [])
    lines.append("")
    lines.append(f"## Comments ({len(comments)})")
    if not comments:
        lines.append("No comments.")
    else:
        for c in comments:
            author = safe(c, "author", "displayName")
            updated = c.get("updated", "")
            lines.append(f"\n### {author} ({updated})")
            lines.append(c.get("body", ""))

    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print("Usage: fetch-ticket.py <TICKET-KEY or URL>")
        sys.exit(1)

    arg = sys.argv[1]

    config = load_config()
    if not config or not config.get("jira_base"):
        print_setup_guide(f"Config file not found or missing jira_base at {CONFIG_PATH}")
        sys.exit(1)

    key = extract_key(arg)
    if not key:
        print(f"Could not extract a Jira ticket key from: {arg}")
        print(f"Expected format: PROJECT-123 or {config['jira_base']}/browse/PROJECT-123")
        sys.exit(1)

    data = fetch_ticket(key, config)
    print(format_ticket(data, config))


if __name__ == "__main__":
    main()
