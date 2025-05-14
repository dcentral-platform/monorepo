## Design Document — `LICENSE.txt` Strategy

*(v1.0 · 14 May 2025)*

> **Repository path:** `/LICENSE.txt`
> **Design‑spec path:** `/docs/compliance/license_design.md`

---

### 1 Purpose

* Provide a **single, repo‑root licence file** that instantly tells lawyers and open‑source scanners **what they can do with each asset**.
* Support two distinct audiences:

  1. Developers who consume or fork **code**.
  2. Partners who reproduce or translate **documentation & design assets**.

---

### 2 Chosen Model — **Dual Licence**

| Asset Class                                    | Licence                     | Why                                                                                       |
| ---------------------------------------------- | --------------------------- | ----------------------------------------------------------------------------------------- |
| **Source code, scripts, smart‑contracts**      | **GPL v3**                  | Copyleft ensures improvements flow back; widely understood in security & embedded worlds. |
| **Documentation, decks, media, design tokens** | **Creative Commons BY 4.0** | Allows integrators and press to remix/translate while requiring attribution.              |

> Anything not fitting those classes can be whitelisted via `NOTICE` section (see §5).

---

### 3 `LICENSE.txt` File Layout

```text
========================
D CENTRAL MONOREPO
MASTER LICENCE FILE
========================

1. OVERVIEW
   • Code  – GPL‑3.0‑or‑later
   • Docs  – CC‑BY‑4.0
   • Third‑party components listed in /legal/open‑source‑license‑matrix.xlsx

2. GPL‑3.0‑OR‑LATER TERMS …  (full text ~5 KB)

3. CC‑BY‑4.0 LEGAL CODE …    (full text ~7 KB)

4. NOTICE (Whitelist / Exceptions)
   * The file /design/logo/static/dcentral-icon.svg is © 2025 D Central Inc.
     and licensed under CC‑BY‑4.0 with trademark restriction.
```

**Why embed both full texts?**
Some jurisdictions still require licence text to be “distributed with the work,” and many scanners look for magic strings inside `LICENSE.txt`.

---

### 4 Header Snippets for Source Files

```go
// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright 2025 D Central Inc.
```

```md
<!---
Copyright 2025 D Central Inc.
SPDX‑License‑Identifier: CC‑BY‑4.0
-->
```

*Added automatically by pre‑commit hook using `license‑headers`.*

---

### 5 Exceptions / NOTICE Section

* Proprietary fonts, trademarks, or vendor SDKs that cannot inherit GPL/CC must be declared here.
* Example entry:

```
5. FONTS
   The Inter typeface (font files under /design/fonts) is licensed under the
   SIL OFL 1.1 and NOT under GPL or CC‑BY.  See /design/fonts/OFL.txt.
```

---

### 6 Compliance Workflow

| Step                              | Tool / File                                                                                  |
| --------------------------------- | -------------------------------------------------------------------------------------------- |
| Developer creates new dep         | Add to `go.mod` / `package.json`                                                             |
| CI **Trivy SBOM** step            | Generates SPDX JSON                                                                          |
| `scripts/ci/sbom_diff_checker.sh` | Fails if new licence not GPL‑compatible **and** missing in `open‑source‑license‑matrix.xlsx` |
| Weekly cron                       | Exports combined SPDX → `/data-room/sbom_full.spdx`                                          |

---

### 7 Contributor Guidance

* PR template reminds: “All new code will be GPL‑3.0‑or‑later.”
* Docs contributors must add attribution line at end of file.
* External logos/images must list **source URL + licence** in front‑matter.

---

### 8 Edge‑Cases & Future Proofing

| Scenario                                  | Action                                                                   |
| ----------------------------------------- | ------------------------------------------------------------------------ |
| Commercial OEM demands permissive licence | Mirror code in `/enterprise/` module under Apache‑2.0 and keep core GPL. |
| Docs translated by partner                | Allowed under CC‑BY; must credit “© 2025 D Central Inc.”                 |
| Integrated MIT‑licensed library           | GPL‑3.0 is compatible; note in matrix.                                   |
| Trademark usage                           | Governed by separate **Brand Guidelines**; reference link in NOTICE.     |

---

### 9 Implementation Checklist

| File / Task                                          | Status        |
| ---------------------------------------------------- | ------------- |
| `/LICENSE.txt` with dual text                        | ☐             |
| `open‑source‑license‑matrix.xlsx` initial population | ☐             |
| Pre‑commit header hook (`reuse lint`)                | ☐             |
| CI SBOM diff job                                     | ☐             |
| Docs page `/docs/compliance/license_design.md`       | ✅ (this file) |

---

### 10 Versioning

* **v1.0** — dual GPL 3 / CC‑BY 4.0, initial NOTICE section
* Changes to licence terms require **BrandDAO Snapshot vote** + TAG `license‑change`.

Place the completed `LICENSE.txt` in repo‑root, wire up the CI header checks, and your project will pass most corporate open‑source compliance reviews on day one.
