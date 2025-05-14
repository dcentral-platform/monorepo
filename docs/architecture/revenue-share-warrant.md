## Design Document — Revenue‑Share Warrant (RSW‑NFT)

*(Version 1.0 · 14 May 2025)*

---

### 1 Purpose

Create a hybrid legal + on‑chain instrument that lets D Central reward early contributors (integrators, guard companies, OEMs) with a **capped slice of Net Platform Revenue**—without issuing equity. The instrument exists in two synced layers:

| Layer        | Artifact                                | Source of Truth                                        |
| ------------ | --------------------------------------- | ------------------------------------------------------ |
| **Legal**    | PDF executed "Revenue‑Share Warrant v1" | Governs jurisdiction, audit rights, confidentiality    |
| **On‑Chain** | ERC‑721 **RSW‑NFT**                     | Automates metering, transfers, and self‑burn at 3× cap |

---

### 2 Key Parameters

| Field              | Example           | Notes                                      |
| ------------------ | ----------------- | ------------------------------------------ |
| Contribution Value | CAD \$10 000      | FMV of in‑kind hardware/labour             |
| Revenue‑Share %    | 1 %               | Fixed across all warrants, avoids haggling |
| Cap Amount         | 3 × Contribution  | Auto‑terminates warrant at cap             |
| Payment cadence    | Quarterly         | Aligns with Stripe payout cycle            |
| Term limit         | 5 years hard stop | Fail‑safe if cap never reached             |
| Audit tolerance    | ±5 %              | Above → Company pays audit costs           |

---

### 3 Legal Document Anatomy

| Section                                    | Why it exists                                                                |
| ------------------------------------------ | ---------------------------------------------------------------------------- |
| **Purpose & Definitions**                  | Links the Contribution to the right revenue bucket ("Net Platform Revenue"). |
| **Revenue‑Share Right**                    | Grants 1 % until Cap OR Term expiry—self‑extinguishing.                      |
| **Payment Mechanics**                      | 45‑day buffer; EFT default; statement transparency.                          |
| **Audit Right**                            | Keeps Company honest; 5 % threshold deters trivial audits.                   |
| **No Equity / Transfer Restriction**       | Protects cap‑table from dilution & messy cap‑table.                          |
| **Confidentiality & Non‑Disparage**        | Standard for strategic partners.                                             |
| **Governing Law (ON) + ADRIC arbitration** | Fast, private resolution; no US discovery burden.                            |

---

### 4 RSW‑NFT Specification

| Attribute (ERC‑721 metadata) | Type             | Example                        | Purpose               |
| ---------------------------- | ---------------- | ------------------------------ | --------------------- |
| `contributor`                | `address`        |  0xA0C…                        | Payment target        |
| `contributionValue`          | `uint256`        |  1000000 (= \$10 000 in cents) | Value baseline        |
| `capAmount`                  | `uint256`        |  3000000                       | 3× value              |
| `percent`                    | `uint16` (bps)   |  100 = 1 %                     | Fixed revenue share   |
| `earned`                     | `uint256`        | Real‑time                      | Increment each payout |
| `issued`                     | `uint64` UNIX ts |                                | For 5‑year expiry     |

**Smart‑contract logic**

```solidity
function distribute(uint256 _amount) external onlyRole(ORACLE){
   for(token in activeWarrants){
       uint256 slice = _amount * token.percent / 10000;
       uint256 newEarned = token.earned + slice;
       if(newEarned >= token.capAmount){
           slice = token.capAmount - token.earned;   // top‑off
           _burn(token.id);                          // self‑destruct
       }
       token.earned = newEarned;
       USDC.transfer(token.contributor, slice);
   }
}
```

Oracle pulls **Net Platform Revenue** from Metabase via Chainlink Functions and triggers `distribute()` quarterly.

---

### 5 Lifecycle

1. **Contribution Scoping** – fill Schedule A (hardware list, hours, FMV).
2. **DocuSign** – both parties sign PDF; save to `/legal`.
3. **Mint NFT** – backend script calls `mint(contributor, metadataURI)`.
4. **Quarterly Oracle** – Stripe → Metabase → Chainlink → `distribute()`.
5. **Self‑Burn Event** emits `CapReached(tokenId)`; HTML warrant archive marked *Terminated*.

---

### 6 Process Flow Diagram

```
Contributor  ->  Sign PDF  ->  Ops uploads ▶ IPFS
                                 │
                                 ▼
            Metadata JSON ← IPFS CID
                                 │
                       mint() on RSW contract
                                 │
     ┌── quarterly ──────────────┴─────────┐
     │  Oracle fetches Net Revenue (SQL)   │
     │  distribute() sends USDC            │
     └──────────────────────────────────────┘
```

---

### 7 Edge Cases & Safeguards

| Scenario                        | Handling                                                          |
| ------------------------------- | ----------------------------------------------------------------- |
| Revenue dips to zero            | Oracle still triggers; slice = 0                                  |
| Contributor sells hardware back | No effect; warrant tied to value at issuance                      |
| Under‑payment > 5 %             | Audit clause ↔ Company reimburses                                 |
| Company acquisition             | Warrant survives as contractual liability; NFT metadata immutable |
| Regulatory token squeeze        | Warrant PDF prevails; NFT can be mirrored on permissioned chain   |

---

### 8 Implementation Checklist

| Checklist                                           | Owner     | Status |
| --------------------------------------------------- | --------- | ------ |
| Draft PDF (template v1)                             | Legal     |  ✅     |
| Create ERC‑721 contract (`RevenueShareWarrant.sol`) | Chain Dev | ☐      |
| Unit tests & Cap‑burn tests (Hardhat)               | Dev       | ☐      |
| Chainlink Functions SQL adapter                     | Data Eng  | ☐      |
| `rsw_mint.js` admin script                          | Ops       | ☐      |
| Metabase "Net Platform Revenue" view                | Finance   | ☐      |
| GitHub repo `/legal/revenue‑share‑warrant_v1.pdf`   | PM        | ☐      |

---

### 9 Future Upgrades

* **ERC‑3525 semi‑fungible** version → easier batch payouts.
* **Streaming payouts** via Superfluid for monthly granularity.
* **DAO swap option** – allow warrant holders to convert to \$DCT tokens at x‑ratio after mainnet launch.

---

Use this design document as `/docs/architecture/revenue-share-warrant.md`.
It explains the *why*, *what*, and *how*—making investor diligence and developer implementation straightforward.