#!/usr/bin/env python3
"""Probe, 2026-11-09: can one orbweaver topic be expressed in HL7 FHIR CPG 2.0.0?

ProtocolBook p.42 (Paediatric convulsions) is converted BY HAND into CPG resources:
the mapping decisions are written out below, one resource at a time, not derived
by a general converter. Patterns are copied from the CPG IG 2.0.0 package examples
(PlanDefinition-chf-*, ActivityDefinition-chf-lasix-iv, Library-CHF).

Writes, one file per resource as it is built (flushed):
  out/<ResourceType>-<id>.json
  ledger.tsv   every fact printed on the page -> where it went in FHIR, and whether
               it is computable, text only, or lost.
The script asserts that every leaf of the topic YAML is named by at least one
ledger row, so the ledger cannot silently skip part of the page.

Codes were looked up 2026-11-09: RxNorm via rxnav.nlm.nih.gov, SNOMED and LOINC via
tx.fhir.org $expand. RxNorm has no diazepam 2.5 mg rectal suppository (only 10 mg,
rxcui 104706), so SNOMED International products are used throughout.
"""
import base64
import json
import sys

import yaml

from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from _repo import REPO  # noqa: E402

HERE = Path(__file__).resolve().parent
OUT = HERE / "out"
TOPIC = REPO / "assets/books/protocolbook/topics/pb_042_paediatric_convulsions.yaml"
CQL = HERE / "PaediatricConvulsions.cql"

BASE = "http://fhir-fli.github.io/orbweaver/fhir"
CPG = "http://hl7.org/fhir/uv/cpg/StructureDefinition"
SCT = "http://snomed.info/sct"
UCUM = "http://unitsofmeasure.org"
LIB = f"{BASE}/Library/PaediatricConvulsions"
DATE = "2026-11-09"

PROCESS = "http://hl7.org/fhir/uv/cpg/CodeSystem/cpg-common-process-cs"
ACTTYPE = "http://hl7.org/fhir/uv/cpg/CodeSystem/cpg-activity-type-cs"


def sct(code, display):
    return {"coding": [{"system": SCT, "code": code, "display": display}]}


ROUTE_IV = sct("47625008", "Intravenous route")
ROUTE_IM = sct("78421000", "Intramuscular route")
ROUTE_PR = sct("37161004", "Rectal route")
PHENOBARB = sct("780186002", "Phenobarbital only product in parenteral dose form")
DIAZ_IV = sct("778977002", "Diazepam only product in parenteral dose form")
DIAZ_PR = sct("778978007", "Diazepam only product in rectal dose form")
GLUCOSE = sct("785369003", "Glucose only product in parenteral dose form")

CAPS = [
    {"url": "http://hl7.org/fhir/StructureDefinition/cqf-knowledgeCapability", "valueCode": c}
    for c in ("shareable", "computable", "publishable")
]


def common(rtype, rid, title, description, extra_ext=()):
    return {
        "resourceType": rtype,
        "id": rid,
        "extension": CAPS + list(extra_ext),
        "url": f"{BASE}/{rtype}/{rid}",
        "version": "0.1.0",
        "name": "".join(w.capitalize() for w in rid.replace("_", "-").split("-")),
        "title": title,
        "status": "draft",
        "experimental": True,
        "date": DATE,
        "publisher": "FHIR-FLI orbweaver",
        "description": description,
    }


def narrative(res):
    """Minimal generated narrative (dom-6): title and description."""
    from html import escape
    body = f"<p><b>{escape(res.get('title', ''))}</b></p><p>{escape(res.get('description', ''))}</p>"
    return {"status": "generated", "div": f'<div xmlns="http://www.w3.org/1999/xhtml">{body}</div>'}


def write(res):
    res["text"] = narrative(res)
    OUT.mkdir(exist_ok=True)
    p = OUT / f"{res['resourceType']}-{res['id']}.json"
    with open(p, "w") as f:
        json.dump(res, f, indent=2)
        f.write("\n")
        f.flush()
    print(f"wrote {p.relative_to(HERE)}", flush=True)
    return res


def cql_id(name):
    return {"language": "text/cql-identifier", "expression": name, "reference": LIB}


