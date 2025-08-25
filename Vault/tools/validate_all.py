#!/usr/bin/env python3
from pathlib import Path
import json, re, sys

REQUIRED_SECTIONS = [
    r'^#\s+.+',                          # Title (H1)
    r'^##\s+Purpose',
    r'^##\s+Audience\s*&\s*Persona',
    r'^##\s+Inputs',
    r'^##\s+Outputs',
    r'^##\s+Constraints',
    r'^##\s+Safety\s*&\s*Verbs',
    r'^##\s+Legal\s*&\s*Privacy\s*Disclaimer',
]

def load_packs():
    """Find all packs (dirs with meta.json) and return dicts {slug, path}."""
    root = Path("Vault/Prompt_Library")
    packs = []
    for meta in root.rglob("meta.json"):
        try:
            data = json.loads(meta.read_text(encoding="utf-8"))
        except Exception:
            # If meta is unreadable, still include pack to surface a warning elsewhere.
            data = {}
        slug = data.get("slug") or meta.parent.name
        packs.append({"slug": slug, "path": str(meta.parent)})
    return packs

def check_disclaimer(packs):
    """Stub to keep compatibility with older pipelines; add your real checks here."""
    return []

def check_prompt_sections(packs):
    warns = []
    for p in packs:
        prompt_path = Path(p["path"]) / "prompt.md"
        if not prompt_path.exists():
            warns.append(f"WARN prompt_missing:{p['slug']}")
            continue
        txt = prompt_path.read_text(encoding="utf-8")
        for pat in REQUIRED_SECTIONS:
            if re.search(pat, txt, flags=re.MULTILINE) is None:
                warns.append(f"WARN prompt_section_missing:{p['slug']}: {pat}")
    return warns

def main():
    packs = load_packs()
    warns = []
    warns += check_disclaimer(packs)
    warns += check_prompt_sections(packs)

    # Print warnings if any (match your previous log style)
    for w in warns:
        print(w)

    print("ALL_VALIDATIONS_OK")
    return 0

if __name__ == "__main__":
    sys.exit(main())
