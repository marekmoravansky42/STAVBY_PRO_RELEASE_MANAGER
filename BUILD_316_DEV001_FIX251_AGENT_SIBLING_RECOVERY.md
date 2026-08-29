# FIX251 Local Agent sibling workspace recovery

Keď je aktívny projekt napr. `C:\SP\STAVBY_PRO`, Local Agent už nehľadá iba:
`C:\SP\STAVBY_PRO\tools\release_agent`.

FIX251 prehľadá aj susedné projekty pod rovnakým rodičom, takže nájde:
`C:\SP\Release_Manager\tools\release_agent`.

Tým zostáva Agent dostupný aj keď je v Release Manageri aktívny STAVBY_PRO.
