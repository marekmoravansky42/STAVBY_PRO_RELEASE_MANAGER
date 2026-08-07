# STAVBY PRO Release Manager 4.0.14 LTS – Build 120

Oprava Build 119:
- odstránená nepoužívaná metóda _runFullWindowsBuild,
- nový krokový Windows workflow zostáva nezmenený,
- odstránené warning `unused_element`, ktorý zastavoval flutter analyze.

Poznámka:
Log `reusePort not supported for Windows` zo STAVBY PRO Build 138 je samostatná runtime vec synchronizácie a nie príčina zlyhania kompilácie Release Managera.
