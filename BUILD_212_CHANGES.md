# STAVBY PRO Release Manager 6.1.4 LTS – Build 212

## Plugin Architecture Foundation

- pridaný deklaratívny `PluginManifest`,
- pridaný kontrakt `ProjectPlugin`,
- pridaný model výsledku registrácie pluginu,
- pridaný `PluginService` na vyhľadanie a validáciu `plugin.json`,
- pridaná kontrola povolenia, kompatibility a podporovaných platforiem,
- pridané vzorové manifesty pre STAVBY PRO a Release Manager,
- zachované existujúce workflow z Build 211,
- verzia synchronizovaná na `6.1.4+212`.

Poznámka: Build 212 vytvára bezpečný manifestový základ. Dynamické načítanie
nekompilovaného Dart kódu za behu nie je súčasťou tohto buildu.