def applicability(name):
    return [{"kind": "applicability", "expression": cql_id(name)}]


def med_activity(rid, title, description, product, route, dosage_text, dose_expr=None,
                 do_not_perform=False, max_per_admin=None, timing=None, dose_range=None):
    ad = common("ActivityDefinition", rid, title, description)
    ad["meta"] = {"profile": [f"{CPG}/cpg-medicationrequestactivity", f"{CPG}/cpg-computableactivity"]}
    ad["library"] = [LIB]
    ad["kind"] = "MedicationRequest"
    ad["profile"] = f"{CPG}/cpg-medicationrequest"
    ad["code"] = {"coding": [{"system": ACTTYPE, "code": "order-medication", "display": "Order a medication"}]}
    ad["intent"] = "proposal"
    ad["doNotPerform"] = do_not_perform
    ad["productCodeableConcept"] = product
    if not do_not_perform:
        dosage = {"sequence": 1, "text": dosage_text}
        if timing:
            dosage["timing"] = timing
        if route:
            dosage["route"] = route
        if dose_range:
            lo, hi, unit = dose_range
            dosage["doseAndRate"] = [{"doseRange": {
                "low": {"value": lo, "unit": unit, "system": UCUM, "code": unit},
                "high": {"value": hi, "unit": unit, "system": UCUM, "code": unit}}}]
        if max_per_admin:
            v, u = max_per_admin
            dosage["maxDosePerAdministration"] = {"value": v, "unit": u, "system": UCUM, "code": u}
        ad["dosage"] = [dosage]
    if dose_expr:
        ad["dynamicValue"] = [{
            "path": "dosageInstruction.doseAndRate.doseQuantity",
            "expression": cql_id(dose_expr),
        }]
    return write(ad)


def service_activity(rid, title, description, code_expr):
    ad = common("ActivityDefinition", rid, title, description)
    ad["meta"] = {"profile": [f"{CPG}/cpg-servicerequestactivity", f"{CPG}/cpg-computableactivity"]}
    ad["kind"] = "ServiceRequest"
    ad["profile"] = f"{CPG}/cpg-servicerequest"
    # The CPG profile fixes ActivityDefinition.code to the activity type, as in the IG's
    # orderservice example, so the clinical service code is supplied by dynamicValue.
    ad["library"] = [LIB]
    ad["code"] = {"coding": [{"system": ACTTYPE, "code": "order-service", "display": "Order a service"}]}
    ad["intent"] = "proposal"
    ad["doNotPerform"] = False
    ad["dynamicValue"] = [{"path": "code", "expression": cql_id(code_expr)}]
    return write(ad)


def ref(res):
    return res["url"]


