# KubeForge

**A cloud-native DevSecOps and platform engineering project.**

KubeForge demonstrates an end-to-end container delivery and Kubernetes operations workflow, combining a Python API, Docker, Kubernetes, Helm, GitOps, automated security checks, Terraform validation, and Prometheus/Grafana observability.

## Project Overview

KubeForge provides a small instrumented API and the deployment automation around it. The project focuses on repeatable builds, Kubernetes deployment, CI quality gates, container publishing, and operational visibility.

### Architecture

```text
Developer
   |
   v
GitHub Repository
   |
   v
GitHub Actions CI
   |-- Python tests
   |-- Helm lint and template validation
   |-- Gitleaks secret scanning
   |-- Semgrep static analysis
   |-- Terraform format and validation
   |
   v
Build and Publish Container
   |
   v
GitHub Container Registry (GHCR)
   |
   v
Kubernetes / Kind
   |-- KubeForge API
   |-- Kubernetes Service
   |-- Horizontal Pod Autoscaler
   |
   +--> Helm deployments
   |
   +--> Argo CD GitOps
   |
   +--> Prometheus --> Grafana
```

The diagram represents the project's components and workflow. Argo CD manages configured GitOps applications; not every deployment path is necessarily controlled by Argo CD.

## Technology Stack

| Area | Technologies |
|---|---|
| API | Python, FastAPI, Uvicorn |
| Testing | pytest |
| Containerization | Docker |
| Orchestration | Kubernetes, Kind |
| Packaging | Helm |
| GitOps | Argo CD |
| CI/CD | GitHub Actions |
| Container registry | GitHub Container Registry |
| Security | Gitleaks, Semgrep |
| Infrastructure configuration | Terraform |
| Metrics and dashboards | Prometheus, Grafana |
| Kubernetes metrics | metrics-server, HPA |

## API Endpoints

The FastAPI application exposes the following endpoints:

| Endpoint | Purpose |
|---|---|
| `GET /` | Application name, version, status, and platform |
| `GET /health` | Health response |
| `GET /ready` | Readiness response |
| `GET /metrics` | Prometheus-format metrics |

FastAPI's interactive API documentation is available at `/docs` when the application is running.

### Prometheus instrumentation

The application records:

- `kubeforge_http_requests_total` — request counter labelled by HTTP method, endpoint, and status code.
- `kubeforge_http_request_duration_seconds` — request-duration histogram labelled by endpoint.

These metrics support request-rate, error-rate, and latency queries in Prometheus.

## Repository Structure

```text
.
├── .github/workflows/ci.yml
├── application/
│   ├── app/
│   ├── tests/
│   └── requirements.txt
├── docker/
│   └── Dockerfile
├── helm/
│   └── kubeforge/
├── kubernetes/
├── gitops/
├── monitoring/
│   ├── kubeforge-servicemonitor.yaml
│   └── values.yaml
├── terraform/
│   └── main.tf
├── labs/
├── scripts/
├── security/
├── docs/
├── .dockerignore
└── README.md
```

Some directories may be reserved for future documentation or extensions.

## CI/CD Pipeline

The workflow in `.github/workflows/ci.yml` runs on pushes and pull requests targeting `main`.

It includes six jobs:

1. **Test Python Application** — installs application dependencies and runs pytest.
2. **Validate Helm Chart** — lints and renders the Helm chart.
3. **Detect Secrets** — runs Gitleaks.
4. **Static Application Security Testing** — runs Semgrep with the Python ruleset.
5. **Terraform Format and Validate** — checks formatting, initializes without a backend, and validates configuration.
6. **Build and Publish Container** — after the required checks pass, builds and publishes the image on pushes to `main`.

Published image tags:

```text
ghcr.io/kesab2909/kubeforge-api:latest
ghcr.io/kesab2909/kubeforge-api:<commit-sha>
```

The publish job requires GitHub Actions package-write permission.

## Run Locally

Requirements: Python 3.12 or compatible, pip, and PowerShell or a shell of your choice.

From the repository root:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r application/requirements.txt
python -m pip install pytest
python -m pytest application/tests/ -v
```

Start the API:

```powershell
python -m pip install uvicorn
python -m uvicorn app.main:app --app-dir application --reload --port 8000
```

Test the endpoints from another terminal:

```powershell
Invoke-RestMethod http://localhost:8000/
Invoke-RestMethod http://localhost:8000/health
Invoke-RestMethod http://localhost:8000/ready
Invoke-WebRequest http://localhost:8000/metrics
```

Open `http://localhost:8000/docs` for the interactive API documentation.

## Kubernetes and Helm

The project includes Kubernetes manifests and a Helm chart under `helm/kubeforge`.

Useful inspection commands:

```powershell
kubectl get nodes
kubectl get pods -A
kubectl get svc -n kubeforge
kubectl get hpa -n kubeforge
helm lint helm/kubeforge
helm template kubeforge helm/kubeforge
helm list -A
```

