# CI/CD Microservice Project: Jenkins + Argo CD + EKS + ECR + Helm

## Overview

Complete CI/CD pipeline for Django microservice using **Jenkins**, **Argo CD**, **Amazon EKS**, **ECR**, and **Helm**. This project implements automated building, testing, and deployment of containerized applications with GitOps principles.

## Project Structure

```
├── main.tf                    # Main Terraform configuration with all modules
├── backend.tf                 # S3 + DynamoDB backend configuration
├── outputs.tf                 # Infrastructure outputs including CI/CD info
├── terraform.tfvars.example   # Example variables file
├── deploy-ci-cd.sh            # Automated CI/CD infrastructure deployment
├── deploy-monitoring.sh       # Automated monitoring stack deployment (Prometheus + Grafana)
├── setup-jenkins.sh           # Jenkins post-deployment configuration
├── check-status.sh            # Quick status check for all components
├── Jenkinsfile                # CI pipeline configuration
├── Dockerfile                 # Django application container
├── requirements.txt           # Python dependencies
├── modules/
│   ├── s3-backend/            # Terraform state storage
│   ├── vpc/                   # Network infrastructure
│   ├── ecr/                   # Docker image registry
│   ├── eks/                   # Kubernetes cluster
│   ├── rds/                   # Universal RDS module (Aurora/RDS)
│   │   ├── rds.tf             # Regular RDS instance creation
│   │   ├── aurora.tf          # Aurora cluster creation
│   │   ├── shared.tf          # Shared resources (subnet group, security group)
│   │   ├── variables.tf       # Module variables
│   │   └── outputs.tf         # Module outputs
│   ├── jenkins/               # Jenkins CI server with Helm
│   └── argo_cd/               # Argo CD deployment controller
├── charts/
│   └── django-app/            # Helm chart for Django application
│       ├── Chart.yaml
│       ├── values.yaml        # Updated by Jenkins pipeline
│       ├── README.md
│       └── templates/
│            ├── _helpers.tpl
│            ├── configmap.yaml
│            ├── deployment.yaml
│            ├── service.yaml
│            └── hpa.yaml
└── docs/
    ├── CI_CD_GUIDE.md         # Detailed CI/CD documentation
    ├── QUICKSTART.md          # Quick start guide
    ├── SETUP.md               # Detailed setup instructions
    └── TROUBLESHOOTING.md     # Common issues and solutions
```

## Components

### 1. Infrastructure (Terraform modules)

- **S3 Backend**: S3 bucket and DynamoDB for Terraform state storage
- **VPC**: Virtual Private Cloud with public and private subnets
- **ECR**: Elastic Container Registry for Docker image storage
- **EKS**: Elastic Kubernetes Service cluster with IRSA support
- **RDS**: Universal database module supporting both Aurora Cluster and regular RDS instances
  - `shared.tf`: Common resources (Subnet Group, Security Group)
  - `aurora.tf`: Aurora Cluster and instances
  - `rds.tf`: Regular RDS instances
  - Automatic parameter group creation based on database type
  - Support for PostgreSQL, MySQL engines with flexible configuration

### 2. CI/CD Components

- **Jenkins**: CI server deployed via Helm with Kaniko for container builds
  - Kubernetes agents for scalable build execution
  - ECR integration with automatic authentication
  - GitHub integration for source code management
- **Argo CD**: GitOps continuous deployment controller
  - Automatic synchronization from Git repositories
  - Self-healing and auto-pruning capabilities
  - Web UI for deployment monitoring

### 3. Monitoring Components

- **Prometheus**: Metrics collection and storage
  - Time-series database for monitoring data
  - Service discovery and metric scraping
  - Alerting rules and notification system
- **Grafana**: Visualization and dashboards
  - Interactive dashboards and charts
  - Data source integration with Prometheus
  - User management and access control

### 4. Application Components

- **Django Application**: Containerized Python web application
- **Helm Chart**: Kubernetes manifests with ConfigMaps, Deployments, Services, HPA
- **Docker Images**: Stored in ECR with automated tagging

