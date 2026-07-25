#!/usr/bin/env python3
"""Clean-room per-age pediatric doses = (our drug cards' mg/kg) x (cited weight-for-age).
Writes an auditable TSV. DRAFT for clinical verification."""
import os
OUT = "/home/grey/.claude/jobs/e8004895/tmp/peds"; os.makedirs(OUT, exist_ok=True)

# age -> (weight kg, age in years). Weight = approx 50th-%ile (Grey confirms/adjusts).
AGES = [("Newborn",3.5,0.0),("6 mo",8,0.5),("1 yr",10,1),("2 yr",12,2),("4 yr",16,4),
        ("6 yr",20,6),("8 yr",25,8),("10 yr",32,10),("12 yr",40,12)]

def fmt(x):
    x = round(x, 3)
    return str(int(x)) if x == int(x) else str(x).rstrip("0").rstrip(".")

# (category, short name, route, unit, lo/kg, hi/kg, floor, cap, step, min_age_yr, note)
# Short names = WVEMS drug-card names. Unit is shown in the frozen Drug column
# ("Name (unit)") so age cells stay unitless & narrow (avoids scroll-row overflow).
D = [
 ("Resuscitation","Epi","IV/IO","mg",0.01,0.01,None,1,0.005,0,"CODE/Brady; = 0.1 mL/kg of 0.1 mg/mL; max 1 mg"),
 ("Resuscitation","Adenosine 1st","IV/IO","mg",0.1,0.1,None,6,0.05,0,"rapid push + flush; max 6 mg"),
 ("Resuscitation","Adenosine 2nd","IV/IO","mg",0.2,0.2,None,12,0.05,0,"max 12 mg"),
 ("Resuscitation","Amiodarone","IV/IO","mg",5,5,None,300,1,0,"CODE; max 300 mg; Q5min x3"),
 ("Resuscitation","Atropine","IV/IO","mg",0.02,0.02,None,0.5,0.01,0,"no minimum (PALS 2020); max 0.5 mg"),
 ("Resuscitation","Calcium","IV/IO","mg",20,20,None,1000,10,0,"over 10 min (bolus in CODE)"),
 ("Resuscitation","Bicarb","IV/IO","mEq",1,1,None,50,1,0,"max 50 mEq"),
 ("Resuscitation","D10","IV/IO","mL",5,5,None,250,5,0,"= 0.5 g/kg"),
 ("Resuscitation","NS bolus","IV/IO","mL",20,20,None,1000,10,0,"limit x3 (60 mL/kg)"),
 ("Resuscitation","3% Saline","IV/IO","mL",2,5,None,250,5,0,"TBI; over 10 min"),
 ("Resuscitation","Magnesium","IV/IO","mg",25,50,None,2000,10,0,"over 10 min; max 2 g"),
 ("Resuscitation","Narcan","IV/IO/IM/IN","mg",0.1,0.1,None,2,0.1,0,"FDA initial 0.01 mg/kg, titrate; max ~2 mg"),
 ("Seizure / Sedation","Ativan","IV/IO/IM/IN","mg",0.1,0.1,None,4,0.05,0,"lorazepam SE 0.1 mg/kg; max 4 mg [OE]"),
 ("Seizure / Sedation","Versed","IV/IO/IM/IN","mg",0.1,0.2,None,10,0.05,0,"midazolam SE 0.1-0.2 mg/kg; max 10 mg [OE]"),
 ("Seizure / Sedation","Ketamine","IV/IO/IM/IN","mg",0.25,0.5,None,None,0.5,0,"pain; higher for Critical Care"),
 ("Seizure / Sedation","Keppra","IV/IO","mg",40,60,None,4500,10,0.25,"levetiracetam SE loading 40-60 mg/kg; 3+ mo; max 4.5 g [OE]"),
 ("Airway / RSI","Etomidate","IV/IO","mg",0.3,0.3,None,None,0.5,10,"10+ y/o only per card"),
 ("Airway / RSI","Rocuronium","IV/IO","mg",1,1,None,None,1,0.25,"RSI 1 mg/kg (OE 1.0-1.2); 3+ months [OE]"),
 ("Airway / RSI","Succinylcholine","IV/IO","mg",2,2,None,150,1,0,""),
 ("Analgesia / Other","Fentanyl","IV/IO/IM/IN","mcg",0.5,2,None,100,1,0,"max ~100 mcg"),
 ("Analgesia / Other","Morphine","IV/IO/IM/IN","mg",0.1,0.2,None,4,0.5,0,"max ~4 mg"),
 ("Analgesia / Other","Toradol","IV/IO/IM/IN","mg",0.5,0.5,None,15,1,2,"ketorolac; 2+ y/o; max 15 mg"),
 ("Analgesia / Other","Zofran","IV/IO/IM/IN","mg",0.1,0.1,None,4,0.5,0,"ondansetron; max 4 mg"),
 ("Analgesia / Other","Benadryl","IV/IO/IM","mg",1,1,None,50,1,0,"diphenhydramine; max 50 mg"),
 ("Analgesia / Other","Decadron","IV/IO/IM","mg",0.6,0.6,None,12,0.5,0,"dexamethasone; croup; max 12 mg"),
 ("Analgesia / Other","Lasix","IV/IO/IM","mg",1,2,None,40,1,0,"furosemide; max 40 mg"),
 ("Analgesia / Other","TXA","IV/IO","mg",15,20,None,1000,10,0,"over 10 min; max 1 g (then 2 mg/kg/hr)"),
 ("Analgesia / Other","Ibuprofen","PO","mg",10,10,None,600,10,0.5,"6+ mo; max ~600 mg"),
 ("Analgesia / Other","Tylenol","PO/IV","mg",15,15,None,1000,10,0,"acetaminophen; max ~1 g"),
 ("Antibiotics / Antidote","Ancef","IV/IO/IM","mg",25,30,None,2000,10,0,"cefazolin; max 2 g"),
 ("Antibiotics / Antidote","Rocephin","IV/IO/IM","mg",50,50,None,2000,10,0,"ceftriaxone sepsis; meningitis 100 mg/kg max 4 g"),
 ("Antibiotics / Antidote","CyanoKit","IV/IO","mg",70,70,None,5000,10,0,"hydroxocobalamin; over 10 min; max 5 g"),
 # Infusions: unit = mcg/min (= mcg/kg/min x weight). TITRATE to effect; mix per pump.
 ("Infusions (titrate)","Dopamine","IV/IO pump","mcg/min",5,20,None,None,5,0,"5-20 mcg/kg/min; titrate"),
 ("Infusions (titrate)","Levophed","IV/IO pump","mcg/min",0.05,0.5,None,None,0.1,0,"norepi 0.05-0.5 mcg/kg/min; 4 mg in 250 mL"),
 ("Infusions (titrate)","Lopressor","IV/IO pump","mcg/min",0.5,0.5,None,None,0.5,0,"metoprolol 0.5 mcg/kg/min"),
]
# Dose/kg display override (infusions are mcg/kg/min, not mcg/min/kg)
PK_OVERRIDE = {"Dopamine":"5–20 mcg/kg/min","Levophed":"0.05–0.5 mcg/kg/min","Lopressor":"0.5 mcg/kg/min"}

