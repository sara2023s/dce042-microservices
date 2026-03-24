# DCE 04.2 – Assessment 1: AWS Containerised DevOps Pipeline

**Student Name:** Sara
**Programme:** 4241 – DCE L7 Diploma in Cloud Engineering
**Course:** DCE04.2 – Multi-Cloud Automation and Emerging Technologies
**Assessment:** Implementation and Technical Documentation (50%)

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Diagram](#2-architecture-diagram)
3. [Resource Inventory](#3-resource-inventory)
4. [Prerequisites](#4-prerequisites)
5. [Deployment Guide](#5-deployment-guide)
6. [Terraform Structure](#6-terraform-structure)
7. [Microservices](#7-microservices)
8. [CI/CD Pipeline](#8-cicd-pipeline)
9. [Azure Entra ID SAML Federation](#9-azure-entra-id-saml-federation)
10. [Monitoring & Autoscaling](#10-monitoring--autoscaling)
11. [Security Design](#11-security-design)
12. [Validation & Testing](#12-validation--testing)
13. [Clean-up](#13-clean-up)

---

## 1. Project Overview

This project provisions a **fully automated, highly available microservices platform** on AWS using Terraform (Infrastructure as Code). Two containerised Python Flask microservices — a **Product Service** and an **Order Service** — are deployed on Amazon ECS Fargate across two Availability Zones, fronted by separate public Application Load Balancers, and released via a single CodePipeline with parallel Blue/Green deployments.

Identity federation with **Azure Entra ID** (SAML 2.0) enables single sign-on into the AWS Console with enforced MFA.

### Design Decisions

| Decision | Rationale |
|---|---|
| **ECS Fargate** over EC2 | Serverless containers eliminate EC2 lifecycle management |
| **Two separate ALBs** | Independent scaling and failure domains per microservice |
| **Private subnets for ECS tasks** | Tasks are not directly internet-accessible; ALBs front all traffic |
| **NAT Gateways (one per AZ)** | ECS tasks in private subnets can reach ECR and AWS APIs without a single point of failure |
| **Blue/Green deployments** | Zero-downtime releases with instant rollback on failure |
| **Remote state (S3 + DynamoDB)** | Team-safe locking, state versioning, and disaster recovery |
| **Modular Terraform** | Each concern (networking, ECS, CI/CD, etc.) is an isolated, reusable module |

---

## 2. Architecture Diagram

```
                          INTERNET
                             |
              +--------------+--------------+
              |                             |
      +-------+-------+           +--------+------+
      |  ALB – Svc A  |           |  ALB – Svc B  |
      | (Product Svc) |           | (Order Svc)   |
      | Port 80 / 443 |           | Port 80 / 443 |
      +-------+-------+           +--------+------+
              |                             |
   +----------+----------+   +-------------+----------+
   |                     |   |                        |
   |   us-east-1a        |   |   us-east-1b           |
   | +--Public Subnet--+ |   | +--Public Subnet------+|
   | |  ALB nodes      | |   | |  ALB nodes          ||
   | +--------+--------+ |   | +----------+----------+|
   |          |  VPC     |   |            |    VPC    |
   | +--Private Subnet-+ |   | +--Private Subnet-----+|
   | | ECS Task: Svc A | |   | | ECS Task: Svc A     ||
   | | ECS Task: Svc B | |   | | ECS Task: Svc B     ||
   | +--------+--------+ |   | +----------+----------+|
   |          |          |   |            |           |
   | +--NAT Gateway----+ |   | +--NAT Gateway-------+|
   +----------+----------+   +-------------+----------+
              |                             |
              +----------+------------------+
                         |
              +----------+----------+
              |   AWS Managed SVCs  |
              | ECR  DynamoDB  S3   |
              | CloudWatch  SNS     |
              +---------------------+

  CI/CD Flow:
  GitHub → CodePipeline
               ├─ Stage 1: Source  (CodeStar Connection)
               ├─ Stage 2: Build   ┬─ CodeBuild (Svc A) ──> ECR
               │                   └─ CodeBuild (Svc B) ──> ECR
               └─ Stage 3: Deploy  ┬─ CodeDeploy Blue/Green (Svc A)
                                   └─ CodeDeploy Blue/Green (Svc B)

  Identity Federation:
  Azure Entra ID ──SAML 2.0──> AWS IAM SAML Provider
                                  ├─ Role: DevOpsEngineer
                                  └─ Role: ReadOnlyAuditor
```

---

## 3. Resource Inventory

| # | Resource | Type | Count |
|---|---|---|---|
| 1 | Dedicated VPC | AWS VPC | 1 |
| 2 | Public Subnets (2 AZs) | AWS Subnet | 2 |
| 3 | Private Subnets (2 AZs) | AWS Subnet | 2 |
| 4 | Internet Gateway | AWS IGW | 1 |
| 5 | NAT Gateways (1 per AZ) | AWS NAT GW | 2 |
| 6 | Route Tables | AWS Route Table | 3 |
| 7 | Security Group – ALB | AWS SG | 1 |
| 8 | Security Group – ECS Tasks | AWS SG | 1 |
| 9 | ECR Repository – Product Service | AWS ECR | 1 |
| 10 | ECR Repository – Order Service | AWS ECR | 1 |
| 11 | ECS Cluster (Fargate) | AWS ECS | 1 |
| 12 | Task Definition – Product Service | AWS ECS Task Def | 1 |
| 13 | Task Definition – Order Service | AWS ECS Task Def | 1 |
| 14 | ECS Service – Product Service | AWS ECS Service | 1 |
| 15 | ECS Service – Order Service | AWS ECS Service | 1 |
| 16 | Application Load Balancer – Svc A | AWS ALB | 1 |
| 17 | Application Load Balancer – Svc B | AWS ALB | 1 |
| 18 | Target Groups (Blue+Green × 2 svcs) | AWS TG | 4 |
| 19 | Autoscaling Policies (scale-out × 2) | AWS ASG Policy | 2 |
| 20 | Autoscaling Policies (scale-in × 2) | AWS ASG Policy | 2 |
| 21 | CloudWatch Alarms (high-CPU × 2) | CW Alarm | 2 |
| 22 | CloudWatch Alarms (low-CPU × 2) | CW Alarm | 2 |
| 23 | CloudWatch Dashboard | CW Dashboard | 1 |
| 24 | S3 Bucket – Pipeline Artifacts | AWS S3 | 1 |
| 25 | S3 Bucket – Application Assets | AWS S3 | 1 |
| 26 | DynamoDB Table – App Data | AWS DynamoDB | 1 |
| 27 | SNS Topic – Notifications | AWS SNS | 1 |
| 28 | IAM Role – ECS Task Execution | AWS IAM Role | 1 |
| 29 | IAM Role – ECS Task (Svc A) | AWS IAM Role | 1 |
| 30 | IAM Role – ECS Task (Svc B) | AWS IAM Role | 1 |
| 31 | IAM Role – CodeBuild | AWS IAM Role | 1 |
| 32 | IAM Role – CodeDeploy | AWS IAM Role | 1 |
| 33 | IAM Role – CodePipeline | AWS IAM Role | 1 |
| 34 | CodeBuild Project – Svc A | AWS CodeBuild | 1 |
| 35 | CodeBuild Project – Svc B | AWS CodeBuild | 1 |
| 36 | CodeDeploy Application – Svc A | AWS CodeDeploy | 1 |
| 37 | CodeDeploy Application – Svc B | AWS CodeDeploy | 1 |
| 38 | CodePipeline | AWS CodePipeline | 1 |
| 39 | IAM SAML Provider (Entra ID) | AWS IAM | 1 |
| 40 | Federated IAM Role – DevOpsEngineer | AWS IAM Role | 1 |
| 41 | Federated IAM Role – ReadOnlyAuditor | AWS IAM Role | 1 |

---

## 4. Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Terraform | >= 1.5.0 | Infrastructure as Code |
| AWS CLI | >= 2.0 | Authenticate and run backend setup |
| Docker | >= 24 | Build container images locally |
| Git | any | Source control |

**AWS Permissions required:**
Your IAM user/role must have permissions to create VPC, ECS, ECR, IAM, S3, DynamoDB, CodeBuild, CodeDeploy, CodePipeline, CloudWatch, and SNS resources.

**GitHub repository:**
Create a GitHub repository (e.g. `dce042-microservices`) with the contents of this project, then create an AWS CodeStar Connection to it via the AWS Console (Developer Tools → Connections).

---

## 5. Deployment Guide

### Step 1 – Clone repository and configure AWS CLI

```bash
git clone https://github.com/<your-username>/dce042-microservices.git
cd dce042-microservices

aws configure
# Enter: AWS Access Key ID, Secret, Region (us-east-1), output (json)
```

Screenshot 1: AWS CLI configuration output (`aws sts get-caller-identity`)

### Step 2 – Create the remote Terraform backend

```bash
chmod +x scripts/setup-backend.sh
./scripts/setup-backend.sh
```

Screenshot 2: S3 bucket and DynamoDB table created in AWS Console

### Step 3 – Configure Terraform variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values:
#   - alert_email
#   - codestar_connection_arn (from AWS Console)
#   - entra_saml_metadata_url (from Entra ID Enterprise App)
```

### Step 4 – Initialise Terraform (creates local + remote state)

```bash
terraform init
```

Screenshot 3: `terraform init` output showing S3 backend initialised and local `terraform.tfstate` created

### Step 5 – Review the execution plan

```bash
terraform plan -out=tfplan
```

Screenshot 4: `terraform plan` summary (number of resources to create)

### Step 6 – Apply infrastructure

```bash
terraform apply tfplan
```

Screenshot 5–15: `terraform apply` progress and final outputs

### Step 7 – Push initial Docker images to ECR

Before the first pipeline run, seed ECR with initial images:

```bash
# Authenticate Docker to ECR
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT.dkr.ecr.$REGION.amazonaws.com

# Build and push service-a
cd microservices/service-a
docker build -t $AWS_ACCOUNT.dkr.ecr.$REGION.amazonaws.com/dce042-dev-product-service:latest .
docker push $AWS_ACCOUNT.dkr.ecr.$REGION.amazonaws.com/dce042-dev-product-service:latest

# Build and push service-b
cd ../service-b
docker build -t $AWS_ACCOUNT.dkr.ecr.$REGION.amazonaws.com/dce042-dev-order-service:latest .
docker push $AWS_ACCOUNT.dkr.ecr.$REGION.amazonaws.com/dce042-dev-order-service:latest
```

Screenshot 16–17: ECR repository with pushed images visible in AWS Console

### Step 8 – Trigger the CI/CD Pipeline

Push a commit to the `main` branch of your GitHub repository. The CodePipeline will automatically trigger:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

Screenshot 18: CodePipeline execution in AWS Console showing Source → Build → Deploy stages

### Step 9 – Verify ECS services

```bash
# Check ECS services are running
aws ecs list-services --cluster dce042-dev-cluster

# Describe services
aws ecs describe-services \
  --cluster dce042-dev-cluster \
  --services dce042-dev-product-service dce042-dev-order-service
```

Screenshot 19: ECS Services console showing ACTIVE status with desired task count

### Step 10 – Test the ALB endpoints

```bash
# Get ALB DNS names from Terraform output
terraform output service_a_alb_dns_name
terraform output service_b_alb_dns_name

# Test Product Service health check
curl http://<service-a-alb-dns>/health

# Test Order Service health check
curl http://<service-b-alb-dns>/health

# Create a product
curl -X POST http://<service-a-alb-dns>/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","price":"9.99","description":"Sample item"}'
```

Screenshot 20: Browser or curl output showing `{"status":"healthy"}` responses from both services

---

## 6. Terraform Structure

```
terraform/
├── backend.tf            # S3 remote backend + provider config
├── main.tf               # Root module – calls all child modules
├── variables.tf          # All input variables (parameterised)
├── outputs.tf            # All outputs exposed after apply
├── terraform.tfvars.example
└── modules/
    ├── networking/       # VPC, subnets, IGW, NAT GW, SGs, route tables
    ├── ecr/              # Two ECR repos with lifecycle policies
    ├── iam/              # Least-privilege roles for ECS, CodeBuild, etc.
    ├── storage/          # S3 buckets, DynamoDB table, SNS topic
    ├── alb/              # Two ALBs with Blue/Green target groups
    ├── ecs/              # Cluster, task definitions, ECS services
    ├── monitoring/       # Autoscaling targets, 4 policies, 4 alarms, dashboard
    ├── cicd/             # CodeBuild, CodeDeploy, CodePipeline
    └── federation/       # Entra ID SAML provider + federated IAM roles
```

Each module follows the pattern: `variables.tf` → `main.tf` → `outputs.tf`.
All resource names use `${project_name}-${environment}-` prefix, making the codebase reusable across environments by changing a single variable.

---

## 7. Microservices

### Service A – Product Service

| Property | Value |
|---|---|
| Language | Python 3.12 / Flask |
| Port | 5000 |
| Endpoints | `GET /health`, `GET /products`, `POST /products`, `GET /products/{id}`, `DELETE /products/{id}` |
| Data store | DynamoDB (`PK=PRODUCT`) |
| Runtime | Gunicorn (2 workers, 2 threads) |

### Service B – Order Service

| Property | Value |
|---|---|
| Language | Python 3.12 / Flask |
| Port | 5001 |
| Endpoints | `GET /health`, `GET /orders`, `POST /orders`, `GET /orders/{id}`, `PUT /orders/{id}/status` |
| Data store | DynamoDB (`PK=ORDER`) |
| Runtime | Gunicorn (2 workers, 2 threads) |

Both services use a **multi-stage Docker build** to minimise image size and run as a **non-root user** for security.

---

## 8. CI/CD Pipeline

```
GitHub (main branch)
    │
    ▼
CodePipeline: dce042-dev-pipeline
    │
    ├── Stage 1: Source
    │     └── CodeStar Connection → GitHub repo
    │
    ├── Stage 2: Build (parallel, run_order = 1)
    │     ├── CodeBuild: dce042-dev-build-product-service
    │     │     - Builds Docker image from microservices/service-a/
    │     │     - Pushes to ECR with commit SHA tag
    │     │     - Writes taskdef.json + appspec.yml
    │     └── CodeBuild: dce042-dev-build-order-service
    │           - Builds Docker image from microservices/service-b/
    │           - Pushes to ECR with commit SHA tag
    │           - Writes taskdef.json + appspec.yml
    │
    └── Stage 3: Deploy (parallel, run_order = 1)
          ├── CodeDeploy Blue/Green → ECS: product-service
          │     - Shifts traffic ALB → Green target group
          │     - Terminates Blue after 5 min (configurable)
          │     - Auto-rolls back on failure
          └── CodeDeploy Blue/Green → ECS: order-service
                - Shifts traffic ALB → Green target group
                - Terminates Blue after 5 min
                - Auto-rolls back on failure
```

**IAM**: All pipeline roles follow least-privilege (only the permissions explicitly required).

---

## 9. Azure Entra ID SAML Federation

### Configuration Steps (Azure Portal)

**Step 1** – In Azure Entra ID, navigate to **Enterprise Applications** → **New Application** → **Create your own application**.

Screenshot 21: Entra ID Enterprise Application creation

**Step 2** – Select **Integrate any other application you don't find in the gallery**, name it `AWS-SSO-dce042`.

**Step 3** – Go to **Single sign-on** → select **SAML**.

**Step 4** – Configure Basic SAML:

| Field | Value |
|---|---|
| Identifier (Entity ID) | `urn:amazon:webservices` |
| Reply URL | `https://signin.aws.amazon.com/saml` |
| Sign on URL | `https://signin.aws.amazon.com/saml` |

Screenshot 22: Entra ID Basic SAML configuration

**Step 5** – Add Attribute & Claims:

| Claim Name | Value |
|---|---|
| `https://aws.amazon.com/SAML/Attributes/Role` | `<role-arn>,<saml-provider-arn>` |
| `https://aws.amazon.com/SAML/Attributes/RoleSessionName` | `user.userprincipalname` |

Screenshot 23: Attribute claims configuration

**Step 6** – Download **Federation Metadata XML**.

**Step 7** – Run Terraform with the metadata URL populated:

```bash
# In terraform.tfvars
entra_saml_metadata_url = "https://login.microsoftonline.com/<tenant-id>/federationmetadata/..."
```

```bash
terraform apply   # Creates aws_iam_saml_provider + two federated roles
```

Screenshot 24: `terraform apply` output showing `saml_provider_arn`

**Step 8** – Update the Entra ID Attribute claim **Role** with the actual ARNs from Terraform outputs:

```
arn:aws:iam::<account>:role/dce042-dev-EntraID-DevOpsEngineer,
arn:aws:iam::<account>:saml-provider/dce042-dev-entra-id-saml
```

**Step 9** – Assign Entra ID groups (DevOpsEngineer, ReadOnlyAuditor) to the Enterprise Application.

**Step 10** – Enforce MFA via **Conditional Access Policy**: require MFA for all users accessing the `AWS-SSO-dce042` application.

Screenshot 25: Conditional Access policy requiring MFA

**Step 11** – Validate end-to-end sign-in:

1. Navigate to `https://myapps.microsoft.com`
2. Click the `AWS-SSO-dce042` tile
3. Complete MFA challenge
4. Confirm redirection to the AWS Console with the DevOpsEngineer role assumed

Screenshot 26: Successful AWS Console login via Entra ID showing assumed role name

---

## 10. Monitoring & Autoscaling

### CloudWatch Alarms (4 total)

| Alarm | Service | Metric | Threshold | Action |
|---|---|---|---|---|
| `*-product-service-high-cpu` | Product Service | CPUUtilization | >= 70% | Scale OUT (+1 task) + SNS |
| `*-product-service-low-cpu` | Product Service | CPUUtilization | <= 30% | Scale IN (−1 task) |
| `*-order-service-high-cpu` | Order Service | CPUUtilization | >= 70% | Scale OUT (+1 task) + SNS |
| `*-order-service-low-cpu` | Order Service | CPUUtilization | <= 30% | Scale IN (−1 task) |

### Autoscaling Policies (4 total)

- **2 × Scale-Out**: Step scaling, +1 task, 60-second cooldown
- **2 × Scale-In**: Step scaling, −1 task, 300-second cooldown (conservative)
- Min tasks per service: **1** | Max tasks per service: **4**

### SNS Notifications

The SNS topic (`dce042-dev-notifications`) sends email alerts for:
- High-CPU scaling events
- Failed CodePipeline deployments
- Any manually subscribed operational alerts

Screenshot 27: CloudWatch dashboard showing CPU metrics for both services
Screenshot 28: SNS subscription confirmation email

---

## 11. Security Design

### Network Security

| Layer | Control |
|---|---|
| ALB Security Group | Allows 80/443 inbound from `0.0.0.0/0`; all egress allowed |
| ECS Task Security Group | Ingress **only** from the ALB Security Group; all egress allowed |
| Private Subnets | ECS tasks have no public IPs; outbound via NAT only |
| HTTPS | ALBs configured for HTTPS (TLS 1.3) when ACM cert ARN provided |

### IAM Least-Privilege Summary

| Role | Permissions |
|---|---|
| ECS Task Execution | ECR pull, CloudWatch Logs write |
| ECS Task – Svc A | DynamoDB CRUD on app-data table, S3 assets bucket |
| ECS Task – Svc B | DynamoDB CRUD on app-data table, CloudWatch Logs |
| CodeBuild | ECR push (specific repos), S3 artifacts, CloudWatch Logs |
| CodeDeploy | ECS blue/green management via `AWSCodeDeployRoleForECS` |
| CodePipeline | S3 artifacts, CodeBuild start, CodeDeploy create deployment |
| DevOpsEngineer (Federated) | PowerUserAccess + ECS/CI/CD operations |
| ReadOnlyAuditor (Federated) | ReadOnlyAccess |

### Encryption

- S3 buckets: AES-256 server-side encryption, versioning enabled
- DynamoDB: encryption at rest enabled
- ECR repositories: AES-256 encryption, image scan on push
- All traffic in transit via HTTPS/TLS

---

## 12. Validation & Testing

### Infrastructure Validation

```bash
# Confirm VPC and subnets
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=dce042"
aws ec2 describe-subnets --filters "Name=tag:Project,Values=dce042"

# Confirm Security Groups
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=dce042"

# Confirm ECS cluster and services
aws ecs describe-clusters --clusters dce042-dev-cluster
aws ecs describe-services \
  --cluster dce042-dev-cluster \
  --services dce042-dev-product-service dce042-dev-order-service

# Confirm ECR repositories
aws ecr describe-repositories

# Confirm CodePipeline
aws codepipeline get-pipeline --name dce042-dev-pipeline
```

### Application Testing

```bash
# Health checks
curl http://<service-a-alb-dns>/health   # Expected: {"status":"healthy","service":"product-service"}
curl http://<service-b-alb-dns>/health   # Expected: {"status":"healthy","service":"order-service"}

# Create a product
curl -X POST http://<service-a-alb-dns>/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":"999.99","description":"High-performance laptop"}'

# List products
curl http://<service-a-alb-dns>/products

# Create an order
curl -X POST http://<service-b-alb-dns>/orders \
  -H "Content-Type: application/json" \
  -d '{"product_id":"<product-id>","quantity":2,"customer":"test@example.com"}'

# List orders
curl http://<service-b-alb-dns>/orders
```

### Multi-AZ HA Validation

```bash
# Verify tasks are spread across AZs
aws ecs list-tasks --cluster dce042-dev-cluster --service-name dce042-dev-product-service
# For each task ARN, describe it:
aws ecs describe-tasks --cluster dce042-dev-cluster --tasks <task-arn>
# Check 'availabilityZone' field – should show both us-east-1a and us-east-1b
```

### Blue/Green Deploy Validation

```bash
# Push a code change and observe CodePipeline:
git add microservices/service-a/app.py
git commit -m "Test blue/green deploy"
git push origin main

# Monitor CodeDeploy deployment
aws deploy list-deployments \
  --application-name dce042-dev-deploy-product-service \
  --deployment-group-name dce042-dev-dg-product-service
```

Screenshot 29: CodeDeploy deployment showing traffic shift from Blue to Green target group

---

## 13. Clean-up

**IMPORTANT**: Delete all resources after assessment to avoid ongoing AWS charges.

```bash
cd terraform

# Destroy all Terraform-managed resources
terraform destroy

# Manually delete the backend resources (not managed by Terraform)
aws s3 rb s3://dce042-tf-state --force
aws dynamodb delete-table --table-name dce042-tf-state-lock --region us-east-1
```

Also delete:
- Azure Entra ID Enterprise Application
- AWS CodeStar Connection
- Any manually created resources (ACM certificates, etc.)

---

*All infrastructure defined in this repository is managed by Terraform. No manual console changes were made outside of the documented steps above.*
