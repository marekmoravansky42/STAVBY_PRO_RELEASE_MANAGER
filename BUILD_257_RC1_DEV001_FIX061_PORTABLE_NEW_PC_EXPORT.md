# FIX061 – Portable New PC Export

Built from confirmed FIX060.

Adds `Nastavenia a pomoc -> Prenos na nový počítač -> EXPORT PRE NOVÝ PC`.

The export creates one ZIP containing:
- sanitized Release Manager configuration;
- available Project Profiles;
- transfer metadata and README.

Security:
- GitHub credentials / DPAPI protected secrets are deliberately not exported;
- saved old-PC paths are metadata only and will be validated during import.

FIX062 will add New PC Restore / Import.
