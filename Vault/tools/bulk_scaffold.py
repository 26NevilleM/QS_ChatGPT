#!/usr/bin/env python3
"""
Bulk scaffolder for QS_ChatGPT packs.
Reads CSV or JSON list and creates Vault/Prompt_Library/<category>/<slug>/{meta.json,prompt.md}.
"""

import argparse, csv, json, re
from pathlib import Path
from datetime import datetime, timezone

ENRICHED_PROMPT_TEMPLATE = """# {TITLE}
## Purpose
## Audience & Persona
## Inputs
## Outputs
## Constraints
## Safety & Verbs
## Legal & Privacy Disclaimer
## Steps / Reasoning Hints
## Examples
### Example 1 — Input
### Example 1 — Output
## Tool Use (if applicable)
## Evaluation Checklist
## Changelog
- v1.0.0 — initial scaffold
"""

def _slugify(s): return re.sub(r"[^a-z0-9_-]+", "_", s.strip().lower()).strip("_") or "unnamed"

def _now_iso(): return datetime.now(timezone.utc).replace(microsecond=0).isoformat()

def make_meta(row):
    return {
        "slug": _slugify(row.get("slug") or row.get("title") or "unnamed"),
        "title": row.get("title") or "",
        "owner": row.get("owner") or "",
        "persona": row.get("persona") or "",
        "use_case": row.get("use_case") or "",
        "version": row.get("version") or "0.0.1",
        "status": row.get("status") or "draft",
        "tags": re.split(r"[;,]", row.get("tags") or "") if row.get("tags") else [],
        "created_at": _now_iso(),
    }

def load_rows(path: Path):
    text = path.read_text(encoding="utf-8")
    if path.suffix == ".csv":
        return list(csv.DictReader(text.splitlines()))
    data = json.loads(text)
    return data["packs"] if isinstance(data, dict) and "packs" in data else data

def scaffold(rows, root, category, force=False):
    created, skipped = 0, 0
    for r in rows:
        meta = make_meta(r)
        cat = _slugify(r.get("category") or category)
        pack_dir = root / "Vault" / "Prompt_Library" / cat / meta["slug"]
        pack_dir.mkdir(parents=True, exist_ok=True)
        meta_path, prompt_path = pack_dir/"meta.json", pack_dir/"prompt.md"
        if force or not meta_path.exists():
            meta_path.write_text(json.dumps(meta, indent=2)+"\n", encoding="utf-8")
        if force or not prompt_path.exists():
            tmpl = ENRICHED_PROMPT_TEMPLATE.format(TITLE=meta["title"] or meta["slug"].title())
            prompt_path.write_text(tmpl, encoding="utf-8")
        if force or not (meta_path.exists() and prompt_path.exists()):
            created += 1
            print("[OK] ", pack_dir)
        else:
            skipped += 1
    print(f"[SUMMARY] created {created}, skipped {skipped}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source", help="CSV or JSON file")
    ap.add_argument("--category", default="sandbox")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()
    rows = load_rows(Path(args.source))
    scaffold(rows, Path("."), args.category, args.force)

if __name__ == "__main__":
    main()
