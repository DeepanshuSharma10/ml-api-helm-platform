# ML API Helm Platform

A reusable, environment-aware Helm-based deployment platform for ML APIs running on Kubernetes.

This project demonstrates how an MLOps/Platform Engineering team can standardize deployment of ML APIs across **Development, Staging, and Production** while minimizing environment-specific configuration and avoiding manual Kubernetes manifest duplication.

---

## 1. Problem Statement

ML Engineers need to deploy machine-learning APIs to Kubernetes across multiple environments.

A common problem is that Kubernetes manifests are manually copied and modified for each environment:

- Development
- Staging
- Production

This leads to:

- Configuration drift
- Duplicated YAML
- Manual deployment errors
- Difficult upgrades and rollbacks
- Inconsistent resource configuration
- Poor scalability
- Increased operational overhead

The objective of this project is to create a **generic Helm chart** that can be reused across environments with only small environment-specific values files.

---

# 2. Solution Overview

This project provides:

- A reusable Helm chart for ML APIs
- Environment-specific Helm values
- Kubernetes Deployment
- Kubernetes Service
- Health checks
- Resource requests and limits
- Horizontal Pod Autoscaler
- Helm tests
- Local Kubernetes deployment
- Dockerized sample ML API
- GitHub Actions CI/CD pipeline
- Helm package generation
- Design for publishing Helm charts to a private OCI registry
- Kubernetes Secret integration
- Terraform-based Helm deployment example
- Versioning and rollback strategy
- Production security recommendations

The deployment model is:

```text
                    ┌──────────────────────┐
                    │   ML API Source Code │
                    │      app/app.py      │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │    Docker Image      │
                    │    ml-api:1.0.0      │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │     Helm Chart       │
                    │      ml-api          │
                    └──────────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
        ┌──────────┐     ┌──────────┐     ┌──────────┐
        │   Dev    │     │ Staging  │     │   Prod   │
        │ Values   │     │  Values  │     │  Values  │
        └──────────┘     └──────────┘     └──────────┘
              │                │                │
              ▼                ▼                ▼
        ┌──────────┐     ┌──────────┐     ┌──────────┐
        │Kubernetes│     │Kubernetes│     │Kubernetes│
        │  Dev     │     │ Staging  │     │  Prod    │
        └──────────┘     └──────────┘     └──────────┘
```

---

# 3. Architecture

The Helm chart acts as the deployment abstraction.

```text
                     Git Repository
                           │
                           ▼
                 ┌────────────────────┐
                 │   Helm Chart       │
                 │     ml-api         │
                 └─────────┬──────────┘
                           │
             ┌─────────────┼─────────────┐
             │             │             │
             ▼             ▼             ▼
       values-dev    values-staging   values-prod
             │             │             │
             ▼             ▼             ▼
          Dev K8s       Staging K8s     Prod K8s
             │             │             │
             ▼             ▼             ▼
        Deployment     Deployment      Deployment
        Service        Service         Service
        HPA            HPA             HPA
```

The same chart is reused for all environments.

Only environment-specific configuration changes.

---

# 4. Repository Structure

```text
ml-api-helm-platform/
│
├── .github/
│   └── workflows/
│       └── helm-ci-cd.yml
│
├── app/
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
│
├── helm/
│   └── ml-api/
│       ├── Chart.yaml
│       ├── .helmignore
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-staging.yaml
│       ├── values-prod.yaml
│       │
│       └── templates/
│           ├── _helpers.tpl
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── hpa.yaml
│           │
│           └── tests/
│               └── test-connection.yaml
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars.example
│
├── tests/
│   └── helm-test.sh
│
├── .gitignore
└── README.md
```

---

# 5. Sample ML API

A lightweight FastAPI application is included to demonstrate the Kubernetes deployment.

The application exposes:

### Root endpoint

```text
GET /
```

Response:

```json
{
  "message": "Hello World",
  "service": "ml-api"
}
```

