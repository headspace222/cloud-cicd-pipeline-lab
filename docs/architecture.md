# Architecture & Design Rationale

## Why This Project, After Seven Manually-Built Ones

Every resource across this portfolio's other seven projects exists because
of a portal click or a hand-typed PowerShell command - which is exactly why
so much of this portfolio's documentation is an honest account of things
going wrong: propagation delays that only show up in practice, parameter
names that changed between module versions, portal wizards with settings in
unexpected places. None of that is a flaw in the earlier projects; it's an
accurate reflection of what manual, click-driven infrastructure work
actually involves.

This project demonstrates the alternative: infrastructure defined once, as
code, reviewed before it merges, and applied identically every single time
by a pipeline rather than a person.

## OIDC Federated Credentials vs. a Stored Client Secret

### The Conventional Approach and Its Real Weakness

The most common way to authenticate a CI/CD pipeline to Azure is a service
principal with a client secret, stored as an encrypted GitHub Actions
secret. This is genuinely secure against casual exposure, but it has a
structural weakness: the secret is a long-lived, standing credential. It
exists indefinitely until manually rotated, and if it ever leaks, it
remains valid and exploitable until someone notices and revokes it.

### What OIDC Actually Changes

With OIDC federated credentials, there is no client secret anywhere in this
pipeline. Instead:

1. GitHub's own OIDC provider issues a short-lived, cryptographically signed
   token to the workflow run, scoped to that specific repository and branch
2. Azure's federated credential configuration says, in effect, "trust tokens
   from GitHub's issuer, but only if they claim to be from
   repo:headspace222/cloud-cicd-pipeline-lab:ref:refs/heads/main"
3. Azure validates the token's signature and claims against that trust
   configuration and issues a short-lived Azure access token in response

Nothing long-lived to leak, nothing to rotate, and the trust relationship is
scoped precisely to one repository and branch.

### The Trade-off, Stated Honestly

OIDC setup is genuinely more involved than pasting a secret into GitHub -
it requires an App Registration, a federated credential with an exactly
correct subject claim, and role assignment, versus generating a secret and
copying it once. For a single pipeline in a portfolio lab, the setup
overhead is a reasonable one-time cost.

## Least-Privilege Scope: Resource Group, Not Subscription

The pipeline's role assignment is Contributor scoped to a single resource
group, not the subscription. This mirrors the least-privilege discipline
established throughout this portfolio: a CI/CD identity should be able to
deploy exactly what it's meant to deploy, and nothing else.

## Validate-Then-Deploy, Not Deploy Directly

The workflow runs az deployment group validate before
az deployment group create - a deliberate two-step process rather than
deploying directly. Validation catches template errors, parameter mismatches,
and policy violations before any actual resource change is attempted.

## What I'd Add at Enterprise Scale

- Environments and approval gates in GitHub Actions
- Separate OIDC federated credentials per environment
- Bicep modules and a proper parameter-file-per-environment structure
- Automated policy compliance checks integrated into the validate step
- Drift detection, comparing deployed resource state against the template