## CI/CD Workflow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │    Jenkins      │    │   Amazon ECR    │
│   Push Code     │───▶│   CI Server     │───▶│ Image Registry  │
│                 │    │   (Kaniko)      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                │                        │
                                ▼                        │
                       ┌─────────────────┐               │
                       │  Git Repository │               │
                       │  Update Helm    │               │
                       │     Charts      │               │
                       └─────────────────┘               │
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │    Argo CD      │    │   EKS Cluster   │
                       │ CD Controller   │───▶│  Django App     │
                       │                 │    │                 │
                       └─────────────────┘    └─────────────────┘
```

### Process Flow

1. **Developer** pushes code to Django application repository
2. **Jenkins Pipeline** automatically:
   - Clones source code
   - Builds Docker image using Kaniko
   - Pushes image to ECR with build number tag
   - Updates Helm chart values.yaml with new image tag
   - Commits and pushes changes back to Git
3. **Argo CD** detects Git changes and:
   - Synchronizes updated Helm chart
   - Deploys new application version to EKS cluster
   - Monitors application health

## RDS Database Module

The universal RDS module supports both Aurora Cluster and regular RDS instances:

### Aurora PostgreSQL Example

```hcl
module "database" {
  source = "./modules/rds"
  
  use_aurora   = true
  project_name = "myapp"
  environment  = "production"
  
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnets
  allowed_security_groups = [module.eks.node_security_group_id]
  
  engine                 = "aurora-postgresql"
  engine_version         = "14.9"
  instance_class         = "db.r6g.large"
  parameter_group_family = "aurora-postgresql14"
  
  database_name   = "django_db"
  master_username = "dbadmin"
  master_password = var.db_password
  
  reader_count            = 2
  backup_retention_period = 14
  storage_encrypted       = true
  deletion_protection     = true
}
```

### Regular MySQL RDS Example

```hcl
module "database" {
  source = "./modules/rds"
  
  use_aurora   = false
  project_name = "myapp"
  environment  = "staging"
  
  vpc_id              = module.vpc.vpc_id
  allowed_cidr_blocks = ["10.0.0.0/16"]
  
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.small"
  
  allocated_storage = 100
  multi_az         = true
  master_password  = var.mysql_password
}
```
## Deployment Options

### Option 1: Complete Infrastructure + CI/CD

```bash
# Deploy complete infrastructure and CI/CD in two phases
chmod +x deploy-ci-cd.sh
./deploy-ci-cd.sh
```

### Option 2: CI/CD Only (Infrastructure Already Exists)

```bash
# Deploy only Jenkins and Argo CD components
./deploy-ci-cd.sh --cicd-only
```

### Option 3: Infrastructure Only

```bash
# Deploy only infrastructure components (VPC, EKS, ECR)
terraform init
terraform plan
terraform apply
```

### Option 4: Deploy Monitoring Stack

```bash
# Deploy Prometheus and Grafana monitoring
chmod +x deploy-monitoring.sh
./deploy-monitoring.sh

# Access Grafana dashboard
kubectl port-forward -n monitoring svc/grafana 3000:80
# URL: http://localhost:3000 (admin/admin123)
```

### Option 5: Complete Cleanup

```bash
# Destroy all infrastructure and CI/CD components
./deploy-ci-cd.sh --destroy
```

## Deployment Steps

### Automated Deployment (Recommended)

```bash
# Deploy complete CI/CD infrastructure
chmod +x deploy-ci-cd.sh
./deploy-ci-cd.sh
```

**What this deploys:**
- EKS cluster with all networking components
- ECR repository for Docker images
- Jenkins CI server with Kaniko support
- Argo CD deployment controller
- Automated configuration and setup

### Manual Step-by-Step Deployment

#### Step 1: Deploy infrastructure

```bash

