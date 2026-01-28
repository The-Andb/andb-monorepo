# Review Result: Project Persistence Issue

## 🚨 Critical Issue Identification

The persistence fix implemented in `projects.ts` contained a conditional check that prevented it from running in the Electron environment (or any environment where `window.electronAPI` is defined).

### The Flaw

```typescript
if (
  (!lastSelected || lastSelected === "default") &&
  typeof window !== "undefined" &&
  !(window as any).electronAPI
) {
  // ... logic to read localStorage ...
}
```

If the user is testing inside the Electron app (which has `window.electronAPI` exposed via preload), this fallback logic **never executes**. Consequently, the critical "Heuristic Recovery" variables (`lastSelectedName`) remain `null`, causing the name-based matching to fail.

## 🛠 Recommended Fix

1.  **Remove the Environment Guard**: The `localStorage` mechanism in the browser window (renderer process) is distinct from the Electron main process storage. It is safe and recommended to use `localStorage` as a fast, synchronous "L1 Cache" for UI state like "Last Selected Project", regardless of whether the native backend is present.
2.  **Unconditional Save/Load**:
    - **Read**: Always check `localStorage` if the primary `settings` store returns 'default' or fails to match an ID.
    - **Write**: Always write to `localStorage` in the watcher, ensuring the "L1 Cache" is fresh.

## 📉 Risk Assessment

- **Low Risk**: `localStorage` is isolated to the origin. Writing to it in Electron (renderer) has no side effects on the main process file storage.
- **High Reward**: guarantees persistence even if the IPC layer is slow or the main process storage file is corrupted/reset.

## ✅ Action Plan

1.  Modify `ui/src/stores/projects.ts` to remove `&& !(window as any).electronAPI` form both the `init()` read logic and the `watch()` write logic.
