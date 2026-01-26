# 🧪 @the-andb/ui Technical Testing Plan

## 🎯 Objectives

Ensure a seamless, high-performance UI experience while maintaining strict project-level state isolation.

## 📊 Current Test Suite (Vitest & Playwright)

Located in `ui/src/**/__tests__` and `ui/tests/`:

### Unit Tests (Vitest)

- **State:** `projectIsolation.unit.test.ts` (Ensures data doesn't leak between projects).
- **Packages:** `miller-column/store.unit.test.ts` (Navigation logic).

### E2E Tests (Playwright/Electron)

- **Flows:**
  - `connection.e2e.spec.ts`: Add/Edit connection workflows.
  - `dump-ops.e2e.spec.ts`: Complex SQL dump comparison loops.
  - `projects.e2e.spec.ts`: Project management CRUD.
- **Screens:**
  - `dashboard.e2e.spec.ts`, `settings.e2e.spec.ts`, `schema-explorer.e2e.spec.ts`.

## 🚀 Quality Control Roadmap

### Priority 1: State Resilience (Short-term)

- **Goal:** Fix flaky unit tests.
- **Action:** Debug `projectIsolation.unit.test.ts` reactivity issues identified during recent runs.

### Priority 2: Selector Stability (Medium-term)

- **Goal:** Reduce E2E failures due to UI changes.
- **Action:** Standardize use of `data-test` attributes across all Vue components for Playwright locators.

### Priority 3: Visual Accuracy (Long-term)

- **Goal:** Prevent regression in complex diff views.
- **Action:** Integrate Playwright screenshots for visual regression testing on `compare.e2e.spec.ts`.

## 🛠️ Tooling & Standards

- **Unit:** Vitest (`npm run test`)
- **UI Mode:** `npm run test:ui` (for component development)
- **E2E:** Playwright (`npm run test:e2e`)
- **Standards:** AAA (Arrange, Act, Assert) pattern.
