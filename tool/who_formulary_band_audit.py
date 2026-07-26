#!/usr/bin/env python3
"""Audit WHO formulary weight-band VALUES against each dose's mg/kg regimen.
Flags: gross mismatch (implied mg/kg at band midpoint far from target) or
non-monotonic bands. Model-knowledge screen -> Grey OE/spot-checks flags."""
import yaml, re, os
F = "/home/grey/dev/fhir/orbweaver-wt/assets/books/who_imci/formulary.yaml"
OUT = "/home/grey/.claude/jobs/e8004895/tmp/whoaudit"; os.makedirs(OUT, exist_ok=True)
d = yaml.safe_load(open(F))["formulary"]
drugs = d["drugs"]
MID = [4.5, 8, 12.5, 17.5, 24.5]           # midpoints of 3-<6,6-<10,10-<15,15-<20,20-29
FRAC = {"¼":0.25,"½":0.5,"¾":0.75,"⅓":0.333,"⅔":0.667}
def qty(s):
    s = s.strip()
    if s in ("—","-","","calc","fixed") or s.startswith("("): return None, None
    ml = "ml" in s.lower()
    s2 = s.lower().replace("ml","").strip()
    # unicode fractions, possibly with leading int e.g. "1½"
    m = re.match(r"^(\d+)?\s*([¼½¾⅓⅔])$", s2)
    if m:
        v = (int(m.group(1)) if m.group(1) else 0) + FRAC[m.group(2)]; return v, ("ml" if ml else "unit")
    try: return float(s2), ("ml" if ml else "unit")
    except: return None, None
def strength(form):
    # returns (mg_per_unit, kind)  kind in tablet|liquid
    m = re.search(r"(\d+(?:\.\d+)?)\s*mg\s*/\s*(\d+(?:\.\d+)?)\s*ml", form)
    if m: return float(m.group(1))/float(m.group(2)), "liquid"
    m = re.search(r"(\d+(?:\.\d+)?)\s*mg", form)
    if m: return float(m.group(1)), "tablet"
    m = re.search(r"(\d+(?:\.\d+)?)\s*(?:µg|mcg)", form)
    if m: return float(m.group(1))/1000.0, "tablet"   # convert µg->mg
    return None, None
def regR(reg):
    # mg/kg low,high (convert µg/kg->mg/kg)
    m = re.search(r"(\d+(?:\.\d+)?)\s*(?:–|-|to)\s*(\d+(?:\.\d+)?)\s*(mg|µg|mcg)\s*/\s*kg", reg)
    if m:
        f = 0.001 if m.group(3)!="mg" else 1
        return float(m.group(1))*f, float(m.group(2))*f
    m = re.search(r"(\d+(?:\.\d+)?)\s*(mg|µg|mcg)\s*/\s*kg", reg)
    if m:
        f = 0.001 if m.group(2)!="mg" else 1
        return float(m.group(1))*f, float(m.group(1))*f
    return None, None

fh = open(os.path.join(OUT,"audit.tsv"),"w"); fh.write("drug\tlabel\tRlo\tRhi\tstrength\tkind\tband\tqty\timplied_mgkg\tstatus\n"); fh.flush()
flags=[]
for dr in drugs:
    for ds in dr.get("doses",[]):
        reg = ds.get("regimen",""); form = ds.get("form",""); bands = ds.get("bands",[])
        Rlo,Rhi = regR(reg)
        if Rlo is None: continue
        sr,kind = strength(form)
        if sr is None: continue
        # numeric band quantities
        vals=[]; ok=True
        for i,b in enumerate(bands[:5]):
            q,unit = qty(b)
            if q is None: vals.append(None); continue
            mg = q*sr
            imp = mg/MID[i] if i<len(MID) else None
            vals.append((q,imp))
        # monotonic check on present numeric qtys
        present=[(i,v[0]) for i,v in enumerate(vals) if v]
        mono = all(present[k][1] <= present[k+1][1]+1e-9 for k in range(len(present)-1))
        for i,v in enumerate(vals):
            if not v: continue
            q,imp = v
            # gross mismatch: implied < 0.5*Rlo or > 2*Rhi
            st = "ok"
            if imp < 0.5*Rlo: st="LOW?"
            elif imp > 2.0*Rhi: st="HIGH?"
            fh.write(f"{dr['name']}\t{ds.get('label','')}\t{Rlo}\t{Rhi}\t{sr}\t{kind}\t{i}\t{q}\t{round(imp,2)}\t{st}\n"); fh.flush()
            if st!="ok": flags.append((dr['name'],ds.get('label',''),f"band{i} ({['3-6','6-10','10-15','15-20','20-29'][i]}kg)",f"{q}x{sr}mg={round(q*sr)}mg -> {round(imp,1)} mg/kg vs target {Rlo}-{Rhi}",st))
        if not mono:
            flags.append((dr['name'],ds.get('label',''),"BANDS NON-MONOTONIC",str([b for b in bands[:5]]),"MONO"))
fh.close()
print(f"=== {len(flags)} FLAGS ===",flush=True)
for f in flags: print(" | ".join(f),flush=True)
print("(audit.tsv has every band's implied mg/kg)",flush=True)
