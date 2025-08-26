import sys, re, json, io, os
p=sys.argv[1]
raw=open(p,"r",encoding="utf-8").read()
s=re.sub(r'/\*.*?\*/', '', raw, flags=re.S)
s=re.sub(r'(^|[^\:])//.*?$', r'\1', s, flags=re.M)
s=re.sub(r',\s*([\]}])', r'\1', s)
obj=json.loads(s)
bak=p+".bak"
if not os.path.exists(bak):
    open(bak,"w",encoding="utf-8").write(raw)
open(p,"w",encoding="utf-8").write(json.dumps(obj, ensure_ascii=False, indent=2))
print("SANITIZED_OK", p)
