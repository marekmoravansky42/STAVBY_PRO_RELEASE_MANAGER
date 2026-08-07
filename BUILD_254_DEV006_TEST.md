# Test Build 254 DEV006

1. Otvor stránku **Agenti**.
2. Spusti **Local Agent** a over port `47834`.
3. Vyber platný Flutter projekt s podporou Windows.
4. Klikni **BUILD WINDOWS RELEASE**.
5. Over živý log a konečný exit code.
6. Pri úspechu over súbor v `build/windows/x64/runner/Release/`.
7. Over zápis do `.release_manager/agent_task_history.json`.

Poznámka: Ak projekt nemá Windows platformu alebo chýba Visual Studio toolchain, agent korektne vráti chybu z Flutteru.
