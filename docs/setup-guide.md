# Setup Guide

Estimated time: 40-50 minutes.

## Step 1 - Create the SQL Server and Free Database via Portal

The free offer application is most reliably done through the Portal own guided flow.

1. Portal, search SQL databases, click plus Create
2. Basics tab: Resource group rg-database-security-lab, Database name db-security-baseline, Server Create new, name it sql-dbsec-jane01, region UK South
3. Look for a banner: Want to try Azure SQL Database for free, click Apply offer
4. Compute and storage: should show the free offer serverless configuration once applied
5. Networking tab: Connectivity method Public endpoint, Allow Azure services No
6. Tags tab: add the standard three tags
7. Review and create, then Create

Evidence to capture: 01-free-database-created.png

## Step 2 - Configure the Security Baseline

Get your own Object ID first with this command:

Get-AzADUser -UserPrincipalName (Get-AzContext).Account.Id

Then run the configuration script:

cd C colon backslash cloud-database-security-lab
dot backslash scripts backslash configure-security.ps1 with ResourceGroupName rg-database-security-lab, ServerName sql-dbsec-jane01, EntraAdminDisplayName your display name, EntraAdminObjectId your object id, WorkspaceResourceId your observability workspace resource id

See docs/setup-guide-commands.md for the exact copy-paste command syntax.

Evidence to capture: 02-security-configured.png

## Step 3 - Confirm SQL Authentication Is Actually Rejected

Attempt an sqlcmd connection using a fabricated SQL username and password. This should fail since SQL authentication is disabled entirely.

Evidence to capture: 03-sql-auth-rejected.png

## Step 4 - Confirm Entra Authentication Succeeds

Attempt an sqlcmd connection using Entra interactive authentication. This should succeed with a browser sign-in prompt.

Evidence to capture: 04-entra-auth-succeeds.png

## Step 5 - Verify Audit Logs in the Observability Workspace

In your Log Analytics workspace Logs pane, query the AzureDiagnostics table filtered to ResourceProvider MICROSOFT.SQL, projecting TimeGenerated, OperationName, ResultType, and principal_name_s, ordered by TimeGenerated descending.

Evidence to capture: 05-audit-logs-in-workspace.png

## Step 6 - Push

cd C colon backslash cloud-database-security-lab
git init
git add dash A
git commit with message describing the initial build
git branch dash M main
git remote add origin pointing to the GitHub repo
git push dash u origin main