### Health endpoint

```text
GET /health
```

Response:

```json
{
  "status": "healthy"
}
```

The `/health` endpoint is used by Kubernetes for:

- Liveness probe
- Readiness probe
- Helm integration testing

---

# 6. Docker Image

The application is containerized using:

```text
python:3.12-slim
```

The Docker image exposes port:

```text
8000
```

The application is started using Uvicorn:

```text
uvicorn app:app --host 0.0.0.0 --port 8000
```

Example local image:

```text
ml-api:1.0.0
```

---

# 7. Generic Helm Chart

The primary design principle is:

> One reusable Helm chart + environment-specific values.

The chart contains Kubernetes resource templates, while environment files contain only configuration that differs between environments.

This prevents copying Kubernetes YAML for every environment.

---

# 8. Helm Chart Configuration

The base configuration is stored in:

```text
helm/ml-api/values.yaml
```

Example:

```yaml
replicaCount: 1

image:
  repository: ml-api
  tag: "1.0.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8000
  targetPort: 8000
```

Common configuration remains in the base values file.

Environment-specific configuration overrides the base values.

---

# 9. Environment Strategy

## Development

File:

```text
helm/ml-api/values-dev.yaml
```

Configuration:

```yaml
replicaCount: 1

autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 3
  targetCPUUtilizationPercentage: 70
```

Development is optimized for lower resource consumption.

---

## Staging

File:

```text
helm/ml-api/values-staging.yaml
```

Configuration:

```yaml
replicaCount: 2

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70
```

Staging uses higher resource allocations to more closely resemble production.

---

## Production

File:

```text
helm/ml-api/values-prod.yaml
```

Configuration:

```yaml
replicaCount: 3

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 65
```

Production is configured with:

- Higher minimum replicas
- Higher maximum replicas
- More CPU and memory
- More conservative autoscaling threshold

---

# 10. Minimal Environment-Specific Configuration

The ML Engineer does not need to modify Kubernetes templates.

For example:

```bash
helm upgrade --install ml-api-dev ./helm/ml-api \
  -f ./helm/ml-api/values-dev.yaml \
  --namespace dev \
  --create-namespace
```

Staging:

```bash
helm upgrade --install ml-api-staging ./helm/ml-api \
  -f ./helm/ml-api/values-staging.yaml \
  --namespace staging \
  --create-namespace
```

Production:

```bash
helm upgrade --install ml-api-prod ./helm/ml-api \
  -f ./helm/ml-api/values-prod.yaml \
  --namespace prod \
  --create-namespace
```

The same chart is used in every environment.

---

# 11. Kubernetes Resources

The Helm chart creates the following resources.

## Deployment

The Deployment manages:

- Application Pods
- Container image
- Resource requests
- Resource limits
- Liveness probes
- Readiness probes
- Optional Kubernetes Secret integration

---

## Service

The Service provides a stable Kubernetes endpoint for the ML API.

Default configuration:

```text
Service type: ClusterIP
Port: 8000
Target port: 8000
```

---

## Horizontal Pod Autoscaler

The chart optionally creates an HPA using:

```text
autoscaling/v2
```

Example:

```yaml
autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 3
  targetCPUUtilizationPercentage: 70
```

Production uses:

```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 65
```

This allows the same Helm chart to support different scaling policies.

---

# 12. Health Probes

The application exposes:

```text
/health
```

Kubernetes uses this endpoint for:

### Liveness Probe

Determines whether the application is alive.

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: http
```

### Readiness Probe

Determines whether the application is ready to receive traffic.

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: http
```

This prevents Kubernetes from routing traffic to an unhealthy or unready Pod.

---

# 13. Resource Management

The chart supports CPU and memory requests and limits.

Example:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi

  limits:
    cpu: 500m
    memory: 512Mi
