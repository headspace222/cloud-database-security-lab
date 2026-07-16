# Setup Guide

Estimated time: 40-50 minutes.

## Step 1 - Create the SQL Server and Free Database via Portal

The free offer application is most reliably done through the Portal own guided flow.

1. Portal, search SQL databases, click plus Create
2. Basics tab: Resource group rg-database-security-lab, Database name db-security-baseline, Server Create new, name it sql-dbsec-jane01, region Sweden Central
3. Look for a banner: Want to try Azure SQL Database for free, click Apply offer
4. Authentication method: select Use Microsoft Entra-only authentication, set your own account as the Entra admin
5. Compute and storage: should show the free offer serverless configuration once applied
6. Networking tab: Connectivity method Public endpoint, Allow Azure services No
7. Tags tab: add the standard three tags
8. Review and create, then Create

Evidence to capture: 01-free-database-created.png

## Step 2 - Configure the Security Baseline

Get your own Object ID first with this command:

Get-AzADUser -UserPrincipalName (Get-AzContext).Account.Id

Then run the configuration script, filling in your resource group, server name, display name, object ID, and workspace resource ID as needed.

Evidence to capture: 02-security-configured.png

## Step 3 - Confirm SQL Authentication Is Actually Rejected

Attempt an sqlcmd connection using a fabricated SQL username and password. This should fail since SQL authentication is disabled entirely.

Evidence to capture: 03-sql-auth-rejected.png

## Step 4 - Confirm Entra Authentication Succeeds

Attempt an sqlcmd connection using Entra authentication. If the account is a guest identity in the tenant, interactive browser sign-in may route to the wrong tenant context. The reliable fix is Azure CLI login with an explicit tenant ID, then connecting sqlcmd using the ActiveDirectoryAzCli authentication method against that session.

Evidence to capture: 04-entra-auth-succeeds.png

## Step 5 - Confirm Audit Configuration

The configuration itself is confirmed correct via PowerShell. Run this to check:

Get-AzSqlServerAudit -ResourceGroupName "rg-database-security-lab" -ServerName "sql-dbsec-jane01"

This should show LogAnalyticsTargetState as Enabled and the correct WorkspaceResourceId.

Note: enabling this required a targeted policy exemption, since SQL Auditing creates an internal resource that does not support tags and was blocked by the mandatory tag policy. See docs/architecture.md for the full diagnostic trail.

Note on live query verification: despite this confirmed-correct configuration and real login events generated afterward, querying the shared workspace for this data across several approaches consistently returned no results. This is documented as a genuine, unresolved finding in docs/architecture.md rather than worked around further. Configuration-level evidence stands as this project proof of the auditing integration.

Evidence to capture: 05-audit-configuration-confirmed.png showing the Get-AzSqlServerAudit output.

## Step 6 - Push

cd C colon backslash cloud-database-security-lab
git init
git add dash A
git commit with a message describing the initial build
git branch dash M main
git remote add origin pointing to the GitHub repo
git push dash u origin main