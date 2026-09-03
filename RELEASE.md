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

**2. Both platforms still ship the stock Flutter logo.** *(Pipeline ready — only the
artwork is missing. Drop a square 1024×1024 PNG at `assets/icon/orbweaver.png` and run
`dart run flutter_launcher_icons`; it writes all five Android densities and all sixteen
iOS entries. See `assets/icon/README.md` for the three constraints the artwork has to
survive.)*
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
`app-release.aab`. **That is the upload. An arm64 phone downloads about 24 MB.**

Measured, compressed, from the bundle:

| part | size | share |
|---|---|---|
| `BUNDLE-METADATA` | 27.9 MB | 41.7% |
| native libs, all three CPU architectures | 23.2 MB | 34.6% |
| assets, the books | 15.1 MB | 22.6% |
| dex, resources, manifest | 0.8 MB | 1.2% |

`BUNDLE-METADATA` is native debug symbols per architecture plus an 8 MB ProGuard map.
Play keeps those to turn obfuscated crash reports back into line numbers; they never
reach a device. The engine is compiled three times — arm64 7.8 MB, armv7 7.3 MB,
x86_64 8.0 MB — and a phone gets exactly one. The x86_64 copy serves emulators only.

So a device receives 15.1 + 7.8 + 0.8 = **23.7 MB**. In a low-bandwidth setting that is
the number that matters. `bundletool build-apks --connected-device` confirms it exactly
if you want it from the tool rather than from the archive.

## ⚪ Worth fixing before the listing

- **Display name is inconsistent:** `android:label="orbweaver"` against iOS
  `CFBundleDisplayName = Orbweaver`. Pick one.
- **`version: 0.1.0+1`.** Fine to start, but every upload needs a higher build
  number, and Play will not accept a repeat.
- **`description:` in `pubspec.yaml` is one line** — "Clinical protocol renderer for
  mobile." The store listing needs its own copy anyway.
- Gradle 8.14.0, AGP 8.11.1 and Kotlin 2.2.20 all warn that Flutter support is being
  dropped soon. Not blocking today.

## ✅ Content rights — WHO licence GRANTED

**Request ID 202610340, granted 2026-09-03.** Non-exclusive, worldwide, royalty-free,
covering current and future releases and both closed testing and a free public listing.
No further request is needed at public release. Every condition, and the two that
required changes to the app, are in `WHO-LICENCE.md`. **Do not re-raise this.**

**The WVEMS protocols.** No copyright statement was found on the first three pages of
the 2026 PDF. WVEMS is the authority for crews operating under it. Whether
redistribution needs their sign-off is a question for them, and it is now the only
content-rights item left open.

**The ProtocolBook is yours**, so it raises nothing.

**Image attribution: ✅ done.** The Wikimedia images are CC BY, CC BY-SA and CC0, and
`assets/credits.yaml` is now rendered by an in-app credits screen, which is what those
licences require.


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
> browser or mail app, which have their own policies. Contact: greyzus@fhirfli.dev
