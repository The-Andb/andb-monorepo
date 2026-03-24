# 🚀 Feature Plan: Visual Schema Conflict Resolver

## 🎨 Inspiration & Analysis

Based on the analysis of `andb-desktop/stitch/andb_comparison_dashboard_2/code.html`, we have identified a **Visual Schema Conflict Resolver** as a high-impact addition to TheAndb ecosystem. This feature allows users to interactively resolve schema drifts between environments (e.g., Production vs. Staging) with a UI that rivals top-tier Git merge tools.

**Why this is "Cool" & Essential:**

- **Currently**: Users can `compare` and see text output, or `export`.
- **The Gap**: There is no safe, visual way to _decide_ which changes to keep when there's a conflict (e.g., a table exists in both but with different columns).
- **The Solution**: A 3-pane merge tool specifically for SQL DDL.

## 🏗 Implementation Strategy

### 1. New Views & Routes

- **Route**: `/compare/resolve/:sessionId`
- **View**: `SchemaResolveView.vue`

### 2. Core Components

We will implement the design found in the stitch file, breaking it down into Vue components:

#### A. Layout (The "Shell")

- **`ResolveLayout.vue`**: Handles the dark mode structure (`bg-background-dark`, header, footer).
- **Header**: Shows "Source → Target" context and conflict count.
- **Footer**: Shows detailed cursor info and stats (lines/cols).

#### B. The Sidebar (`ConflictList.vue`)

- Displays objects grouping by status (Conflict, Resolved, Auto-mergeable).
- **UI**:
  - Amber (`#f59e0b`) for Conflicts.
  - Emerald (`#10b981`) for Resolved.
  - Objects: `users`, `triggers`, `indexes`.

#### C. The Diff Engine (`ThreeWayDiff.vue`)

_Instead of a heavy Monaco implementation for all panes, we can start with the lightweight DOM-based approach from the prototype for "Read-only" views and use Monaco only for the "Merged Result" if editing is needed._

- **Pane 1 (Source)**: "Production" (Current State).
- **Pane 2 (Target)**: "Staging" (Desired State).
- **Pane 3 (Result)**: The "Draft" DDL that will be applied.
- **Features**:
  - Syntax highlighting for SQL (Custom or via library).
  - Conflict markers (`<<<<`, `====`, `>>>>`) visualization.
  - "Accept" buttons hovering over conflict blocks.

### 3. State Management

- **Store**: `useResolveStore`
- **State**:
  - `conflicts`: Array of diff objects.
  - `currentResolution`: Map of `ObjectId -> ResolvedContent`.
  - `statistics`: { remaining: 8, resolved: 0 }.

## 📅 Execution Steps

1.  **Scaffold**: Create the view and layout based on `code.html`.
2.  **Styles**: Port the Tailwind config extensions (colors: `conflict`, `panel-dark`) to `tailwind.config.js`.
3.  **Componentize**: Split the HTML into the Vue components listed above.
4.  **Integration**: Mock the data first (using the `users` table example from the HTML) to ensure UI parity, then connect to the core `compare` bridge.

---

## 🔮 Future Expansions (based on other folders)

- **Comparison Dashboard**: A high-level summary view (pie charts of changed objects) - _Low Priority_.
- **Deep DDL Diff**: Detailed single-file diff - _Medium Priority_.
