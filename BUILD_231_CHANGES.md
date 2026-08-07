# STAVBY PRO Release Manager 6.3.4 LTS – Build 231

## Plugin SDK Foundation – Fáza 1

- pridané compile-time rozhranie `PluginApi`,
- pridaný validovaný `PluginDescriptor`,
- deklarácia capabilities pluginov,
- obmedzený typový `PluginContext`,
- register pluginov s kontrolou duplicít,
- loader s kontrolou kompatibility host verzie,
- bezpečné výsledky inicializácie a uvoľnenie pluginov,
- barrel export `plugin_sdk.dart`,
- automatizované testy validácie, registra a loadera.

Bezpečnostná zásada: Build 231 nenačítava ľubovoľný Dart kód z disku. Pluginy musia byť skompilované s aplikáciou a explicitne registrované.
