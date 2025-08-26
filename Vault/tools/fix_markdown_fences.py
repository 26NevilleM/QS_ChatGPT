#!/usr/bin/env python3
import sys, re, pathlib

# Target markdown files
targets = [p for p in pathlib.Path(".").rglob("*.md")]

changed = 0
for md in targets:
    txt = md.read_text(encoding="utf-8", errors="ignore")
    orig = txt

    # 1) Strip stray markers like bquote> or heredoc>
    txt = re.sub(r'(?m)^\s*(bquote>|heredoc>)\s*', '', txt)

    # 2) Normalize Windows-style backtick fences
    txt = txt.replace("```\r", "```")

    # 3) Ensure fences balanced
    opens = len(re.findall(r'(?m)^```', txt))
    if opens % 2 == 1:
        txt = txt.rstrip() + "\n```\n"

    if txt != orig:
        md.write_text(txt, encoding="utf-8")
        changed += 1

print(f"[markdown-fences] checked {len(targets)} files; fixed {changed}")
sys.exit(0)
