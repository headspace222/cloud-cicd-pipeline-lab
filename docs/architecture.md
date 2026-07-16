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
by a pipeline rather than a person. The same class of error - a missed
tag, a wrong parameter, a forgotten step - becomes structurally much harder
to introduce, because the deployment logic lives in a file under version
control rather than in a sequence of manual actions nobody can fully replay
exactly.

## OIDC Federated Credentials vs. a Stored Client Secret

### The Conventional Approach and Its Real Weakness

The most common way to authenticate a CI/CD pipeline to Azure is a service
principal with a client secret, stored as an encrypted GitHub Actions
secret. This is genuinely secure against casual exposure - GitHub encrypts
secrets at rest and never displays them in logs - but it has a structural
weakness: the secret is a long-lived, standing credential. It exists
indefinitely until manually rotated, and if it ever leaks (a misconfigured
log statement, a compromised runner, a copy-paste into the wrong place), it
remains valid and exploitable until someone notices and revokes it.

### A Genuinely Current Platform Change: Immutable Subject Claims

This lab's build hit a platform change GitHub shipped on April 23, 2026:
any repository created after July 15, 2026 automatically issues OIDC
tokens using a new "immutable subject claim" format, embedding permanent
numeric owner and repository IDs directly into the subject
(repo:org@ownerID/repo@repoID:ref:refs/heads/main) rather than the
previous name-only format (repo:org/repo:ref:refs/heads/main). This
repository was created on July 16, 2026 - one day after that cutoff - so
its tokens use the new format automatically, with no opt-in required and no
warning in the workflow itself.

The security rationale is sound: under the old format, if a repository or
organisation name was deleted and later recreated (or renamed) by a
different owner, that new owner could mint tokens with an identical subject
claim to the original, potentially inheriting trust relationships that were
never meant for them. Embedding immutable IDs closes that gap permanently.

The practical fix was straightforward once diagnosed: the federated
credential's Subject field needed to match the new format exactly, using
the real owner and repository IDs GitHub's own error message revealed
directly (AADSTS700213: No matching federated identity record found for
presented assertion subject '...') - Azure's error output contained the
exact correct value to use, which made this a fast fix once correctly
identified as a platform-version issue rather than a configuration mistake.

### What OIDC Actually Changes

With OIDC federated credentials, there is no client secret anywhere in this
pipeline - not in GitHub, not in Azure, not transmitted between them.
Instead:

1. GitHub's own OIDC provider issues a short-lived, cryptographically signed
   token to the workflow run, scoped to that specific repository and branch
2. Azure's federated credential configuration says, in effect, "trust tokens
   from GitHub's issuer, but only if they claim to match a specific subject
   - see the note above on this repository's actual subject format
   including immutable IDs, which differs from the simpler example shown
   here"
3. Azure validates the token's signature and claims against that trust
   configuration and issues a short-lived Azure access token in response

Nothing long-lived to leak, nothing to rotate, and the trust relationship is
scoped precisely to one repository and branch rather than being a
credential that would work from anywhere.

### The Trade-off, Stated Honestly

OIDC setup is genuinely more involved than pasting a secret into GitHub -
it requires an App Registration, a federated credential with an exactly
correct subject claim, and role assignment, versus generating a secret and
copying it once. For a single pipeline in a portfolio lab, the setup
overhead is a reasonable one-time cost; the underlying principle (prefer
short-lived, narrowly-trusted tokens over standing secrets wherever
possible) scales to matter considerably more at production scale, where
dozens of pipelines each holding their own long-lived secret represents a
meaningfully larger attack surface than the same pipelines each trusted via
narrowly-scoped OIDC federation.

## Least-Privilege Scope: Resource Group, Not Subscription

The pipeline's role assignment is Contributor scoped to a single resource
group, not the subscription. This mirrors the least-privilege discipline
established throughout this portfolio (the identity governance lab's custom
RBAC roles, the security posture lab's Key Vault role scoping): a CI/CD
identity should be able to deploy exactly what it's meant to deploy, and
nothing else. A leaked or misused pipeline identity scoped to one resource
group can do meaningfully less damage than one scoped to an entire
subscription.

## Validate-Then-Deploy, Not Deploy Directly

The workflow runs az deployment group validate before
az deployment group create - a deliberate two-step process rather than
deploying directly. Validation catches template errors, parameter mismatches,
and policy violations (including this portfolio's own tag-enforcement
policy from the cost governance lab) before any actual resource change is
attempted, giving a clear failure message at the cheaper, non-destructive
step rather than a partial or failed deployment to clean up afterward.

## What I'd Add at Enterprise Scale

- Environments and approval gates in GitHub Actions - requiring manual
  approval before a production-scoped deployment proceeds, rather than
  every push to main deploying automatically
- Separate OIDC federated credentials per environment (dev/staging/prod),
  each scoped to its own resource group and potentially its own branch or
  GitHub Environment, rather than one credential covering everything
- Bicep modules and a proper parameter-file-per-environment structure,
  as the infrastructure being deployed grows beyond a single resource
- Automated policy compliance checks (e.g. via Azure Policy's
  what-if/deny evaluation) integrated directly into the validate step,
  surfacing governance violations in the same place as template errors
- Drift detection, periodically comparing deployed resource state
  against the Bicep template to catch manual out-of-band changes that would
  otherwise silently diverge from what's in source control