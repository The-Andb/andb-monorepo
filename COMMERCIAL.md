# Commercial Usage Policy

TheAndb is fully open source under **AGPL-3.0** — `andb-core`, `andb-cli`, `andb-mcp`, `andb-desktop`, and `andb-www` all ship under the same license. There is no separate proprietary tier. This document clarifies what AGPL-3.0 permits and where a commercial license is still needed.

---

## ✅ Permitted (No commercial license required)

*   **Individual & team internal use:** Using any TheAndb component — including the Desktop app — to manage your own team's databases, regardless of whether your company is commercial.
*   **Production use:** Running TheAndb as a primary tool within a commercial engineering team, including the Desktop application.
*   **CI/CD pipelines:** Integrating `andb compare` or `andb export` into automated pipelines (GitHub Actions, GitLab CI, Jenkins) for drift detection and deployment guards.
*   **Self-hosting:** Running the engine on your own infrastructure for your own organization's benefit.
*   **Education & research:** Using the source code for learning, academic work, or non-commercial publication.
*   **Open-source projects:** Integrating TheAndb into projects that are themselves released under a compatible open-source license.
*   **Modifying the source:** Forking and modifying any component for your own use, provided modifications distributed to others (including over a network) are published under AGPL-3.0.

## ❌ Requires a Commercial License

*   **SaaS re-hosting:** Wrapping TheAndb and offering it as a managed database schema service to third-party customers without publishing your modifications under AGPL-3.0.
*   **Competing products:** Embedding TheAndb in a commercial product that competes directly with TheAndb's own offerings.
*   **White-labeling:** Distributing modified versions of TheAndb as part of a closed-source commercial product without disclosing source modifications (required by AGPL-3.0).

> **AGPL-3.0 in plain language:** If you use TheAndb — modified or not — to *provide a service to others over a network*, and your modifications aren't published under AGPL-3.0, you need a commercial license instead.

---

## Why AGPL-3.0 for the Whole Stack?

AGPL-3.0 is the strongest form of copyleft available: it closes the "SaaS loophole" that regular GPL leaves open, where a cloud provider can re-host modified source without ever distributing it (and therefore without ever publishing changes). Applying it across the entire stack — engine and desktop app alike — means:

*   You get **real, verifiable source access** to everything you run, not a source-available preview.
*   Anyone offering a hosted TheAndb-based service must contribute their modifications back.
*   The project's sustainability comes from **sponsorship**, not from gating features behind a proprietary build.

## Commercial Licensing & Enterprise Inquiries

For a commercial exception (SaaS re-hosting, white-label OEM) or enterprise support inquiries, contact **ph4n4n@gmail.com**.

---

## Support the Project

TheAndb doesn't hold anything back behind a paywall — sponsorship doesn't unlock code, it funds the time that keeps the project moving: development, testing, CI/CD, releases, and documentation. See **[Sponsor The-Andb](https://github.com/sponsors/The-Andb)**.
