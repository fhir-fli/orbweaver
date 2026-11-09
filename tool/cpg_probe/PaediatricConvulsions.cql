library PaediatricConvulsions version '0.1.0'

// Hand-written for the 2026-11-09 CPG probe: the decision logic of
// ProtocolBook p.42 (assets/books/protocolbook/topics/pb_042_paediatric_convulsions.yaml).
// Pattern follows the CPG IG 2.0.0 example Library-CHF (FHIR 4.0.1 + FHIRHelpers).

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "SNOMED-CT": 'http://snomed.info/sct'
codesystem "LOINC": 'http://loinc.org'

code "Body weight": '29463-7' from "LOINC" display 'Body weight'
code "Duration of seizure": '313289001' from "SNOMED-CT" display 'Duration of seizure'
code "Oxygen therapy": '57485005' from "SNOMED-CT" display 'Oxygen therapy'
code "Glucose measurement, blood": '33747003' from "SNOMED-CT" display 'Glucose measurement, blood'

parameter Encounter Encounter

context Patient

// ---- Case features ----

define "Latest Weight":
  Last(
    [Observation: "Body weight"] O
      where O.status in { 'final', 'amended', 'corrected' }
      sort by (effective as FHIR.dateTime)
  )

define "Weight kg":
  convert FHIRHelpers.ToQuantity("Latest Weight".value as FHIR.Quantity) to 'kg'

define "Weight Value kg":
  "Weight kg".value

// Every seizure recorded in this encounter, with its running duration in minutes.
define "Seizure Durations This Encounter":
  [Observation: "Duration of seizure"] O
    where O.status in { 'preliminary', 'final', 'amended', 'corrected' }
      and O.encounter.reference = 'Encounter/' + Encounter.id

define "Current Seizure":
  Last("Seizure Durations This Encounter" O sort by (effective as FHIR.dateTime))

define "Current Seizure Minutes":
  convert FHIRHelpers.ToQuantity("Current Seizure".value as FHIR.Quantity) to 'min'

// ---- Decisions printed on the page ----

// Callout: "Convulsions in the 1st month of life".
define "Is Neonate":
  AgeInMonths() < 1

define "Age Over One Month":
  AgeInMonths() >= 1

// Stage 1: "child convulsing for more than 5 minutes OR presents convulsing".
// "Presents convulsing" is represented as a current seizure observation of any duration.
define "Stage 1 Applies":
  "Age Over One Month"
    and "Current Seizure" is not null

// Stage 1 No-branch: "3rd convulsion lasting <5mins in <2 hours?"
define "Short Seizures In Last 2 Hours":
  "Seizure Durations This Encounter" O
    where (O.effective as FHIR.dateTime) during Interval[Now() - 2 hours, Now()]
      and FHIRHelpers.ToQuantity(O.value as FHIR.Quantity) < 5 'min'

define "Third Short Seizure In 2 Hours":
  "Age Over One Month"
    and Count("Short Seizures In Last 2 Hours") >= 3

// Stages 2 and 3: "Convulsion stops after 5 more minutes?"
define "Still Convulsing After 10 Minutes":
  "Current Seizure Minutes" > 10 'min'

define "Still Convulsing After 15 Minutes":
  "Current Seizure Minutes" > 15 'min'

// ---- Doses (all weight-based, so all computed) ----

define "Diazepam IV Dose":
  System.Quantity { value: Min({ 0.2 * "Weight Value kg", 10.0 }), unit: 'mg' }

// Printed bands: <10kg 1 · 10–15kg 2 · 15–20kg 3 · 20–25kg 4.
// The print does not say which band 10, 15 or 20 kg falls in, nor what to give above 25 kg.
// Here a boundary weight takes the higher band; above 25 kg returns null.
define "Rectal Diazepam Suppository Count":
  case
    when "Weight Value kg" < 10 then 1
    when "Weight Value kg" < 15 then 2
    when "Weight Value kg" < 20 then 3
    when "Weight Value kg" <= 25 then 4
    else null
  end

define "Dextrose 10% Volume":
  System.Quantity { value: 2.0 * "Weight Value kg", unit: 'mL' }

define "Phenobarbital Load Dose":
  System.Quantity { value: 20.0 * "Weight Value kg", unit: 'mg' }

define "Phenobarbital Repeat Dose":
  System.Quantity { value: 10.0 * "Weight Value kg", unit: 'mg' }

define "Phenobarbital Maintenance Dose Low":
  System.Quantity { value: 3.0 * "Weight Value kg", unit: 'mg' }

define "Phenobarbital Maintenance Dose High":
  System.Quantity { value: 5.0 * "Weight Value kg", unit: 'mg' }

// ---- Service codes (the CPG service activity profile fixes ActivityDefinition.code
// to the activity type, so the clinical code is supplied here) ----

define "Oxygen Therapy Code":
  Concept { codes: { "Oxygen therapy" } }

define "Blood Glucose Measurement Code":
  Concept { codes: { "Glucose measurement, blood" } }
