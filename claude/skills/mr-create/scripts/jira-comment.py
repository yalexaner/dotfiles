#!/usr/bin/env python3
"""Post a comment on a Jira ticket. Used by mr-create skill to link switch-builder MRs."""

import json
import sys
import urllib.request
import base64
import netrc
import os

CONFIG_PATH = os.path.expanduser("~/.claude/jira-config.json")


def main():
    if len(sys.argv) < 3:
        print("usage: jira-comment.py <ticket-id> <comment-body>", file=sys.stderr)
        sys.exit(1)

    ticket = sys.argv[1]
    body = sys.argv[2]

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
    data = json.dumps({"body": body}).encode()
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Authorization", f"Basic {creds}")
    req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            print(f"comment posted (id: {result['id']})")
    except urllib.error.HTTPError as e:
        print(f"error: {e.code} {e.reason}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