terraform init
terraform plan
terraform apply
```

#### Step 2: Configure kubectl

```bash
CLUSTER_NAME=$(terraform output -raw eks_info | jq -r '.cluster_name')
aws eks update-kubeconfig --region us-west-2 --name $CLUSTER_NAME
kubectl get nodes
```

#### Step 3: Configure CI/CD Tools

```bash
# Setup Jenkins credentials and ECR access
chmod +x setup-jenkins.sh
./setup-jenkins.sh

# Check overall system status
chmod +x check-status.sh
./check-status.sh
```

#### Step 4: Setup Jenkins Pipeline

1. Access Jenkins UI (URL provided after deployment)
2. Login with credentials: admin / admin123!
3. Add GitHub credentials (ID: 'github-credentials')
4. Create new Pipeline job pointing to your Django repository
5. Configure webhook for automatic builds

#### Step 5: Setup Argo CD Application

1. Access Argo CD UI (URL provided after deployment)
2. Login with credentials: admin / admin123!
3. Verify Django application is automatically created
4. Configure auto-sync policies if needed

#### Step 6: Deploy Monitoring (Optional)

```bash
# Deploy Prometheus and Grafana
chmod +x deploy-monitoring.sh
./deploy-monitoring.sh

# Check monitoring deployment
kubectl get pods -n monitoring

# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80
```

#### Step 7: Verify deployment

```bash
# Check infrastructure status
./check-status.sh

# Check Kubernetes resources
kubectl get pods -A
kubectl get services
kubectl get applications -n argocd

# Check Jenkins and Argo CD
kubectl logs -f deployment/jenkins -n jenkins
kubectl logs -f deployment/argocd-application-controller -n argocd
```

## Access Information

After deployment, you'll receive access information for:

### Jenkins CI Server
- **URL**: Provided via LoadBalancer (check deployment output)
- **Username**: admin
- **Password**: admin123!
- **Purpose**: CI pipeline management and build monitoring

### Argo CD Controller
- **URL**: Provided via LoadBalancer (check deployment output)
- **Username**: admin  
- **Password**: admin123!
- **Purpose**: CD pipeline monitoring and application management

### Django Application
- **URL**: Available after first successful deployment
- **Access**: Via Kubernetes LoadBalancer service

### Monitoring Stack (Optional)
- **Prometheus URL**: http://localhost:9090 (via port-forward)
- **Grafana URL**: http://localhost:3000 (via port-forward)
- **Grafana Login**: admin / admin123
- **Purpose**: Infrastructure and application monitoring

## CI/CD Pipeline Configuration

### Jenkins Pipeline (Jenkinsfile)

The Jenkinsfile includes:
- **Source Code Checkout**: Clones Django application repository
- **Docker Build**: Uses Kaniko for secure container builds in Kubernetes
- **ECR Push**: Automatic authentication and image push with build tags
- **Helm Chart Update**: Updates values.yaml with new image tags
- **Git Commit**: Pushes updated chart back to repository

### Argo CD Application

Automatically configured to:
- **Monitor**: Git repository for Helm chart changes
- **Sync**: Deploy updated applications to EKS cluster  
- **Self-Heal**: Automatically fix configuration drift
- **Prune**: Remove orphaned resources

## Configuration

### Environment Variables (ConfigMap)

ConfigMap is configured in `charts/django-app/values.yaml` with the following variables:

```yaml
configMap:
  data:
    DEBUG: "False"
    ALLOWED_HOSTS: "*"
    DATABASE_ENGINE: "django.db.backends.postgresql"
    DATABASE_NAME: "django_db"
    DATABASE_USER: "django_user"
    DATABASE_PASSWORD: "django_password"
    DATABASE_HOST: "postgres-service"
    DATABASE_PORT: "5432"
    REDIS_HOST: "redis-service"
    REDIS_PORT: "6379"
    SECRET_KEY: "your-secret-key-change-in-production"
