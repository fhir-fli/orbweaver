# Orbweaver

**An offline clinical quick-reference app for health workers in low-resource hospitals.**

Orbweaver carries three clinical references side by side, laid out for a phone screen rather than reproduced as scanned pages, so dose tables, flowcharts and algorithms are readable without pinching and scrolling:

- *Quick Reference: Basic Protocols in Paediatrics and Internal Medicine for Resource Limited Settings* (the ProtocolBook), by J. Grey Faulkenberry, MD MPH
- *Pocket book of hospital care for children*, 2nd edition, World Health Organization, reproduced under licence
- *WVEMS Prehospital Protocols*, 2026 edition

Everything is bundled with the app and read from the device. There is no network access, no account, no analytics and no advertising. It works in aeroplane mode. Cross-references between the books are tappable, dose calculators work from the patient's weight, and a flag on every page opens a pre-filled error report.

This app was not developed or published by the World Health Organization and should not be credited to it. It is not a substitute for clinical judgement: verify every dose against a current source before giving it.

## Getting the app

Orbweaver is in closed testing on Google Play; it is not yet in a public store. To join the test, email grey@fhirfli.dev with the address you use for Google Play.

## Running it from source

You need [Flutter](https://docs.flutter.dev/get-started/install) (stable channel, Dart 3.11 or newer).

```bash
git clone https://github.com/fhir-fli/orbweaver.git
cd orbweaver
flutter pub get
flutter run          # on a connected phone, an emulator, or the desktop
flutter test         # the test suite
```

## Writing pages for it

Every page is a YAML topic file; the app is only a renderer. The [Orbweaver playground](https://fhir-fli.github.io/fhir_fli_documentation/docs/demos/orbweaver_demo) renders a topic in the browser and checks it against the published JSON Schema, and the [authoring reference](https://fhir-fli.github.io/fhir_fli_documentation/docs/orbweaver/orbweaver_authoring) explains every block. [SCHEMA.md](SCHEMA.md) describes the schemas and [docs/](docs/) the interactive blocks (formulas, scores, unit conversions).

## Clinical review

The ProtocolBook is being audited page by page against WHO guidance, the Uganda Clinical Guidelines 2023, Cochrane reviews and itself. Questions waiting on a clinical answer are in [OPENEVIDENCE.md](OPENEVIDENCE.md); its first line gives how many are open. Rulings are kept under `tool/crossbook/` and `tool/protocolbook_source_errata.md`.

## License

The software (everything under `lib/`, `test/`, `tool/`, the platform folders and the project configuration) is MIT. The books under `assets/books/` are **not**: each carries its own terms, and cloning this repository gives no right to redistribute them. See [LICENSE](LICENSE) and [WHO-LICENCE.md](WHO-LICENCE.md).

## Contact

grey@fhirfli.dev · [GitHub issues](https://github.com/fhir-fli/orbweaver/issues)
