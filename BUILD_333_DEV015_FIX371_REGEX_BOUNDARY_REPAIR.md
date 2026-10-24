# FIX371
Opravuje iba chybný escape hranice slova v troch historických pubspec identity testoch z FIX370.
Regex teraz správne akceptuje `version: 8.0.0+333` aj `version: 8.0.0-dev.N+333`.
Produkčná logika FIX369 sa nemení.
