#!/usr/bin/env python3
import argparse, json, sys, pathlib

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bundle", required=True)
    ap.add_argument("--expect-version", required=True)
    ap.add_argument("--check-modules", default="")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    out = {"bundle": args.bundle, "expect_version": args.expect_version, "script": "run_smoketest.py v1.0", "results": []}

    bundle_path = pathlib.Path(args.bundle)
    if not bundle_path.exists():
        out["results"].append({"check": "bundle_exists", "status": "FAIL", "path": str(bundle_path)})
        out["overall"] = "FAIL"
    else:
        out["results"].append({"check": "bundle_exists", "status": "PASS", "path": str(bundle_path)})
        try:
            data = json.loads(bundle_path.read_text())
            ver = data.get("version")
            if ver == args.expect_version:
                out["results"].append({"check": "version", "status": "PASS", "found": ver})
            else:
                out["results"].append({"check": "version", "status": "FAIL", "found": ver, "expected": args.expect_version})
            # modules
            if args.check_modules:
                for m in args.check_modules.split(","):
                    m = m.strip()
                    if not m:
                        continue
                    mp = pathlib.Path(m)
                    status = "PASS" if mp.exists() else "FAIL"
                    out["results"].append({"check": f"module {m}", "status": status, "path": str(mp.resolve()) if mp.exists() else str(mp)})
        except Exception as e:
            out["results"].append({"check": "bundle_json", "status": "FAIL", "error": str(e)})

        # overall
        out["overall"] = "FAIL" if any(r.get("status")=="FAIL" for r in out["results"]) else "PASS"

    pathlib.Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(args.out).write_text(json.dumps(out, indent=2))
    print(f"Smoke test complete. Report written to {args.out}")

    if out["overall"] == "FAIL":
        sys.exit(1)

if __name__ == "__main__":
    main()