# App Store listing — every field, paste-ready

App ID **6808414486**, `Orbweaver Clinical Reference`, version 1.0.

🛑 **For TestFlight you do not need most of this.** Internal TestFlight testing —
up to 100 people on your own team — needs only an uploaded build. Screenshots,
description and keywords are required to submit for App Store REVIEW. If closed
testing is the goal right now, upload a build and go to the TestFlight tab
instead of filling this in.

🛑 **The WHO licence constrains this page.** Clause 8 forbids any suggestion that
WHO endorses the app, clause 9 forbids using the WHO name as branding, and
clause 3 requires saying the app is not WHO's. So the description states the
source factually and says plainly it is not WHO's. Do not add "WHO" to the app
name, subtitle or keywords.

---

## Subtitle (30)

    Offline paediatric protocols

## Promotional Text (170) — editable later without review

    Three clinical references in one offline app, written for district hospitals
    where the network is not dependable.

## Description (4000)

    Orbweaver is an offline clinical quick-reference for health workers in
    low-resource hospitals.

    It carries three references side by side:

    • Quick Reference: Basic Protocols in Paediatrics and Internal Medicine for
      Resource Limited Settings, by J. Grey Faulkenberry, MD MPH
    • Pocket book of hospital care for children, 2nd edition, published by the
      World Health Organization and reproduced under licence
    • WVEMS Prehospital Protocols, 2026 edition

    Everything is bundled with the app and read from the device. There is no
    network access, no account, no analytics and no advertising, and nothing you
    do in the app leaves your phone. It works in aeroplane mode, which is the
    point: it is written for hospitals where the network is not dependable.

    Protocols are laid out for a phone screen rather than reproduced as pages, so
    charts, dose tables and algorithms are readable without pinching and
    scrolling. Cross-references between the three books are tappable.

    A flag icon on every page opens your mail app with a report already carrying
    the page you were looking at, so errors can be reported in seconds.

    This app was not developed or published by the World Health Organization and
    should not be credited to it. WHO is not responsible for any changes made to
    the original content, and responsibility for this adaptation rests solely
    with the publisher of this app.

    Not a substitute for clinical judgement. Verify every dose against a current
    source before administering it.

## Keywords (100, comma separated, no spaces after commas)

    paediatric,pediatric,clinical,protocols,offline,reference,dosing,hospital,emergency,IMCI,global health

## Support URL

    https://fhir-fli.github.io/fhir_fli_documentation/

## Marketing URL

    (leave blank)

## Version

    1.0

## Copyright (200)

    2026 J. Grey Faulkenberry

---

## App Review Information

**Sign-in required:** NO. Everything is bundled; there is no login and no server.
Leave the username and password fields empty and untick the box.

**Contact:** your own name, phone and `greyzus@fhirfli.dev`.

**Notes** — this is the field that prevents a rejection. Paste this:

    This app reproduces the WHO Pocket book of hospital care for children, 2nd
    edition, under a non-exclusive licence granted by the World Health
    Organization on 3 September 2026, permissions request ID 202610340. The
    licence covers reproduction in this application for current and future
    releases, and both closed testing and a free public listing.

    The app requires no network connection and collects no data of any kind. It
    has no accounts, no analytics, no advertising and no in-app purchases, so
    there is no demo account to provide and nothing is hidden behind a login.

    The developer is a physician boarded in internal medicine, paediatrics and
    clinical informatics.

## App Store Version Release

Choose **Manually release this version**, so an approval does not put it live
before you are ready.

---

## Screenshots

Required: 6.5-inch iPhone, at 1242 × 2688 or 1284 × 2778. Only the first three
appear on the install sheet, so lead with the most useful pages.

Take them from the simulator on the Mac:

    flutter run -d "iPhone 15 Pro Max" --release

Then Cmd-S in the simulator saves a correctly sized screenshot to the desktop.

Suggested three, in order: a dose-bearing protocol page, a flowchart, and the
shelf showing all three books.
