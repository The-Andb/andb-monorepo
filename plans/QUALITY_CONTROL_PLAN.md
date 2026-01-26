# 🛡️ Quality Control & Testing Master Plan (2026)

## 📌 Executive Summary

This document defines the high-level quality assurance strategy for `The Andb`. As we pivot from a functional tool to an enterprise-grade product (Phase 2: Hardening), strict QC and automated testing are mandatory to ensure **Safety**, **Stability**, and **Semantic Correctness**.

---

## 🏗️ 1. Global QC Architecture

| Layer                | Technology     | Responsibility                                    | Current Status |
| :------------------- | :------------- | :------------------------------------------------ | :------------- |
| **Core Integration** | Jest           | Deep logic, semantic parsing, driver stability    | 🟢 Established |
| **UI Logic**         | Vitest         | Pinia store isolation, business logic, components | 🟡 Developing  |
| **End-to-End**       | Playwright     | Full Electron app flow, cross-platform UI         | 🟢 Established |
| **Automated Audit**  | Custom Scripts | Security, Perf, SEO, Accessibility                | 🔴 Planned     |

---

## ⚙️ 2. @the-andb/core (The Engine)

### Strategy: "Semantic Reliability"

Core testing focuses on the accuracy of database introspection and comparison logic.

#### Existing Test Inventory (Core)

- **Services:**
  - `comparator.test.js`: Validates schema diff generation logic.
  - `migrator.test.js`: Ensures SQL generation for migrations is safe.
  - `exporter.test.js` / `exporter.driver.test.js`: Tests database introspection.
  - `monitor.test.js` / `container.test.js`: Internal lifecycle management.
- **Storage:**
  - `comparison.repository.test.js`, `ddl.repository.test.js`, `migration.repository.test.js`: Persistence layer tests.
- **Utils:**
  - `ddl.parser.test.js`: Critical test for semantic SQL parsing.
  - `file.helper.test.js`: IO operations.

#### QC Goals for Core:

1. **Semantic Parsing Coverage**: Increase DDL parser tests to cover complex MySQL objects (Stored Procs, Triggers).
2. **Transaction Safety**: Implement tests specifically for dry-runs and rollback simulations.
3. **Driver Agnosticism**: Prepare test suites that can run across both MySQL and future PostgreSQL drivers.

---

## 🎨 3. @the-andb/ui (The Interface)

### Strategy: "Predictable Interaction"

UI testing ensures that complex project-based state (Pinia) remains isolated and the Electron wrapper behaves correctly.

#### Existing Test Inventory (UI)

- **Unit Tests (`*.unit.test.ts`):**
  - `projectIsolation.unit.test.ts`: Ensures switching projects clears state correctly.
  - `miller-column/store.unit.test.ts`: Tests high-perf tree navigation logic.
- **E2E Tests (`*.e2e.spec.ts`):**
  - `app.e2e.spec.ts` / `skeleton.e2e.spec.ts`: Launch and structure.
  - `connection.e2e.spec.ts`: MySQL & Dump creation flows.
  - `dashboard.e2e.spec.ts`: UI stats and recent activity.
  - `dump-ops.e2e.spec.ts`: File-based comparison workflows.
  - `projects.e2e.spec.ts`, `schema-explorer.e2e.spec.ts`, `compare.e2e.spec.ts`, `settings.e2e.spec.ts`: Screen-specific flow verification.

#### QC Goals for UI:

1. **State Resilience**: Resolve the flakiness in `projectIsolation.unit.test.ts`.
2. **Selector Hardening**: Move from text-based selectors to `data-test` IDs for headless stability.
3. **Visual Regression**: (Planned) Implement screenshot comparison for core diff views.

---

## 🚀 4. Automated QC Pipeline (Future)

To achieve "Hero" status, we will implement an automated checklist triggered on every major change/release.

1. **Phase A (Security)**: `security_scan.py` & `vulnerability_scanner`.
2. **Phase B (Consistency)**: `lint_runner.py` & `schema_validator.py`.
3. **Phase C (Stability)**: `test_runner.py` (Core + UI Unit).
4. **Phase D (Integration)**: `playwright_runner.py` (E2E).
5. **Phase E (Performance)**: `lighthouse_audit.py` & `bundle_analyzer.py`.

---

_Created: Jan 2026_
_Next Audit: Feb 2026_