```

### CI/CD Integration

The pipeline automatically:
- Updates image.repository with ECR URL
- Updates image.tag with Jenkins build number
- Triggers Argo CD synchronization via Git changes

### Autoscaling (HPA)

- **Minimum replicas**: 2
- **Maximum replicas**: 6  
- **Trigger**: CPU > 70%
- **Monitoring**: Automatic scaling based on load

## Testing

### CI/CD Pipeline Testing

```bash
# Trigger pipeline by pushing to Django repository
git push origin main

# Monitor Jenkins build
kubectl logs -f -l app=jenkins -n jenkins

# Monitor Argo CD synchronization
kubectl logs -f -l app.kubernetes.io/name=argocd-application-controller -n argocd

# Check application deployment
kubectl get pods -l app=django-app
```

### Get external IP

```bash
# Django application service
kubectl get service django-app

# Jenkins UI
kubectl get service jenkins -n jenkins

# Argo CD UI
kubectl get service argocd-server -n argocd
```

### Test autoscaling

```bash
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
while true; do wget -q -O- http://django-app/; done

kubectl get hpa django-app --watch
```

## Cleanup

### Complete Infrastructure Cleanup

```bash
# Destroy all infrastructure
./deploy-ci-cd.sh --destroy

# Or using Terraform directly
terraform destroy
```

### Individual Component Cleanup

```bash
# Remove Django application
helm uninstall django-app

# Remove Jenkins
helm uninstall jenkins -n jenkins

# Remove Argo CD  
helm uninstall argocd -n argocd

# Remove Monitoring Stack (if installed)
helm uninstall prometheus -n monitoring
helm uninstall grafana -n monitoring
kubectl delete namespace monitoring

# Then destroy infrastructure
terraform destroy
```

## Troubleshooting

### Monitoring Issues

```bash
# Check monitoring stack status
kubectl get pods -n monitoring
kubectl get svc -n monitoring

# Check Prometheus logs
kubectl logs -n monitoring deployment/prometheus-server

# Check Grafana logs
kubectl logs -n monitoring deployment/grafana

# Restart monitoring services
kubectl rollout restart deployment/prometheus-server -n monitoring
kubectl rollout restart deployment/grafana -n monitoring

# Access Grafana admin
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

### AWS Free Tier Compatibility

```bash
# Error: FreeTierRestrictionError - backup retention period exceeds free tier limit
# Solution: Use free tier compatible settings

# For Aurora PostgreSQL (Free Tier)
module "database" {
  source = "./modules/rds"
  
  use_aurora   = true
  engine       = "aurora-postgresql"
  engine_version = "13.13"  # Stable version
  instance_class = "db.t3.medium"  # Minimum for Aurora
  
  backup_retention_period = 1   # Max 1 day for free tier
  reader_count           = 0    # No readers for free tier
  deletion_protection    = false # For development
  
  # Other required settings...
}

# For Regular RDS (Free Tier Alternative)
module "database" {
  source = "./modules/rds"
  
  use_aurora   = false
  engine       = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.micro"   # Free tier eligible
  
  allocated_storage       = 20    # Free tier limit
  backup_retention_period = 0     # No backups for free tier
  multi_az               = false  # Single-AZ for free tier
  
  # Other required settings...
}
```

### Script Execution Issues (WSL/Linux)

```bash
# Fix "cannot execute: required file not found" error
# This happens when scripts have Windows line endings (CRLF)

# Solution 1: Convert line endings (if dos2unix is available)
dos2unix deploy-ci-cd.sh
chmod +x deploy-ci-cd.sh
./deploy-ci-cd.sh

# Solution 2: Convert using sed (if dos2unix not available)
sed -i 's/\r$//' deploy-ci-cd.sh
chmod +x deploy-ci-cd.sh
./deploy-ci-cd.sh

# Solution 3: Convert using tr
tr -d '\r' < deploy-ci-cd.sh > deploy-ci-cd-fixed.sh
mv deploy-ci-cd-fixed.sh deploy-ci-cd.sh
chmod +x deploy-ci-cd.sh
./deploy-ci-cd.sh

# Solution 4: Run with bash directly
bash deploy-ci-cd.sh
```

### CI/CD Issues

