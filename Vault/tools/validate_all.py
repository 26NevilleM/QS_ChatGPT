#!/usr/bin/env python3
import json, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]  # repo root
PL = ROOT / "Vault/Prompt_Library"

REQUIRED_SETS = [
    PL / "active",
    PL / "sandbox",
]

def validate_dir(dirpath):
    errors, warns = [], []
    if not dirpath.exists():
        return errors, warns  # sandbox may be empty
    for prompt_dir in dirpath.iterdir():
        if not prompt_dir.is_dir():
            continue
        pmd = prompt_dir / "prompt.md"
        meta = prompt_dir / "meta.json"
        # Hard errors
        if not pmd.exists(): errors.append(f"missing:{pmd}")
        if not meta.exists():
            errors.append(f"missing:{meta}")
        else:
            try:
                data = json.loads(meta.read_text(encoding="utf-8"))
                if not isinstance(data, dict):
                    errors.append(f"bad_meta_not_object:{meta}")
            except Exception as e:
                errors.append(f"bad_meta_json:{meta}:{e}")

        # Soft warnings
        if pmd.exists():
            try:
                txt = pmd.read_text(encoding="utf-8")
                if txt.count("!") >= 5:
                    warns.append(f"WARN excessive_exclamation:{prompt_dir.name}:{txt.count('!')}")
                if "not legal advice" not in txt.lower():
                    warns.append(f"WARN legal_disclaimer_missing:{prompt_dir.name}")
            except Exception as e:
                errors.append(f"unreadable:{pmd}:{e}")
    return errors, warns

def main():
    all_errors, all_warns = [], []
    for d in REQUIRED_SETS:
        e, w = validate_dir(d)
        all_errors.extend(e)
        all_warns.extend(w)

    # Output
    for w in all_warns:
        print(w)
    for e in all_errors:
        print(e, file=sys.stderr)

    if all_errors:
        print(f"VALIDATION_FAILED errors={len(all_errors)} warns={len(all_warns)}", file=sys.stderr)
        sys.exit(1)
    else:
        print("ALL_VALIDATIONS_OK")

if __name__ == "__main__":
    main()