def build():
    # ---- Library: the page's decision logic ----
    lib = common("Library", "PaediatricConvulsions", "Paediatric convulsions logic",
                 "Decision logic and weight-based doses for ProtocolBook p.42.")
    lib["type"] = {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/library-type",
                               "code": "logic-library"}]}
    lib["content"] = [{"contentType": "text/cql",
                       "data": base64.b64encode(CQL.read_bytes()).decode()}]
    lib["url"] = LIB
    write(lib)

    # ---- ActivityDefinitions ----
    pb_load = med_activity(
        "pb042-phenobarbital-load", "Phenobarbitone 20 mg/kg",
        "Loading dose. Only where respiratory monitoring is available: causes apnoea and hypotension.",
        PHENOBARB, None, "20 mg/kg stat", "Phenobarbital Load Dose")
    pb_load_imiv = med_activity(
        "pb042-phenobarbital-load-im-iv", "IM/IV phenobarbitone 20 mg/kg",
        "Loading dose after two doses of diazepam have failed. If given IV, give over 20 min.",
        PHENOBARB, {"coding": ROUTE_IM["coding"] + ROUTE_IV["coding"]}, "20 mg/kg IM or IV",
        "Phenobarbital Load Dose",
        timing={"repeat": {"duration": 20, "durationUnit": "min"}})
    pb_repeat = med_activity(
        "pb042-phenobarbital-repeat", "Phenobarbitone further 10 mg/kg",
        "Further dose if still fitting. Cumulative maximum 40 mg/kg.",
        PHENOBARB, None, "10 mg/kg; cumulative maximum 40 mg/kg", "Phenobarbital Repeat Dose")
    pb_maint_neo = med_activity(
        "pb042-phenobarbital-maintenance-neonate", "Phenobarbitone maintenance (neonate)",
        "Maintenance, starting 12-24 hours after the load.",
        PHENOBARB, None, "3-5 mg/kg daily",
        timing={"repeat": {"frequency": 1, "period": 1, "periodUnit": "d"}},
        dose_range=(3, 5, "mg/kg"))
    pb_maint_child = med_activity(
        "pb042-phenobarbital-maintenance-child", "Phenobarbitone maintenance (child)",
        "Maintenance IV/IM once daily for 48 hours, starting 12-24 hours after the load.",
        PHENOBARB, {"coding": ROUTE_IV["coding"] + ROUTE_IM["coding"]}, "3-5 mg/kg IV/IM OD x 48 hrs",
        timing={"repeat": {"frequency": 1, "period": 1, "periodUnit": "d",
                           "boundsDuration": {"value": 48, "unit": "h", "system": UCUM, "code": "h"}}},
        dose_range=(3, 5, "mg/kg"))
    diaz_neo_no = med_activity(
        "pb042-diazepam-not-neonate", "Do not give diazepam to neonates",
        "Do not give diazepam to neonates.", DIAZ_IV, None, "", do_not_perform=True)
    diaz_iv = med_activity(
        "pb042-diazepam-iv", "Diazepam 0.2 mg/kg IV",
        "IV slowly over 1 minute, maximum 10 mg.", DIAZ_IV, ROUTE_IV,
        "0.2 mg/kg IV slowly over 1 min (max 10 mg)", "Diazepam IV Dose", max_per_admin=(10, "mg"),
        timing={"repeat": {"duration": 1, "durationUnit": "min"}})
    diaz_pr = med_activity(
        "pb042-diazepam-pr", "Rectal diazepam 2.5 mg suppositories",
        "By weight: <10kg 1 suppository, 10-15kg 2, 15-20kg 3, 20-25kg 4.", DIAZ_PR, ROUTE_PR,
        "2.5 mg suppository: <10kg 1, 10-15kg 2, 15-20kg 3, 20-25kg 4")
    diaz_pr["dynamicValue"] = [{"path": "dosageInstruction.doseAndRate.doseQuantity.value",
                                "expression": cql_id("Rectal Diazepam Suppository Count")}]
    write(diaz_pr)
    d10 = med_activity(
        "pb042-dextrose-10", "Dextrose 10% 2 mL/kg IV", "Dextrose 10% 2 mL/kg IV.",
        GLUCOSE, ROUTE_IV, "Dextrose 10% 2 mL/kg IV", "Dextrose 10% Volume")
    glucose_check = service_activity(
        "pb042-check-glucose", "Check glucose", "Check blood glucose (alternative to giving dextrose).",
        "Blood Glucose Measurement Code")
    oxygen = service_activity(
        "pb042-oxygen", "Oxygen", "Start oxygen; continue during active seizure.",
        "Oxygen Therapy Code")

    def act(title, description=None, definition=None, condition=None, children=None,
            selection=None, aid=None, related=None, process=None):
        a = {"title": title}
        if aid:
            a["id"] = aid
        if description:
            a["description"] = description
        if process:
            a["code"] = [{"coding": [{"system": PROCESS, "code": process}]}]
        if condition:
            a["condition"] = applicability(condition)
        if related:
            a["relatedAction"] = related
        if selection:
            a["selectionBehavior"] = selection
        if definition:
            a["definitionCanonical"] = ref(definition)
        if children:
            a["action"] = children
        return a

    def after(target, minutes=None, low_h=None, high_h=None):
        r = {"actionId": target, "relationship": "after-start"}
        if minutes is not None:
            r["offsetDuration"] = {"value": minutes, "unit": "min", "system": UCUM, "code": "min"}
        if low_h is not None:
            r["offsetRange"] = {"low": {"value": low_h, "unit": "h", "system": UCUM, "code": "h"},
                                "high": {"value": high_h, "unit": "h", "system": UCUM, "code": "h"}}
        return [r]

    # ---- Recommendation: neonate (the red callout) ----
    rec_neo = common("PlanDefinition", "pb042-neonate-convulsions", "Convulsions in the 1st month of life",
                     "Phenobarbitone, not diazepam, for convulsions in the first month of life.")
    rec_neo["meta"] = {"profile": [f"{CPG}/cpg-recommendationdefinition", f"{CPG}/cpg-computableplandefinition"]}
    rec_neo["type"] = {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/plan-definition-type",
                                   "code": "eca-rule"}]}
    rec_neo["library"] = [LIB]
    rec_neo["action"] = [act(
        "Convulsions in the 1st month of life", condition="Is Neonate", children=[
            act("Phenobarbitone 20 mg/kg stat", aid="neo-load", definition=pb_load),
            act("If still fitting after 30 min, further 10 mg/kg", definition=pb_repeat,
                related=after("neo-load", minutes=30)),
            act("Maintenance 3-5 mg/kg daily", definition=pb_maint_neo,
                related=after("neo-load", low_h=12, high_h=24)),
            act("Do not give diazepam to neonates", definition=diaz_neo_no),
        ])]
    write(rec_neo)

    # ---- Recommendation: child over 1 month (the flowchart) ----
    observe = act("Check ABC, observe, investigate cause",
                  description="Check ABC. Observe. Investigate cause.")
    diazepam_choice = act("Diazepam IV or rectal", selection="exactly-one", children=[
        act("Diazepam 0.2 mg/kg IV slowly over 1 min (max 10 mg)", definition=diaz_iv),
        act("Rectal diazepam 2.5 mg suppository by weight", definition=diaz_pr),
    ])
    rec_child = common("PlanDefinition", "pb042-child-convulsions", "Paediatric convulsions over 1 month",
                       "Diazepam, then repeat diazepam, then phenobarbitone, at 5-minute intervals.")
    rec_child["meta"] = rec_neo["meta"]
    rec_child["type"] = rec_neo["type"]
    rec_child["library"] = [LIB]
    rec_child["action"] = [
        act("Treat fit and hypoglycaemia", aid="stage1", condition="Stage 1 Applies", children=[
            act("Ensure safety and check ABC"),
            act("Start oxygen", definition=oxygen),
            diazepam_choice,
            act("Dextrose 10% or check glucose", selection="exactly-one", children=[
                act("Dextrose 10% 2 mL/kg IV", definition=d10),
                act("Check glucose", definition=glucose_check),
            ]),
            act("Check ABCs when fit stops"),
        ]),
        act("Third convulsion lasting <5 min in <2 hours: phenobarbitone",
            description="Children with up to 2 fits lasting <5 mins do not require emergency drug treatment.",
            condition="Third Short Seizure In 2 Hours", definition=pb_load_imiv),
        act("Repeat diazepam", aid="stage2", condition="Still Convulsing After 10 Minutes",
            related=after("stage1", minutes=5), children=[
                diazepam_choice,
                act("Continue oxygen", definition=oxygen),
                act("Check ABCs when fit stops"),
            ]),
        act("Give IM/IV phenobarbitone 20 mg/kg", aid="stage3", condition="Still Convulsing After 15 Minutes",
            related=after("stage2", minutes=5), children=[
                act("Phenobarbitone 20 mg/kg IM/IV", aid="child-load", definition=pb_load_imiv),
                act("If still fitting after 15 min, further 10 mg/kg (cumulative max 40 mg/kg)",
                    description="Only where respiratory monitoring is available; bag-valve mask at the bedside.",
                    definition=pb_repeat, related=after("child-load", minutes=15)),
                act("Do not give more than 2 doses of diazepam in 24 hours once phenobarbitone used"),
                act("Maintenance phenobarbitone 3-5 mg/kg IV/IM OD x 48 hrs", definition=pb_maint_child,
                    related=after("child-load", low_h=12, high_h=24)),
                act("Continue oxygen during active seizure", definition=oxygen),
                act("Check ABCs when fit stops"),
                act("Investigate cause"),
            ]),
        observe,
    ]
    write(rec_child)

    # ---- Strategy: the page ----
    strat = common("PlanDefinition", "pb042-paediatric-convulsions", "Paediatric Convulsions",
                   "ProtocolBook p.42: treatment of paediatric convulsions.")
    strat["meta"] = {"profile": [f"{CPG}/cpg-strategydefinition", f"{CPG}/cpg-computableplandefinition"]}
    strat["type"] = {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/plan-definition-type",
                                 "code": "workflow-definition"}]}
    strat["library"] = [LIB]
    strat["action"] = [
        act("Convulsions in the 1st month of life", description="Neonates: phenobarbitone only.",
            definition=rec_neo, process="emergency-care"),
        act("Convulsions over 1 month", description="Diazepam, repeat diazepam, then phenobarbitone.",
            definition=rec_child, process="emergency-care"),
    ]
    write(strat)


