# MediCore Secure Clinical Cloud Infrastructure

## Project Overview

This repository contains the secure cloud infrastructure developed for MediCore Health Systems as part of the DTS202 Data Governance and Compliance assignment.

MediCore is a UK digital health organisation supporting approximately 140,000 patient records across three NHS Trusts. The project demonstrates the design, deployment, security hardening, monitoring and analysis of an AWS-based clinical cloud environment.

The solution was deployed in the AWS Europe (London) region (`eu-west-2`) and includes network segmentation, controlled administrative access, encrypted storage, monitoring and alerting, resilience testing, container security, vulnerability scanning, data analysis and compliance documentation.

The repository also contains the supporting evidence used throughout the assignment.

---

## Architecture Overview

The MediCore environment uses a three-tier architecture deployed within a custom AWS Virtual Private Cloud (VPC).

### AWS Region and VPC

- AWS Region: Europe (London) — `eu-west-2`
- VPC: `medicore-vpc`
- VPC CIDR: `10.0.0.0/16`
- Three Availability Zones:
  - `eu-west-2a`
  - `eu-west-2b`
  - `eu-west-2c`

Nine subnets are distributed across the three Availability Zones:

- three public subnets;
- three private application subnets;
- three restricted database subnets.

The public subnets use an Internet Gateway. The private application and database tiers use local VPC routing and do not have a direct Internet route.

This segmentation reduces unnecessary exposure between infrastructure tiers and limits communication to required network paths.

### Public Tier

The public tier contains:

- an Internet-facing Application Load Balancer (ALB);
- a bastion host used for controlled administrative access.

The ALB is deployed across all three public subnets.

HTTP traffic on port 80 is redirected to HTTPS on port 443. HTTPS/TLS terminates at the ALB and requests are forwarded to the application instances through the target group on HTTP port 80.

The bastion host accepts SSH only from the authorised administrator IP address.

### Application Tier

The application tier contains EC2 instances deployed in private application subnets.

The instances are managed by an Auto Scaling Group configured with:

- minimum capacity: 2;
- desired capacity: 2;
- maximum capacity: 4.

The Auto Scaling Group spans three Availability Zones and is integrated with the Application Load Balancer target group.

Application Security Groups permit:

- HTTP port 80 only from the ALB Security Group;
- SSH port 22 only from the bastion Security Group.

The application instances do not require direct inbound Internet access.

### Database Tier

The database tier contains Amazon RDS for PostgreSQL in restricted database subnets.

The RDS configuration includes:

- PostgreSQL;
- encrypted storage;
- private subnet placement;
- no public accessibility;
- PostgreSQL port 5432 accessible only from the application Security Group;
- automated backups and Point-in-Time Recovery (PITR).

The assignment deployment uses Single-AZ RDS and a one-day backup retention period because of the project environment and cost constraints.

For a production clinical environment, Multi-AZ deployment and a backup retention period of at least seven days are recommended.

### Object Storage

Amazon S3 is used for clinical-data object storage.

Security controls include:

- server-side encryption using SSE-S3 (AES-256);
- S3 Block Public Access enabled.

No real patient data is stored in this assignment environment.

### Monitoring and Resilience

Amazon CloudWatch is used for infrastructure monitoring and security-related alerting.

The deployment includes five CloudWatch alarms, including monitoring for failed SSH login activity and infrastructure health.

A CloudWatch Logs metric filter is used to identify failed SSH authentication attempts.

The resilience of the application tier was tested by terminating an EC2 application instance. The service continued to return HTTP 200 responses while the Auto Scaling Group detected the change and created a replacement instance.

---

## Security Architecture

Security Groups enforce communication between the infrastructure tiers.

| Security Group | Permitted Traffic |
|---|---|
| Bastion | SSH 22 from authorised administrator IP only |
| ALB | HTTP 80 and HTTPS 443 from clients |
| Application | HTTP 80 from ALB Security Group; SSH 22 from bastion |
| Database | PostgreSQL 5432 from application Security Group; administrative SSH path restricted through bastion where applicable |

This implements a layered network model in which resources are exposed only where required.

The NCSC recommends granular access controls and the principle of least privilege so that identities and services can access only the resources required for their role. The same principle was applied to both AWS IAM and network access within the MediCore environment.

---

