# Managing Database Connections in TheAndb

This guide explains how to set up and manage your database connections securely.

## 1. Creating a Connection
To create a new connection, follow these steps:
- Go to the **Global Connections** tab (Terminal/Plus icon in the sidebar).
- Click the **Add Connection** button.
- Select your database engine (SQLite, MySQL, or PostgreSQL).
- Fill in the connection details (Host, Port, User, Password).

## 2. Using Templates
Templates allow you to pre-define common connection settings:
- Go to **Settings > Connections**.
- Create a template for common environments (Dev, Staging, Prod).
- When creating a new connection, you can select a template to auto-fill details.

## 3. Secure Storage (Vault)
All passwords and sensitive tokens are stored in the **Workspace Vault**, which is encrypted locally. You can manage vault settings in **Settings > Vault**.

---
*Tip: Use the AI Assistant to verify if your connection string follows best practices.*
