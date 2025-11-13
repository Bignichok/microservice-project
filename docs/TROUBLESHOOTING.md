# 🔧 Troubleshooting Guide

## Common Issues and Solutions

### 1. Terraform Issues

#### "Error: bucket already exists"
```bash
aws s3 ls
s3_bucket_name = "terraform-state-bucket-microservice-project-YOUR-UNIQUE-NAME"
```

#### "Error: could not acquire state lock"
```bash
terraform force-unlock LOCK_ID

aws dynamodb delete-item \
  --table-name terraform-locks \
  --key '{"LockID":{"S":"LOCK_ID"}}'
```

### 2. EKS Issues

#### "Unable to connect to the server"
```bash
aws eks update-kubeconfig --region us-west-2 --name $(make get-cluster-name)
aws sts get-caller-identity
aws eks describe-cluster --name $(make get-cluster-name) --region us-west-2
```

#### "nodes not ready"
```bash
kubectl get nodes -o wide

aws eks describe-nodegroup \
  --cluster-name $(make get-cluster-name) \
  --nodegroup-name microservice-project-worker-nodes \
  --region us-west-2

kubectl describe nodes
```

### 3. ECR Issues

#### "no basic auth credentials"
```bash
make login-ecr
aws sts get-caller-identity
aws configure get region
```

#### "repository does not exist"
```bash
aws ecr describe-repositories --region us-west-2
terraform apply -target=module.ecr
```

### 4. Helm Issues

#### "timed out waiting for the condition"
```bash
kubectl get pods -l app.kubernetes.io/name=django-app
kubectl describe pods -l app.kubernetes.io/name=django-app
kubectl logs -l app.kubernetes.io/name=django-app
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### "ImagePullBackOff"
```bash
aws ecr list-images --repository-name microservice-project-ecr --region us-west-2
aws ecr describe-repository --repository-name microservice-project-ecr --region us-west-2
kubectl get secrets
```

### 5. LoadBalancer Issues

#### "Service External IP pending"
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
aws ec2 describe-security-groups --group-names "*eks*"
aws ec2 describe-vpcs
aws ec2 describe-subnets
```

### 6. HPA Issues

#### "unable to get metrics"
```bash
kubectl get pods -n kube-system | grep metrics-server

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl describe hpa django-app
```

### 7. Networking Issues

#### "Connection timeout"
```bash
aws ec2 describe-security-groups --filters "Name=group-name,Values=*eks*"
aws ec2 describe-network-acls
kubectl get services
kubectl describe service django-app
```

### 8. DNS Issues

#### "Name resolution failed"
```bash
kubectl get pods -n kube-system | grep coredns
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default
```

## Diagnostic Commands

### General Information
```bash
kubectl cluster-info
kubectl top nodes
kubectl top pods
kubectl get all
```

### Logs and Events
```bash
kubectl logs -n kube-system -l app=aws-load-balancer-controller
kubectl get events --all-namespaces --sort-by=.metadata.creationTimestamp
kubectl describe deployment django-app
kubectl describe service django-app
kubectl describe hpa django-app
```

### AWS Resources
```bash
aws eks describe-cluster --name $(make get-cluster-name) --region us-west-2
aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/$(make get-cluster-name),Values=owned"
aws elbv2 describe-load-balancers
```

## Cleanup on Issues

```bash
helm uninstall django-app
kubectl delete pods --field-selector=status.phase=Failed
kubectl rollout restart deployment django-app

make clean-helm
make destroy
make full-deploy
```