## Identity and Access Management

Five AWS IAM roles were created to demonstrate role-based, least-privilege access:

- Clinical Read Only;
- Clinical Write;
- Database Administrator;
- Monitoring Read Only;
- Backup Operator.

Permissions were separated according to operational responsibilities rather than providing unrestricted administrative access.

This supports the NCSC principle of least privilege and reduces the potential impact of compromised or incorrectly used credentials.

---

## Encryption

Data-at-rest protection is implemented using:

- Amazon RDS encrypted storage;
- Amazon S3 SSE-S3 encryption using AES-256;
- encrypted EC2 storage where configured.

Data in transit between users and the public application endpoint is protected using HTTPS/TLS at the Application Load Balancer.

During the assignment deployment, a self-signed certificate was imported into AWS Certificate Manager for demonstration and testing. A production deployment should replace this with a trusted certificate associated with the organisation's registered domain.

The NCSC Cloud Security Principles recommend protecting data in transit using established protocols such as TLS and protecting customer data at rest using appropriate encryption.

---

## Repository Structure

```text
Assignment-DTS202-MediCore/
│
├── infrastructure/
│   └── Terraform Infrastructure as Code files
│
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── vulnerability-notes.md
│
├── kubernetes/
│   ├── deployment.yaml
│   └── service.yaml
│
├── screenshots/
│   └── assignment evidence organised by assessment activity
│
├── analysis/
│   ├── Jupyter Notebook
│   ├── monitoring CSV files
│   ├── requirements.txt
│   └── generated analysis outputs
│
├── compliance/
│   └── MediCore Incident Response Plan and supporting documents
│
├── .github/
│   └── workflows/
│
└── README.md
```

---

# Deployment Instructions

The following steps describe how the MediCore environment can be deployed from scratch.

## 1. Prerequisites

Install the following tools:

- Git
- AWS CLI
- Terraform
- Docker
- Docker Compose
- Trivy
- Grype
- Python 3
- Jupyter Notebook
- kubectl where Kubernetes validation or deployment is required

An AWS account with permission to create the required infrastructure is also required.

Clone the repository:

```bash
git clone https://github.com/bi86op/Assignment-DTS202-MediCore.git
cd Assignment-DTS202-MediCore
```

Configure the AWS CLI:

```bash
aws configure
```

Select the London AWS region:

```text
eu-west-2
```

AWS credentials must not be committed to the repository.

---

## 2. Initialise Terraform

Move to the infrastructure directory:

```bash
cd infrastructure
```

Initialise Terraform:

```bash
terraform init
```

Validate the Terraform configuration:

```bash
terraform validate
```

Review the infrastructure that Terraform intends to create:

```bash
terraform plan
```

Do not apply a Terraform plan without reviewing the proposed resources and security settings.

---

## 3. Deploy the AWS Infrastructure

After reviewing the plan:

```bash
terraform apply
```

Confirm the deployment when prompted.

The infrastructure configuration creates the AWS resources required for the MediCore architecture, including the VPC, subnet structure and associated cloud resources represented in the Infrastructure as Code configuration.

Where resources were configured or validated separately during the assignment, the corresponding evidence is retained in the `screenshots/` directory.

---

## 4. Verify Network Segmentation

After deployment, verify that:

1. the VPC uses CIDR `10.0.0.0/16`;
2. public, private application and restricted database subnets exist across the three Availability Zones;
3. public subnets have a route to the Internet Gateway;
4. private application and database subnets do not have a direct Internet route;
5. the bastion host is located in the public tier;
6. application EC2 instances are located in private application subnets;
7. database resources are located in the restricted database tier.

Verify the Security Group rules to ensure that:

- bastion SSH access is restricted to the authorised administrator IP;
- application HTTP access is accepted only from the ALB;
- application SSH access is accepted only through the bastion;
- PostgreSQL port 5432 is accepted only from the application Security Group.

---

## 5. Configure and Verify the Application Load Balancer

Deploy or verify the Application Load Balancer across the three public subnets.

The listener configuration should provide:

```text
HTTP 80  -> Redirect to HTTPS 443
HTTPS 443 -> Application target group
```

Register the application instances with the target group and verify that the targets report as healthy.

For the assignment environment, a self-signed TLS certificate was generated and imported into AWS Certificate Manager.

