# MediCore Secure Clinical Cloud Infrastructure

## Project Overview

This repository contains the infrastructure, security controls, containerisation artefacts, monitoring analysis, compliance documentation, and incident response evidence for the MediCore Health Systems DTS202 assignment.

## Architecture Overview

The planned AWS architecture will use the Europe (London) region (`eu-west-2`) and will include:

- a custom VPC;
- public, private application, and restricted database subnets;
- a bastion host as the controlled administrative entry point;
- private web/application compute resources;
- an encrypted PostgreSQL database;
- private object storage;
- monitoring, logging, and alerting;
- Docker and Kubernetes artefacts;
- Infrastructure as Code using Terraform.

This section will be updated after the final architecture has been deployed and tested.

## Repository Structure

- `infrastructure/` — Terraform Infrastructure as Code files
- `docker/` — Dockerfile, docker-compose.yml, and vulnerability documentation
- `kubernetes/` — Kubernetes deployment and service manifests
- `screenshots/` — clearly named assignment evidence
- `analysis/` — monitoring data, visualisations, and chart outputs
- `compliance/` — Incident Response Plan and supporting compliance documents
- `.github/workflows/` — CI/CD workflow files

## Deployment Instructions

Step-by-step deployment instructions will be added as the infrastructure is implemented and tested.

## Tools Used and Rationale

This section will document the tools selected for the project, including Terraform, AWS CLI, GitHub Actions, Docker, Kubernetes, and vulnerability scanning tools. Security-related choices will be supported by authoritative sources such as NCSC and OWASP where applicable.

## Security Notice

No AWS credentials, private keys, passwords, Terraform state files, environment secrets, or patient data are stored in this repository.

