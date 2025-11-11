# Lesson 7: Kubernetes (EKS) + ECR + Helm

## Overview

Create Kubernetes cluster with ECR repository and deploy Django application using Helm chart.

## Project Structure

```
lesson-7/
├── main.tf                    
├── backend.tf                 
├── outputs.tf                 
├── terraform.tfvars.example  
├── deploy.sh                  
├── modules/
│   ├── s3-backend/           
│   ├── vpc/                  
│   ├── ecr/                  
│   └── eks/                  
└── charts/
    └── django-app/           
        ├── Chart.yaml
        ├── values.yaml
        ├── README.md
        └── templates/
            ├── _helpers.tpl
            ├── configmap.yaml
            ├── deployment.yaml
            ├── service.yaml
            └── hpa.yaml
```

## Components

### 1. Terraform modules

- **S3 Backend**: S3 bucket and DynamoDB for Terraform state storage
- **VPC**: Virtual Private Cloud with public and private subnets
- **ECR**: Elastic Container Registry for Docker image storage
- **EKS**: Elastic Kubernetes Service cluster

### 2. Helm Chart

- **Deployment**: Django application deployment from ECR image
- **Service**: LoadBalancer for external access
- **ConfigMap**: Django environment variables
- **HPA**: Horizontal Pod Autoscaler (2-6 pods at CPU > 70%)

## Deployment Steps

### Option 1: Automated deployment

```bash
chmod +x lesson-7/deploy.sh
./lesson-7/deploy.sh all
```

### Option 2: Step-by-step deployment

#### Step 1: Deploy infrastructure

```bash
cd lesson-7

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

#### Step 3: Upload Docker image to ECR

```bash
ECR_URL=$(terraform output -raw ecr_info | jq -r '.repository_url')
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_URL

docker build -t django-app .
docker tag django-app:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

#### Step 4: Deploy Helm Chart

```bash
helm install django-app ./charts/django-app \
  --set image.repository=$ECR_URL \
  --set image.tag=latest
```

#### Step 5: Verify deployment

```bash
kubectl get pods
kubectl get services
kubectl get hpa
kubectl logs -f deployment/django-app
```

## Configuration

### ConfigMap variables

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

### Autoscaling (HPA)

- **Minimum replicas**: 2
- **Maximum replicas**: 6
- **Trigger**: CPU > 70%

## Testing

### Get external IP

```bash
kubectl get service django-app
```

### Test autoscaling

```bash
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
while true; do wget -q -O- http://django-app/; done

kubectl get hpa django-app --watch
```

## Cleanup

```bash
helm uninstall django-app

cd lesson-7
terraform destroy
```

## Troubleshooting

### ECR issues

```bash
aws ecr describe-repositories --region us-west-2
aws ecr list-images --repository-name lesson-7-ecr --region us-west-2
```

### EKS issues

```bash
aws eks describe-cluster --name lesson-7-eks-cluster --region us-west-2
aws eks describe-nodegroup --cluster-name lesson-7-eks-cluster --nodegroup-name lesson-7-worker-nodes --region us-west-2
```

### Helm issues

```bash
helm list
helm history django-app
helm get all django-app
```

## Additional Features

### Update application

```bash
docker build -t django-app:v2 .
docker tag django-app:v2 $ECR_URL:v2
docker push $ECR_URL:v2

helm upgrade django-app ./charts/django-app \
  --set image.tag=v2
```

### Monitoring

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

kubectl create serviceaccount dashboard-admin-sa
kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa
```