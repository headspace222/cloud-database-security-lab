# Azure SQL Database Security Baseline

**Microsoft Entra-only authentication, network-restricted access, and audit logging wired into a centralised observability workspace - built on Azure SQL Database's genuinely permanent free offer, not a time-boxed trial.**

Every project in this portfolio touches Storage in some form - Blob, Table, Queue - but none has touched an actual relational database, a real gap for most cloud and platform engineer roles. This lab closes it, and does so with a security posture that ties directly back into the rest of this portfolio: no SQL authentication at all (only Entra ID), firewall-restricted network access, and audit logs flowing into the same Log Analytics workspace the observability capstone already built.

## Why the Free Offer Is Safe to Build On

Azure SQL Database's free offer, generally available since 2025, provides up to 10 serverless databases per subscription, each with 100,000 vCore-seconds of compute and 32GB of storage free every month, for the lifetime of the subscription - not a 12-month or 30-day trial. Critically, this offer works regardless of subscription type, including Free Trial subscriptions specifically, and draws from a completely separate quota and billing pool than the VM-based compute that blocked three earlier attempts in this portfolio (Function Apps, AKS, Databricks).

## What's Included

| Component | Purpose |
|---|---|
| scripts/configure-security.ps1 | Configures Entra-only authentication, a restrictive firewall rule, and audit logging |
| docs/architecture.md | Design rationale: Entra-only auth vs. SQL auth, network restriction, and audit logging |
| docs/architecture-diagram.md | Visual diagram of the authentication and audit flow |
| docs/setup-guide.md | Full reproduction steps with screenshot evidence points |
| docs/screenshots/ | Evidence of Entra-only auth actually rejecting SQL login attempts |

## Security Baseline Summary

| Control | Configuration | Why |
|---|---|---|
| Authentication | Microsoft Entra ID only - SQL authentication disabled entirely | Removes an entire credential class from the attack surface |
| Network access | Firewall rule restricted to a specific client IP | Denies connections from anywhere else by default |
| Auditing | Enabled, sent to the observability capstone's shared Log Analytics workspace | Every login attempt and query becomes queryable alongside every other resource's logs |
| Encryption at rest | Transparent Data Encryption (enabled by default) | Confirmed and documented, not assumed |

## Cost

- The database itself: free, permanently, within the monthly 100,000 vCore-second / 32GB allowance
- Entra-only authentication, firewall rules, TDE: all configuration, no additional cost
- Auditing to Log Analytics: covered by the same always-free monthly ingestion grant used throughout this portfolio

## Screenshots

Evidence of the free database, the security configuration, and the authentication tests actually working, captured against a live Azure subscription during this build. Files live in docs/screenshots/.

1. Free Database Created
Image: docs/screenshots/01-free-database-created.png
The SQL database shown Online, with the free offer confirmed directly on the Overview page: Pricing tier Free General Purpose Serverless, and the full 100,000 vCore seconds remaining for the month.

2. Security Baseline Configured
Image: docs/screenshots/02-security-configured.png
The Entra admin set, Entra-only authentication confirmed enabled, and a firewall rule scoped to exactly one known IP address, all verified in one script run.

3. SQL Authentication Rejected
Image: docs/screenshots/03-sql-auth-rejected.png
A connection attempt using a fabricated SQL username and password, rejected with the precise reason stated directly by the server: Azure Active Directory only authentication is enabled. Not a generic failure, an explicit structural rejection.

4. Entra Authentication Succeeds
Image: docs/screenshots/04-entra-auth-succeeds.png
The same server, connected successfully via Microsoft Entra ID, after working through a genuine tenant-routing issue with a guest account and landing on Azure CLI authentication as the reliable path.

5. Audit Configuration Confirmed
Image: docs/screenshots/05-audit-configuration-confirmed.png
Audit logging enabled and correctly pointed at the shared observability workspace, reached only after diagnosing a tag-policy conflict across three different tools and resolving it via a targeted Azure CLI policy exemption.

## Conclusion

This project set out to close a real, specific gap in this portfolio: nine earlier projects touched storage, identity, networking, and observability, but none touched an actual database. That gap is closed here, with a security posture that goes further than most database tutorials attempt: not just preferring Microsoft Entra authentication, but disabling SQL authentication entirely, proven by a genuine rejected login attempt sitting right next to a genuine accepted one.

The build also produced this portfolio most involved troubleshooting arc yet, and it is worth naming plainly rather than smoothing over. A guest identity routed through the wrong tenant during interactive browser authentication, a modern rewrite of a familiar command-line tool with an unfamiliar flag set, a tag-enforcement policy catching its fifth distinct resource type across this portfolio, and a genuine bug in a specific PowerShell module version that Azure CLI did not share. Each of these was diagnosed on its own terms rather than worked around blindly, and each is documented in full in docs/architecture.md.

Not every thread was tied off. Live query verification of audit data in the shared observability workspace was not achieved, despite confirmed-correct configuration, and that limitation is stated as plainly as every success in this project. A portfolio built entirely from clean successes would be a less honest one than this.

Ten projects, one throughline: real Azure resources, built on genuinely free-tier services, with the actual obstacles encountered documented rather than edited out.

## Setup Guide

Full steps: docs/setup-guide.md

## Skills Demonstrated

- Database security hardening: Entra-only authentication as a deliberate choice to eliminate an entire credential class
- Network-restricted PaaS access: firewall rules scoped to specific, known sources
- Audit logging integration: connecting a new resource type into an existing centralised observability workspace
- Free-tier service selection judgement: recognising the difference between a permanent free offer and a time-boxed trial
- Portfolio-level integration: this lab connects to the identity governance lab's authentication model and the observability capstone's logging pipeline

## Author

Jane - Cloud & Infrastructure Engineer, AZ-104 candidate.
The tenth and final project in a broader Azure governance and security portfolio.