# DEV001 FIX154 – Distribution BUILD number parsing fix

The Build 270 screenshots exposed the exact remaining issue: Release Dashboard
still selected BUILD_257.

Root cause:
`releaseBuildNumber()` used a raw Dart string with `\\d+`. In a raw string that
means a literal backslash followed by `d`, not the digit character class.
Therefore every normal `BUILD_257`, `BUILD_270`, etc. parsed as `-1`, and the
sort silently fell back to filesystem modified time.

FIX154:
- changes the raw regex to `r'BUILD[_-]?(\d+)'`,
- highest numeric BUILD now wins as intended,
- adds a diagnostic log showing parsed selected BUILD and path,
- adds a regression contract preventing the double-backslash form.

No Integrity/Publish Gate rules are weakened.
Identity: 8.0.0 RC1 • Build 271 • DEV001 FIX154.
