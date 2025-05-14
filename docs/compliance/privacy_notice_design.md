## Design Document — Privacy Notice v1.0

*(14 May 2025 · GDPR + PIPEDA + CASL)*

> **File path recommendation:**
> *Public HTML/MD:* `/legal/privacy‑notice_v1.0.md`
> *Design‑spec (this doc):* `/docs/compliance/privacy_notice_design.md`

---

### 1 Objective

Produce a single Privacy Notice that:

1. **Complies simultaneously with GDPR (EU), PIPEDA (Canada), CASL (Canada anti‑spam), and baseline CCPA wording.**
2. Covers the two principal data streams:

   * **Platform Data** – video, access logs, sensor events stored by customers.
   * **Marketing Data** – website analytics, lead‑capture forms, newsletter.
3. Can be **parameterised** for cloud‑only pilots vs. on‑prem edge deployments.
4. Slots into the D Central website footer, Docs portal, and mobile apps.

---

### 2 Target Audience & Tone

| Audience                            | Tone / Level                                 |
| ----------------------------------- | -------------------------------------------- |
| Integrator & Enterprise Legal Teams | Formal, article‑referenced                   |
| End‑Consumers (mobile app users)    | Plain‑language summaries + accordion details |
| Regulators (OPC, ICO)               | Explicit legal bases, DPO contact            |

---

### 3 Document Layout

| §  | Section Title               | Key Content                                                                   |
| -- | --------------------------- | ----------------------------------------------------------------------------- |
| 0  | Cover Summary ("TL;DR")     | 5‑bullet plain‑language commitments                                           |
| 1  | Scope & Controller Identity | "D Central Inc., 123 Street, Toronto, ON, Canada"                             |
| 2  | How We Collect Data         | Table: video clips, account info, cookies                                     |
| 3  | Purposes & Legal Bases      | GDPR Art 6 mapping table (contract, legitimate interest, consent)             |
| 4  | Retention Periods           | Mirrors `/compliance/data_retention_policy.md`                                |
| 5  | Sharing & Sub‑Processors    | Link to live list `/legal/subprocessors.json`                                 |
| 6  | International Transfers     | EU‑>Canada adequacy + SCCs; on‑prem option                                    |
| 7  | Your Rights                 | GDPR Art 12–23, PIPEDA S.4, CASL unsubscribe                                  |
| 8  | Automated Decision‑Making   | "None" or future AI pack note                                                 |
| 9  | Cookies & Tracking          | GA4 (anonymised IP), Hotjar; banner logic                                     |
| 10 | Security Measures           | TLS 1.3, mTLS, TPM secure boot, SOC‑2 roadmap                                 |
| 11 | Contact & DPO               | [dpo@dcentral.ai](mailto:dpo@dcentral.ai), tel, EU representative placeholder |
| 12 | Updates & Versioning        | Change‑log, DAO vote reference                                                |

---

### 4 Variable Tokens

| Token                   | Example                      | Notes                      |
| ----------------------- | ---------------------------- | -------------------------- |
| `{{Company_LegalName}}` | D Central Inc.               | Autopopulated              |
| `{{DPO_Name}}`          | TBD                          | Replace once appointed     |
| `{{EU_Rep_Name}}`       | TBD EU Art 27 representative |                            |
| `{{Last_Updated}}`      | 2025‑05‑14                   | Tag release date           |
| `{{Subprocessor_URL}}`  | `/legal/subprocessors.json`  | Live JSON for easy updates |

*Store tokens in `/docs/compliance/notice_tokens.yml` so CI can replace on build.*

---

### 5 Data‑Flow & Lawful Basis Mapping (excerpt)

| Category        | Examples            | Lawful Basis                       | Retention              |
| --------------- | ------------------- | ---------------------------------- | ---------------------- |
| Video Clips     | Faces, vehicles     | Legitimate interest (Art 6 (1)(f)) | 7–90 days configurable |
| Access Logs     | Badge ID, timestamp | Contract (Art 6 (1)(b))            | 365 days               |
| Billing Data    | Name, address, VAT  | Contract + legal obligation        | 7 yrs                  |
| Marketing Leads | Name, email, IP     | Consent (CASL double opt‑in)       | 24 mo inactive         |

---

### 6 Generation & Deployment Workflow

| Step                | Tool / File                                                            |
| ------------------- | ---------------------------------------------------------------------- |
| Draft v0.9          | Prompt ChatGPT: *"Write GDPR‑compliant privacy notice using table X."* |
| Human red‑line      | Flat‑fee review (Goodlawyer)                                           |
| Convert to Markdown | Paste into `/legal/privacy‑notice_v1.0.md`                             |
| CI build            | `pandoc` → `privacy.html` saved under `/docs/_site`                    |
| Website footer      | Framer `<Link href="/privacy">Privacy</Link>`                          |
| Mobile app          | RN WebView `"https://dcentral.ai/privacy"`                             |

---

### 7 Compliance Verification

* **GitHub Action:** `npm run markdown-link-check` to ensure all policy links resolve.
* **GDPR Checklist updates** – tick boxes in `/docs/compliance/gdpr_casl_checklist.md`.
* **TrustedSite™ Privacy Seal** – submit notice URL for scan.

---

### 8 Edge Cases

| Case                                                   | Resolution                                                              |
| ------------------------------------------------------ | ----------------------------------------------------------------------- |
| Operator stores video longer than 90 days              | Operator becomes *independent controller*; notice clarifies role split. |
| Consumer opts‑out of marketing but not service e‑mails | CASL transactional exemption §6.                                        |
| EU lead form                                           | Trigger geo‑based double‑opt‑in flow; consent recorded in HubSpot.      |

---

### 9 Version Control & DAO Governance

* File header contains `Version`, `Effective`, `Supersedes`, and Git commit hash.
* **BrandDAO** proposal required for any material change (Art 13 transparency).
* Changelog entry in `/docs/compliance/privacy_notice_changelog.md`.

---

### 10 Implementation Checklist

| Item                            | Owner      | Status |
| ------------------------------- | ---------- | ------ |
| Draft v0.9 via ChatGPT          | PM         | ☐      |
| Legal review & redlines         | Counsel    | ☐      |
| Publish Markdown & build CI     | DevOps     | ☐      |
| Add footer links (site + docs)  | WebDev     | ☐      |
| Update checklist & DAO snapshot | Compliance | ☐      |

---

Place this design file in `/docs/compliance/privacy_notice_design.md`.
It provides the **structure, tokens, workflow, and compliance reasoning** behind your Privacy Notice—making audits and future updates painless.