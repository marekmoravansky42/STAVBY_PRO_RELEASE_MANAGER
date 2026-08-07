# Build 254 DEV005 FIX001

- Opravená neaktívna akcia Flutter Test pri prevzatí staršieho agenta.
- DEV005 akceptuje iba agenta s protocolVersion >= 3 a capability flutter_test.
- Predvolený port zmenený na 47833, aby sa nepreberal starší agent z DEV003/DEV004.
- Analyze aj Test zostávajú dostupné po pripojení kompatibilného agenta.
