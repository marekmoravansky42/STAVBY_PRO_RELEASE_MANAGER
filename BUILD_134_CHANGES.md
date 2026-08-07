# STAVBY PRO Release Manager 4.0.28 LTS – Build 134

## Oprava
- Opravený lint `use_build_context_synchronously` v diagnostickom dialógu.
- Globálny `BuildContext` navigátora sa po asynchrónnej medzere kontroluje cez `rootContext.mounted`.
- Diagnostické okno zostáva otvárané cez hlavný navigátor po uvoľnení busy vrstvy.
