# DCentral DAO Voting Playbook

## Overview

This document outlines the procedures, guidelines, and best practices for conducting governance votes within the DCentral DAO ecosystem. It serves as a reference for proposal authors, voters, and governance facilitators.

## Table of Contents

1. [Governance Principles](#governance-principles)
2. [Proposal Types](#proposal-types)
3. [Voting Process](#voting-process)
4. [Proposal Lifecycle](#proposal-lifecycle)
5. [Voting Powers and Delegation](#voting-powers-and-delegation)
6. [Emergency Procedures](#emergency-procedures)
7. [Governance Tools](#governance-tools)
8. [Security Considerations](#security-considerations)
9. [Best Practices](#best-practices)
10. [Appendix](#appendix)

## Governance Principles

The DCentral DAO operates on the following core principles:

- **Transparency**: All governance actions and proposals must be openly visible to all stakeholders.
- **Inclusivity**: The governance process must be accessible to all token holders, regardless of holdings size.
- **Security**: Governance mechanisms must prioritize system security and sustainability.
- **Effectiveness**: Governance should be efficient while maintaining adequate deliberation time.
- **Alignment**: Proposals should align with the DCentral mission and vision.

## Proposal Types

### 1. Core Protocol Proposals

These proposals affect the core functionality of the DCentral platform:

- Protocol parameter changes
- Smart contract upgrades
- Network security enhancements
- Cross-chain integration modifications

**Quorum Requirement**: 10% of total voting power
**Approval Threshold**: 66% majority

### 2. Treasury Proposals

Proposals related to the management of the DAO treasury:

- Grant allocations
- Investment strategies
- Budget approvals
- Expense reimbursements

**Quorum Requirement**: 8% of total voting power
**Approval Threshold**: 60% majority

### 3. Brand and Marketing Proposals

Proposals related to the DCentral brand and marketing strategies:

- Brand guideline changes
- Major marketing initiatives
- Partnership approvals
- Community events

**Quorum Requirement**: 5% of total voting power
**Approval Threshold**: 55% majority

### 4. Policy and Process Proposals

Proposals to modify governance policies, processes, or documentation:

- Changes to this playbook
- New governance processes
- Community guidelines
- Code of conduct modifications

**Quorum Requirement**: 7% of total voting power
**Approval Threshold**: 60% majority

### 5. Meta-Governance Proposals

Proposals related to DCentral's participation in other DAOs or governance systems:

- Voting strategies for other protocols
- Delegation of voting power
- Cross-DAO collaborations

**Quorum Requirement**: 8% of total voting power
**Approval Threshold**: 65% majority

## Voting Process

### Step 1: Discussion and Feedback

Before formal submission, proposals should go through:

1. Initial discussion in Discord or community forums
2. Temperature check in the #governance channel
3. Formal RFC (Request for Comments) on the governance forum
4. Incorporation of community feedback

### Step 2: Formal Proposal Submission

1. Author drafts the proposal using the standard template
2. Proposal is submitted to the governance forum for final review
3. After 48 hours of community review, the proposal moves to Snapshot

### Step 3: On-chain Voting

1. Proposal is published on Snapshot/voting platform
2. Voting period begins (duration depends on proposal type)
3. Voters cast votes: FOR, AGAINST, or ABSTAIN
4. Voting power is calculated based on token holdings at snapshot time

### Step 4: Implementation

1. Results are finalized after voting period ends
2. If approved, proposal moves to implementation queue
3. Technical team implements approved changes
4. Community is notified of implementation completion

## Proposal Lifecycle

```
Temperature Check → Forum Discussion → Formal Proposal → 
On-chain Vote → Results → Implementation → Monitoring
```

### Expected Timeframes

| Stage | Duration | Purpose |
|-------|----------|---------|
| Temperature Check | 3-5 days | Gauge initial community sentiment |
| Forum Discussion | 5-7 days | Detailed feedback and refinement |
| Formal Proposal | 2 days | Final review before vote |
| Voting Period | 3-7 days (by type) | Official voting |
| Implementation | Varies by complexity | Technical implementation |

## Voting Powers and Delegation

### Token-based Voting

Voting power is primarily determined by:

1. DBRAND token holdings (1 token = 1 vote)
2. DCENTRAL-NFT holdings (each NFT provides additional voting weight)
3. Locked tokens in governance staking (with multipliers based on lock time)

### Delegation

Token holders can delegate their voting power to trusted community members:

1. Delegation can be performed through the governance portal
2. Delegated voting power can be revoked at any time
3. Delegate performance metrics are publicly visible
4. Delegation does not transfer token ownership

### Voting Power Calculation

The formula for calculating voting power is:

```
Voting Power = DBRAND Balance + (NFT Count × Multiplier) + (Staked Tokens × Time Multiplier)
```

## Emergency Procedures

### Emergency Action Committee (EAC)

The EAC consists of:
- 2 Core Team Members
- 3 Community-elected Representatives
- 2 Technical Advisors

### Emergency Proposal Process

1. Emergency identified and reported to EAC
2. EAC convenes within 4 hours to assess severity
3. If deemed critical, expedited proposal process is initiated
4. Shortened voting period (24 hours minimum)
5. Implementation immediately follows approval

### Security Vulnerabilities

For critical security vulnerabilities:
1. Report privately to security@dcentral.io
2. Do not disclose publicly until patched
3. EAC may implement temporary measures without vote
4. Retroactive governance approval required within 72 hours

## Governance Tools

### Official Platforms

| Platform | Purpose | URL |
|----------|---------|-----|
| Snapshot | Voting | https://vote.dcentral.io |
| Discourse | Discussion | https://forum.dcentral.io |
| Github | Technical proposals | https://github.com/dcentral-dao/governance |
| Discord | Community discussions | https://discord.gg/dcentral |

### Governance Dashboards

- Governance Overview: https://dcentral.io/governance
- Proposal Tracker: https://dcentral.io/proposals
- Delegate Leaderboard: https://dcentral.io/delegates

## Security Considerations

### Vote Security

- Snapshot timestamps are announced 24 hours in advance
- Multi-sig wallets secure implementation actions
- Timelock delays on all protocol parameter changes
- Anti-manipulation measures for large token movements

### Smart Contract Security

- All governance contracts undergo:
  - Multiple independent audits
  - Formal verification where possible
  - Public bug bounty program
  - Extensive testing on testnets

## Best Practices

### For Proposal Authors

1. Engage early with the community
2. Provide comprehensive documentation
3. Consider alternative approaches
4. Include technical implementation details
5. Address potential risks and mitigations
6. Outline clear success metrics

### For Voters

1. Research proposals thoroughly
2. Consider long-term impacts
3. Vote based on project's best interest
4. Participate in discussion forums
5. Delegate thoughtfully if unable to actively participate

### For Delegates

1. Maintain transparent voting rationale
2. Regularly engage with delegators
3. Publish voting statements for significant proposals
4. Consider diverse community perspectives
5. Disclose any potential conflicts of interest

## Appendix

### Proposal Templates

#### Standard Proposal Template:

```markdown
# [Title of Proposal]

## Simple Summary
[One sentence description]

## Abstract
[2-3 paragraph summary]

## Motivation
[Why should this be implemented?]

## Specification
[Technical details of implementation]

## Benefits
[What benefits does this bring?]

## Drawbacks
[What are the drawbacks or risks?]

## Vote Options
- FOR: Implement the proposal as specified
- AGAINST: Do not implement this proposal
- ABSTAIN: Formally abstain from voting

## Timeline
[Implementation timeline if approved]

## References
[Links to relevant discussions, research, precedents]
```

### Glossary

- **Quorum**: Minimum participation required for a valid vote
- **Snapshot**: Point in time when token balances are captured for voting
- **Delegation**: Assigning your voting power to another address
- **Timelock**: Mandatory delay between vote approval and implementation
- **Multi-sig**: Wallet requiring multiple signatures to execute transactions

### Additional Resources

- [DCentral Governance Overview](https://docs.dcentral.io/governance)
- [Technical Implementation Guide](https://docs.dcentral.io/governance/implementation)
- [Governance FAQ](https://docs.dcentral.io/governance/faq)
- [Community Governance Call Schedule](https://calendar.dcentral.io/governance)