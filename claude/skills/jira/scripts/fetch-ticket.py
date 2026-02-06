#!/usr/bin/env python3
"""Fetch a Jira ticket via REST API and display it in a readable format."""

import json
import re
import sys
import urllib.request
import urllib.error
import netrc

JIRA_BASE = "https://ksu.nag.ru"
FIELDS = ",".join([
    "summary", "description", "status", "assignee", "reporter",
    "priority", "issuetype", "comment", "created", "updated",
    "labels", "fixVersions", "components", "subtasks", "parent",
    "issuelinks",
])


def get_auth():
    """Read credentials from ~/.netrc for the Jira host."""
    try:
        nrc = netrc.netrc()
        host = JIRA_BASE.replace("https://", "").replace("http://", "")
        auth = nrc.authenticators(host)
        if auth:
            import base64
            user, _, password = auth
            token = base64.b64encode(f"{user}:{password}".encode()).decode()
            return f"Basic {token}"
    except (FileNotFoundError, netrc.NetrcParseError):
        pass
    return None


def extract_key(arg):
    """Extract a Jira ticket key from a URL or plain key."""
    # try to extract from URL path
    match = re.search(r"/browse/([A-Z]+-\d+)", arg)
    if match:
        return match.group(1)
    # try plain key format
    match = re.match(r"^[A-Z]+-\d+$", arg.strip())
    if match:
        return match.group(0)
    return None


def fetch_ticket(key):
    """Fetch ticket JSON from Jira REST API."""
    url = f"{JIRA_BASE}/rest/api/2/issue/{key}?fields={FIELDS}"
    req = urllib.request.Request(url)

    auth = get_auth()
    if auth:
        req.add_header("Authorization", auth)

    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        if e.code == 403:
            print("ERROR 403: Access denied. CAPTCHA may be triggered.")
            print(f"Log into {JIRA_BASE} in your browser, solve CAPTCHA, then retry.")
            sys.exit(1)
        elif e.code == 404:
            print(f"ERROR 404: Ticket {key} not found.")
            sys.exit(1)
        else:
            print(f"ERROR {e.code}: {e.reason}")
            sys.exit(1)


def safe(obj, *keys, default="None"):
    """Safely traverse nested dicts."""
    for k in keys:
        if isinstance(obj, dict):
            obj = obj.get(k)
        else:
            return default
    return obj if obj is not None else default


def format_ticket(data):
    """Format ticket data as readable text."""
    f = data["fields"]

    lines = []
    lines.append(f"# {data['key']}: {f['summary']}")
    lines.append("")
    lines.append(f"**URL**: {JIRA_BASE}/browse/{data['key']}")
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
    key = extract_key(arg)
    if not key:
        print(f"Could not extract a Jira ticket key from: {arg}")
        print("Expected format: STB-1417 or https://ksu.nag.ru/browse/STB-1417")
        sys.exit(1)

    data = fetch_ticket(key)
    print(format_ticket(data))


if __name__ == "__main__":
    main()
