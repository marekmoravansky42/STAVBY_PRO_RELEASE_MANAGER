# Build 232 – Etapa 1: Plugin Manifest

- pridaný nemenný model `PluginManifest`
- pridaná JSON serializácia `fromJson()` a `toJson()`
- pridaný bezpečný `PluginManifestParser`
- validácia ID, názvu, verzie, API verzie, enabled a capabilities
- chybný používateľský JSON vracia validačný výsledok namiesto výnimky
- pridané jednotkové testy parsera a serializácie
- verzia projektu synchronizovaná na `6.3.5+232`

Táto etapa ešte nepridáva skenovanie adresára ani registráciu pluginov.
