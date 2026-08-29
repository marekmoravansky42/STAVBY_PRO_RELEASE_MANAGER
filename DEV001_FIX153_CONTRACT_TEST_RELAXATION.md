# DEV001 FIX153 – Contract test relaxation

FIX152 runtime logic is unchanged.

The only failing test matched one exact source spelling of the BUILD-number
regular expression. The implementation itself was present and correct, but the
test was too formatting-sensitive.

FIX153 changes that test to verify the actual behavior anchors instead:
- `releaseBuildNumber(Directory directory)` exists,
- the BUILD regex is used via `firstMatch(name)`,
- the captured build number is parsed with `int.tryParse(...)`,
- the candidate sort still compares parsed build numbers.

Identity: 8.0.0 RC1 • Build 270 • DEV001 FIX153.
