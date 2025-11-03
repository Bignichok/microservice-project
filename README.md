# Terraform Infrastructure Project - Lesson 6

This project demonstrates creating a complete AWS infrastructure using Terraform with a modular architecture. The project includes setting up S3 backend for state file storage, creating VPC with public and private subnets, ECR repository for Docker images, and a fully functional EKS (Elastic Kubernetes Service) cluster with managed node groups.

## 📁 Project Structure

```
lesson-6/
│
├── main.tf                  # Main file for connecting modules
├── backend.tf               # Backend configuration for state (S3 + DynamoDB)
├── outputs.tf               # General resource outputs
├── terraform.tfvars         # Variable values configuration
├── terraform.tfvars.example # Example variable configuration
├── .gitignore              # Git ignore file
├── README.md
└── modules/                # Directory with all modules
    │
    ├── s3-backend/         # Module for S3 and DynamoDB
    │   ├── s3.tf           # S3 bucket creation
    │   ├── dynamodb.tf     # DynamoDB creation
    │   ├── variables.tf    # Variables for S3
    │   └── outputs.tf      # S3 and DynamoDB information output
    │
    ├── vpc/                # Module for VPC
    │   ├── vpc.tf          # VPC, subnets, Internet Gateway creation
    │   ├── routes.tf       # Routing configuration
    │   ├── variables.tf    # Variables for VPC
    │   └── outputs.tf      # VPC information output
    │
    ├── ecr/                # Module for ECR
    │   ├── ecr.tf          # ECR repository creation
    │   ├── variables.tf    # Variables for ECR
    │   └── outputs.tf      # ECR repository URL output
    │
    └── eks/                # Module for EKS
        ├── eks.tf          # EKS cluster and node groups
        ├── addons.tf       # EKS managed add-ons
        ├── variables.tf    # Variables for EKS
        └── outputs.tf      # EKS cluster information output
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** - configured with appropriate access rights
2. **Terraform** >= 1.0
3. **AWS credentials** with rights to create:
   - S3 buckets
   - DynamoDB tables
   - VPC and network resources
   - ECR repositories
   - EKS clusters and node groups
   - IAM roles and policies

### Steps to Launch

#### 1. Clone and navigate to directory
```bash
cd lesson-6
```

#### 2. Initialize Terraform
```bash
terraform init
```

#### 3. Check deployment plan
```bash
terraform plan
```

#### 4. Apply configuration
```bash
terraform apply
```
Confirm resource creation by entering `yes` when prompted.

#### 5. View created resources
```bash
terraform show
```

#### 6. Destroy infrastructure (when needed)
```bash
terraform destroy
```

## 🏗️ Module Description

### 1. S3 Backend Module (`modules/s3-backend/`)

**Purpose**: Create infrastructure for storing Terraform state files.

**Resources**:
- **S3 Bucket** - state file storage
- **DynamoDB Table** - locking to prevent conflicts

**Outputs**:
- `s3_bucket_name` - S3 bucket name
- `s3_bucket_arn` - S3 bucket ARN
- `dynamodb_table_name` - DynamoDB table name

### 2. VPC Module (`modules/vpc/`)

**Purpose**: Create AWS network infrastructure.

**Resources**:
- **VPC** with CIDR `10.0.0.0/16`
- **3 public subnets** (`10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`)
- **3 private subnets** (`10.0.4.0/24`, `10.0.5.0/24`, `10.0.6.0/24`)
- **Internet Gateway** for public access
- **3 NAT Gateways** for private subnets
- **Route Tables** for routing

**Outputs**:
- `vpc_id` - VPC identifier
- `public_subnet_ids` - list of public subnets
- `private_subnet_ids` - list of private subnets
- `nat_gateway_ids` - list of NAT Gateways

### 3. ECR Module (`modules/ecr/`)

**Purpose**: Create repository for Docker images.

**Resources**:
- **ECR Repository** with automatic scanning
- **Lifecycle Policy** for image management
- **Repository Policy** for access control

**Outputs**:
- `repository_name` - repository name
- `repository_url` - repository URL
- `repository_arn` - repository ARN

### 4. EKS Module (`modules/eks/`)

**Purpose**: Create a complete Amazon EKS (Elastic Kubernetes Service) cluster with managed node groups and essential add-ons.

**Resources**:
- **EKS Cluster** (Kubernetes v1.28)
- **Managed Node Groups** with auto-scaling
- **Security Groups** for cluster and worker nodes
- **IAM Roles** with appropriate policies
- **IRSA** (IAM Roles for Service Accounts) support
- **EKS Add-ons**: VPC CNI, CoreDNS, Kube-proxy, EBS CSI Driver

**Configuration**:
- **Cluster Name**: `lesson-6-eks-cluster`
- **Node Instance Type**: `t3.micro` (cost-optimized for learning)
- **Node Group**: 1 desired, 1-2 scaling range
- **Disk Size**: 10GB per node
- **Subnets**: Worker nodes in private subnets for security

**Features**:
- ✅ **Security**: Private worker nodes with security groups
- ✅ **Scalability**: Auto-scaling node groups (1-2 nodes)
- ✅ **Cost-Optimized**: t3.micro instances for study purposes
- ✅ **Add-ons**: Essential Kubernetes components pre-installed
- ✅ **IRSA**: Secure pod-level AWS permissions
- ✅ **Logging**: EKS control plane logging enabled

**Outputs**:
- `cluster_name` - EKS cluster name
- `cluster_endpoint` - Kubernetes API endpoint
- `cluster_arn` - EKS cluster ARN
- `kubectl_config_command` - Command to configure kubectl access

**Post-Deployment Steps**:
```bash
# Configure kubectl to access the cluster
aws eks --region us-west-2 update-kubeconfig --name lesson-6-eks-cluster

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces

# Deploy a test application
kubectl create deployment nginx --image=nginx:alpine
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

## ⚙️ Configuration

### Environment Variables

Before running, make sure AWS credentials are configured:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

### Backend Configuration

Backend configuration is located in `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-lesson5"
    key            = "lesson-6/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

**Important**: Before first run, change the bucket name to a unique one!

### Variable Customization

You can change settings in `main.tf`:

```hcl
# Change region
variable "aws_region" {
  default = "us-west-2"  # Replace with desired region
}

# Change S3 bucket name
variable "s3_bucket_name" {
  default = "your-unique-bucket-name"  # Use a unique name
}
```

## 🎯 EKS Learning Guide

### Essential kubectl Commands

```bash
# Cluster information
kubectl cluster-info
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Monitor resource usage
kubectl top nodes
kubectl top pods -A

# Deploy sample application
kubectl create deployment hello-world --image=nginx:alpine
kubectl scale deployment hello-world --replicas=2
kubectl expose deployment hello-world --port=80 --type=LoadBalancer

# Check deployments and services
kubectl get deployments
kubectl get services
kubectl get pods

# View logs
kubectl logs -f deployment/hello-world

# Clean up test resources
kubectl delete deployment hello-world
kubectl delete service hello-world
```

### EKS-Specific Commands

```bash
# Check EKS add-ons status
aws eks list-addons --cluster-name lesson-6-eks-cluster

# View cluster details
aws eks describe-cluster --name lesson-6-eks-cluster

# Check node group status
aws eks describe-nodegroup \
  --cluster-name lesson-6-eks-cluster \
  --nodegroup-name lesson-6-worker-nodes

# View cluster logs
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/eks/lesson-6-eks-cluster"
```

## 🔧 Troubleshooting

### Common Issues

1. **Nodes not ready**
   ```bash
   kubectl describe nodes
   kubectl get events --sort-by='.lastTimestamp'
   ```

2. **Pod networking issues**
   ```bash
   kubectl get pods -n kube-system | grep aws-node
   kubectl logs -n kube-system daemonset/aws-node
   ```

3. **DNS resolution problems**
   ```bash
   kubectl get pods -n kube-system | grep coredns
   kubectl logs -n kube-system deployment/coredns
   ```

4. **Storage issues**
   ```bash
   kubectl get storageclass
   kubectl get pv
   kubectl describe pod <pod-name>
   ```

### Useful Debugging

```bash
# Check EKS add-on versions
aws eks describe-addon-versions --addon-name vpc-cni
aws eks describe-addon-versions --addon-name coredns
aws eks describe-addon-versions --addon-name kube-proxy
aws eks describe-addon-versions --addon-name aws-ebs-csi-driver

# Verify IRSA (IAM Roles for Service Accounts)
kubectl get sa -A
kubectl describe sa aws-node -n kube-system
```

```bash
# Destroy all infrastructure
terraform destroy

# Or selectively destroy EKS only (if needed)
terraform destroy -target=module.eks
```

**Warning**: This will permanently delete all resources. Make sure you have backups of important data.
