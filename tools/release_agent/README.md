# STAVBY PRO Release Agent

Lokálny alebo LAN agent pre STAVBY PRO Release Manager.

## Spustenie

Na Windows spusti `START_RELEASE_AGENT.bat`, alebo v tomto priečinku:

```text
dart run bin/release_agent.dart 47833
```

## API DEV003

- `GET /status` – registrácia a heartbeat
- `GET /ping` – test spojenia
- `POST /tasks/analyze` – spustenie `flutter analyze` v explicitnom pracovnom priečinku
- `POST /tasks/test` – spustenie `flutter test` v explicitnom pracovnom priečinku
- `GET /tasks/{id}` – stav, log a návratový kód úlohy

Agent povoľuje naraz jednu úlohu.
