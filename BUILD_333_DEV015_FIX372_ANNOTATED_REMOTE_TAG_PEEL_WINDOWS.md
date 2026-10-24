# FIX372 – Windows annotated remote FINAL tag peel repair

Reálny test potvrdil, že remote SHA `0893ce44...` je objekt anotovaného tagu, ktorý sa dereferencuje na commit `43b4c5ee...`. Lokálny FINAL tag ukazuje na ten istý commit.

Príčina falošného konfliktu bola Windows shell interpretácia znaku `^` v `refs/tags/<tag>^{}` pri `Process.run(..., runInShell: true)`. Overenie remote tagu teraz spúšťa Git priamo (`runInShell: false`), takže peeled `^{}` ref sa odošle Git-u nezmenený.

Žiadny tag sa nemaže ani neprepisuje.