Verify HTTPS connectivity and the negotiated TLS connection.

For production use, replace the demonstration certificate with a trusted certificate for the organisation's registered domain.

---

## 6. Verify Auto Scaling

Configure or verify the application Auto Scaling Group:

```text
Minimum capacity: 2
Desired capacity: 2
Maximum capacity: 4
```

The Auto Scaling Group should use the private application subnets across the three Availability Zones and connect its instances to the ALB target group.

Verify that at least two healthy application instances are available.

Resilience can be tested by terminating one application instance and confirming that:

1. the application remains available through the ALB;
2. the terminated instance becomes unhealthy or disappears from the target group;
3. the Auto Scaling Group launches a replacement instance;
4. the replacement instance becomes healthy.

---

## 7. Configure and Verify RDS

Deploy or verify the PostgreSQL RDS instance in the database subnet group.

Confirm that:

- `Publicly accessible` is disabled;
- storage encryption is enabled;
- the database Security Group permits PostgreSQL 5432 only from the application Security Group;
- automated backups are enabled;
- Point-in-Time Recovery is available.

The assignment configuration uses Single-AZ and one-day backup retention.

For production:

```text
Multi-AZ = Enabled
Backup retention >= 7 days
```

---

## 8. Configure and Verify S3

Create or verify the clinical-data S3 bucket.

Enable:

- S3 Block Public Access;
- server-side encryption using SSE-S3/AES-256.

Confirm that public access is blocked before storing any test objects.

Do not upload real patient information or other sensitive personal data to the assignment environment.

---

## 9. Configure CloudWatch Monitoring

Configure the CloudWatch metrics, logs and alarms required for infrastructure and security monitoring.

The assignment environment includes five alarms and a failed-SSH monitoring control.

Authentication logs are used with a CloudWatch metric filter to identify failed SSH login attempts.

Verify that the relevant logs and alarms are visible in CloudWatch.

Monitoring data used for the assignment analysis is stored in the `analysis/` directory.

---

# Container Deployment and Security

## 10. Build the Docker Image

Move to the Docker directory:

```bash
cd docker
```

Build the image:

```bash
docker build -t medicore-app .
```

The Dockerfile uses a multi-stage build so that unnecessary build dependencies are not included in the production image.

The production container runs as a non-root user (`appuser`, UID 1001).

---

## 11. Run Docker Compose

Start the container environment:

```bash
docker compose up -d
```

The Compose configuration applies security controls including:

- memory limit: 256 MB;
- CPU limit: 0.5 CPU;
- read-only root filesystem;
- `tmpfs` for `/tmp`;
- Docker secrets rather than plaintext password environment variables.

OWASP recommends limiting container resources to reduce the impact of denial-of-service conditions and using read-only filesystems where possible.

---

## 12. Vulnerability Scanning

Scan the image using Trivy:

```bash
trivy image medicore-app
```

Scan the same image using Grype:

```bash
grype medicore-app
```

The image was scanned with both tools during the assignment.

Critical vulnerabilities identified during the initial scan were remediated. The before-and-after results, remediation actions and accepted-risk decisions for remaining findings are documented in:

```text
docker/vulnerability-notes.md
```

The final security requirement was:

```text
CRITICAL vulnerabilities = 0
```

---

## 13. Docker User Namespace Remapping

Docker user namespace remapping was enabled and tested.

The configuration demonstrates that a process can appear as UID 0 inside the container while being mapped to an unprivileged high-numbered UID on the host.

This reduces the privileges associated with container root processes on the underlying host.

---

# Kubernetes Configuration

## 14. Validate the Kubernetes Manifests

The Kubernetes configuration is stored in:

```text
kubernetes/deployment.yaml
kubernetes/service.yaml
```

The deployment configuration includes:

- two replicas;
- CPU and memory requests;
- CPU and memory limits;
- a liveness probe using `/health`;
- `runAsNonRoot: true`;
- `runAsUser: 1001`.

Where a Kubernetes cluster is available, the manifests can be applied using:

```bash
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
```

Verify the deployment using:

```bash
kubectl get pods
kubectl get deployments
kubectl get services
```

---

# Monitoring Data Analysis

## 15. Create the Python Environment

Move to the analysis directory:

```bash
cd analysis
```

