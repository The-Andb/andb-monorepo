# AI Knowledge Base (RAG) Guide

TheAndb AI Assistant uses a Retrieval-Augmented Generation (RAG) system to provide context-aware answers based on internal documentation.

## How it works

1. **Storage**: The system scans the `docs/` folder in your Workspace Vault and the internal `docs/` folder of the application.
2. **Indexing**: It parses all `.md` files into searchable chunks.
3. **Retrieval**: When you ask a question, the system uses keyword-based weighting to find the most relevant sections of documentation.
4. **Augmentation**: These sections are injected into the AI's prompt as "Internal Documentation".

## Adding your own knowledge

To give the AI assistant more context about your specific database standards or team workflows:

1. Open your Workspace Vault directory (the path where `andb-storage.db` is located).
2. Create a folder named `docs`.
3. Add any `.md` files containing your team's SQL standards, naming conventions, or common troubleshooting steps.
4. Restart the AI Assistant or reload the app.

## Current Limitations

- **No Vector Embeddings**: Currently, the system uses keyword matching. Support for vector embeddings (semantic search) is planned for a future update.
- **File Types**: Only Markdown (`.md`) files are supported.
