#!/usr/bin/env python3
"""Fetch a Jira ticket via REST API and display it in a readable format."""

import base64
import html as html_mod
import json
import os
import re
import sys
import urllib.request
import urllib.error
import urllib.parse
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
    print("Create the file with your Jira (and optionally Confluence) base URLs:")
    print()
    print("```json")
    print('{')
    print('  "jira_base": "https://your-jira-instance.example.com",')
    print('  "confluence_base": "https://your-confluence-instance.example.com"')
    print('}')
    print("```")
    print()
    print("- `jira_base` (required): your Jira Server URL")
    print("- `confluence_base` (optional): your Confluence URL, if ticket descriptions link to Confluence pages")
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
    print("If your Confluence instance shares the same user directory (common with Atlassian products),")
    print("the Jira credentials will be reused automatically. Otherwise, add a separate entry for the")
    print("Confluence host.")
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


def extract_confluence_urls(text, config):
    """Extract Confluence page URLs from text, return list of (url, page_id) tuples."""
    confluence_base = config.get("confluence_base")
    if not text or not confluence_base:
        return []
    # escape dots in hostname for regex
    host_pattern = re.escape(confluence_base.replace("https://", "").replace("http://", ""))
    results = []
    for m in re.finditer(rf'https?://{host_pattern}/pages/viewpage\.action\?pageId=(\d+)', text):
        results.append((m.group(0), m.group(1)))
    for m in re.finditer(rf'https?://{host_pattern}/display/\S+', text):
        results.append((m.group(0), None))
    return results


def confluence_host(config):
    """Extract hostname from confluence_base URL."""
    base = config.get("confluence_base", "")
    return base.replace("https://", "").replace("http://", "").split("/")[0]


def resolve_confluence_page_id(display_url, config):
    """Resolve a /display/ URL to a page ID via Confluence REST API."""
    match = re.search(r'/display/([^/]+)/(.+)', display_url)
    if not match:
        return None
    space = match.group(1)
    title = urllib.parse.unquote_plus(match.group(2).split('?')[0].split('#')[0])
    base = config["confluence_base"]
    url = f"{base}/rest/api/content?spaceKey={space}&title={urllib.parse.quote(title)}"
    req = urllib.request.Request(url)
    auth = get_auth(confluence_host(config), config)
    if auth:
        req.add_header("Authorization", auth)
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            results = data.get("results", [])
            if results:
                return results[0]["id"]
    except Exception:
        pass
    return None


def fetch_confluence_page(page_id, config):
    """Fetch a Confluence page by ID, return (title, html_body) or None."""
    base = config["confluence_base"]
    url = f"{base}/rest/api/content/{page_id}?expand=body.view"
    req = urllib.request.Request(url)
    auth = get_auth(confluence_host(config), config)
    if auth:
        req.add_header("Authorization", auth)
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            title = data.get("title", "Untitled")
            body = data.get("body", {}).get("view", {}).get("value", "")
            return title, body
    except Exception:
        return None


def html_to_text(html_content):
    """Convert HTML to readable plain text."""
    text = re.sub(r'<br\s*/?>', '\n', html_content)
    text = re.sub(r'</(?:p|div|tr|li|h[1-6])>', '\n', text)
    text = re.sub(r'<(?:p|div|tr|h[1-6])[^>]*>', '\n', text)
    text = re.sub(r'</t[dh]>', '\t', text)
    text = re.sub(r'<[^>]+>', '', text)
    text = html_mod.unescape(text)
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()


def format_confluence_pages(description, config):
    """Fetch linked Confluence pages from description, return formatted text."""
    urls = extract_confluence_urls(description, config)
    if not urls:
        return ""
    base = config["confluence_base"]
    sections = []
    for url, page_id in urls:
        if page_id is None:
            page_id = resolve_confluence_page_id(url, config)
        if page_id is None:
            sections.append(f"\n## Linked Confluence Page\n**URL**: {url}\n\nFailed to resolve page ID.")
            continue
        result = fetch_confluence_page(page_id, config)
        if result is None:
            sections.append(f"\n## Linked Confluence Page\n**URL**: {url}\n\nFailed to fetch page content.")
            continue
        title, body = result
        text = html_to_text(body)
        page_url = f"{base}/pages/viewpage.action?pageId={page_id}"
        sections.append(f"\n## Linked Confluence Page: {title}\n**URL**: {page_url}\n\n{text}")
    return "\n".join(sections)


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
    description = f.get("description") or ""
    lines.append("")
    lines.append("## Description")
    lines.append(description or "No description.")

    # linked confluence pages
    confluence = format_confluence_pages(description, config)
    if confluence:
        lines.append(confluence)

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
