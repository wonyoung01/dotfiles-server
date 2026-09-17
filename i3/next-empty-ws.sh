#!/usr/bin/env python3
"""Jump to (or move the focused container to) the next empty workspace.

i3 has no native "next free workspace" command, so we ask i3 for the list of
workspaces, pick the lowest positive integer that isn't in use, and act on it.

Usage:
  next-empty-ws.sh switch   # focus the next empty workspace, then open rofi
  next-empty-ws.sh move     # send the focused window there and follow it
"""
import json
import subprocess
import sys

mode = sys.argv[1] if len(sys.argv) > 1 else "switch"

# 11-36 are reserved for the letter workspaces A-Z (named "11:A" .. "36:Z"),
# so never hand one of those out as a "fresh" workspace.
RESERVED = range(11, 37)

workspaces = json.loads(subprocess.check_output(["i3-msg", "-t", "get_workspaces"]))
used = {w["num"] for w in workspaces if w["num"] > 0}

n = 1
while n in used or n in RESERVED:
    n += 1

if mode == "move":
    subprocess.run(["i3-msg", f"move container to workspace number {n}; workspace number {n}"])
else:
    subprocess.run(["i3-msg", f"workspace number {n}"])
    # match the split bindings: open the launcher so the fresh workspace is useful
    subprocess.Popen(["rofi", "-show", "drun"])
