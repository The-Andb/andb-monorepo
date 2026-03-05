# 📦 Distribution Strategy

> Updated: Feb 24, 2026

## Phase 1: CLI First (14-day sprint)

```bash
# Primary: npm global install
npm install -g @the-andb/cli
andb compare --source db1 --target db2

# Alternative: npx (zero install)
npx @the-andb/cli compare -s schema.sql -t live-db
```

### Package: `@the-andb/cli`

- Version: `4.0.0-beta.1`
- Tag: `beta` until 3 external users confirm stability
- Scope: `@the-andb` (existing npm org)

## Phase 2: Docker (Post-beta)

```dockerfile
FROM node:20-alpine
RUN npm install -g @the-andb/cli
ENTRYPOINT ["andb"]
```

```bash
# CI usage
docker run --rm ghcr.io/the-andb/cli compare \
  --source-host db1.staging \
  --target-host db2.staging
```

### Registry: GitHub Container Registry (GHCR)

- Auto-build on tag push
- Multi-arch: linux/amd64, linux/arm64

## Phase 3: Desktop (Parallel track)

- Electron app via GitHub Releases (DMG/EXE/AppImage)
- Not priority for 14-day sprint
- Desktop enhances but is NOT required for core value

## Checklist Before First Publish

- [ ] `npm whoami` confirms permissions on `@the-andb`
- [ ] Version bumped to `4.0.0-beta.1`
- [ ] README has install + quickstart
- [ ] `andb --version` works
- [ ] `andb compare --help` shows all options
- [ ] Exit codes work (0/1/2)
- [ ] JSON output works
- [ ] No Framework debug noise in production mode