```

Environment-specific resources can be overridden without modifying the Deployment template.

---

# 14. Secrets Strategy

The Helm chart supports consuming an existing Kubernetes Secret.

Configuration:

```yaml
secrets:
  enabled: false
  existingSecret: ""
```

When enabled:

```yaml
secrets:
  enabled: true
  existingSecret: ml-api-secrets
```

The Deployment consumes the Secret using:

```yaml
envFrom:
  - secretRef:
      name: ml-api-secrets
```

The actual secret values are **not stored in Git**.

## Recommended Production Architecture

For a cloud deployment, sensitive values should preferably be stored in a dedicated secret manager.

Example:

```text
AWS Secrets Manager
        │
        ▼
External Secrets Operator
        │
        ▼
Kubernetes Secret
        │
        ▼
ML API Pod
```

This keeps credentials outside the source repository and Helm values.

---

# 15. Helm Tests

A Helm test is included:

```text
helm/ml-api/templates/tests/test-connection.yaml
```

The test creates a temporary Pod using BusyBox and verifies connectivity to:

```text
http://ml-api:8000/health
```

Run:

```bash
helm test ml-api-dev -n dev
```

Expected result:

```text
TEST SUITE: ml-api-test-connection
Phase: Succeeded
```

---

# 16. Static Helm Tests

Additional tests are included in:

```text
tests/helm-test.sh
```

The script performs:

1. Helm lint
2. Dev rendering
3. Staging rendering
4. Production rendering
5. Deployment validation
6. Service validation
7. HPA validation
8. Health endpoint configuration validation

Run:

```bash
./tests/helm-test.sh
```

Expected output:

```text
==> Helm lint
1 chart(s) linted, 0 chart(s) failed

==> Testing environment: dev
PASS: dev

==> Testing environment: staging
PASS: staging

==> Testing environment: prod
PASS: prod

==> All Helm chart tests passed
```

---

# 17. Local Kubernetes Deployment

The chart has been tested against a local Docker Desktop Kubernetes cluster.

Check the Kubernetes context:

```bash
kubectl config current-context
```

Expected:

```text
docker-desktop
```

Check nodes:

```bash
kubectl get nodes
```

Example:

```text
NAME                    STATUS   ROLES           VERSION
desktop-control-plane   Ready    control-plane   v1.36.1
```

---

# 18. Build the Application Image

Build the Docker image:

```bash
docker build -t ml-api:1.0.0 ./app
```

Verify:

```bash
docker images | grep ml-api
```

Expected:

```text
ml-api    1.0.0
```

Because Docker Desktop Kubernetes shares the Docker environment, the locally built image can be used by the local Kubernetes cluster.

---

# 19. Deploy to Development

Run:

```bash
helm upgrade --install ml-api-dev ./helm/ml-api \
  -f ./helm/ml-api/values-dev.yaml \
  --namespace dev \
  --create-namespace
```

Expected:

```text
Release "ml-api-dev" has been deployed
```

Check the release:

```bash
helm list -n dev
```

Check Pods:

```bash
kubectl get pods -n dev
```

Example:

```text
NAME                       READY   STATUS    RESTARTS
ml-api-xxxxxxxxxx-xxxxx    1/1     Running   0
```

Check Service:

```bash
kubectl get svc -n dev
```

---

# 20. Access the ML API Locally

The Kubernetes Service is a ClusterIP service.

Port-forward it to the local machine:

```bash
kubectl port-forward svc/ml-api 8000:8000 -n dev
```

Then test:

```bash
curl http://localhost:8000/
```

Expected:

```json
{
  "message": "Hello World",
  "service": "ml-api"
}
```

Health check:

```bash
curl http://localhost:8000/health
```

Expected:

```json
{
  "status": "healthy"
}
```

This satisfies the requirement that the ML API is callable from the local PC.

---

# 21. Helm Integration Test

Run:

```bash
helm test ml-api-dev -n dev
```

Expected:

```text
TEST SUITE: ml-api-test-connection
Phase: Succeeded
```

---

# 22. Helm Lint

Run:

```bash
helm lint helm/ml-api
```

Expected:

```text
1 chart(s) linted, 0 chart(s) failed
```

The chart currently produces only an informational recommendation regarding the optional chart icon.

---

# 23. Render Environment Configurations

Development:

```bash
helm template ml-api-dev helm/ml-api \
  -f helm/ml-api/values-dev.yaml