```bash
# Check Jenkins status and logs
kubectl get pods -n jenkins
kubectl logs deployment/jenkins -n jenkins

# Check Argo CD status and logs  
kubectl get pods -n argocd
kubectl logs deployment/argocd-application-controller -n argocd

# Force Argo CD synchronization
kubectl patch app django-app -n argocd --type merge \
  --patch='{"operation":{"sync":{"revision":"HEAD"}}}'

# Re-run Jenkins setup
./setup-jenkins.sh

# Check overall system status
./check-status.sh
```

### ECR issues

```bash
aws ecr describe-repositories --region us-west-2
aws ecr list-images --repository-name microservice-project-ecr --region us-west-2

# Test ECR authentication
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_URL
```

### EKS issues

```bash
aws eks describe-cluster --name microservice-project-eks-cluster --region us-west-2
aws eks describe-nodegroup --cluster-name microservice-project-eks-cluster --nodegroup-name microservice-project-worker-nodes --region us-west-2
```

### Helm issues

```bash
helm list
helm history django-app
helm get all django-app
```

## Additional Features

### Automated CI/CD Pipeline

The system provides:
- **Zero-downtime deployments** via Kubernetes rolling updates
- **Automatic rollback** capabilities via Argo CD
- **Build artifact management** in ECR with automatic cleanup
- **Monitoring and alerting** through Kubernetes events

### Update Application

```bash
# Push new code to trigger automatic CI/CD
git add .
git commit -m "Update application"
git push origin main

# Monitor deployment progress
kubectl get pods -w
kubectl get applications -n argocd

# Manual deployment (if needed)
helm upgrade django-app ./charts/django-app \
  --set image.tag=<new-tag>
```

### Scaling and Monitoring

```bash
# Manual scaling
kubectl scale deployment django-app --replicas=5

# View HPA status
kubectl get hpa django-app --watch

# Monitor resource usage
kubectl top pods
kubectl top nodes
```

### Monitoring and Observability

```bash
# Kubernetes Dashboard (optional)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin user
kubectl create serviceaccount dashboard-admin-sa
kubectl create clusterrolebinding dashboard-admin-sa \
  --clusterrole=cluster-admin \
  --serviceaccount=default:dashboard-admin-sa

# Access Jenkins metrics
kubectl port-forward svc/jenkins 8080:80 -n jenkins

# Access Argo CD metrics  
kubectl port-forward svc/argocd-server 8081:80 -n argocd
```

## Documentation

- **[docs/CI_CD_GUIDE.md](docs/CI_CD_GUIDE.md)**: Comprehensive CI/CD setup and usage guide
- **[docs/MONITORING.md](docs/MONITORING.md)**: Monitoring setup with Prometheus and Grafana
- **[docs/QUICKSTART.md](docs/QUICKSTART.md)**: Quick start guide for immediate deployment
- **[docs/SETUP.md](docs/SETUP.md)**: Detailed setup and configuration instructions
- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**: Common issues and their solutions
- **[DEPLOYMENT.md](DEPLOYMENT.md)**: Two-phase deployment guide with prerequisites and verification steps

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- kubectl >= 1.24
- Helm >= 3.0
- Docker (for local testing)
- Git configured with access tokens

## Support & Troubleshooting

For issues and troubleshooting, follow this order:

1. **🚀 Quick Start**: Check [docs/QUICKSTART.md](docs/QUICKSTART.md) for immediate deployment
2. **📋 Deployment Guide**: Review [DEPLOYMENT.md](DEPLOYMENT.md) for step-by-step instructions
3. **⚙️ Setup Issues**: Check [docs/SETUP.md](docs/SETUP.md) for detailed configuration
4. **🔧 Common Problems**: See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for solutions
5. **📊 System Status**: Run `./check-status.sh` for system overview
6. **📋 Logs**: Review component logs using kubectl commands in the troubleshooting section above

### Quick Health Check

```bash
# Check overall system status
./check-status.sh

# Check specific components
kubectl get pods -A
kubectl get services -A
helm list -A
```