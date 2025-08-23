from pathlib import Path
import json

root = Path("Q_Vault_v2.0.0_FULL")
changelog = root / "Vault" / "Changelog"
changelog.mkdir(parents=True, exist_ok=True)

# Pick the active bundle (update here if needed)
bundle = root / "Vault" / "Master" / "Q_Vault_v2.0.7_bundle.json"

def load_json(p: Path):
    if not p.exists():
        return None
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return None

# --- Collect referenced module file paths from the active bundle ------------
referenced = set()
b = load_json(bundle)

def add(path_str: str):
    if not path_str:
        return
    p = (root / "Vault" / "Modules" / path_str)
    # support absolute-like paths too
    q = root / path_str
    if p.exists():
        referenced.add(str(p))
    elif q.exists():
        referenced.add(str(q))

def walk_collect(node):
    if isinstance(node, dict):
        for k, v in node.items():
            # naive heuristic: strings that end with .json might be module refs
            if isinstance(v, str) and v.lower().endswith(".json"):
                add(v)
            else:
                walk_collect(v)
    elif isinstance(node, list):
        for v in node:
            walk_collect(v)

if isinstance(b, dict):
    walk_collect(b)

# --- Everything that exists under Modules -----------------------------------
modules_dir = root / "Vault" / "Modules"
all_modules = {str(p) for p in modules_dir.rglob("*.json")} if modules_dir.exists() else set()

# --- Snapshots (optional folder) --------------------------------------------
snapshots_dir = root / "Vault" / "Snapshots"
all_snapshots = {str(p) for p in snapshots_dir.glob("*.json")} if snapshots_dir.exists() else set()
# Nothing currently references snapshots programmatically here, so all are orphans by default
# You can add logic later if you model snapshot references somewhere.
orphan_snapshots = sorted(all_snapshots)

# --- Bundles in Master ------------------------------------------------------
master_dir = root / "Vault" / "Master"
all_bundles = {str(p) for p in master_dir.glob("*bundle.json")} if master_dir.exists() else set()
referenced_bundles = {str(bundle)} if bundle.exists() else set()
orphan_bundles = sorted(all_bundles - referenced_bundles)

# --- Modules orphans --------------------------------------------------------
orphans = sorted(all_modules - referenced)

report = {
    "bundle": str(bundle),
    "referenced_module_count": len(referenced),
    "modules_total": len(all_modules),
    "orphans_module_count": len(orphans),
    "orphans_modules": orphans,
    "bundles_total": len(all_bundles),
    "active_bundles": sorted(list(referenced_bundles)),
    "orphan_bundles": orphan_bundles,
    "snapshots_total": len(all_snapshots),
    "orphan_snapshots": orphan_snapshots,
}

out = changelog / "vault_cleanup_inventory.json"
out.write_text(json.dumps(report, indent=2), encoding="utf-8")
print(f"Wrote {out}")
