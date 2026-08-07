# STAVBY PRO Release Manager 6.3.0 LTS – Build 227

## Performance & Startup Optimization

- zdieľaná cache načítania AppSettings zabraňuje duplicitným čítaniam disku pri štarte,
- súbežné požiadavky používajú jeden in-flight Future,
- cache sa po každej zmene nastavení bezpečne invaliduje,
- nový StartupPerformance meria Flutter binding, runApp, načítanie témy a prvý frame,
- čas štartu sa zapisuje do živého terminálového logu bez ďalšieho prekresľovania,
- bez zmeny používateľského workflow alebo funkcionality release procesov.