Create a virtual environment:

```bash
python3 -m venv .venv
```

Activate it:

```bash
source .venv/bin/activate
```

On Windows:

```powershell
.venv\Scripts\Activate.ps1
```

Install the required packages:

```bash
pip install -r requirements.txt
```

Start Jupyter Notebook:

```bash
jupyter notebook
```

The analysis uses monitoring data exported from AWS CloudWatch.

The visualisations include:

- application EC2 CPU utilisation over time;
- failed SSH attempts per hour.

The analysis provides a baseline for identifying infrastructure behaviour and potential security events.

---
# 1. AWS Services and Architecture Rationale
   
| AWS Service                         | Purpose                                    | Rationale                                                                                                                                                                                     |
| ----------------------------------- | ------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **AWS VPC**                         | Network isolation                          | Provides a dedicated network boundary and enables separation of public, application and database tiers.                                                                                       |
| **Amazon EC2**                      | Application and administrative compute     | Provides flexible compute for the private application tier and bastion host and integrates directly with ALB and Auto Scaling.                                                                |
| **Application Load Balancer (ALB)** | Traffic distribution and HTTPS termination | Distributes application traffic across multiple instances and Availability Zones, performs health checks and provides a central HTTPS endpoint.                                               |
| **EC2 Auto Scaling**                | Application resilience                     | Maintains the required application capacity and automatically replaces unhealthy instances.                                                                                                   |
| **Amazon RDS for PostgreSQL**       | Clinical database                          | Selected instead of a self-managed database for the main clinical database because RDS provides managed backups, PITR and storage encryption while reducing database administration overhead. |
| **Amazon S3**                       | Object storage                             | Provides scalable object storage with SSE-S3 encryption and Block Public Access controls.                                                                                                     |
| **AWS IAM**                         | Access control                             | Supports role-based, least-privilege access and separation of responsibilities through the five MediCore IAM roles.                                                                           |
| **Amazon CloudWatch**               | Monitoring and alerting                    | Provides native integration with AWS metrics and logs and was used for alarms and failed-SSH monitoring without introducing a separate monitoring platform.                                   |

# 2. Tools Used and Rationale

The tools used in this project were selected based on security, reproducibility, integration with AWS and their suitability for demonstrating industry-standard cloud and DevSecOps practices.

| Tool / Service | Purpose | Rationale and Alternative Considered |
|---|---|---|
| **Terraform** | Infrastructure as Code (IaC) | Selected over manual AWS Console configuration and AWS CloudFormation because it provides a declarative, version-controlled and repeatable deployment using readable HCL. Unlike CloudFormation, Terraform is not limited to AWS and provides transferable multi-cloud IaC skills. NCSC guidance recommends Infrastructure as Code for non-experimental cloud environments because it supports consistency, recovery and security review of infrastructure definitions. |
| **AWS CLI** | AWS configuration and verification | Used alongside the AWS Management Console because command-line operations are repeatable and provide an additional way to verify deployed resources rather than relying only on manual console interaction. |
| **Git / GitHub** | Version control | Selected instead of maintaining local copies of configuration files because Git provides version history, traceability and the ability to review changes to infrastructure, security configuration and documentation. |
| **Docker** | Application containerisation | Selected instead of relying directly on the host operating system because containers provide a consistent and reproducible runtime that can be hardened and vulnerability-scanned independently. |
| **Docker Compose** | Container runtime configuration | Selected instead of individual `docker run` commands because security settings such as CPU and memory limits, a read-only filesystem, tmpfs and Docker secrets can be defined consistently in a version-controlled configuration file. |
| **Trivy** | Primary vulnerability scanning | Selected over Snyk as the primary scanner because Trivy it is open source, lightweight, straightforward to run locally and suitable for container-image vulnerability scanning. It also fits automated DevSecOps workflows. |
| **Grype** | Secondary vulnerability scanning | Used alongside Trivy rather than relying on a single scanner. This allowed findings to be cross-checked using an independent vulnerability-scanning engine. |
| **Kubernetes** | Container orchestration | Used to demonstrate production-oriented container controls including replicas, health checking, resource requests and limits, and non-root execution. This provides controls beyond those available from running individual Docker containers alone. |
| **Python / pandas** | Monitoring-data analysis | Selected instead of manually analysing exported CSV data because pandas provides reproducible filtering, aggregation and processing of CloudWatch monitoring data. |
| **Matplotlib** | Data visualisation | Selected instead of manually creating charts because visualisations can be generated programmatically and reproduced directly from the analysed data. |
| **Jupyter Notebook** | Reproducible analysis | Selected because code, outputs, visualisations and interpretation can be retained together in one reproducible analysis rather than separating the analysis code from its results. |

