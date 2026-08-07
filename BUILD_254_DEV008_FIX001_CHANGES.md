# Build 254 DEV008 FIX001 – Local Agent Auto Connect & Friendly Errors

- Local Agent sa pri otvorení stránky Agentov automaticky obnoví alebo spustí.
- Po štarte sa Release Manager automaticky pripojí a aktivuje Pipeline Runner.
- Surové SocketException hlášky sú nahradené zrozumiteľným oznamom.
- Tlačidlo SPUSTIŤ PIPELINE ponúkne spustenie Local Agenta, ak agent nie je pripojený.
- Pri strate spojenia sa neaktuálny agent odstráni zo stavu UI.
