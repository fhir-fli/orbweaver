# App icon

Put a **square 1024 x 1024 PNG** here as `orbweaver.png`, then run:

    dart run flutter_launcher_icons

That writes the five Android mipmap densities and all sixteen iOS entries from
the one file. Nothing else needs editing.

## Why this directory exists empty

Both platforms currently ship the **stock Flutter logo**. All five Android
densities are byte-identical to the Flutter template and the iOS 1024 is the
Flutter mark. Apple rejects placeholder artwork, and Play will accept it but
nobody installs an app wearing the framework's logo.

## What the icon has to survive

- **No alpha channel on iOS.** The App Store rejects it. `remove_alpha_ios: true`
  in `pubspec.yaml` strips it, flattening onto white.
- **Android masks it.** A circle, a squircle or a rounded square depending on the
  launcher, so keep the meaningful part inside the middle ~66% and let the rest
  be background.
- **It is read at 48 px.** Whatever it is has to be legible at the size of a
  fingernail, which rules out fine line work and text.
