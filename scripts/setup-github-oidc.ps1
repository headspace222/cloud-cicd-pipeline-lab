<#
.SYNOPSIS
    One-time setup: creates the Azure App Registration, federated
    credential, and least-privilege role assignment that let GitHub Actions
    authenticate to Azure without any stored secret.

.PARAMETER AppName
    Display name for the App Registration.

.PARAMETER GitHubOrg
    Your GitHub username or organisation.

.PARAMETER GitHubRepo
    The repository name (this one).

.PARAMETER ResourceGroupName
    The resource group the pipeline will be allowed to deploy into.

.PARAMETER Location
    Azure region for the resource group.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$AppName,

    [Parameter(Mandatory=$true)]
    [string]$GitHubOrg,

    [Parameter(Mandatory=$true)]
    [string]$GitHubRepo,

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [string]$Location = "uksouth"
)

Write-Host "Step 1: Creating resource group ..." -ForegroundColor Cyan
New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag @{CostCenter="LAB001"; Owner="jane"; Environment="NonProduction"} -Force | Out-Null
Write-Host "  [OK] Resource group ready." -ForegroundColor Green

Write-Host "`nStep 2: Creating App Registration '$AppName' ..." -ForegroundColor Cyan
try {
    $app = New-AzADApplication -DisplayName $AppName -ErrorAction Stop
    Write-Host "  [OK] App created. AppId: $($app.AppId)" -ForegroundColor Green
} catch {
    Write-Host "  [FAILED] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Fallback: create manually via Portal -> Microsoft Entra ID -> App registrations -> New registration." -ForegroundColor Yellow
    throw
}

Write-Host "`nStep 3: Creating Service Principal for the app ..." -ForegroundColor Cyan
try {
    $sp = New-AzADServicePrincipal -ApplicationId $app.AppId -ErrorAction Stop
    Write-Host "  [OK] Service principal created." -ForegroundColor Green
} catch {
    Write-Host "  [FAILED] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Fallback: Portal -> the App Registration -> it usually creates the SP automatically, or use 'az ad sp create --id <AppId>' in Azure CLI." -ForegroundColor Yellow
    throw
}

Write-Host "`nStep 4: Adding federated credential for GitHub Actions (main branch) ..." -ForegroundColor Cyan
try {
    $subject = "repo:$($GitHubOrg)/$($GitHubRepo):ref:refs/heads/main"
    New-AzADAppFederatedCredential `
        -ApplicationObjectId $app.Id `
        -Name "github-actions-main-branch" `
        -Issuer "https://token.actions.githubusercontent.com" `
        -Subject $subject `
        -Audience "api://AzureADTokenExchange" `
        -ErrorAction Stop
    Write-Host "  [OK] Federated credential created for subject: $subject" -ForegroundColor Green
} catch {
    Write-Host "  [FAILED] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Fallback: Portal -> the App Registration -> Certificates & secrets -> Federated credentials -> Add credential -> GitHub Actions scenario." -ForegroundColor Yellow
    Write-Host "  Use: Organisation=$GitHubOrg, Repository=$GitHubRepo, Entity type=Branch, Branch name=main" -ForegroundColor Yellow
    throw
}

Write-Host "`nStep 5: Assigning least-privilege Contributor role, scoped to the resource group only ..." -ForegroundColor Cyan
try {
    $scope = (Get-AzResourceGroup -Name $ResourceGroupName).ResourceId
    New-AzRoleAssignment -ApplicationId $app.AppId -RoleDefinitionName "Contributor" -Scope $scope -ErrorAction Stop | Out-Null
    Write-Host "  [OK] Role assigned, scoped to $ResourceGroupName only - not the subscription." -ForegroundColor Green
} catch {
    Write-Host "  [FAILED] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Fallback: Portal -> the resource group -> Access control (IAM) -> Add role assignment -> Contributor -> select the app by name." -ForegroundColor Yellow
    throw
}

Write-Host "`n=== Setup complete. Add these as GitHub repository VARIABLES (not secrets - none of these are secret) ===" -ForegroundColor Cyan
Write-Host "  Settings -> Secrets and variables -> Actions -> Variables tab -> New repository variable" -ForegroundColor Yellow
Write-Host ""
Write-Host "  AZURE_CLIENT_ID       = $($app.AppId)" -ForegroundColor Green
Write-Host "  AZURE_TENANT_ID       = $((Get-AzContext).Tenant.Id)" -ForegroundColor Green
Write-Host "  AZURE_SUBSCRIPTION_ID = $((Get-AzContext).Subscription.Id)" -ForegroundColor Green
Write-Host "  AZURE_RESOURCE_GROUP  = $ResourceGroupName" -ForegroundColor Green
Write-Host "  STORAGE_ACCOUNT_NAME  = <pick a globally unique name, lowercase alphanumeric>" -ForegroundColor Green