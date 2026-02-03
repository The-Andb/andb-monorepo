# 📦 NPM Publishing Strategy (The "Switcheroo" Plan)

> **WARNING**: Review this document BEFORE running `npm publish`!

## 🎯 Objective

Migrate package names to reflect the new Architecture (NestJS/Vue3) while preserving Legacy support.

## 📅 The Plan

### Phase 1: The Legacy Handover

1.  **Publish Legacy Core**:
    - Package: `andb-core-legacy`
    - NPM Name: `@the-andb/core-legacy`
    - Version: `3.x.x` (Continue from last stable core version)
    - Command:
      ```bash
      cd andb-core-legacy
      npm publish --access public
      ```

2.  **Publish Legacy Desktop (Optional)**:
    - Package: `andb-desktop-legacy`
    - NPM Name: `@the-andb/desktop-legacy` (was `@the-andb/ui`)
    - Note: Desktop apps are usually distributed via GitHub Releases (DMG/EXE), not NPM. This might not be needed unless used as a lib.

### Phase 2: The New Era (Major Bump)

1.  **Publish NestJS Core**:
    - Package: `andb-core`
    - NPM Name: **`@the-andb/core`** (Reclaiming the throne 👑)
    - Version: **`4.0.0`** (Breaking Change!)
    - Tag: start with `next` or `beta` first.
    - Command:
      ```bash
      cd andb-core
      npm version 4.0.0-beta.1
      npm publish --tag beta --access public
      ```

2.  **Publish Desktop New**:
    - Package: `andb-desktop`
    - Name: `@the-andb/desktop`
    - Dependency: Must point to `@the-andb/core@^4.0.0` (or beta).

## 🛡️ Checklist before Publish

- [ ] Did you bump `andb-core` (NestJS) to v4.0.0?
- [ ] Did you rename `andb-core-legacy` to `@the-andb/core-legacy` in package.json?
- [ ] Did you check `npm whoami` to ensure you have permissions?
