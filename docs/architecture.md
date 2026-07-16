# Architecture and Design Rationale

## Why the Free Offer, Not a Manually-Sized Database

Azure SQL Database's free offer, made generally available in 2025, provides up to 10 serverless General Purpose databases per subscription, each with 100,000 vCore-seconds and 32GB free every month, for the lifetime of the subscription - genuinely permanent, not a trial. This matters specifically for this portfolio: three earlier attempts at compute-based services (Function Apps, AKS, Databricks) hit a hard, permanent, non-negotiable zero-VM-quota wall on this subscription's Free Trial type. The SQL Database free offer draws from an entirely separate quota and billing pool - vCore-seconds allocated to a serverless PaaS database, not VM cores - and explicitly documents itself as available regardless of subscription type, including Free Trial specifically.

What happens at the free limit: if the monthly 100,000 vCore-second allowance is exhausted, the database auto-pauses until the next calendar month by default. At this lab's actual usage, the free allowance is not remotely at risk of being exhausted.

## Entra-Only Authentication: Removing a Credential Class, Not Strengthening It

Azure SQL Database supports two authentication models, and they are not equally strong:

- SQL authentication: a username and password stored and managed within SQL Server itself, independent of Entra ID entirely.
- Microsoft Entra authentication: the same identity, RBAC, and Conditional Access governance already applied everywhere else in this portfolio, extended to database access.

This lab goes a step further than simply preferring Entra authentication - it disables SQL authentication entirely via Set-AzSqlServerActiveDirectoryOnlyAuthentication. There is no SQL login/password pair anywhere on this server capable of authenticating, at all, under any circumstance.

## Firewall Rules: The Free-Tier Equivalent of Network Isolation

The networking lab demonstrated Private Endpoints - the strongest network isolation available. Private Endpoints carry a small hourly cost, and this lab deliberately uses the zero-cost alternative instead: a firewall rule permitting exactly one known IP address, denying everything else by default. This is a real trade-off, stated honestly: firewall rules still leave the server's public endpoint technically reachable, whereas a Private Endpoint removes the public path structurally.

## Why Auditing Integrates With the Existing Observability Workspace

Rather than provisioning a new, isolated logging destination, this lab sends SQL audit logs to the same Log Analytics workspace the observability capstone already built - a deliberate test that a well-built shared observability layer should accept a new source without requiring its own dedicated infrastructure.

## What I Would Add at Enterprise Scale

- Private Endpoint for the SQL Server, replacing the firewall-rule approach with structurally stronger network isolation
- Microsoft Defender for SQL, a paid Defender plan providing active threat detection - deliberately not enabled in this lab
- Dynamic Data Masking and row-level security for sensitive fields
- Automated failover groups for redundancy
- Query Store performance monitoring feeding into the same workspace