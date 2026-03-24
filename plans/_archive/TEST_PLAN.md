# Serious Test Plan for TheAndb Desktop

This document outlines the testing strategy to ensure high reliability and zero regressions for TheAndb Desktop application. We adopt a multi-layer testing approach tailored for an Electron + Vue 3 application.

## 1. Testing Architecture

We divide testing into 4 strict layers to balance speed, cost, and confidence.

| Layer                 | Focus                                 | Tools                                         | Location Convention      | Target                               |
| :-------------------- | :------------------------------------ | :-------------------------------------------- | :----------------------- | :----------------------------------- |
| **Unit**              | Business Logic, Helpers, Stores       | `vitest`                                      | `src/**/*.unit.test.ts`  | `stores/`, `utils/`, `packages/`     |
| **Component (UI)**    | Interaction, Rendering, Accessibility | `vitest`, `@testing-library/vue`, `happy-dom` | `src/**/*.spec.ts`       | `components/`, `views/`              |
| **IPC (Integration)** | Renderer <-> Main Bridge              | `vitest` + `vi.mock`                          | `src/**/*.ipc.test.ts`   | Service calls, Data flow             |
| **E2E**               | Full App Flow, Packaging, startup     | `playwright` (Electron)                       | `tests/**/*.e2e.spec.ts` | Key user journeys (Setup, Migration) |
| **Build**             | Packaging Integrity                   | `electron-builder`                            | CI Pipeline              | Artifact generation                  |

---

## 2. Layer Details & Standards

### 2.1. Unit Testing

_Goal: Verify logic in isolation._

- **Tool**: Vitest (Existing)
- **Environment**: `happy-dom` (lightweight DOM for Vue reactivity)
- **Rules**:
  - Mock all external dependencies (File System, Network, IPC).
  - 100% coverage for `utils/` and deeply nested logic in `stores/`.
  - **No UI assertions** here (use Component tests for that).

### 2.2. UI Component Testing

_Goal: Verify components work as the user sees them._

- **Tool**: `@testing-library/vue` (To Be Added) + `vitest`
- **Philosophy**: "The more your tests resemble the way your software is used, the more confidence they can give you."
- **Rules**:
  - Do NOT test implementation details (e.g., internal component state).
  - Test user interactions: `await fireEvent.click(button)`.
  - Assert what is visible: `getByText`, `getByRole`.
  - Use `user-event` for realistic input simulation.

### 2.3. IPC Integration Testing

_Goal: Verify the Renderer correctly handles data from the Main process._

- **Tool**: Vitest + `vi.mock`
- **Strategy**:
  - We do _not_ spawn the main process here.
  - We mock `window.electron` or imports from `@/services`.
  - Test loading states, error handling from IPC, and data transformation.
  - **Example**:
    ```ts
    vi.mock("@/services/ipc", () => ({
      invoke: vi.fn(),
    }));
    ```

### 2.4. End-to-End (E2E) Testing

_Goal: Verify the compiled application works on the OS._

- **Tool**: Playwright (Electron Mode)
- **Scope**:
  - Application startup (Splash -> Home).
  - Critical Flows: "Create Connection", "Run Migration".
  - Window management (Minimize, Close).
- **Rules**:
  - Tests run on the _built_ or _packaged_ binary (or highly accurate dev mode).
  - **Zero Mocks** (where possible). Use real database files (SQLite) in temporary folders.

---

## 3. Implementation Plan

### Step 1: Dependencies & Configuration (Immediate)

- [ ] Install `@testing-library/vue` and `@testing-library/user-event`.
- [ ] Install `jsdom` (optional, but happy-dom is usually sufficient; stick to happy-dom unless issues arise).
- [ ] Create `vitest.setup.ts` to extend Vitest matchers (e.g., `jest-dom` matchers for cleaner assertions).

### Step 2: Refactor Existing Tests

- [ ] Move `*.unit.test.ts` to ensuring they are strictly unit tests.
- [ ] Create `src/components/__tests__` examples using Testing Library.

### Step 3: CI/CD Pipeline

- **Pull Request Checks**:
  1. Lint (`npm run lint`)
  2. Types (`npm run build` - implicitly checks types via vue-tsc)
  3. Unit/UI/IPC Tests (`npm run test`)
- **Release/Main Branch**:
  1. All PR checks.
  2. Build (`npm run electron:build`)
  3. E2E Tests (`npm run test:e2e`) - [IMPLEMENTED] `tests/full-flow.e2e.spec.ts` covers core journey.

## 4. Example: Testing "Secure Connections" (Current Task)

**Unit**: `stores/setupSteps.ts`

- Test `canContinue` logic: inputs -> boolean.
- Test `generateScript` output format.

**UI**: `SetupUserTemplate.vue`

- Render component.
- Fill inputs using `userEvent`.
- Assert "Next" button becomes enabled.
- Assert "Manual Mode" switches the view.

**E2E**:

- Launch App.
- Navigate to "New Connection".
- Select "Secure Mode".
- Complete the wizard.
- Verify the connection appears in the sidebar.