# ---- Ledger: every fact on the page, by hand ----
# status: computable = a machine can act on it; text = carried as human-readable text only;
# lost = no place for it in the CPG resources.
LEDGER = [
    # yaml path, fact, status, where in FHIR, note
    ("topic.id", "topic id", "computable", "PlanDefinition.id/url", ""),
    ("topic.title", "title", "text", "PlanDefinition.title", ""),
    ("topic.list_subtitle", "list subtitle 'p.42 · diazepam → phenobarbitone'", "lost", "", "no list-display element"),
    ("topic.last_reviewed", "source edition 'pocketbook v1.7'", "lost", "", "PlanDefinition.lastReviewDate is a date; edition string has no place (relatedArtifact could cite it)"),
    ("topic.tags", "search tags (8)", "lost", "", "PlanDefinition.topic exists but needs codes; tags are free words"),
    ("topic.category", "category 'medical'", "lost", "", "no equivalent; topic/useContext need codes"),
    ("topic.page_number", "printed page 42", "lost", "", "no element; relatedArtifact could cite the page"),
    ("topic.blocks.0.type", "block is prose", "lost", "", "layout"),
    ("topic.blocks.0.callout", "shown as red alert callout", "lost", "", "no display semantics; action.priority could carry urgency, not appearance"),
    ("topic.blocks.0.palette", "callout colours (3)", "lost", "", "layout"),
    ("topic.blocks.0.title", "callout title / neonate scope", "computable", "rec_neo action condition 'Is Neonate'", "'1st month' read as AgeInMonths() < 1"),
    ("topic.blocks.0.markdown", "phenobarbitone 20 mg/kg stat", "computable", "AD pb042-phenobarbital-load + CQL dose", ""),
    ("topic.blocks.0.markdown", "further 10 mg/kg if still fitting after 30 min", "computable", "relatedAction offset 30 min + AD repeat", "'still fitting' has no condition expression in the neonate branch"),
    ("topic.blocks.0.markdown", "cumulative maximum 40 mg/kg", "text", "Dosage.text", "maxDosePerLifetime is lifetime and absolute; a per-episode, per-kg cap has no element"),
    ("topic.blocks.0.markdown", "only where respiratory monitoring is available", "text", "ActivityDefinition.description", "a setting precondition; no element"),
    ("topic.blocks.0.markdown", "phenobarbitone causes apnoea and hypotension", "text", "ActivityDefinition.description", ""),
    ("topic.blocks.0.markdown", "maintenance 3-5 mg/kg daily", "computable", "AD maintenance-neonate doseRange + timing", "doseRange in mg/kg is valid UCUM but not a per-patient dose"),
    ("topic.blocks.0.markdown", "maintenance starts 12-24 h after load", "computable", "relatedAction offsetRange 12-24 h", ""),
    ("topic.blocks.0.markdown", "do not give diazepam to neonates", "computable", "AD doNotPerform=true", ""),
    ("topic.blocks.0.markdown", "bold emphasis on doses", "lost", "", "layout"),
    ("topic.blocks.1.type", "block is flowchart", "lost", "", "layout"),
    ("topic.blocks.1.variant", "algorithm layout variant", "lost", "", "layout"),
    ("topic.blocks.1.boxes", "shared 'observe' box: Check ABC / Observe / Investigate cause", "text", "action title+description", "no code found for these acts"),
    ("topic.blocks.1.stages.0.decision", "age >1 month AND (convulsing >5 min OR presents convulsing)", "computable", "condition 'Stage 1 Applies'", "'presents convulsing' needs a current seizure observation; the >5 min arm and the presents arm collapse to one test"),
    ("topic.blocks.1.stages.0.outcomes.0.label", "Yes", "computable", "applicability condition true", ""),
    ("topic.blocks.1.stages.0.outcomes.0.box.title", "Treat fit and hypoglycaemia", "text", "action.title", ""),
    ("topic.blocks.1.stages.0.outcomes.0.box.bullets.0", "ensure safety and check ABC", "text", "action.title", "no code found"),
    ("topic.blocks.1.stages.0.outcomes.0.box.bullets.1", "start oxygen", "computable", "AD pb042-oxygen (SNOMED 57485005)", "no flow rate or target saturation on the page"),
    ("topic.blocks.1.stages.0.outcomes.0.box.bullets.2", "diazepam 0.2 mg/kg IV over 1 min, max 10 mg", "computable", "AD pb042-diazepam-iv", ""),
    ("topic.blocks.1.stages.0.outcomes.0.box.bullets.2", "OR rectal diazepam", "computable", "selectionBehavior exactly-one", ""),
    ("topic.blocks.1.stages.0.outcomes.0.box.bullets.2", "suppository weight bands", "computable", "CQL 'Rectal Diazepam Suppository Count'", "print does not say which band 10/15/20 kg falls in, nor what above 25 kg"),
    ("topic.blocks.1.stages.0.outcomes.0.box.bullets.3", "dextrose 10% 2 mL/kg IV", "computable", "AD pb042-dextrose-10", ""),
    ("topic.blocks.1.stages.0.outcomes.0.box.bullets.3", "(or check glucose)", "computable", "selectionBehavior exactly-one + AD check-glucose", "the print's 'or' is read as exactly one"),
    ("topic.blocks.1.stages.0.outcomes.0.box.bullets.4", "check ABCs when fit stops", "text", "action.title", "trigger 'fit stops' not expressed"),
    ("topic.blocks.1.stages.0.outcomes.0.continue", "continue to next stage", "computable", "relatedAction stage2 after stage1 +5 min", ""),
    ("topic.blocks.1.stages.0.outcomes.1.label", "No", "computable", "separate applicability condition", ""),
    ("topic.blocks.1.stages.0.outcomes.1.box.title", "3rd convulsion <5 min in <2 h?", "computable", "condition 'Third Short Seizure In 2 Hours'", "needs each seizure recorded as an Observation"),
    ("topic.blocks.1.stages.0.outcomes.1.box.bullets.0", "No -> check ABC, observe, investigate", "text", "observe action (unconditioned)", "the No-of-the-No branch has no condition"),
    ("topic.blocks.1.stages.0.outcomes.1.box.bullets.1", "Yes -> phenobarbitone", "computable", "action -> AD phenobarbital-load-im-iv", ""),
    ("topic.blocks.1.stages.0.outcomes.1.box.bullets.2", "up to 2 fits <5 min need no emergency drugs", "text", "action.description", ""),
    ("topic.blocks.1.stages.1.decision", "convulsion stops after 5 more minutes?", "computable", "condition 'Still Convulsing After 10 Minutes'", "read as total seizure duration >10 min"),
    ("topic.blocks.1.stages.1.outcomes.0.label", "Yes", "computable", "", ""),
    ("topic.blocks.1.stages.1.outcomes.0.goto", "Yes -> observe box", "text", "observe action", "no condition links stop -> observe"),
    ("topic.blocks.1.stages.1.outcomes.1.label", "No", "computable", "", ""),
    ("topic.blocks.1.stages.1.outcomes.1.box.title", "repeat diazepam", "text", "action.title", ""),
    ("topic.blocks.1.stages.1.outcomes.1.box.bullets.0", "diazepam IV or PR, dosing as above", "computable", "same ADs reused", ""),
    ("topic.blocks.1.stages.1.outcomes.1.box.bullets.1", "continue oxygen", "computable", "AD pb042-oxygen", ""),
    ("topic.blocks.1.stages.1.outcomes.1.box.bullets.2", "check ABCs when fit stops", "text", "action.title", ""),
    ("topic.blocks.1.stages.1.outcomes.1.continue", "continue", "computable", "relatedAction stage3 after stage2 +5 min", ""),
    ("topic.blocks.1.stages.2.decision", "convulsion stops after 5 more minutes?", "computable", "condition 'Still Convulsing After 15 Minutes'", ""),
    ("topic.blocks.1.stages.2.outcomes.0.label", "Yes", "computable", "", ""),
    ("topic.blocks.1.stages.2.outcomes.0.goto", "Yes -> observe box", "text", "observe action", ""),
    ("topic.blocks.1.stages.2.outcomes.1.label", "No", "computable", "", ""),
    ("topic.blocks.1.stages.2.outcomes.1.continue", "continue to terminal", "computable", "", ""),
    ("topic.blocks.1.terminal.title", "IM/IV phenobarbitone 20 mg/kg", "computable", "AD phenobarbital-load-im-iv", ""),
    ("topic.blocks.1.terminal.bullets.0", "further 10 mg/kg after 15 min", "computable", "relatedAction +15 min + AD repeat", "'still fitting' not tested at 15 min"),
    ("topic.blocks.1.terminal.bullets.0", "cumulative max 40 mg/kg", "text", "Dosage.text", "same gap as neonate"),
    ("topic.blocks.1.terminal.bullets.0", "only with respiratory monitoring; bag-valve mask at bedside", "text", "action.description", ""),
    ("topic.blocks.1.terminal.bullets.1", "no more than 2 diazepam doses in 24 h once phenobarbitone used", "text", "action.title", "maxDosePerPeriod is absolute and unconditional; the 'once phenobarbitone used' condition has no element"),
    ("topic.blocks.1.terminal.bullets.1", "if IV, give over 20 min", "computable", "Timing.repeat.duration 20 min", "attached to phenobarbitone; the print places it after the diazepam sentence"),
    ("topic.blocks.1.terminal.bullets.2", "maintenance 3-5 mg/kg IV/IM OD x 48 h from 12-24 h", "computable", "AD maintenance-child", ""),
    ("topic.blocks.1.terminal.bullets.2", "editorial note '(OE 2026-08-30 ...)'", "lost", "", "authoring provenance inside the bullet"),
    ("topic.blocks.1.terminal.bullets.3", "continue oxygen during active seizure", "computable", "AD pb042-oxygen", "'during active seizure' not expressed"),
    ("topic.blocks.1.terminal.bullets.4", "check ABCs when fit stops", "text", "action.title", ""),
    ("topic.blocks.1.terminal.bullets.5", "investigate cause", "text", "action.title", ""),
]


