# Build 327 DEV009 FIX311

- Oprava compile chyby iba v FIX310 regression teste.
- Očakávaný source fragment s `${project...}` je raw string, takže Dart ho neinterpretuje ako premennú testu.
- Produkčná logika FINAL Publication Receipt sa nemení.
- Identita: RC1 DEV009 FIX311.
