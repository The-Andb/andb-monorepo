---
name: the-andb-desktop
description: "Use when building Vue components, Pinia stores, Electron main/preload IPC handlers, or UI views under @the-andb/desktop. Examples: \"Add a connection setting to the UI\", \"Implement a sliding panel for schema details\", \"Refactor sidebar state loading\""
---

# 🖥️ Developing Desktop UI & Electron Shell (@the-andb/desktop)

This skill covers development, UI styling, and Electron IPC boundary guidelines for `@the-andb/desktop`.

## 🎨 UI & UX Philosophy

- **Dark Mode Only**: Build sleek, premium dark-themed interfaces using Tailwind CSS and harmonious palettes.
- **Micro-Animations & Hover Effects**: Make the UI feel responsive, alive, and premium.
- **Integrated Overlays / Sliding Panels**: Avoid modas unless absolutely necessary.
- **Pinia Stores**: Use `initPromise` guards to prevent concurrent loading race conditions.
- **Synchronized Scrolling**: Source (Left) and Target (Right) comparison panes must scroll in sync. Use [EMPTY] placeholders with identical heights.

## 📁 Key Directories

```
andb-desktop/
├── electron/
│   ├── main.ts                        # 60+ IPC handlers, window management
│   └── services/andb-builder.ts       # CoreBridge wrapper
├── src/
│   ├── App.vue                        # Root layout
│   ├── views/                         # Dashboard, Compare, GlobalSchemaView
│   ├── components/                    # Sidebar, DDL diff, connection managers
│   ├── stores/                        # 12 Pinia stores (app, sidebar, projects)
│   ├── i18n/                          # en.yaml, vi.yaml (Mandatory translation)
│   └── utils/andb.ts                  # IPC Client (Andb.export, Andb.getSchemas)
```

## 🔌 IPC Boundary Rules (CRITICAL)

- **Air Gap**: Renderer process (Vue) cannot access Node.js APIs or `@the-andb/core` directly.
- **Window API**: All operations must invoke `window.electronAPI.andbExecute()` or use the `Andb` helper class inside `src/utils/andb.ts`.
- **IPC Response Contract**: Every IPC handler must return `{ success: true, data }` or `{ success: false, error }`.

## 🛠️ Code Conventions

- **Vue 3 Composition API**: Use `<script setup lang="ts">` only. No Options API.
- **Tailwind Only**: No inline styles.
- **i18n Mandatory**: All UI text must be defined as translation keys inside `en.yaml` and `vi.yaml`. Use `{{ $t('key') }}` in Vue templates.
- **Icons**: Import individually from `lucide-vue-next`.
- **SQL Highlighting**: Use PrismJS with `language-sql`.

## Checklist for Desktop Changes

- [ ] Ensure all changes remain inside `andb-desktop/` directory.
- [ ] Implement UI text using `en.yaml` and `vi.yaml` translation files.
- [ ] Verify that Electron main process calls are decoupled via `Andb` utility inside `src/utils/andb.ts`.
- [ ] Add smooth hover transitions and animations to interactive elements.
- [ ] Test the UI performance to avoid rendering lags or "zombie" progress indicators.
