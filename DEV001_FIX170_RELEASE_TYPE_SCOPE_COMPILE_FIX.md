# DEV001 FIX170 – releaseType scope compile fix

FIX169 correctly introduced explicit export stages, but one Build Completion
Center call referenced a local variable `releaseType` that does not exist in
that scope. Flutter analyze therefore failed with undefined_identifier.

FIX170 reads the optional release type from the existing completion `data` map
and passes that value to the exporter. FAST DEV BUILD remains explicitly DEV.

Identity: Build 287 / DEV001 FIX170.
