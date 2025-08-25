#!/usr/bin/env python3
import sys, re, argparse
from pathlib import Path

ROOT = Path("Vault/Prompt_Library")

# Canonical required sections (H2) and their default stubs
REQUIRED = [
    ("## Purpose", "State what this prompt is for and the main outcome."),
    ("## Audience & Persona", "- Primary users:\n- Secondary users:\n- Tone:"),
    ("## Inputs", "- Required fields:\n- Optional fields:"),
    ("## Outputs", "- What the model should return:\n\n### Expected structure (bullets or JSON schema)\n- …\n\n### Example output\n- …"),
    ("## Constraints", "- Scope boundaries (what NOT to do)\n- Time/length limits, style constraints"),
    ("## Safety & Verbs", '- Use "assist / review / suggest / analyze"\n- Avoid absolutes; guidance only; **not legal advice**'),
    ("## Legal & Privacy Disclaimer", "- Informational only; verify with primary sources\n- Minimize personal data in examples\n- You are responsible for policy/legal compliance"),
    ("## Steps / Reasoning Hints", "1) …\n2) …\n3) …"),
    ("## Examples", "### Example 1 — Input\nheredoc>\n### Example 1 — Output\nheredoc>"),
    ("## Tool Use (if applicable)", "- Tools available\n- When to call\n- Fallback behavior if unavailable"),
    ("## Evaluation Checklist", "- [ ] Section coverage present\n- [ ] Outputs match schema\n- [ ] Edge cases covered\n- [ ] Safety & legal disclaimers included"),
    ("## Changelog", "- v1.0.0 — initial scaffold"),
]

H1_RE = re.compile(r"^#\s+.+", re.MULTILINE)

def find_h2_blocks(text):
    """Return list of (header_line, start_idx, end_idx, body) in order."""
    matches = list(re.finditer(r"^##\s+.+$", text, flags=re.MULTILINE))
    blocks = []
    for i, m in enumerate(matches):
        start = m.start()
        end = matches[i+1].start() if i + 1 < len(matches) else len(text)
        header = text[m.start():m.end()]
        body = text[m.end():end].strip("\n")
        blocks.append((header, start, end, body))
    return blocks

def has_h2(text, header):
    return re.search(rf"^{re.escape(header)}\s*$", text, flags=re.MULTILINE) is not None

def section_empty(body: str) -> bool:
    # Empty if only whitespace or HTML comments
    stripped = body.strip()
    if not stripped:
        return True
    # ignore pure comment bodies
    no_comments = re.sub(r"<!--.*?-->", "", stripped, flags=re.DOTALL).strip()
    return len(no_comments) == 0

def ensure_h1(title_from_dir: str, text: str) -> str:
    if H1_RE.search(text) is None:
        return f"# {title_from_dir}\n\n{text}"
    return text

def canonicalize(text: str, fill: bool, summary):
    # Ensure H1 present; use folder name or keep existing
    title = Path(summary['pack_dir']).name.replace("_", " ").title()
    text = ensure_h1(title, text)

    # Ensure all required sections exist
    for header, stub in REQUIRED:
        if not has_h2(text, header):
            text = text.rstrip() + f"\n\n{header}\n{stub}\n"
            summary['added'] += 1

    # Re-scan and fill empty ones if needed
    # (We keep original order, but we can reorder canonically if requested)
    if fill:
        blocks = find_h2_blocks(text)
        for header, _, _, body in blocks:
            for req_header, stub in REQUIRED:
                if header.strip() == req_header.strip() and section_empty(body):
                    # Replace the empty body with stub
                    # Find where this header starts and where body begins/ends
                    pat = rf"^{re.escape(req_header)}\s*$"
                    m = re.search(pat, text, flags=re.MULTILINE)
                    if not m: 
                        continue
                    body_start = m.end()
                    # Next H2 or EOF
                    nxt = re.search(r"^##\s+.+$", text[body_start:], flags=re.MULTILINE)
                    body_end = body_start + (nxt.start() if nxt else len(text[body_start:]))
                    before = text[:body_start]
                    after = text[body_end:]
                    text = before + "\n" + stub.strip() + "\n" + after
                    summary['filled'] += 1

    # Optional: reorder to canonical order
    # Build a dict of existing bodies, then reassemble in REQUIRED order
    bodies = {}
    blocks = find_h2_blocks(text)
    for header, _, _, body in blocks:
        bodies[header.strip()] = body

    # Keep anything before first H2
    head_match = re.search(r"^##\s+.+$", text, flags=re.MULTILINE)
    prefix = text[:head_match.start()] if head_match else text

    rebuilt = [prefix.rstrip()]
    for header, stub in REQUIRED:
        h = header.strip()
        b = bodies.get(h, "").strip()
        if not b:
            b = stub.strip()
        rebuilt.append(f"{header}\n{b}\n")
    # Append any extra (non-canonical) sections after
    for header, _, _, body in blocks:
        if header.strip() not in {h for h, _ in REQUIRED}:
            rebuilt.append(f"{header}\n{body}\n")

    return ("\n".join(x.rstrip() for x in rebuilt if x is not None).strip() + "\n")

def process_file(p: Path, fill: bool):
    txt = p.read_text(encoding="utf-8")
    summary = {'pack_dir': str(p.parent), 'added': 0, 'filled': 0, 'changed': False}
    new = canonicalize(txt, fill=fill, summary=summary)
    summary['changed'] = (new != txt)
    if summary['changed']:
        p.write_text(new, encoding="utf-8")
    return summary

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="Exit 1 if any file has missing or empty required sections.")
    ap.add_argument("--fill", action="store_true", help="Fill empty/missing sections with stubs.")
    ap.add_argument("--category", default="", help="Only process a subfolder (e.g. 'sandbox', 'active', 'clinical').")
    args = ap.parse_args()

    base = ROOT / args.category if args.category else ROOT
    prompts = sorted(base.rglob("prompt.md"))
    if not prompts:
        print("[INFO] No prompt.md files found.")
        return 0

    missing_or_empty = 0
    totals = {'added': 0, 'filled': 0, 'changed': 0, 'count': 0}

    for p in prompts:
        txt = p.read_text(encoding="utf-8")
        # quick check for missing/empty
        issues = 0
        for header, stub in REQUIRED:
            if not has_h2(txt, header):
                issues += 1
            else:
                # get body
                blocks = find_h2_blocks(txt)
                for h, _, _, body in blocks:
                    if h.strip() == header.strip() and section_empty(body):
                        issues += 1
        if args.fill:
            s = process_file(p, fill=True)
            totals['added'] += s['added']
            totals['filled'] += s['filled']
            totals['changed'] += (1 if s['changed'] else 0)
        missing_or_empty += (1 if issues else 0)
        totals['count'] += 1

    print(f"[SUMMARY] files={totals['count']} changed={totals['changed']} added_sections={totals['added']} filled_sections={totals['filled']}")
    if args.check and missing_or_empty:
        print(f"[CHECK] {missing_or_empty} file(s) have missing/empty required sections.")
        return 1 if missing_or_empty else 0
    return 0

if __name__ == "__main__":
    sys.exit(main())
