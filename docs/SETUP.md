# Setup for Deployment

## Preparation

### 1. Copy terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit terraform.tfvars

Change values in `terraform.tfvars` file:

```bash
# AWS region for resource deployment
aws_region = "us-west-2"

# Unique S3 bucket name for Terraform state
# IMPORTANT: Replace with your unique name!
s3_bucket_name = "terraform-state-bucket-microservice-project-bignichok"
```

### 3. Configure AWS CLI

```bash
# Configure AWS credentials
aws configure

# Or export environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

### 4. Enable S3 backend (optional)

If you want to use S3 backend for Terraform state, uncomment the block in `backend.tf` file:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-microservice-project-bignichok"
    key            = "microservice-project/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

**Warning**: S3 bucket and DynamoDB table must exist before using the backend!

### 5. Install Required Tools

#### Windows:
```powershell
# Chocolatey
choco install terraform awscli kubernetes-cli kubernetes-helm docker-desktop

# Or Winget
winget install Hashicorp.Terraform Amazon.AWSCLI Helm.Helm Docker.DockerDesktop
```

#### macOS:
```bash
# Homebrew
brew install terraform awscli kubectl helm docker
```

#### Linux (Ubuntu/Debian):
```bash
# Terraform
sudo apt-get update && sudo apt-get install terraform --classic

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# kubectl
sudo snap install kubectl --classic

# Helm
sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Docker
sudo apt install docker.io docker-compose
sudo usermod -aG docker $USER
```

## Readiness Check

```bash
# Check tool versions
terraform version
aws --version
kubectl version --client
helm version
docker --version

# Check AWS access
aws sts get-caller-identity
```

## Structure After Deployment

After successful deployment you will have:

1. **EKS cluster** with 1-2 worker nodes
2. **ECR repository** for Docker images
3. **VPC** with public and private subnets
4. **Django application** deployed via Helm
5. **LoadBalancer** for external access
6. **HPA** for autoscaling

## Security

### Recommendations:

1. **Do not store secrets in values.yaml**
2. **Use AWS Secrets Manager or Kubernetes Secrets**
3. **Configure RBAC for EKS**
4. **Restrict ECR access**
5. **Use private subnets for worker nodes**

### Example Kubernetes Secret creation:

```bash
kubectl create secret generic django-secrets \
  --from-literal=database-password='secure-password' \
  --from-literal=secret-key='very-secret-key'
```

Then in deployment.yaml:

```yaml
envFrom:
  - configMapRef:
      name: django-config
  - secretRef:
      name: django-secrets
```