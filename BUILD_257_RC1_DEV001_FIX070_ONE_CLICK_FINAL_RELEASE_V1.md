# FIX070 – One Click Final Release v1

Built from confirmed FIX069C.

Adds the requested `FINÁLNA VERZIA` checkbox and `VYTVORIŤ FINÁLNY RELEASE`.

Flow:
- calculates next build number;
- backs up current pubspec and app version identity;
- stages target identity as `LTS / FINAL`;
- runs the already-tested platform-aware LTS Release Wizard;
- if anything fails, restores original pubspec/app identity so the build number
  is not permanently increased;
- after success keeps the new build identity and renames the output directory
  to `<PROJECT>_<VERSION>_LTS_BUILD_<BUILD>_FINAL`;
- refreshes project, Git and displayed identity.

For projects using `lib/app/app_version.dart`, channel/stage are changed to
`LTS` / `FINAL` before compiling so the built application itself displays the
final identity.

Git commit/tag remains a separate explicit step for safety in v1.
