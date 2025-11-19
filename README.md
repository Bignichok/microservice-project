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
    ├── DEPLOYMENT_CHECKLIST.md # Step-by-step deployment guide
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

### 2. CI/CD Components

- **Jenkins**: CI server deployed via Helm with Kaniko for container builds
  - Kubernetes agents for scalable build execution
  - ECR integration with automatic authentication
  - GitHub integration for source code management
- **Argo CD**: GitOps continuous deployment controller
  - Automatic synchronization from Git repositories
  - Self-healing and auto-pruning capabilities
  - Web UI for deployment monitoring

### 3. Application Components

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

## Deployment Steps

### Option 1: Full CI/CD Infrastructure Deployment

```bash
# Deploy complete CI/CD infrastructure
chmod +x deploy-ci-cd.sh
./deploy-ci-cd.sh
```

This will deploy:
- EKS cluster with all networking components
- ECR repository for Docker images
- Jenkins CI server with Kaniko support
- Argo CD deployment controller
- Automated configuration and setup

### Option 2: Manual Step-by-step Deployment

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

#### Step 6: Verify deployment

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

# Then destroy infrastructure
terraform destroy
```

## Troubleshooting

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

### Update application

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
- **[docs/DEPLOYMENT_CHECKLIST.md](docs/DEPLOYMENT_CHECKLIST.md)**: Step-by-step deployment verification checklist
- **[docs/QUICKSTART.md](docs/QUICKSTART.md)**: Quick start guide for immediate deployment
- **[docs/SETUP.md](docs/SETUP.md)**: Detailed setup and configuration instructions
- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**: Common issues and their solutions

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- kubectl >= 1.24
- Helm >= 3.0
- Docker (for local testing)
- Git configured with access tokens

## Support

For issues and troubleshooting:
1. **Quick Start**: Check [docs/QUICKSTART.md](docs/QUICKSTART.md) for immediate deployment
2. **Setup Issues**: Review [docs/SETUP.md](docs/SETUP.md) for detailed configuration
3. **Common Problems**: Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for solutions
4. **System Status**: Run `./check-status.sh` for system status overview
5. **Logs**: Review component logs using kubectl commands provided above