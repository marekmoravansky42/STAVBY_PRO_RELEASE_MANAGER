# FIX367 – test interpolation repair

FIX366 analyze zlyhal iba preto, že jeho regresný test interpretoval `$requestedTag` ako Dart premennú namiesto doslovného textu zo zdrojového kódu. FIX367 mení assertion na raw string. Produkčná recovery logika FIX366 sa nemení.
