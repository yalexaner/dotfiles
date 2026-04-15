#!/usr/bin/env python3
"""Check if GitLab Bot posted a recent comment on a Jira ticket. Exit 0 if found, 1 if not."""

import json
import sys
import urllib.request
import base64
import netrc
import os

CONFIG_PATH = os.path.expanduser("~/.claude/jira-config.json")


def main():
    if len(sys.argv) < 2:
        print("usage: jira-check-bot-comment.py <ticket-id>", file=sys.stderr)
        sys.exit(1)

    ticket = sys.argv[1]

    with open(CONFIG_PATH) as f:
        config = json.load(f)

    base = config["jira_base"]
    host = base.replace("https://", "").replace("http://", "").split("/")[0]

    nrc = netrc.netrc()
    auth_info = nrc.authenticators(host)
    if not auth_info:
        print(f"error: no netrc entry for {host}", file=sys.stderr)
        sys.exit(1)

    creds = base64.b64encode(f"{auth_info[0]}:{auth_info[2]}".encode()).decode()

    url = f"{base}/rest/api/2/issue/{ticket}/comment"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Basic {creds}")

    try:
        with urllib.request.urlopen(req) as resp:
            comments = json.loads(resp.read().decode("utf-8"))["comments"]
            bot_comments = [c for c in comments if c["author"]["displayName"] == "GitLab Bot"]
            if bot_comments:
                latest = bot_comments[-1]
                print(f"bot comment found ({latest['created'][:19]})")
                sys.exit(0)
            else:
                print("no bot comment found")
                sys.exit(1)
    except urllib.error.HTTPError as e:
        print(f"error: {e.code} {e.reason}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
