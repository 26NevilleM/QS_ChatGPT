#!/usr/bin/env python3
import argparse, json, pathlib, sys

REQUIRED_TOP_KEYS = ["id","name","version","agents","crosswalk","controls","checklists"]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    report = {"script": "smoketest_dp.py", "module": args.file, "results": []}

    p = pathlib.Path(args.file)
    if not p.exists():
        report["results"].append({"check":"file_exists","status":"FAIL"})
        report["overall"] = "FAIL"
    else:
        report["results"].append({"check":"file_exists","status":"PASS"})
        try:
            data = json.loads(p.read_text())
            report["results"].append({"check":"valid_json","status":"PASS"})
            # top-level keys
            missing = [k for k in REQUIRED_TOP_KEYS if k not in data]
            report["results"].append({"check":"top_level_keys","status":"PASS" if not missing else "FAIL","missing":missing})
            # identity
            report["results"].append({"check":"identity","status":"PASS","id":data.get("id"),"version":data.get("version")})
            # jurisdictions
            j = data.get("jurisdictions",{})
            report["results"].append({"check":"jurisdictions","status":"PASS" if j else "FAIL","found":list(j.keys())})
            # agents present
            agents = data.get("agents",{})
            report["results"].append({"check":"agents_prompts","status":"PASS" if all(agents.get(a,{}).get('prompt') for a in agents) else "FAIL"})
            report["results"].append({"check":"agents_present","status":"PASS" if {'navigator','picasso'}.issubset(set(agents.keys())) else "FAIL","found":list(agents.keys())})
            # crosswalk
            cw = data.get("crosswalk",{})
            report["results"].append({"check":"crosswalk_keys","status":"PASS" if cw else "FAIL"})
            # nonempty basics
            report["results"].append({"check":"crosswalk_nonempty","status":"PASS" if any(cw.get(k) for k in cw) else "FAIL"})
            # controls structure
            ctrls = data.get("controls",[])
            ctrl_ok = all(isinstance(c, dict) and {'id','name','owner','evidence'} <= set(c.keys()) for c in ctrls)
            report["results"].append({"check":"controls_schema","status":"PASS" if ctrl_ok else "FAIL","count":len(ctrls)})
            # checklists roles
            ch = data.get("checklists",{})
            must_roles = {'HR','Clinical','IT_SecOps','Marketing','Finance'}
            report["results"].append({"check":"checklists_roles","status":"PASS" if must_roles.issubset(set(ch.keys())) else "FAIL"})
            report["results"].append({"check":"checklists_nonempty","status":"PASS" if all(ch.get(r) for r in must_roles) else "FAIL"})
            # playbook – breach
            pb = data.get("playbooks",{}).get("breach_response",{})
            steps = pb.get("steps",[])
            report["results"].append({"check":"playbooks_breach_response","status":"PASS" if len(steps)>=5 else "FAIL","steps":len(steps)})
            # references
            refs = data.get("references",[])
            report["results"].append({"check":"references_nonempty","status":"PASS" if refs else "FAIL","count":len(refs)})
            report["overall"] = "FAIL" if any(r.get("status")=="FAIL" for r in report["results"]) else "PASS"
        except Exception as e:
            report["results"].append({"check":"valid_json","status":"FAIL","error":str(e)})
            report["overall"] = "FAIL"

    outp = pathlib.Path(args.out)
    outp.parent.mkdir(parents=True, exist_ok=True)
    outp.write_text(json.dumps(report, indent=2))
    print(f"Smoke test {'PASS' if report.get('overall')=='PASS' else 'FAIL'}. Report written to {outp}")
    if report.get("overall") == "FAIL":
        sys.exit(1)

if __name__ == "__main__":
    main()