def one(perkg, floor, cap, step, unit, w):
    v = perkg * w
    if floor is not None and v < floor: v = floor
    capped = cap is not None and v > cap
    if capped: v = cap
    if step: v = round(v/step)*step
    return fmt(v), unit, capped

def cell(lo, hi, floor, cap, step, unit, w, min_age, yr):
    # unitless number (unit shown in the frozen Drug column); * = capped, — = below min age
    if yr < min_age: return "—"
    l, _, lc = one(lo, floor, cap, step, unit, w)
    h, _, hc = one(hi, floor, cap, step, unit, w)
    if l == h:
        return l + ("*" if lc else "")
    return f"{l}–{h}" + ("*" if hc else "")

fh = open(os.path.join(OUT, "doses.tsv"), "w")
hdr = ["Category","Drug","Dose/kg","Note"] + [a for a,_,_ in AGES]
fh.write("\t".join(hdr) + "\n"); fh.flush()
print("weights: " + " | ".join(f"{a} {w}kg" for a,w,_ in AGES), flush=True)
for cat,name,route,unit,lo,hi,floor,cap,step,minage,note in D:
    drug = f"{name} ({unit})"                                  # unit frozen in Drug col
    pk = PK_OVERRIDE.get(name, (fmt(lo) if lo==hi else f"{fmt(lo)}–{fmt(hi)}") + f" {unit}/kg")
    cells = [cell(lo,hi,floor,cap,step,unit,w,minage,yr) for _,w,yr in AGES]
    fh.write("\t".join([cat,drug,pk,note]+cells) + "\n"); fh.flush()
    print(f"{drug[:22]:22s} {pk[:14]:14s} | NB={cells[0]}  1yr={cells[2]}  8yr={cells[6]}", flush=True)
fh.close()
print("DONE -> doses.tsv  (* = capped, — = below min age)", flush=True)
