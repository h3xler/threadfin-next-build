# threadfin-next-build

Threadfin (upstream: `Threadfin/Threadfin`) ARM64 Docker image, built via
GitHub Actions and pushed to GHCR.

- Trigger: manual only (`workflow_dispatch`) with a pinned upstream commit SHA.
- Tag strategy: `<yyyymmdd>-<short-sha>` (e.g. `20261004-6b9c0ccf`). No `latest`.
- Image: `ghcr.io/h3xler/threadfin-next:<tag>` (`linux/arm64`).
- No credentials or secrets are stored in this repo.
