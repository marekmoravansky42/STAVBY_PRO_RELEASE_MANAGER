# FIX365 – FIX356 expectation repair

FIX364 prešiel analyzérom a celý test run mal jediný failing test: historický FIX356 očakával regexový text `RC1 DEV015 FIX\\d+` v zdroji FIX354, ale FIX354 bol už správne zovšeobecnený na prefix `RC1 DEV015 FIX`. FIX365 zosúlaďuje iba túto zastaranú testovaciu očakávanú hodnotu. Produkčná FINAL logika sa nemení.
