# STAVBY PRO Release Manager 6.2.7 LTS – Build 224

## Shared UI Components Library – Fáza 1

- Spoločné UI komponenty boli vyčlenené do `lib/shared/widgets/`.
- `RMSectionCard`, `RMSectionHeader`, `RMMetricCard` a `RMStatusBadge` už nie sú definované v centrálnom súbore dizajnu.
- Pridané opakovane použiteľné komponenty `RMPrimaryButton`, `RMSecondaryButton`, `RMInfoCard`, `RMProgressIndicator` a `RMConfirmationDialog`.
- Lokálne wrappery `_SectionCard` a `_GitMetricCard` boli odstránené z `main.dart`.
- Existujúce obrazovky teraz používajú spoločné komponenty priamo.
- Funkčné správanie aplikácie zostalo nezmenené.
- Verzia synchronizovaná na `6.2.7+224`.
