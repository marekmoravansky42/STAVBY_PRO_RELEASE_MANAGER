# Build 333 / DEV015 / FIX350 – FINAL Publish Center re-entry

Reálny FINAL test STAVBY PRO 3.8.108 Build 482 odhalil blokujúcu navigačnú chybu: po zatvorení FINAL Publish Center zostal release na 100 %, INTEGRITY OK a Publish Gate POVOLENÉ, ale používateľ sa už k publikačnému centru nevedel vrátiť bez nového buildu.

FIX350 pridáva na Release Dashboard dve bezpečné vstupné akcie „PUBLIKOVAŤ FINAL“ (Rýchle release akcie + karta Posledná finálna verzia). Obe používajú persistovaný posledný overený FINAL ZIP a vyžadujú existujúci FINAL release, INTEGRITY OK a Publish Gate POVOLENÉ. Nevytvárajú nový build, commit ani tag; iba znovu otvoria existujúci FINAL Publish Center.

Odložené nálezy z celkového testu (napr. prekrývanie spodného textu s FINAL ZIP, AI assistant FINAL default, Release Notes jazyk, manifest flow, Release History) sa týmto FIXom zámerne nemenia.
