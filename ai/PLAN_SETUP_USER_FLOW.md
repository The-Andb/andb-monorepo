# PRD & Tech Spec: Setup Restricted User Flow (`the_andb`)

## 1. Overview

The goal is to implement a professional, security-first connection flow. Instead of requiring `root` or `admin` credentials for daily operations, "The Andb" will guide users to create a dedicated user, `the_andb`, with the minimum permissions required for the app's functionality.

**This flow will be implemented as a "Global Setup Template"**, ensuring a consistent, high-trust experience across all database connection types.

---

## 2. The "Trust & Safety" Communication Strategy

To ensure user peace of mind, all UI elements must adhere to these messaging guidelines:

- **Proactive Explanation**: Instead of just asking for a password, explain _why_ (e.g., "We use an admin account only once to set up a playground. We never store your admin password.").
- **Visibility of Action**: Every SQL command generated must be readable. No "Black Box" operations.
- **Safety Badge**: Use a persistent "Safe Environment" indicator throughout the setup.
- **Micro-copy for Reassurance**:
  - _"The Andb will NEVER delete your data."_
  - _"We only ask for permissions that allow us to read your database structure."_
  - _"The admin password you enter is used only for this session and is immediately discarded."_

---

## 3. User Journey (UI/UX - Global Template)

### Step 1: Connection Setup (Initial)

- **UI**: Standard form (Host, Port, DB Name, Admin Username, Admin Password).
- **Action**: App tests the connection using these credentials.
- **Reassurance**: Small lock icon next to the password field with a tooltip: "Encrypted in memory, never saved to disk."

### Step 2: Choose Setup Mode & Configure Permissions

- **Mode Toggle**: **"Automatic (Recommended)"** vs **"Manual (Advanced/DBA)"**.
- **Permission Checklist**:
  - **READ (Mandatory)**: Export DDL, View Schema. (Description: "Required to visualize your database.")
  - **WRITE (Optional)**:
    - [ ] Alter Table (Description: "Allow The Andb to suggest and apply schema changes.")
    - [ ] Update Views (Description: "Allow updating view definitions.")
- **Visuals**: Dynamic "Permission Level" meter (e.g., "Level 1: Read-Only" 🟢 to "Level 3: Full DDL Support" 🟠).

### Step 3: Execution

#### Option A: Automatic Setup

- **Action**: User confirms "Set up User".
- **Feedback**: A real-time log show exactly what's happening:
  - `> Checking Admin credentials... [OK]`
  - `> Creating 'the_andb' user... [OK]`
  - `> Applying Restricted Permissions... [OK]`
  - `> Discarding Admin Credentials... [DONE]`

#### Option B: Manual Setup

- **Action**: Display the SQL script.
- **Reassurance**: "You are in full control. Review the script below before running it on your server."

### Step 4: Health Check (Verification)

- **Action**: A detailed report showing:
  - 🛡️ **Base Connection**: PASS
  - 🛡️ **Schema Reading**: PASS
  - 🛡️ **Sanbox Alter Test**: PASS (or SKIPPED if disabled)

---

## 4. Technical Implementation (Global Template)

### A. Component Architecture

- **`SetupUserTemplate.vue`**: A reusable layouts for the setup process.
- **`SetupStepsStore`**: A global state to manage connection metadata during the setup phase.

### B. Backend Connection Strategy

- **Admin Pool (Ephemeral)**: Lives only in the `SetupService` memory. Destroyed on completion or failure.
- **Andb Pool (Persistent)**: The final connection saved to the app's config.

### C. SQL Generator & Probing

- **Template Logic**: Shared between Auto and Manual paths to ensure consistency.
- **Sanbox Probing**: Use `CREATE TEMPORARY TABLE` to ensure zero impact on user data during testing.

---

## 5. Security Guards (The "No-Go" List)

| Keyword         | Action    | Message to User                                               |
| :-------------- | :-------- | :------------------------------------------------------------ |
| `DROP DATABASE` | **BLOCK** | "Deletion of databases is not permitted."                     |
| `TRUNCATE`      | **BLOCK** | "Clearing table data is outside the scope of The Andb."       |
| `DELETE`        | **BLOCK** | "DML operations (Data manipulation) are disabled for safety." |

---

## 6. Acceptance Criteria

1. **Consistency**: The setup flow looks and feels identical regardless of the original DB type.
2. **Transparency**: The user must be able to see the exact SQL being run in Auto mode if they click "View Log".
3. **No Credential Leaks**: Automated tests must verify the Admin Password is NOT present in any persistent storage or logs.
4. **Error UX**: Every error must offer a "Solution" (e.g., "Check if your user has 'GRANT' privileges").

---

## 7. Milestones

- **Phase 1**: Design the Global Setup UI Template with focus on "Reassurance". (✅ Done)
- **Phase 2**: Core Setup Logic (Auto/Manual flows). (✅ Done)
- **Phase 3**: Verification & Validation (Probing/Health Check). (✅ Done)
- **Phase 4**: Production Hardening (Sanitization/Blocklist). (✅ Done)

---

## 8. Summary of Achievements

- **Component `SetupUserTemplate.vue`**: A high-end, glassmorphism-inspired UI for setup.
- **Trust-First Copywriting**: All micro-copy refined in English and Vietnamese to maximize user trust.
- **Verification Engine**: Multi-stage health check (Base, Read, Sandbox Write).
- **Security Design**: Ephemeral admin credential handling (discarded from memory).
- **Seamless Integration**: Directly accessible via the global `ConnectionForm.vue`.
