# 🌐 The Andb Web Showcase Plan

**Objective:** Transform the current landing page into a "Powerhouse Showcase" that demonstrates the core value of The Andb through interactivity and live data simulation.

---

## 🏗️ 1. Architecture: The "Interactive Mirror"

Instead of static screenshots, the new web will feature a live **Engine Simulation**.

### A. Preset System

- **Presets**: Pre-loaded database dump pairs (e.g., `E-commerce v1 vs v2`, `Auth System v1.5 vs v1.6`).
- **Data Source**: JSON-based mock DDL stores.

### B. Twin-Pane Interface (Showcase Section)

- **Left Pane (Source A)**: SQL Editor (Read-only/Editable) showing Dump A.
- **Right Pane (Target B)**: SQL Editor showing Dump B.
- **Center Action**: A "Compare & Synchronize" button that triggers the simulated Andb logic.

---

## 🎨 2. Visual Aesthetic: "Deep Tech & Precision"

- **Color Palette**: `Electric Indigo`, `Cipher Blue`, `Ghost White` in a **Glassmorphic** Dark UI.
- **Typography**: `Outfit` for headings, `JetBrains Mono` for code and metadata.
- **Animations**:
  - `Smooth Scroll` using Lenis (already installed).
  - `Holographic Diffs`: Lines of code that highlight and "pulse" when differences are detected.
  - `Cyber Progress`: High-tech loading states during comparison.

---

## 🛠️ 3. Feature Breakdown

### Section 1: Immersive Hero

- **Dynamic 3D Cluster**: A floating database schema visualization.
- **Value Prop**: "The Engine that Powers Professional Migrations."

### Section 2: The Interactive Playground (@andb-www/playground)

- **Live Preview**: Let users see the content of Dump A and Dump B directly.
- **Diff Mode**: unified/split view exactly like the Desktop app.
- **Direct Download**: Buttons to download `sample_a.sql` and `sample_b.sql` so users can try them in the real Desktop app immediately.
- **Online Test**: A small "mini-shell" simulation showing CLI output.

### Section 3: Performance Metrics

- Show benchmarks: "Parsed 10k tables in 45ms" (simulated or real benchmark data).

---

## 📅 4. Implementation Steps

### Phase 1: Engine Mocking (JS)

- Port basic string-diffing logic to a client-side utility in `andb-www`.
- Create a `DumpProvider` service to manage SQL presets.

### Phase 2: Premium UI Components

- Integrate **Monaco Editor** for the "Show Content" requirement.
- Build the "Twin-Pane" component with responsive layout.

### Phase 3: Assets & Polishing

- Generate high-quality 3D assets for the HERO.
- Add "DMCA Protected" and "Proprietary" footer branding (Legacy Unified).

---

## 🚀 5. Goal: "Test directly on showcase"

By the end of this plan, a user can:

1. Click "Showcase".
2. See two different SQL dumps.
3. Edit one line in Dump A.
4. Click "Sync".
5. See the generated `ALTER` statement instantly.
6. Download both dumps to verify with the Desktop app.
