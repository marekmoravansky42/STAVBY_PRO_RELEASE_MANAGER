# Build 316 DEV001 FIX263 – Fixture Scope Fix

FIX262 correctly added Windows transition fixtures to the historical FIX252
test, but used the nonexistent variable `workspace`. The existing temporary
workspace variable in that test is named `root`.

FIX263 changes both Windows fixture paths from `workspace.path` to `root.path`.
No production transition behavior is changed.
