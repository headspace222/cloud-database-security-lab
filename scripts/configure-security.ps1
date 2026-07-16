<#
.SYNOPSIS
    Configures a security baseline on an existing Azure SQL Server: Microsoft
    Entra-only authentication, a restrictive firewall rule, and audit
    logging to a Log Analytics workspace.

.DESCRIPTION
    Run this after creating the SQL Server and free-tier database via the
    Portal (see docs/setup-guide.md Step 1 - the free offer application is
    most reliably done through Portal's guided banner).

    Configures, in order:
    1. A Microsoft Entra administrator for the server
    2. Entra-only authentication (disables SQL logins entirely)
    3. A firewall rule permitting only your current public IP
    4. Auditing sent to the specified Log Analytics workspace

.PARAMETER ResourceGroupName
    Resource group containing the SQL Server.

.PARAMETER ServerName
    Name of the SQL Server (logical server), without the
    .database.windows.net suffix.

.PARAMETER EntraAdminDisplayName
    Display name of the Microsoft Entra user/group to set as admin.

.PARAMETER EntraAdminObjectId
    Object ID of that Microsoft Entra user/group.

.PARAMETER WorkspaceResourceId
    Full Resource ID of the Log Analytics workspace to send audit logs to.
    Optional - skip auditing setup if not supplied.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$ServerName,

    [Parameter(Mandatory=$true)]
    [string]$EntraAdminDisplayName,

    [Parameter(Mandatory=$true)]
    [string]$EntraAdminObjectId,

    [string]$WorkspaceResourceId
)

$script:HadFailure = $false

function Report-Error {
    param([string]$Message)
    $script:HadFailure = $true
    Write-Host "  [FAILED] $Message" -ForegroundColor Red
}

Write-Host "Step 1: Setting Microsoft Entra administrator for the server ..." -ForegroundColor Cyan
try {
    Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DisplayName $EntraAdminDisplayName -ObjectId $EntraAdminObjectId -ErrorAction Stop
    Write-Host "  [OK] Entra admin set: $EntraAdminDisplayName" -ForegroundColor Green
} catch {
    Report-Error $_.Exception.Message
    Write-Host "  Fallback: Portal -> the SQL Server -> Microsoft Entra ID -> Set admin." -ForegroundColor Yellow
}

Write-Host "`nStep 2: Enabling Entra-only authentication (disables SQL logins entirely) ..." -ForegroundColor Cyan
try {
    Enable-AzSqlServerActiveDirectoryOnlyAuthentication -ResourceGroupName $ResourceGroupName -ServerName $ServerName -ErrorAction Stop
    Write-Host "  [OK] SQL authentication disabled - Entra ID is now the only way to authenticate." -ForegroundColor Green
} catch {
    Report-Error $_.Exception.Message
    Write-Host "  Fallback: Portal -> the SQL Server -> Microsoft Entra ID -> check Support only Azure Active Directory authentication." -ForegroundColor Yellow
}

Write-Host "`nStep 3: Adding a firewall rule for your current public IP only ..." -ForegroundColor Cyan
try {
    $myIp = (Invoke-RestMethod -Uri "https://api.ipify.org" -ErrorAction Stop).Trim()
    Write-Host "  Detected public IP: $myIp" -ForegroundColor Cyan

    $existingRule = Get-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName -FirewallRuleName "AllowMyClientIP" -ErrorAction SilentlyContinue
    if ($existingRule) {
        if ($existingRule.StartIpAddress -eq $myIp -and $existingRule.EndIpAddress -eq $myIp) {
            Write-Host "  [OK] Firewall rule already exists for $myIp." -ForegroundColor Green
        } else {
            Set-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName -FirewallRuleName "AllowMyClientIP" -StartIpAddress $myIp -EndIpAddress $myIp -ErrorAction Stop
            Write-Host "  [OK] Firewall rule updated - only $myIp can reach this server." -ForegroundColor Green
        }
    } else {
        New-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName -FirewallRuleName "AllowMyClientIP" -StartIpAddress $myIp -EndIpAddress $myIp -ErrorAction Stop
        Write-Host "  [OK] Firewall rule created - only $myIp can reach this server." -ForegroundColor Green
    }
} catch {
    Report-Error $_.Exception.Message
    Write-Host "  Fallback: find your IP at whatismyip.com, then Portal -> the SQL Server -> Networking -> add a firewall rule manually." -ForegroundColor Yellow
}

if ($WorkspaceResourceId) {
    Write-Host "`nStep 4: Enabling auditing to the Log Analytics workspace ..." -ForegroundColor Cyan
    try {
        Set-AzSqlServerAudit -ResourceGroupName $ResourceGroupName -ServerName $ServerName -LogAnalyticsTargetState Enabled -WorkspaceResourceId $WorkspaceResourceId -ErrorAction Stop
        Write-Host "  [OK] Auditing enabled - login attempts and queries now flow to the shared observability workspace." -ForegroundColor Green
    } catch {
        Report-Error $_.Exception.Message
        Write-Host "  Fallback: Portal -> the SQL Server -> Auditing -> Enable Azure Monitor logs -> select the workspace." -ForegroundColor Yellow
    }
} else {
    Write-Host "`nStep 4: Skipped (no -WorkspaceResourceId supplied)." -ForegroundColor Yellow
}

Write-Host "`nSetup complete. Verifying final state ..." -ForegroundColor Green
try {
    Get-AzSqlServerActiveDirectoryOnlyAuthentication -ResourceGroupName $ResourceGroupName -ServerName $ServerName -ErrorAction Stop | Out-Null
    Write-Host "  [OK] Entra-only authentication setting retrieved successfully." -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Could not verify Entra-only authentication: $($_.Exception.Message)" -ForegroundColor Yellow
}

try {
    $firewallRules = @(Get-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName -ServerName $ServerName -ErrorAction Stop)
    if ($firewallRules.Count -gt 0) {
        $firewallRules | Format-Table -AutoSize
    } else {
        Write-Host "  No firewall rules were returned for this server." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [WARN] Could not verify firewall rules: $($_.Exception.Message)" -ForegroundColor Yellow
}

if ($script:HadFailure) {
    Write-Host "`nScript completed with one or more failures." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nScript completed successfully." -ForegroundColor Green
exit 0