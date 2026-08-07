# Build 254 DEV003 FIX002

## Local Agent bind a prevzatie existujúceho procesu

- Local Agent v lokálnom režime binduje iba na `127.0.0.1`.
- `shared` bind je vypnutý, aby nevznikali nejednoznačné dvojité servery.
- Pred spustením nového procesu Release Manager overí, či už kompatibilný agent na porte nebeží.
- Existujúci agent sa prevezme namiesto spustenia druhého procesu.
- Pri zlyhaní bindu agent vypíše adresu, port a `SocketException`.
- Neočakávaná chyba nastaví nenulový exit code.
- Diagnostika uchováva viac riadkov a normálny exit code 0 sa nehlási ako pád.
