# Architecture Diagram

```mermaid
flowchart TB
    subgraph GitHub["GitHub"]
        direction TB
        G1[Push to main - infra/main.bicep changed]
        G2[GitHub Actions workflow triggers]
        G3[OIDC token requested from GitHub's own issuer]
    end

    subgraph Trust["OIDC Federated Trust - No Stored Secret"]
        direction TB
        T1[Azure App Registration]
        T2[Federated Credential - subject: repo:org/repo:ref:refs/heads/main]
        T3[Short-lived Azure access token issued]
    end

    subgraph Deploy["Deployment"]
        direction TB
        D1[az deployment group validate]
        D2[az deployment group create]
        D3[Tagged Storage Account - DeployedBy: github-actions-oidc]
    end

    G1 --> G2 --> G3
    G3 -.validates against.-> T2
    T1 --> T2 --> T3
    T3 --> D1 --> D2 --> D3

    style GitHub fill:#e8f4fd,stroke:#1a73e8
    style Trust fill:#fef7e0,stroke:#f9ab00
    style Deploy fill:#e6f4ea,stroke:#188038
```

## Reading This Diagram

**GitHub (top, blue):** a push to main touching the infrastructure code
triggers the workflow, which requests a short-lived OIDC token from
GitHub's own token issuer.

**Trust (middle, amber):** the actual security mechanism. Azure's federated
credential is configured to trust tokens matching a very specific subject
claim - this exact repository, this exact branch.

**Deploy (bottom, green):** the pipeline validates the Bicep template before
attempting to apply it, then deploys.