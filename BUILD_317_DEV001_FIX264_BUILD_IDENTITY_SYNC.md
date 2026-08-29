# Build 317 DEV001 FIX264 – Release Manager Build Identity Sync

This batch fixes the mismatch where the working FIX label advanced while the
Release Manager's own build stayed at 316.

Current identity:
- Version: 8.0.0
- Build: 317
- Stage: RC1 DEV001 FIX264
- pubspec: 8.0.0+317

Policy from FIX264 onward:
Every new working FIX that represents a new Release Manager package must bump
both:
1. ReleaseManagerVersion.build
2. ReleaseManagerVersion.stage

The pubspec build metadata must match the same build number.
UI badge/label continues to derive from ReleaseManagerVersion.
