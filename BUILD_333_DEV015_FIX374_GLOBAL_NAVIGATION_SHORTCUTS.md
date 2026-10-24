# FIX374 – globálne Ctrl+1 až Ctrl+9

Identita: 8.0.0 RC1, Build 333, RC1 DEV015 FIX374.

Pôvodný CallbackShortcuts závisel od fokusu v podstrome hlavnej obrazovky,
rozpoznával iba logické číslice a povoľoval opakovanie klávesu. Nový globálny
FocusManager handler používa horný fyzický číselný rad aj na slovenskej
klávesnici. Naviguje iba pri prvom Ctrl+číslo bez ďalších modifikátorov,
mimo textových vstupov a iba keď je hlavná route aktuálna. Otvorený dialóg
neprepína ani nezatvára. Pri odstránení komponentu sa handler odregistruje.
Existujúca ochrana pri busy stave a navigačné akcie ostávajú zachované.

Mapovanie z pomocníka: 1 Dashboard, 2 Projekt, 3 APK, 4 WINDOWS,
5 GitHub, 6 Release Wizard, 7 Git, 8 Plugin Center, 9 Release Pipeline.

## Kontroly

- Cielené Flutter testy s `--no-pub`: `test/fix374_navigation_shortcuts_test.dart`,
  `test/fix350_final_publish_center_reentry_test.dart`,
  `test/release_manager_version_single_source_contract_test.dart`.
  Výsledok: 9 testov prešlo, návratový kód 0.
- `dart analyze lib/main.dart lib/app/app_version.dart lib/app/app_navigation_shortcuts.dart test/fix374_navigation_shortcuts_test.dart`.
  Výsledok: návratový kód 1, 8 warnings a 5 info v nesúvisiacich riadkoch
  `lib/main.dart`, rovnaké hlásenia ako pri FIX373. Žiadne hlásenie v novom
  handleri, jeho teste ani centrálnej identite. Nesúvisiace nálezy neboli opravené.
- FIX374 nie je označený za zelený: cielená statická analýza neprešla.
- Build aplikácie, úplná testovacia sada ani manuálne Windows overenie neboli
  spustené. Bez commitu, pushu a publikovania.

## Synchronizácia a manuálne overenie

ZIP je zdrojový balík pre existujúcu akciu SYNCHRONIZOVAŤ ZIP. Obsahuje
aktuálne miestne zdroje vrátane FIX373 a nesúvisiacich rozpracovaných zdrojov,
testov a dokumentácie; `pubspec.yaml`, `lib` a `windows` sú v koreni ZIPu.
Neobsahuje Git metadáta, build výstupy, cache ani miestne prevádzkové nastavenia.

1. V existujúcom postupe vyberte tento ZIP cez SYNCHRONIZOVAŤ ZIP a následne
   FAST DEV BUILD. Tento krok nebol vykonaný pri príprave balíka. Jeho výsledok
   treba posúdiť podľa skutočného reportu; tento balík negarantuje úspech celého buildu.
2. Po úspešnom zostavení a spustení overte odznak 8.0.0 / Build 333 /
   RC1 DEV015 FIX374. Z Dashboardu aj z inej stránky skúste Ctrl+1 až Ctrl+9
   podľa mapovania vyššie; opakujte s fokusom na bežnom tlačidle a na slovenskom
   hornom číselnom rade. Kláves držte: jedna navigácia na jedno stlačenie.
3. V textovom poli napíšte text a skúste všetkých deväť skratiek. Stránka,
   text a fokus majú zostať zachované a písanie musí pokračovať.
4. Otvorte dialóg (napr. Klávesové skratky alebo FINAL Publish Center).
   Ctrl+1 až Ctrl+9 nesmú navigovať na pozadí ani zavrieť dialóg.
   Po jeho zatvorení majú skratky opäť fungovať mimo textového vstupu.
5. Overte zachované tlačidlo ZAVRIEŤ z FIX373 v FINAL Publish Center.

## Súbory zmeny

- lib/main.dart
- lib/app/app_version.dart
- lib/app/app_navigation_shortcuts.dart (nový)
- test/fix374_navigation_shortcuts_test.dart (nový)
- BUILD_333_DEV015_FIX374_GLOBAL_NAVIGATION_SHORTCUTS.md (tento report)
