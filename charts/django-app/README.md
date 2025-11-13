# Django App Helm Chart

This Helm chart deploys Django application in Kubernetes cluster.

## Installation

### Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- ECR repository with Django Docker image

### Installing the chart

1. First, get ECR repository URL from Terraform outputs:
```bash
terraform output ecr_info
```

2. Install chart with specified image URL:
```bash
helm install django-app ./charts/django-app \
  --set image.repository=<ECR_REPOSITORY_URL> \
  --set image.tag=latest
```

Or create values.yaml file with your configuration:
```bash
helm install django-app ./charts/django-app -f custom-values.yaml
```

### Configuration

#### Main Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| `image.repository` | ECR repository URL | `""` |
| `image.tag` | Docker image tag | `"latest"` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.type` | Kubernetes service type | `LoadBalancer` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container target port | `8000` |
| `deployment.replicaCount` | Number of replicas | `2` |

#### Autoscaling

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | Minimum number of replicas | `2` |
| `autoscaling.maxReplicas` | Maximum number of replicas | `6` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization percentage | `70` |

#### ConfigMap

ConfigMap contains environment variables for Django application:
- `DEBUG`
- `ALLOWED_HOSTS`
- `DATABASE_*` (database configuration)
- `REDIS_*` (Redis configuration)
- `SECRET_KEY`

### Verify Deployment

```bash
# Check pods status
kubectl get pods

# Check services
kubectl get services

# Check HPA
kubectl get hpa

# Get logs
kubectl logs -f deployment/django-app
```

### Uninstallation

```bash
helm uninstall django-app
```

## ECR Connection

To work with ECR, authentication setup is required:

```bash
# Get Docker token
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <ECR_REPOSITORY_URL>

# Build and push image
docker build -t django-app .
docker tag django-app:latest <ECR_REPOSITORY_URL>:latest
docker push <ECR_REPOSITORY_URL>:latest
```