```

Staging:

```bash
helm template ml-api-staging helm/ml-api \
  -f helm/ml-api/values-staging.yaml
```

Production:

```bash
helm template ml-api-prod helm/ml-api \
  -f helm/ml-api/values-prod.yaml
```

This allows Kubernetes manifests to be validated before deployment.

---

# 24. CI/CD

GitHub Actions is used for Helm CI/CD.

Workflow:

```text
.github/workflows/helm-ci-cd.yml
```

Pipeline:

```text
Pull Request
     │
     ▼
Checkout
     │
     ▼
Setup Helm
     │
     ▼
Helm Tests
     │
     ▼
Helm Lint
     │
     ▼
Render Dev
     │
     ▼
Render Staging
     │
     ▼
Render Production
     │
     ▼
Package Helm Chart
     │
     ▼
Upload CI Artifact
```

On a push to `main`, the pipeline additionally has a publishing stage:

```text
main
 │
 ▼
Validate
 │
 ▼
Package
 │
 ▼
Authenticate using GitHub OIDC
 │
 ▼
Amazon ECR OCI Registry
```

---

# 25. Pull Request Validation

The workflow is triggered for changes to:

```text
helm/**
tests/**
.github/workflows/helm-ci-cd.yml
```

For Pull Requests, the pipeline performs validation but does not publish the chart.

This provides an early quality gate before changes are merged.

---

# 26. Helm Chart Packaging

The chart can be packaged using:

```bash
helm package helm/ml-api
```

Example artifact:

```text
ml-api-0.1.0.tgz
```

The package contains the reusable Helm chart and can be distributed through an OCI-compatible Helm repository.

---

# 27. Private Helm Repository

The CI/CD workflow is designed to publish the Helm chart to a private Amazon ECR OCI registry.

Example target:

```text
oci://<aws-account>.dkr.ecr.<region>.amazonaws.com/helm
```

The pipeline uses:

- GitHub Actions
- AWS OIDC
- IAM role
- Amazon ECR
- Helm OCI support

The intended authentication flow is:

```text
GitHub Actions
       │
       │ OIDC
       ▼
AWS IAM Role
       │
       ▼
Amazon ECR
       │
       ▼
Private Helm OCI Registry
```

### Important

An AWS account is not currently available for this assignment environment.

Therefore:

- The ECR publishing stage is implemented as CI/CD design/code.
- Local Helm validation, packaging, rendering, and deployment have been tested.
- Actual AWS ECR publication has not been executed.
- No AWS credentials are stored in the repository.

To enable publishing in a real environment, configure:

```text
AWS_REGION
```

as a GitHub Actions repository/environment variable.

Configure:

```text
AWS_GITHUB_ACTIONS_ROLE_ARN
```

as a GitHub Actions secret.

The IAM role should trust GitHub's OIDC provider and provide only the required ECR permissions.

---

# 28. CI/CD Security

AWS credentials should not be stored as static access keys in GitHub.

The recommended approach is:

```text
GitHub Actions
       │
       ▼
OIDC Identity Token
       │
       ▼
AWS IAM Role
       │
       ▼
Temporary AWS Credentials
```

Advantages:

- No long-lived AWS access keys
- Reduced credential exposure
- Short-lived credentials
- Better auditability
- Least-privilege IAM policies

---

# 29. Terraform Deployment

A small Terraform example is included to demonstrate infrastructure-as-code based Helm deployment.

Location:

```text
terraform/
```

Files:

```text
main.tf
variables.tf
terraform.tfvars.example
```

Terraform uses the Helm provider.

Example:

```hcl
resource "helm_release" "ml_api" {
  name      = "ml-api-${var.environment}"
  namespace = var.environment

  create_namespace = true

  chart = "../helm/ml-api"

  values = [
    file("../helm/ml-api/values-${var.environment}.yaml")
  ]

  wait = true
}
```

Environment is validated using:

```hcl
["dev", "staging", "prod"]
```

Example:

```hcl
environment = "dev"
```

This demonstrates how the same Helm chart can be consumed from infrastructure-as-code.

---

# 30. Terraform Usage

Initialize Terraform:

```bash
cd terraform
terraform init
```

Create a local variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Validate:

```bash
terraform validate
```

Format:

```bash
terraform fmt
```

Plan:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

The Terraform example assumes a Kubernetes context is already available through:

```text
~/.kube/config
```

---

# 31. Versioning Strategy

Helm chart versioning follows semantic versioning.

Current chart:

```yaml
version: 0.1.0
```

The chart follows:

```text
MAJOR.MINOR.PATCH
```

Examples:

```text
0.1.0
0.1.1
0.2.0
1.0.0
```

### PATCH

Use for:

- Bug fixes
- Small template corrections
- Non-breaking changes

Example:

```text
0.1.0 → 0.1.1
```

### MINOR

Use for:

- New optional features
- New configurable parameters
- Backward-compatible changes

Example:

```text
0.1.0 → 0.2.0
```

### MAJOR

Use for:

- Breaking configuration changes
- Breaking deployment behavior
- Removal of existing values

Example:

```text
0.x → 1.0.0
```

---

# 32. Application Versioning

Application version is maintained independently from Helm chart version.

Example:

```yaml
appVersion: "1.0.0"
```

Container image:

```text
ml-api:1.0.0
```

A future production deployment could use immutable image tags such as:

```text
ml-api:1.0.1
```

or preferably:

```text
ml-api:<git-sha>
```

This makes deployments traceable to source code.

---

# 33. Deployment Promotion Strategy

A recommended promotion model is:

```text
Feature Branch
      │
      ▼
Pull Request
      │
      ▼
CI Validation
      │
      ▼
Merge to Main
      │
      ▼
Development
      │
      ▼
Staging
      │
      ▼
Production
```

The same Helm chart artifact should ideally be promoted between environments rather than rebuilding different chart versions for each environment.

This reduces the possibility of environment drift.

---

# 34. Rollback

Helm provides release history and rollback capabilities.

View history:

```bash
helm history ml-api-dev -n dev
```

Rollback:

```bash
helm rollback ml-api-dev <REVISION> -n dev
```

Check status:

```bash
helm status ml-api-dev -n dev
```

This provides a simple recovery mechanism for failed deployments.

---

# 35. Security Considerations

The current project demonstrates the basic security architecture.

For production, the following should be added or enforced:

- Kubernetes RBAC
- Dedicated service accounts
- NetworkPolicies
- Pod Security Standards
- Non-root containers
- Read-only root filesystem
- Image vulnerability scanning
- Image signing
- SBOM generation
- Secrets Manager integration
- External Secrets Operator
- Resource quotas
- Limit ranges
- Admission policies
- Runtime security monitoring

---

# 36. Production Container Hardening

The current sample image uses:

```text
python:3.12-slim
```

For a production deployment, additional hardening can be applied.

Recommended improvements:

```text
Run as non-root
        │
        ▼
Read-only filesystem
        │
        ▼
Drop Linux capabilities
        │
        ▼
Minimal image
        │
        ▼
Vulnerability scanning
        │
        ▼
Signed image
```

---

# 37. Observability

A production ML API should expose operational metrics and logs.

Recommended architecture:

```text
ML API
 │
 ├── Application Logs
 │
 ├── Metrics
 │
 └── Traces
       │
       ▼
Observability Platform
```

Potential technologies include:

- Prometheus
- Grafana
- OpenTelemetry
- ELK/OpenSearch
- CloudWatch

The current assignment intentionally keeps the application simple while leaving room for these integrations.

---

# 38. ML/MLOps Extensions

The generic Helm architecture can support more advanced ML workloads.

Possible future extensions include:

- Model version configuration
- Model artifact URI
- Model registry integration
- MLflow integration
- S3 model artifacts
- Canary deployments
- Blue/green deployments
- Model-specific autoscaling
- GPU node scheduling
- Node affinity
- Tolerations
- Model health checks
- Model performance monitoring
- Data drift detection
- Model drift detection
- Inference latency monitoring

For example:

```yaml
model:
  name: fraud-detection
  version: "v2"
  artifactUri: "s3://ml-models/fraud/v2/"
```

This could be introduced as additional values without changing the overall deployment model.

---

# 39. Outside-the-Box Improvement: GitOps

A future production architecture could use GitOps.

Example:

```text
Developer
    │
    ▼
Git Repository
    │
    ▼
CI
    │
    ▼
Helm Chart / Image
    │
    ▼
Environment Configuration
    │
    ▼
Argo CD
    │
    ▼
Kubernetes
```

Argo CD could continuously reconcile the desired state from Git.

This would eliminate the need for engineers to manually execute Helm commands for every deployment.

---

# 40. Outside-the-Box Improvement: Progressive Delivery

Production deployments could use:

```text
New Version
    │
    ▼
5% Traffic
    │
    ▼
Observe Metrics
    │
    ├── Healthy ──► 25%
    │                  │
    │                  ▼
    │                 50%
    │                  │
    │                  ▼
    │                100%
    │
    └── Unhealthy ──► Rollback
```

This can be implemented using technologies such as:

- Argo Rollouts
- Service Mesh
- Ingress-based traffic splitting

---

# 41. Outside-the-Box Improvement: Policy as Code

A platform team could enforce deployment standards automatically.

Examples:

```text
Every production deployment must have:
    ✓ Resource requests
    ✓ Resource limits
    ✓ Readiness probe
    ✓ Liveness probe
    ✓ Non-root container
    ✓ Approved image registry
    ✓ No plaintext secrets
```

Tools such as OPA/Gatekeeper or Kyverno could enforce these policies.

---

# 42. Local Validation Evidence

The following validations were performed locally.

## Helm Lint

```text
1 chart(s) linted, 0 chart(s) failed
```

## Helm Static Tests

```text
PASS: dev
PASS: staging
PASS: prod

All Helm chart tests passed
```

## Kubernetes Deployment

The application was successfully deployed to a local Docker Desktop Kubernetes cluster.

Example:

```text
Release: ml-api-dev
Namespace: dev
Status: deployed
```

## Pod

The application Pod reached:

```text
1/1 Running
```

## API

Root endpoint successfully returned:

```json
{
  "message": "Hello World",
  "service": "ml-api"
}
```

Health endpoint successfully returned:

```json
{
  "status": "healthy"
}
```

## Helm Test

Successfully completed:

```text
TEST SUITE: ml-api-test-connection
Phase: Succeeded
```

## Environment Rendering

Helm templates successfully rendered for:

```text
Development
Staging
Production
```

---

# 43. Assignment Requirement Mapping

| Requirement | Implementation | Status |
|---|---|---|
| Generic Helm Chart | `helm/ml-api` | Implemented |
| Deployable locally | Docker Desktop Kubernetes | Tested |
| ML API callable locally | Port-forward + curl | Tested |
| Environment-specific values | Dev/Staging/Prod values | Implemented |
| Minimize manual changes | Reusable templates | Implemented |
| Helm tests | Helm hook + shell tests | Tested |
| CI/CD | GitHub Actions | Implemented |
| Build/package Helm chart | `helm package` | Implemented |
| Private cloud repository | ECR OCI design | Implemented as cloud design |
| Autoscaling | HPA | Implemented |
| Health checks | Liveness/readiness | Implemented |
| Secrets strategy | Existing K8s Secret | Implemented |
| Cloud secret management | AWS Secrets Manager + ESO design | Recommended |
| IaC | Terraform Helm provider | Implemented |
| Version control strategy | Semantic versioning | Documented |
| Rollback | Helm rollback | Documented |
| Production security | Security recommendations | Documented |
| Observability | Architecture recommendations | Documented |
| GitOps | Argo CD design | Future enhancement |

---

# 44. What Has Been Tested vs Designed

To keep the assignment evaluation transparent:

### Tested Locally

- Helm chart lint
- Helm template rendering
- Dev configuration
- Staging configuration
- Production configuration
- Helm static tests
- Kubernetes Deployment
- Kubernetes Service
- Kubernetes HPA resource creation
- Application health endpoint
- Application API endpoint
- Helm integration test
- Docker image
- Local Kubernetes deployment

### Designed / Ready for Cloud Integration

- Private Helm OCI repository using Amazon ECR
- GitHub Actions AWS authentication using OIDC
- AWS IAM role integration
- Cloud-based Helm chart publication
- AWS Secrets Manager integration
- External Secrets Operator
- Production cloud infrastructure

Actual AWS deployment and ECR publication were not performed because an AWS account was not available in the development environment.

---

# 45. Key Design Principles

The project follows these principles:

### 1. DRY

Avoid duplicated Kubernetes manifests.

```text
One Chart
+
Multiple Values
```

### 2. Configuration over duplication

Environment differences belong in values files instead of separate Kubernetes manifests.

### 3. Immutable artifacts

Build once and promote the same version wherever possible.

### 4. Secure by design

Secrets should not be committed to Git.

### 5. Automated validation

Every Helm change should be validated before publication.

### 6. Environment consistency

Development, staging, and production use the same deployment templates.

### 7. Rollback capability

Every production deployment should have a known rollback path.

### 8. Infrastructure as Code

Infrastructure and application deployment should be reproducible.

---

# 46. Quick Start

Clone the repository:

```bash
git clone <repository-url>
cd ml-api-helm-platform
```

Build the application:

```bash
docker build -t ml-api:1.0.0 ./app
```

Deploy:

```bash
helm upgrade --install ml-api-dev ./helm/ml-api \
  -f ./helm/ml-api/values-dev.yaml \
  --namespace dev \
  --create-namespace
```

Check:

```bash
kubectl get pods -n dev
kubectl get svc -n dev
kubectl get hpa -n dev
```

Port-forward:

```bash
kubectl port-forward svc/ml-api 8000:8000 -n dev
```

Test:

```bash
curl http://localhost:8000/
curl http://localhost:8000/health
```

Run Helm test:

```bash
helm test ml-api-dev -n dev
```

Run chart tests:

```bash
./tests/helm-test.sh
```

---

# 47. Conclusion

This project demonstrates a reusable Kubernetes deployment model for ML APIs using Helm.

Instead of maintaining separate Kubernetes manifests for each environment, the platform provides:

```text
                    Generic Helm Chart
                           │
            ┌──────────────┼──────────────┐
            │              │              │
            ▼              ▼              ▼
           Dev          Staging          Prod
            │              │              │
            ▼              ▼              ▼
        Kubernetes     Kubernetes     Kubernetes
```

The approach provides:

- Reusable deployment templates
- Minimal environment-specific configuration
- Automated validation
- Health checks
- Autoscaling
- Helm testing
- CI/CD
- Private registry integration
- Secret management strategy
- Infrastructure-as-code integration
- Versioning
- Rollback capability
- Clear path toward GitOps and progressive delivery

The implementation is intentionally generic so that the same platform pattern can be reused for different ML APIs without modifying the underlying Kubernetes templates.
