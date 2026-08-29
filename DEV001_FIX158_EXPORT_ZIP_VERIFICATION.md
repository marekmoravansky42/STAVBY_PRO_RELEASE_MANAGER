# FIX158 – Export ZIP physical verification

Export is marked OK only after the returned ZIP exists physically.
Dashboard quick Export also verifies non-zero size, displays the full path in
the completion message and offers OTVORIŤ to select the exact ZIP in Explorer.
The verified path is stored for the current build cycle and cleared when a new
cycle starts.
