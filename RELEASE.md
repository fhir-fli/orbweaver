# Releasing orbweaver to the Play Store and App Store

Audited 2026-09-01 against a clean tree at `2c5d3be`. Three things block a store
upload today. Everything else is ready.

## 🔴 Blockers

**1. Release builds are signed with the DEBUG key.** Measured, not inferred: a
release bundle built on 2026-09-01 reports

> Owner: C=US, O=Android, CN=Android Debug

`android/app/build.gradle.kts` has `signingConfig = signingConfigs.getByName("debug")`
inside the release block, and there is no `android/key.properties` and no keystore.
Google Play rejects a debug-signed bundle outright. Create an upload keystore, put
its details in `android/key.properties` (gitignored), and point the release
signingConfig at it.

**2. Both platforms still ship the stock Flutter logo.**
All five Android densities are byte-identical to the Flutter template, and the iOS
1024 icon is the Flutter logo. Apple rejects placeholder artwork; Play will take it
but nobody will install it. The icon sets themselves are complete — 5 Android
densities, 16 iOS entries — so this is artwork, not plumbing.

**3. There is no privacy policy, and both stores require a URL for every app.**
This one is cheap here, because the honest policy is almost empty. See below.

## ✅ What is already right

- **Identifiers match across platforms:** `dev.fhirfli.orbweaver` on both.
- **The app is genuinely offline.** No networking code, no analytics, no Firebase.
  Dependencies are `cupertino_icons`, `shared_preferences`, `url_launcher`, `yaml`.
- **No Android permissions are declared at all.**
- So the Play **Data safety** form and Apple's **App Privacy** are both "no data
  collected, no data shared", which is the simplest path either store offers.
  `url_launcher` opens `https:` and `mailto:` links out to the system browser; that
  is not collection, but say so in the listing if asked.

## The build works, and its size is not what it looks like

`flutter build appbundle --release` succeeds in about 70 s and produces a **67.2 MB**
`app-release.aab`. That number is the upload, not the download. Roughly 50 MB of it is
`BUNDLE-METADATA` — native debug symbols for all three ABIs plus an 8 MB ProGuard map —
which Play strips, and the three copies of `libflutter.so` and `libapp.so` are served as
per-device splits. What a phone actually downloads is the 18 MB of assets plus one ABI's
libraries. **That figure is an estimate from the bundle's contents, not a measurement**;
`bundletool build-apks --connected-device` gives the real one if it matters, and in a
low-bandwidth setting it does.

## ⚪ Worth fixing before the listing

- **Display name is inconsistent:** `android:label="orbweaver"` against iOS
  `CFBundleDisplayName = Orbweaver`. Pick one.
- **`version: 0.1.0+1`.** Fine to start, but every upload needs a higher build
  number, and Play will not accept a repeat.
- **`description:` in `pubspec.yaml` is one line** — "Clinical protocol renderer for
  mobile." The store listing needs its own copy anyway.
- **No `LICENSE` file.**
- Gradle 8.14.0, AGP 8.11.1 and Kotlin 2.2.20 all warn that Flutter support is being
  dropped soon. Not blocking today.

## 🛑 The account question, which is yours and not a technical one

Both stores gate some health apps behind an organisation account. That was hit
before with `fhirant` and settled there by releasing the APK directly rather than
forming an entity. **orbweaver is a different case and the difference may matter:**
it is a reference text that stores nothing and transmits nothing, not a record
system holding patient data. Whether that clears a personal developer account is a
judgement the store's reviewers make, not something the repo can answer.

## The privacy policy, written out

It needs to live at a public URL you control. The content is short because the app
does nothing:

> **orbweaver privacy policy.** orbweaver does not collect, store, transmit or share
> any personal or health information. It has no accounts, no analytics and no network
> access. Everything it displays is bundled with the app and read from the device.
> Preferences you set are stored only on your device. Links you tap open in your
> browser or mail app, which have their own policies. Contact: grey@fhirfli.dev
