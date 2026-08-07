# STAVBY PRO Release Manager 6.4.4 LTS – Build 241 FIX002

## Opravy

- doplnený priamy import `plugin_discovery_report.dart`, ktorý definuje `PluginDiscoveryEntry`,
- zoznam výsledkov discovery je explicitne deklarovaný ako `List<PluginDiscoveryEntry>`,
- tým sa odstráni následná nesprávna nullable analýza prístupu `entry.manifest`.

Verzia a build zostávajú `6.4.4+241`.
