## Design Document — Mutual NDA v1.0

*(14 May 2025 · Ontario Law · 2‑Year Term)*

> **File path recommendation:** `/docs/compliance/nda_design.md`
> **Template PDF/MD:** `/legal/mutual‑nda_v1.0.*`

---

### 1 Purpose & Goals

| Goal                                | Why it matters                                            |
| ----------------------------------- | --------------------------------------------------------- |
| **Protect pre‑pilot trade secrets** | Edge AI models, BOM costs, tokenomics, pilot data.        |
| **Symmetric obligations**           | Both D Central and counter‑party exchange sensitive info. |
| **Fast execution**                  | Two pages, plain language, < 10 min DocuSign cycle.       |
| **Open‑source carve‑out**           | Preserve freedom to release independent code.             |
| **GDPR / PIPEDA ready**             | Integrator or EU vendor can sign without addendum.        |

---

### 2 Document Anatomy

| Section                       | Function                                                      | Editable Fields                       |
| ----------------------------- | ------------------------------------------------------------- | ------------------------------------- |
| *Heading / Parties*           | Identifies entities, Effective Date                           | Legal names, addresses                |
| 1 Purpose                     | Limits use of info to *"edge‑security business relationship"* | N‑A                                   |
| 2 Definitions                 | Sets "Confidential Information" scope + carve‑outs            | N‑A                                   |
| 3 Recipient Obligations       | Care standard, need‑to‑know test                              | N‑A                                   |
| 4 Mandatory Disclosure        | Safeguard vs. subpoenas                                       | N‑A                                   |
| 5 Return or Destruction       | 10‑day cleanup window                                         | Adjust days if integrator requests    |
| 6 Term & Survival             | 2‑year obligation; survival clauses                           | Term length variable                  |
| 7 No Licence                  | Protects IP rights                                            | N‑A                                   |
| 8 Open‑Source Clause *(opt.)* | Allows independent OSI contributions                          | Delete if counter‑party uncomfortable |
| 9 Data Protection             | GDPR / PIPEDA compliance hook                                 | Add CCPA if US retail partner         |
| 10 Remedies                   | Injunctive relief                                             | N‑A                                   |
| 11 Governing Law & ADRIC      | Ontario + arbitration                                         | Jurisdiction negotiable               |
| 12 Miscellaneous              | Entire agr., amendments, assignment, counterparts             | N‑A                                   |
| Signature Blocks              | Execution                                                     | Name / title / date lines             |

---

### 3 Variable Table

| Token                  | Example                 | Source                                |
| ---------------------- | ----------------------- | ------------------------------------- |
| `{{EffectiveDate}}`    | 2025‑05‑18              | Today's date                          |
| `{{PartyA_LegalName}}` | SecureTech Ltd.         | Counter‑party registration            |
| `{{PartyA_Address}}`   | 123 King St. W, Toronto | Counter‑party                         |
| `{{TermYears}}`        | 2                       | Default; can set 3 for longer R\&D    |
| `{{Jurisdiction}}`     | Ontario                 | Change if US partner demands Delaware |

---

### 4 Workflow

1. **Generate draft** via ChatGPT prompt:
   *"Create Mutual NDA with {{PartyA}}, {{EffectiveDate}}, 2‑year term."*
2. **Insert logo & styling** in Google Docs → download PDF.
3. **Law‑clinic review** (flat fee) if template modified.
4. **Upload to DocuSign**; drag signature & date fields.
5. Upon execution,

   * save PDF to `/legal/mutual-nda_signed_<Party>.pdf`
   * commit hash of PDF SHA‑256 to Git (`/legal/nda_manifest.txt`).
6. Mark roadmap issue *W1‑02* **Done**; CI moves card.

---

### 5 Security Handling

| Storage                    | Retention            | Access           |
| -------------------------- | -------------------- | ---------------- |
| Git LFS (encrypted branch) | Indefinite for audit | Founder, DPO     |
| SharePoint Legal Vault     | 7 yrs                | Founder, counsel |

---

### 6 Edge Cases & Guidance

| Scenario                                   | Action                                                      |
| ------------------------------------------ | ----------------------------------------------------------- |
| Counter‑party wants **perpetual** term     | Accept only if carve‑out for public domain info; update §6. |
| Wants **court litigation** not arbitration | Accept Ontario Superior Court; remove ADRIC line.           |
| Wants mutual **indemnity**                 | Push back—NDA is duty of care, not indemnity instrument.    |
| Open‑source clause rejected                | Delete §8; still track independent code diffs for proof.    |

---

### 7 Diff Log (v1.0 → Future)

| Version | Change           | Reason                       |
| ------- | ---------------- | ---------------------------- |
| v1.0    | Initial template | Covers open‑source carve‑out |
| v1.1    | TBD              | e.g., add CCPA wording       |

Changelog lives in `/legal/CHANGELOG_NDA.md`.

---

### 8 Implementation Checklist

| Item                                    | Folder                           | Status |
| --------------------------------------- | -------------------------------- | ------ |
| `mutual‑nda_v1.0.md` ⟶ `/legal/`        | ✅ (generated)                    |        |
| `mutual‑nda_v1.0.pdf`                   | convert via Pandoc / Google Docs | ☐      |
| Signature manifest (`nda_manifest.txt`) | SHA‑256, signer names            | ☐      |
| Roadmap issue `W1‑02`                   | Milestone Week 1                 | ☐      |

---

Place this design file in your repo and you've documented the *why*, *what*, and *how* of your NDA template—meeting investor, partner, and compliance expectations.