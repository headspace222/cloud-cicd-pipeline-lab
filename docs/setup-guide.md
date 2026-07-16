# Setup Guide

**Estimated time:** 45-60 minutes - OIDC setup is the most involved part of
this lab, but it's a one-time cost.

## Step 1 - Run the OIDC Setup Script

```powershell
cd C:\cloud-cicd-pipeline-lab
.\scripts\setup-github-oidc.ps1 -AppName "gh-actions-cicd-lab" -GitHubOrg "headspace222" -GitHubRepo "cloud-cicd-pipeline-lab" -ResourceGroupName "rg-cicd-pipeline-lab" -Location "uksouth"
```

**Evidence to capture:**
- 01-oidc-setup-output.png

## Step 2 - Add Repository Variables in GitHub

1. Your repo on GitHub, Settings, Secrets and variables, Actions
2. Click the Variables tab (not Secrets)
3. New repository variable, add all five:
   - AZURE_CLIENT_ID
   - AZURE_TENANT_ID
   - AZURE_SUBSCRIPTION_ID
   - AZURE_RESOURCE_GROUP -> rg-cicd-pipeline-lab
   - STORAGE_ACCOUNT_NAME -> pick something globally unique, e.g. stcicdlabjane01

**Evidence to capture:**
- 02-github-variables-configured.png

## Step 3 - Push to Trigger the Pipeline

```powershell
cd C:\cloud-cicd-pipeline-lab
git init
git add -A
git commit -m "Initial commit: Bicep template and OIDC-authenticated deployment workflow"
git branch -M main
git remote add origin https://github.com/headspace222/cloud-cicd-pipeline-lab.git
git push -u origin main
```

## Step 4 - Watch the Pipeline Run

1. Your repo on GitHub, Actions tab
2. Click into the workflow run

**Evidence to capture:**
- 03-pipeline-run-succeeded.png
- 04-deployment-log-detail.png

## Step 5 - Verify the Resource Actually Deployed

```powershell
Get-AzStorageAccount -ResourceGroupName "rg-cicd-pipeline-lab" -Name "<your-storage-account-name>" | Select-Object StorageAccountName, Location, Tags
```

**Evidence to capture:**
- 05-resource-verified.png

## Step 6 - Prove It's Actually Repeatable

Make a small change to infra/main.bicep, commit, and push again.

**Evidence to capture:**
- 06-second-run-succeeded.png

## Step 7 - Final Push

```powershell
git add -A
git commit -m "Add evidence and finalize documentation"
git push
```