The existing local Kind cluster and namespaces may differ from a fresh installation. Review the chart values and manifests before deploying to another cluster.

## GitOps with Argo CD

Argo CD is installed in the development cluster, and the repository contains GitOps configuration. Review the manifests under `gitops/` and the Argo CD application status before applying them to another environment.

```powershell
kubectl get applications -A
kubectl get pods -n argocd
```

These commands require a cluster with Argo CD and the relevant custom resources installed.

## Monitoring and Observability

The project uses Prometheus to scrape KubeForge metrics and Grafana to display a platform dashboard.

The dashboard includes:

1. API request rate
2. KubeForge pod health
3. Total API requests
4. HTTP 5xx error rate
5. P95 request latency
6. KubeForge container restarts

The custom ServiceMonitor is defined in `monitoring/kubeforge-servicemonitor.yaml`; Helm monitoring settings are in `monitoring/values.yaml`.

Example local port-forward commands, assuming the current release and namespaces:

```powershell
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
kubectl port-forward -n kubeforge-helm svc/kubeforge 8080:80
```

Run each port-forward in a separate terminal. These commands assume the named Services exist in your cluster.

Open:

- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`
- KubeForge health endpoint: `http://localhost:8080/health`

Container CPU and memory usage metrics were not available in the current Prometheus setup during development; the dashboard therefore uses the available restart-count metric for its sixth panel.

## Terraform and AWS Deployment

KubeForge includes two Terraform configurations:

- `terraform/` — configuration for the existing AWS environment. Its resources were imported into Terraform state; the original EC2 server was created manually.
- `terraform/fresh/` — a separate configuration that provisions a fresh AWS deployment, including a VPC, public subnet, internet gateway, route table, security group, and EC2 instance.

### Fresh deployment architecture

The fresh configuration provisions an Amazon Linux EC2 instance (`t3.micro`) in `ap-southeast-2` and uses EC2 user data to install Docker, pull the published KubeForge API image from GHCR, and run the container on port 80.

The root volume is an encrypted 8 GB `gp3` EBS volume. The security group permits inbound HTTP on port 80. This demonstration uses HTTP, not HTTPS, and should not be treated as a production-hardened public deployment.

### Deploy

From the repository root in PowerShell:

```powershell
terraform -chdir=terraform/fresh init
terraform -chdir=terraform/fresh fmt
terraform -chdir=terraform/fresh validate
terraform -chdir=terraform/fresh plan
```

Review the plan before applying it. The fresh deployment creates separate AWS resources and can incur charges.

```powershell
terraform -chdir=terraform/fresh apply
terraform -chdir=terraform/fresh output
```

The outputs provide the API URL, health-check URL, and EC2 instance ID. The deployed API was verified at the time of testing: the root endpoint returned the expected KubeForge application metadata, and `/health` returned `healthy`.

### Important state and cleanup notes

- The fresh configuration has its own Terraform state under `terraform/fresh/`.
- Terraform state files and saved plan files must not be committed to Git.
- The original manually deployed server is separate from the fresh deployment.
- Review the plan carefully before applying changes or destroying resources.
- When the demonstration is no longer needed, review the resources and costs in AWS. Destroy only the fresh resources after confirming the plan targets the correct configuration and state.

The configuration is a learning demonstration, not a complete production landing zone. HTTPS, stronger network restrictions, centralized secrets, and production-grade remote state management remain possible improvements.


## Current Validation Status

During development, the following checks were verified:

- Python tests passed (4 tests at the recorded checkpoint).
- Helm linting and template rendering passed.
- Helm release test passed.
- Terraform validation passed.
- GitHub Actions completed all six jobs successfully for commit `73c2033`.
- Both KubeForge Prometheus scrape targets returned `up = 1`.
- The Kubernetes HPA reported CPU metrics after a temporary cluster disruption.

These are recorded development results, not a guarantee that every environment or future commit will behave identically.

## Limitations and Future Improvements

- The `terraform/fresh/` configuration provisions a fresh AWS deployment, while the original `terraform/` configuration manages resources associated with the existing AWS environment.
- Container CPU and memory time-series metrics can be expanded through additional Prometheus exporters and monitoring configuration.
- Enhance the project documentation with architecture diagrams, deployment runbooks, and detailed troubleshooting reports as they are completed and verified. AWS deployment screenshots and Grafana dashboard screenshots are available in `docs/screenshots/`.
- The current AWS demonstration uses HTTP without TLS and is not production-hardened. Future improvements include HTTPS, stricter network access controls, enhanced secrets management, and additional security validation.
- Review Terraform plans, AWS resource costs, Kubernetes resource limits, security policies, and deployment settings before applying infrastructure changes or using the project in production.

## License

No license is declared yet. Add a `LICENSE` file before distributing the project under an open-source license.
