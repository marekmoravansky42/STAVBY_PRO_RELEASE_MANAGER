# STAVBY PRO Release Manager 7.1.0 LTS – Build 254 DEV001

## Remote Build Agent – registrácia, heartbeat a ping

- pridaná nová karta **Agenti** v hlavnej navigácii,
- manuálne pripojenie agenta cez IP/názov počítača a port,
- načítanie identity, OS, Flutter verzie a podporovaných platforiem,
- automatický heartbeat každých 5 sekúnd,
- samostatný test spojenia **Ping Agent** s meraním latencie,
- pridaný minimálny samostatný Dart projekt `tools/release_agent`,
- HTTP endpointy `/status` a `/ping`,
- build verzia zvýšená na `7.1.0+254`, stage `DEV001`.

DEV001 ešte nevykonáva vzdialené pipeline príkazy ani neprenáša artefakty.