def leaves(node, path):
    if isinstance(node, dict):
        for k, v in node.items():
            yield from leaves(v, f"{path}.{k}")
    elif isinstance(node, list) and not path.endswith(".tags"):
        for i, v in enumerate(node):
            yield from leaves(v, f"{path}.{i}")
    else:
        yield path


def write_ledger():
    data = yaml.safe_load(TOPIC.read_text())
    paths = list(leaves(data, ""))
    paths = [p.lstrip(".") for p in paths]
    named = [r[0] for r in LEDGER]
    missing = [p for p in paths if not any(p == n or p.startswith(n + ".") for n in named)]
    unknown = [n for n in named if not any(p == n or p.startswith(n + ".") for p in paths)]
    with open(HERE / "ledger.tsv", "w") as f:
        f.write("yaml_path\tfact\tstatus\tfhir_location\tnote\n")
        for row in LEDGER:
            f.write("\t".join(row) + "\n")
            f.flush()
    counts = {}
    for r in LEDGER:
        counts[r[2]] = counts.get(r[2], 0) + 1
    print(f"yaml leaves {len(paths)}; ledger rows {len(LEDGER)}; {counts}", flush=True)
    if missing or unknown:
        print(f"UNCOVERED yaml leaves: {missing}", flush=True)
        print(f"ledger paths not in yaml: {unknown}", flush=True)
        sys.exit(1)


if __name__ == "__main__":
    build()
    write_ledger()
