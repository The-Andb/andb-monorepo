# @the-andb/desktop v3.2.4 Release

## ✨ New Features
- **Compare Stack Bar Reimagined**: Completely overhauled the Compare Stack workflow. The stack bar has been redesigned from a bulky block into a sleek, centralized, and mutually exclusive "Pill" UI. It elegantly manages your source and target selections with dynamic badges and one-click removal.
- **Interactive Top-Level Instant Compare**: Instant Compare is no longer a restricted modal pop-up. It has been elevated to a top-level route accessible via a new, modern iOS-style segmented control toggle in the Diff & Sync header.
- **Unified Feature Ecosystem Map**: A beautifully rendered, interactive Left-to-Right Mermaid flowchart has been deployed to the `andb-www` feature landing page to perfectly visualize the engine's capabilities.
- **Real-Time Code Syntax Environment**: Integrated a lightweight, real-time SQL execution and syntax-highlighting environment (Prism.js) into the Instant Compare textareas for a seamless developer lab experience.
- **Smart Database Connection Flow**: Redesigned the connection creation experience. The Engine Type selector is now the foremost step. The UI smartly reveals the advanced "Restricted User Auth" wizard only when appropriate (e.g. MySQL, Postgres), keeping the interface clean for embedded databases.
- **SQLite File-Centric UX**: SQLite connections now feature an optimized, file-centric configuration form. Redundant network and authentication fields are hidden, and a native file-picker replaces the standard Host input for frictionless `.sqlite` database integration.

## 🛠 Improvements & Fixes
- **Global Settings Multi-Tab Crash Fix**: Resolved a critical layout instability causing the Interface section (Typography and Visual Density) to permanently overwrite other settings tabs. The DOM structural integrity has been explicitly balanced and sealed.
- **Lucide Icon Vue 3 Proxy Leak**: Eliminated UI freezing by applying `markRaw()` exclusions to Vue reactivity on dynamically bound Lucide icons across the Settings panel.
- **Tree Context Relocation**: Shifted the "Expand All" and "Collapse All" utility actions out of the global header and natively embedded them alongside the database search tree for significantly more intuitive schema navigation.
- **Localization Completion**: Added missing UI translation keys for generic structural tokens (like `COMMON.CHANGE`) in Vietnamese and English.
- **Global Connections Consistency**: Removed the strict project context requirement when saving templates, restoring the ability to cleanly save and share root-level Global Connections.
