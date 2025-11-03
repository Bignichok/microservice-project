# Terraform Infrastructure Project - Lesson 5

This project demonstrates creating AWS infrastructure using Terraform with a modular architecture. The project includes setting up S3 backend for state file storage, creating VPC with public and private subnets, and an ECR repository for Docker images.

## 📁 Project Structure

```
lesson-5/
│
├── main.tf                  # Main file for connecting modules
├── backend.tf               # Backend configuration for state (S3 + DynamoDB)
├── outputs.tf               # General resource outputs
└── modules/                 # Directory with all modules
|    │
|    ├── s3-backend/          # Module for S3 and DynamoDB
|    │   ├── s3.tf            # S3 bucket creation
|    │   ├── dynamodb.tf      # DynamoDB creation
|    │   ├── variables.tf     # Variables for S3
|    │   └── outputs.tf       # S3 and DynamoDB information output
|    │
|    ├── vpc/                 # Module for VPC
|    │   ├── vpc.tf           # VPC, subnets, Internet Gateway creation
|    │   ├── routes.tf        # Routing configuration
|    │   ├── variables.tf     # Variables for VPC
|    │   └── outputs.tf       # VPC information output
|    │
|    └── ecr/                 # Module for ECR
|        ├── ecr.tf           # ECR repository creation
|        ├── variables.tf     # Variables for ECR
|        └── outputs.tf       # ECR repository URL output
|
└── README.md                 # Project documentation
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

### Steps to Launch

#### 1. Clone and navigate to directory
```bash
cd lesson-5
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
    key            = "lesson-5/terraform.tfstate"
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

## 🧹 Resource Cleanup

To delete all created resources:

```bash
terraform destroy
```
