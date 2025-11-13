# ✅ CI/CD Deployment Checklist

## 📋 Before Deployment

- [ ] AWS CLI installed and configured
- [ ] Terraform installed (>= 1.0)
- [ ] kubectl installed  
- [ ] helm installed (>= 3.0)
- [ ] AWS permissions allow creating EKS, ECR, VPC
- [ ] GitHub Personal Access Token ready

## 🚀 Deployment Steps

### 1. Infrastructure Preparation
- [ ] Project repository cloned
- [ ] terraform.tfvars file verified
- [ ] `./deploy-ci-cd.sh` executed
- [ ] Terraform successfully created resources

### 2. Kubernetes Configuration
- [ ] kubectl configured for EKS cluster
- [ ] All cluster nodes in Ready state
- [ ] Jenkins pod running and ready
- [ ] Argo CD pods running and ready

### 3. Jenkins Setup
- [ ] Jenkins UI accessible via LoadBalancer
- [ ] Jenkins login works (admin/admin123!)
- [ ] GitHub credentials added (ID: github-credentials)
- [ ] Docker registry secret created
- [ ] Pipeline job created

### 4. Argo CD Setup
- [ ] Argo CD UI accessible via LoadBalancer  
- [ ] Argo CD login works (admin/admin123!)
- [ ] Django application created automatically
- [ ] Repository connected to Argo CD

### 5. Pipeline Testing
- [ ] Django repository created with Dockerfile
- [ ] Jenkinsfile copied to Django repository
- [ ] Pipeline triggers on code push
- [ ] Docker image builds and publishes to ECR
- [ ] Helm chart updates with new tag
- [ ] Argo CD synchronizes changes to cluster

## 🔍 Component Verification

### EKS Cluster
```bash
kubectl get nodes                    # All nodes Ready
kubectl get pods -A                  # All system pods running
kubectl cluster-info                 # Cluster accessible
```

### Jenkins
```bash
kubectl get pods -n jenkins          # Jenkins pod Running
kubectl get svc jenkins -n jenkins   # LoadBalancer has External-IP
kubectl logs deployment/jenkins -n jenkins  # Logs without errors
```

### Argo CD
```bash
kubectl get pods -n argocd           # All Argo CD pods Running  
kubectl get svc argocd-server -n argocd     # LoadBalancer has External-IP
kubectl get applications -n argocd   # Django app created
```

### ECR Repository
```bash
aws ecr describe-repositories        # Repository exists
aws ecr get-login-password | docker login <ecr-url>  # Login works
```

## 🐞 Troubleshooting

### Jenkins Cannot Push to ECR
- [ ] Check Jenkins service account IAM role
- [ ] Run `./setup-jenkins.sh` again
- [ ] Check Docker registry secret

### Argo CD Not Synchronizing
- [ ] Check Git repository access
- [ ] Check repository settings in Argo CD
- [ ] Force synchronization via UI or kubectl

### Pipeline Fails on Image Build
- [ ] Check Dockerfile in Django repository
- [ ] Check requirements.txt
- [ ] Check Kaniko pod logs

### LoadBalancer Does Not Get External-IP
- [ ] Check AWS Load Balancer Controller
- [ ] Check security groups
- [ ] Wait a few minutes (AWS may take time)

## 📊 Final Verification

- [ ] Jenkins UI accessible and functional
- [ ] Argo CD UI accessible and functional  
- [ ] ECR repository created
- [ ] Pipeline can build and publish images
- [ ] Argo CD can deploy applications
- [ ] Django application accessible in cluster

## 🎉 Successful Completion

If all items are completed, your CI/CD pipeline is ready to work!

### Next Steps:
1. Create Django microservice
2. Add Jenkinsfile to repository
3. Push code
4. Watch automatic deployment

### Useful Commands for Further Work:

```bash
# Pipeline monitoring
kubectl logs -f -l app=jenkins -n jenkins

# Argo CD sync monitoring
kubectl logs -f -l app.kubernetes.io/name=argocd-application-controller -n argocd

# Django app verification
kubectl get pods -l app=django-app
kubectl logs -l app=django-app

# Access Django via port-forward (if LoadBalancer not ready)
kubectl port-forward svc/django-app 8080:80
```