# Build 255 DEV004 – Smart Git Recovery

- Git preflight now scans oversized blobs in outgoing commit history, not only the current index.
- Generated build artifacts over GitHub’s 100 MB limit are removed from outgoing history by safely squashing unpushed commits onto origin/<branch>.
- Local files remain on disk and generated paths are added to .gitignore.
- Unknown large user files are never removed automatically; Git LFS/manual action is required.
- Push runs only after a second verification confirms no oversized tracked or outgoing blobs remain.
