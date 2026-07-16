# CI/CD Pipeline: GitHub Actions Deploying Azure Infrastructure via Bicep

**Infrastructure as Code, deployed automatically on every push, authenticated
via OIDC federated credentials rather than a stored secret - built entirely
on free-tier GitHub Actions and free-tier Azure resources.**

Every resource in this portfolio's other seven projects was created by
clicking through the Azure Portal or running PowerShell commands by hand -
which is exactly why so much of this portfolio's documentation is honest
troubleshooting: propagation delays, parameter mismatches, portal UI quirks.
This project demonstrates the alternative professional teams actually use:
infrastructure defined as code, reviewed before it merges, and deployed
automatically and identically every time - removing the human click as a
source of drift or error.

## Why OIDC, Not a Stored Client Secret

The conventional way to authenticate a CI/CD pipeline to Azure is a service
principal with a client secret, stored as a GitHub Actions secret. This
works, but it means a credential capable of authenticating as that service
principal exists indefinitely in GitHub's secret store, needs manual
rotation, and - if ever leaked - remains valid until someone notices and
revokes it.

**OIDC federated credentials remove the stored secret entirely.** Azure
trusts GitHub's own token issuer directly: when a workflow run from a
specific repository and branch requests a token, GitHub's OIDC provider
issues a short-lived token, Azure validates it against a federated
credential trust relationship (no shared secret involved), and grants access
scoped to exactly that trust. Nothing long-lived is stored in GitHub at all.
This is the same "eliminate the standing credential" principle behind
managed identities, applied to CI/CD specifically - and it's a meaningfully
stronger security posture than the secret-based approach most tutorials
still default to.

## What's Included

| Component | Purpose |
|---|---|
| [`infra/main.bicep`](infra/main.bicep) | The Bicep template defining the infrastructure to deploy |
| [`.github/workflows/deploy-infrastructure.yml`](.github/workflows/deploy-infrastructure.yml) | The GitHub Actions workflow: validates, then deploys, on every push to main |
| [`scripts/setup-github-oidc.ps1`](scripts/setup-github-oidc.ps1) | One-time setup: creates the Azure App Registration, federated credential, and least-privilege role assignment |
| [`docs/architecture.md`](docs/architecture.md) | Design rationale: OIDC vs. secrets, Bicep vs. manual deployment, least-privilege scoping |
| [`docs/architecture-diagram.md`](docs/architecture-diagram.md) | Visual diagram of the OIDC trust flow and deployment pipeline |
| [`docs/setup-guide.md`](docs/setup-guide.md) | Full reproduction steps with screenshot evidence points |
| [`docs/screenshots/`](docs/screenshots/) | Evidence of the pipeline actually running and deploying successfully |

## Cost

- **GitHub Actions**: free on public repositories - no minute limit that
  this lab's usage would ever approach
- **Azure App Registration and federated credential**: no cost, an identity
  configuration, not a billed resource
- **The Bicep template's deployed resource** (a tagged storage account):
  same free-tier profile as the storage accounts used throughout this
  portfolio

## Setup Guide

Full steps: [`docs/setup-guide.md`](docs/setup-guide.md).

## Skills Demonstrated

- **Infrastructure as Code**: Bicep template authorship - parameters,
  outputs, resource definitions - rather than manual portal configuration
- **CI/CD pipeline design**: GitHub Actions workflow triggers, job
  permissions, validate-then-deploy staging
- **OIDC federated authentication**: eliminating stored secrets from CI/CD
  by trusting a token issuer directly, rather than defaulting to the more
  common but weaker secret-based approach
- **Least-privilege service identity**: scoping the pipeline's role
  assignment to a single resource group, not the subscription, consistent
  with the least-privilege discipline established throughout this portfolio
- **DevOps practice**: treating infrastructure changes as reviewable,
  version-controlled, automatically-applied code rather than ad hoc manual
  changes

## Author

Jane - Cloud & Infrastructure Engineer, AZ-104 candidate.
Part of a broader Azure governance and security portfolio.