# Landing Page Master Plan: The Face of "The Andb"

This document outlines the strategy to transform the current basic landing page into a **stunning, high-conversion showcase** for The Andb.

> **Goal**: Create a "Love at First Sight" experience. The landing page must reflect the premium, modern, and powerful nature of the application itself.

---

## 🎯 The Core Purpose: Building TRUST & Solving PAIN

> **Why this page exists?** Developers are terrified of running unknown tools on their Production DBs. This page must scream: **"Safe. Professional. Essential."**
> **Vision:** "It’s not built to replace large platforms – just a practical tool to solve real problems." We don't oversell; we deliver focused utility.

---

## 🎨 Design Philosophy (Trust > Flashiness)

- **Vibe**: "Industrial Grade Elegance". Think Linear, Raycast, or Vercel. Dark mode, precision lines, subtle glows, but **no distracting/laggy 3D gimmicks**.
- **Typography**: Monospace for code/data (JetBrains Mono) combined with a clean Sans (Inter).
- **Trust Signals**: Use "Green" accents for Success/Safe states. High-contrast screenshots that are legible.

---

## 🏗 Site Structure & Content

### 1. Hero Section (The Promise)

- **Headline**: "Practical Schema Management. No fluff."
- **Sub-headline**: "Not a replacement for your heavy IDE. Just a sharp tool to export DDL, compare schemas offline, and generate migration scripts safely."
- **Primary CTA**: "Download Beta"
- **Secondary CTA**: "Explore CLI"
- **Visual**: A split-screen video/gif showing "Export -> Diff -> Generate Script". **Show the tool doing the work.**

### 2. The Core Value Proposition (The Hook)

- **Export DDL to Local**: "Extract tables, procedures, functions, and triggers to flat files."
- **Offline Schema Diff**: "Compare environments locally without sharing schemas or data to the cloud."
- **Auto-Generate Migrations**: "Instantly get accurate `ALTER` scripts from structural differences."
- **Integrate CI/CD pipelines via CLI**: "Hooks directly into your CI/CD pipelines to catch drift before deployment."

### 3. Functionality Grid (The Toolkit)

- **AI Ready via MCP**: "Give AI agents safe, structured access to your database schema through our MCP server."
- **Deep Comparison**: "Not just text diff, but semantic structure analysis."
- **Multi-Driver**: MySQL (Deep support), Postgres (Coming soon), SQLite.
- **Privacy First**: "**Your data never leaves your machine.** No cloud mandates. No tracking."

### 4. Comparison / "Why Andb?"

- A simple table or slider comparing "Traditional Clients" (DBeaver, Workbench) vs "The Andb" (Focus on UX, Intelligence, Safety).

### 5. Download & OS Support

- Cards for macOS (Intel/Silicon), Windows, Linux.
- Version badges (v3.0.0-beta).

### 6. Footer

- Links: Documentation, GitHub, Twitter/X, Discord?
- Copyright.

---

## 🛠 Technology Stack

- **Framework**: Vue 3 + Vite (Existing).
- **Styling**: Tailwind CSS (Existing).
- **Animation**: `motion` (from `@vueuse/motion`) or `framer-motion` equivalent for Vue.
- **Icons**: `lucide-vue-next`.
- **Highlighting**: `prismjs` (for code snippets on the page).

---

## 🗓 Execution Roadmap

### Phase 1: Foundation & Design System

- [ ] **Setup**: Clean up `landing/src`. Install `motion` library.
- [ ] **Design System**: Define color palette (CSS variables/Tailwind config) and typography in `tailwind.config.js`.
- [ ] **Component Library**: Create base components: `Button` (Glow effect), `Card` (Glass), `Section` (Container).

### Phase 2: Core Sections Implementation

- [ ] **Hero**: Implement layout, massive CTA, and floating UI screenshot.
- [ ] **Features**: Build the Bento Grid.
- [ ] **Downloads**: Create the download section with mock links for now.

### Phase 3: Polish & Assets

- [ ] **Screenshots**: Capture high-res screenshots of the actual app (Dark mode).
- [ ] **Copywriting**: Refine text for impact and clarity.
- [ ] **SEO**: Meta tags, OpenGraph images.

### Phase 4: Integration

- [ ] **Auto-Update Info**: Fetch latest release info from GitHub API to show version/download count.
- [ ] **CI/CD**: Ensure the landing page builds and deploys (Vercel/Netlify/GitHub Pages).

---

## 📝 Immediate Next Steps

1.  **Refactor**: Clean up the `src` folder structure (components, views, assets).
2.  **Dependencies**: Install necessary animation libraries.
3.  **Hero**: Build the Hero section first to set the tone.
