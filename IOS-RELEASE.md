# Orbweaver on the App Store — the walkthrough

Written 2026-09-03 against a clean tree. Everything here is done ON THE MAC,
except the parts already committed from Linux, which are marked ✅.

The Android side is further along; `RELEASE.md` covers it and the two are
independent. `WHO-LICENCE.md` applies to both.

---

## Before you start

**Apple Developer Program membership: ✅ Grey already has one** (confirmed
2026-09-03). Noted only so nobody re-raises it: it is $99/year against Play's
one-off $25, and it is the gate that would otherwise take days.

**You need a Mac with Xcode.** Not optional and not emulatable: the iOS toolchain
only runs on macOS. A Linux checkout cannot build, sign or upload an iOS app.

## What is already done ✅

- Bundle identifier `dev.fhirfli.orbweaver`, the same string as Android.
- Display name `Orbweaver`.
- Deployment target iOS 13.0.
- All 15 app icon entries generated and committed. `Contents.json` declares 15
  and all 15 are present, verified by opening the catalogue rather than counting
  files.
- `ITSAppUsesNonExemptEncryption` = `false` in `Info.plist`. Without it, App
  Store Connect stops every single upload to ask the export-compliance question
  by hand. The app has no networking and no crypto, so the answer is false.
  **Revisit this if networking is ever added.**
- No permission strings are needed. The app requests nothing: no camera, no
  photos, no location, no microphone. An `Info.plist` with no `NS*UsageDescription`
  keys is correct here, not an oversight.

## On the Mac

### 1. Get the code and its dependencies

    git clone https://github.com/fhir-fli/orbweaver.git
    cd orbweaver
    flutter pub get
    flutter build ios --release --no-codesign

🛑 **Do not run `pod install` first — it fails with "No Podfile found".** The
Podfile is not in the repository and is not meant to be: Flutter generates it,
and only during an iOS build. `flutter build ios` writes `ios/Podfile`, runs
`pod install` itself, and compiles without needing a signing team yet, so it also
surfaces any other missing tooling early.

Two plugins carry iOS platform code and genuinely need pods: `url_launcher` and
`shared_preferences`. If CocoaPods itself is missing: `sudo gem install cocoapods`.

### 2. Set the signing team

    open ios/Runner.xcworkspace

Open the **workspace**, not the `.xcodeproj` — the project alone will not build
once CocoaPods is involved.

Select **Runner** in the navigator, then **Signing & Capabilities**. Tick
*Automatically manage signing* and pick your team. Xcode creates the App ID and
the provisioning profile. `CODE_SIGN_STYLE` is already `Automatic`; only the team
is unset, because it is tied to your Apple account and cannot be committed.

### 3. Create the app record

App Store Connect → **My Apps** → **+** → **New App**.

- Platform: iOS
- Name: `Orbweaver`
- Primary language: English (U.S.)
- Bundle ID: `dev.fhirfli.orbweaver` — it appears in the dropdown after step 2
- SKU: anything unique and internal, e.g. `orbweaver-001`

### 4. Build and upload

    flutter build ipa --release

Then either open `build/ios/archive/Runner.xcarchive` in Xcode's Organizer and
use **Distribute App**, or upload straight from the command line:

    xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
      -u YOUR_APPLE_ID --password YOUR_APP_SPECIFIC_PASSWORD

Generate the app-specific password at appleid.apple.com. Do not use your account
password, and do not put either in this repo.

### 5. TestFlight

The build appears in TestFlight after processing, usually 10–30 minutes. Internal
testing, up to 100 people on your own team, needs no review. External testing,
up to 10,000, needs a short Beta App Review, normally a day.

For a handful of named clinicians, internal testing is the faster path.

## What Apple will ask that Google did not

**Export compliance.** Answered in advance by the `Info.plist` key above.

**Privacy nutrition labels.** Every answer is "no data collected". The app has no
network code, no analytics and no advertising. The published policy is at
`https://fhir-fli.github.io/fhir_fli_documentation/orbweaver-privacy`. Apple, unlike
Play at the closed-testing stage, wants the privacy URL immediately.

**Screenshots**, for at least a 6.7-inch iPhone. Take these from the simulator:
`flutter run` on an iPhone 15 Pro Max, then Cmd-S in the simulator.

**A demo account**, if reviewers cannot see the content without one. Not
applicable here: everything is bundled and there is no login. Say so in the review
notes so nobody assumes a wall.

⚠️ **Review notes are worth writing carefully.** This is a clinical reference app
reproducing WHO material. State that permission was granted, and give the request
ID **202610340**. A reviewer who wonders about the copyright and finds no answer
will reject and cost you a round trip.

## What is NOT set up

**macOS is not a target.** There is no `macos/` directory. The Mac App Store would
need `flutter create --platforms=macos .` first, plus a real look at whether a
phone-shaped reference reads well in a desktop window. That is a separate piece of
work, not a checkbox.
