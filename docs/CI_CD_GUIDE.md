# CI/CD Infrastructure Deployment Guide

This document describes the process of deploying a complete CI/CD pipeline using Jenkins + Helm + Terraform + Argo CD.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│    Jenkins      │───▶│   Amazon ECR    │───▶│    Argo CD      │
│   (CI Server)   │    │ (Image Registry)│    │ (CD Controller) │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                                              │
         │                                              ▼
         ▼                                    ┌─────────────────┐
┌─────────────────┐                          │                 │
│                 │                          │   EKS Cluster   │
│  Git Repository │◄─────────────────────────│  (Django App)   │
│ (Helm Charts)   │                          │                 │
└─────────────────┘                          └─────────────────┘
```

## CI/CD Process

1. **Jenkins**: Builds Docker image from Django application and publishes to ECR
2. **Jenkins**: Updates Helm chart with new image tag in Git
3. **Argo CD**: Automatically synchronizes changes from Git to Kubernetes cluster

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed (>= 1.0)
- kubectl installed
- Helm installed (>= 3.0)

## Deployment Steps

### 1. Initialize Terraform

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply configuration
terraform apply
```

### 2. Configure kubectl

```bash
# Configure kubectl for EKS cluster
aws eks update-kubeconfig --region us-west-2 --name microservice-project-eks-cluster
```

### 3. Setup Jenkins

```bash
# Grant execution permissions for the script
chmod +x setup-jenkins.sh

# Run Jenkins setup
./setup-jenkins.sh
```

### 4. Setup GitHub Credentials in Jenkins

1. Open Jenkins UI
2. Navigate to `Manage Jenkins > Credentials`
3. Add new credentials:
   - **Kind**: Username with password
   - **Username**: Your GitHub username
   - **Password**: GitHub Personal Access Token
   - **ID**: `github-credentials`

### 5. Create Pipeline in Jenkins

1. In Jenkins UI create a new Pipeline job
2. In Pipeline configuration specify:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your Git repository URL
   - **Script Path**: `Jenkinsfile`

### 6. Verify Argo CD

```bash
# Get Argo CD URL
kubectl get svc argocd-server -n argocd

# Get admin password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

## Repository Setup

For proper pipeline operation you need two repositories:

### 1. Django Application Repository

Structure:
```
django-microservice/
├── Dockerfile
├── requirements.txt
├── manage.py
├── myproject/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
└── myapp/
    ├── __init__.py
    ├── views.py
    └── urls.py
```

### 2. Helm Charts Repository (current)

Contains:
- `charts/django-app/` - Helm chart for Django application
- `Jenkinsfile` - Pipeline configuration

## Workflow

1. **Developer** pushes code to Django application repository
2. **Jenkins** automatically:
   - Clones code
   - Builds Docker image using Kaniko
   - Publishes image to ECR with build number tag
   - Updates `values.yaml` in Helm chart with new tag
   - Commits and pushes changes
3. **Argo CD** detects Git changes and:
   - Synchronizes new Helm chart
   - Deploys updated application to cluster

## Monitoring and Management

### Jenkins
- **URL**: Output after terraform apply
- **Credentials**: admin / admin123!

### Argo CD
- **URL**: Output after terraform apply  
- **Credentials**: admin / admin123!

### Useful Commands

```bash
# Check pods status
kubectl get pods -A

# Jenkins logs
kubectl logs -f deployment/jenkins -n jenkins

# Argo CD logs
kubectl logs -f deployment/argocd-application-controller -n argocd

# Check applications status in Argo CD
kubectl get applications -n argocd

# Manual application synchronization
kubectl patch app django-app -n argocd --type merge --patch='{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

## Troubleshooting

### ECR Authentication Issue

```bash
# Check and update Docker credentials
./setup-jenkins.sh
```

### Argo CD Not Synchronizing

```bash
# Force synchronization
kubectl patch app django-app -n argocd --type merge --patch='{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
```

### Jenkins Cannot Clone Repository

1. Check GitHub credentials in Jenkins
2. Ensure Personal Access Token has repository read permissions

## Scaling

For production environment it's recommended to:

1. **Jenkins**: 
   - Increase resources for Jenkins controller
   - Configure automatic agent scaling

2. **Argo CD**:
   - Enable HA mode
   - Configure repository secrets for private repositories

3. **EKS**:
   - Configure automatic node group scaling
   - Add monitoring and logging

## Security

- Use IAM roles instead of access keys
- Configure Network Policies in Kubernetes
- Regular updates of images and Helm charts
- Use secrets management for sensitive data