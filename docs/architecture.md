# Architecture and Design Rationale

## Why the Free Offer, Not a Manually-Sized Database

Azure SQL Database's free offer, made generally available in 2025, provides up to 10 serverless General Purpose databases per subscription, each with 100,000 vCore-seconds and 32GB free every month, for the lifetime of the subscription, genuinely permanent, not a trial. This matters specifically for this portfolio: three earlier attempts at compute-based services, Function Apps, AKS, Databricks, hit a hard, permanent, non-negotiable zero-VM-quota wall on this subscription Free Trial type. The SQL Database free offer draws from an entirely separate quota and billing pool, and explicitly documents itself as available regardless of subscription type, including Free Trial specifically.

What happens at the free limit: if the monthly 100,000 vCore-second allowance is exhausted, the database auto-pauses until the next calendar month by default. At this lab actual usage, the free allowance is not remotely at risk of being exhausted.

## Entra-Only Authentication: Removing a Credential Class, Not Strengthening It

Azure SQL Database supports two authentication models, and they are not equally strong. SQL authentication is a username and password stored and managed within SQL Server itself, independent of Entra ID entirely. Microsoft Entra authentication is the same identity, RBAC, and Conditional Access governance already applied everywhere else in this portfolio, extended to database access.

This lab goes a step further than simply preferring Entra authentication, it disables SQL authentication entirely via Set-AzSqlServerActiveDirectoryOnlyAuthentication. There is no SQL login and password pair anywhere on this server capable of authenticating, at all, under any circumstance.

## Firewall Rules: The Free-Tier Equivalent of Network Isolation

The networking lab demonstrated Private Endpoints, the strongest network isolation available. Private Endpoints carry a small hourly cost, and this lab deliberately uses the zero-cost alternative instead: a firewall rule permitting exactly one known IP address, denying everything else by default. This is a real trade-off, stated honestly: firewall rules still leave the server public endpoint technically reachable, whereas a Private Endpoint removes the public path structurally.

## Why Auditing Integration Was Attempted, and What Was and Was Not Achieved

The original intent was to send SQL audit logs to the same Log Analytics workspace the observability capstone already built.

Getting there required diagnosing and resolving a genuine tag-policy and tooling conflict, worth documenting precisely. Enabling SQL Auditing to Log Analytics creates an internal diagnostic resource called SQLSecurityAuditEvents that does not support tags, and this portfolio enforce-mandatory-tags policy correctly blocked it, the same category of issue that previously caught an Automation Account, a Function App, a Workbook, and a Private DNS Zone. This is the fifth occurrence of the same policy doing exactly what it was built to do.

Three attempts to resolve it were made, in order, with the third succeeding. Set-AzSqlServerAudit in PowerShell failed with a generic 403 Forbidden, with none of the policy-identifying detail other tag-policy denials elsewhere in this portfolio have shown. The Portal own Auditing blade failed with the same underlying cause, but with a fully detailed error message identifying the exact policy and resource involved. A targeted policy exemption scoped to this specific SQL Server resource, created via Azure CLI, succeeded cleanly. Notably, the equivalent PowerShell cmdlet, New-AzPolicyExemption on Az.Resources version 10.0.1, failed with what appears to be a genuine module bug: its PolicyAssignment parameter does not correctly serialize into the policyAssignmentId field the underlying API requires. Azure CLI equivalent command succeeded immediately with the identical logical request, confirming the issue was specific to that PowerShell module version rather than the operation itself.

With the exemption in place, Set-AzSqlServerAudit succeeded, and Get-AzSqlServerAudit confirms the configuration is correct, showing LogAnalyticsTargetState as Enabled and the correct WorkspaceResourceId.

A final, honestly-documented limitation: despite this confirmed-correct configuration and real login events generated afterward, live query verification of the data actually landing in the workspace was not achieved within a reasonable troubleshooting window. AzureDiagnostics queries filtered by ResourceProvider, broad table-name searches, and Get-AzDiagnosticSetting against the SQL Server resource directly all returned nothing. This suggests SQL Server Auditing likely routes through a distinct backend mechanism from the generic diagnostic settings framework most other Azure resources use for Log Analytics integration, which would explain why standard diagnostic-setting verification approaches did not surface it here. Configuration-level evidence stands as this project proof of the auditing integration; live query evidence does not, and that distinction is stated plainly rather than implied away.

## A Real Finding: Guest Account Tenant Routing With Interactive Auth

Proving Entra-only authentication actually worked required more than expected. The account configured as this server Entra admin is a guest and external identity in this Azure tenant rather than a native one, and Microsoft standard interactive browser sign-in flow, when given an ambiguous account, defaulted to routing authentication through the account consumer home tenant rather than the specific tenant this database actually lives in. This produced a consistent, reproducible error regardless of which account was picked from the browser account selector, and regardless of using sqlcmd -U flag to hint the exact UPN.

The reliable fix was authenticating via Azure CLI directly with an explicit tenant ID specified at login, which forces the tenant explicitly at login time rather than leaving it to be inferred from account selection, then pointing sqlcmd at that already-authenticated CLI session using the ActiveDirectoryAzCli authentication method. This is a genuinely useful thing to know for any environment where a personal or guest account is used as an Entra admin: interactive browser auth flows are not always tenant-unambiguous for such accounts, and CLI-based authentication with an explicit tenant ID sidesteps the issue entirely.

A second, smaller finding along the way: the modern Go-based sqlcmd, installed via winget install Microsoft.Sqlcmd, uses a different flag set than the legacy ODBC-based sqlcmd most existing documentation and tutorials assume, using authentication-method equals ActiveDirectoryInteractive rather than the classic -G shorthand, and lacks a dedicated tenant-id flag, which is why the Azure CLI approach was needed at all.

## What I Would Add at Enterprise Scale

Private Endpoint for the SQL Server, replacing the firewall-rule approach with the structurally stronger network isolation demonstrated in the networking lab.

Microsoft Defender for SQL, a paid Defender plan providing active threat detection on the database specifically, deliberately not enabled in this lab to preserve its free-tier guarantee, consistent with the security posture lab decision to stay within Defender for Cloud free Foundational tier.

Dynamic Data Masking and row-level security, for genuinely sensitive financial data fields, rather than relying on access control alone.

Automated failover groups, for the redundancy story this lab single-region database does not address, mirroring the storage redundancy trade-offs documented in the migration lab.

Query Store performance monitoring, feeding into the same observability workspace this lab already sends audit logs to.