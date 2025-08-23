import json, pathlib, sys
root = pathlib.Path("Q_Vault_v2.0.0_FULL")
conf = root/"Vault/Modules/Config/Config_Master.json"

def load_json(p): 
    with open(p, "r", encoding="utf-8") as f: return json.load(f)

cfg = load_json(conf)
bundle_rel = cfg["orchestrator"]["default_bundle"]      # e.g. Vault/Master/Q_Vault_v2.0.7_bundle.json
bundle = root/bundle_rel
b = load_json(bundle)

# Heuristic: collect referenced module paths from bundle + Config
referenced = set()
def add(p): 
    p = str(pathlib.Path("Q_Vault_v2.0.0_FULL")/p) if not str(p).startswith("Q_Vault_v2.0.0_FULL") else str(p)
    referenced.add(p)

# bundle might list modules under common keys; collect any *.json under Vault/Modules
def walk_collect(d):
    if isinstance(d, dict):
        for k, v in d.items(): walk_collect(v)
    elif isinstance(d, list):
        for v in d: walk_collect(v)
    elif isinstance(d, str) and d.endswith(".json"):
        if "/Vault/Modules/" in d or d.startswith("Vault/Modules/") or d.startswith("Q_Vault_v2.0.0_FULL/Vault/Modules/"):
            add(d)

walk_collect(b)

# Everything that exists under Modules
all_modules = { str(p) for p in (root/"Vault/Modules").rglob("*.json") }

# Report
orphans = sorted(all_modules - referenced)
report = {
  "bundle": str(bundle),
  "referenced_count": len(referenced),
  "modules_total": len(all_modules),
  "orphans_count": len(orphans),
  "orphans": orphans
}
out = root/"Vault/Changelog/vault_cleanup_inventory.json"
out.write_text(json.dumps(report, indent=2), encoding="utf-8")
print(f"Wrote {out}")
