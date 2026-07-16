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