NCSC guidance supports the use of Infrastructure as Code for cloud deployments because it can improve consistency, support recovery and allow infrastructure definitions to be reviewed for security issues.

OWASP container security guidance recommends controls including resource limits and read-only filesystems. These recommendations informed the Docker and Docker Compose hardening used in this project.

---

# Security Rationale

The project applies security controls based on established cloud and application-security principles.

The NCSC Cloud Security Principles state that data in transit should be protected against interception and tampering, including through the use of encryption such as TLS. This informed the use of HTTPS/TLS at the Application Load Balancer.

The NCSC also recommends protecting data at rest and applying granular access controls based on the principle of least privilege. These principles informed the use of RDS and S3 encryption, Security Group restrictions and role-based IAM permissions.

Security monitoring was implemented using CloudWatch logs, metrics and alarms. NCSC guidance highlights the importance of audit information and security alerts for identifying and investigating security incidents.

For container security, OWASP recommends limiting container resources and using read-only filesystems. These controls are implemented in the Docker Compose configuration alongside non-root execution and Docker secrets.

---

# Security Limitations and Production Recommendations

This repository demonstrates an assignment environment rather than a production NHS clinical platform.

The main limitations are:

- RDS is currently Single-AZ;
- RDS backup retention is one day;
- the TLS certificate used for testing is self-signed;
- the architecture was designed within assignment and AWS cost constraints.

Before production deployment, the following should be prioritised:

1. enable RDS Multi-AZ;
2. increase database backup retention to at least seven days;
3. replace the demonstration TLS certificate with a trusted production certificate;
4. conduct further security testing and operational monitoring;
5. complete MediCore's own NHS DSPT assessment and organisational governance activities.

---

# Compliance and Incident Response

The repository contains a MediCore Incident Response Plan covering the response to security incidents affecting the clinical cloud environment.

The wider assignment considers:

- UK GDPR;
- Data Protection Act 2018;
- NHS Data Security and Protection Toolkit (DSPT);
- Network and Information Systems Regulations;
- ISO/IEC 27001;
- AWS shared-responsibility considerations.

AWS compliance certifications support assurance in the cloud provider but do not remove MediCore's responsibility for configuring and operating its own workloads securely.

---

# Security Notice

No AWS credentials, private keys, passwords, Terraform state files, environment secrets or real patient data should be committed to this repository.

Before committing changes, check the staged files:

```bash
git status
git diff --cached
```

Secrets must be stored using appropriate secret-management mechanisms rather than hard-coded into source files.

---

# References

National Cyber Security Centre (NCSC) (2023) *Cloud security guidance: The cloud security principles – Principle 1: Data in transit protection*. Available at: https://www.ncsc.gov.uk/collection/cloud/the-cloud-security-principles/principle-1-data-in-transit-protection (Accessed: 23 August 2026).

National Cyber Security Centre (NCSC) (2023) *Cloud security guidance: The cloud security principles – Principle 2: Asset protection and resilience*. Available at: https://www.ncsc.gov.uk/collection/cloud/the-cloud-security-principles/principle-2-asset-protection-and-resilience (Accessed: 23 August 2026).

National Cyber Security Centre (NCSC) (2023) *Using a cloud platform securely*. Available at: https://www.ncsc.gov.uk/collection/cloud/using-cloud-services-securely/using-a-cloud-platform-securely (Accessed: 23 August 2026).

National Cyber Security Centre (NCSC) (2023) *Cloud security guidance: Principle 13 – Audit information and alerting for customers*. Available at: https://www.ncsc.gov.uk/collection/cloud/the-cloud-security-principles/principle-13-audit-information-and-alerting-for-customers (Accessed: 23 August 2026).

OWASP Foundation (n.d.) *Docker Security Cheat Sheet*. Available at: https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html (Accessed: 23 August 2026).

---

