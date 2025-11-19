# Two-Phase Deployment Structure

## Overview
The deployment is now organized to avoid Terraform circular dependencies:

### Phase 1: Infrastructure (`main.tf`)
- VPC and networking
- EKS cluster 
- ECR repository
- S3 backend for state

### Phase 2: CI/CD Components (`cicd/main.tf`)
- Jenkins with Kaniko builds
- Argo CD for GitOps
- Separate Terraform state

## 📋 Prerequisites Checklist

### Required Tools
- [ ] AWS CLI installed and configured
- [ ] Terraform installed (>= 1.0)
- [ ] kubectl installed  
- [ ] helm installed (>= 3.0)
- [ ] Git installed

### AWS Permissions
- [ ] AWS credentials configured (`aws configure`)
- [ ] Permissions for EKS, ECR, VPC, S3, DynamoDB
- [ ] Region set to us-west-2 (or update terraform.tfvars)

### Repository Setup
- [ ] Repository cloned locally
- [ ] terraform.tfvars file configured
- [ ] deploy-ci-cd.sh script executable

## File Structure
```
.
├── main.tf                    # Infrastructure components
├── outputs.tf                # Infrastructure outputs
├── variables.tf              # Infrastructure variables
├── deploy-ci-cd.sh           # Main deployment script
└── cicd/
    └── main.tf               # CI/CD components (Jenkins, Argo CD)
```

## Deployment Commands

### Option 1: Complete Deployment
```bash
# Deploy everything in two phases automatically
./deploy-ci-cd.sh
```

### Option 2: CI/CD Only (after infrastructure exists)
```bash
# Deploy only Jenkins and Argo CD components
./deploy-ci-cd.sh --cicd-only
```

### Option 3: Manual Phase Deployment
```bash
# Phase 1: Infrastructure
terraform init
terraform apply

# Phase 2: CI/CD (after infrastructure is ready)
cd cicd
terraform init
terraform apply -var="cluster_name=<cluster-name>" -var="ecr_repository_url=<ecr-url>"
```

### Option 4: Destroy Everything
```bash
./deploy-ci-cd.sh --destroy
```

## 🎯 Post-Deployment Verification

### Infrastructure Check
- [ ] EKS cluster created and accessible
- [ ] ECR repository available
- [ ] kubectl configured for cluster
- [ ] All cluster nodes in Ready state

### Services Check  
- [ ] Jenkins pod running (2/2 containers ready)
- [ ] Argo CD pods all running
- [ ] LoadBalancer services have external IPs
- [ ] Services accessible via URLs

### Access Verification
- [ ] Jenkins UI accessible (admin/admin123!)
- [ ] Argo CD UI accessible (admin/admin123!)
- [ ] Both services responding correctly

## 🚀 Next Steps After Deployment

1. **Configure Jenkins**:
   - Install required plugins (Kubernetes, Pipeline, Git)
   - Add GitHub credentials
   - Create pipeline job

2. **Setup Argo CD**:
   - Connect to Git repository
   - Create Application for Django microservice
   - Configure sync policies

3. **Test Pipeline**:
   - Push code to trigger CI/CD
   - Verify Docker image builds
   - Check Argo CD deployment