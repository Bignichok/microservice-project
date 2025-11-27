# Monitoring Configuration Guide

## Grafana Data Source Setup

### Automatic Prometheus Connection
```bash
# Prometheus URL for Grafana data source
http://prometheus-server.monitoring.svc:80
```

### Manual Configuration Steps
1. Open Grafana: http://localhost:3000
2. Login: admin / admin123
3. Go to Configuration → Data Sources
4. Click "Add data source"
5. Select "Prometheus"
6. Set URL: `http://prometheus-server.monitoring.svc:80`
7. Click "Save & Test"

## Recommended Dashboards

### Essential Kubernetes Dashboards
```bash
# Import these dashboard IDs in Grafana:
# + → Import → Enter ID

# Kubernetes Cluster Overview
Dashboard ID: 7249
Description: Complete cluster monitoring with nodes, pods, and resources

# Node Exporter Full
Dashboard ID: 1860  
Description: Detailed node metrics including CPU, memory, disk, network

# Kubernetes Pod Monitoring
Dashboard ID: 6417
Description: Pod-level metrics and resource usage

# Kubernetes Deployments
Dashboard ID: 8588
Description: Deployment and StatefulSet monitoring
```

### Application-Specific Dashboards
```bash
# Django Application Monitoring
Dashboard ID: 9528
Description: Django application performance metrics

# PostgreSQL Database
Dashboard ID: 9628
Description: PostgreSQL database monitoring

# NGINX Ingress Controller
Dashboard ID: 9614
Description: Ingress controller metrics
```

## Quick Setup Commands

### Deploy Monitoring Stack
```bash
# Make script executable
chmod +x deploy-monitoring.sh

# Deploy with defaults
./deploy-monitoring.sh

# Deploy with custom settings
./deploy-monitoring.sh --namespace=monitoring --grafana-password=mypassword

# Check deployment status
./deploy-monitoring.sh --check

# Show access information
./deploy-monitoring.sh --access-info
```

### Access Services
```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus-server 9090:80 &
# Access: http://localhost:9090

# Grafana  
kubectl port-forward -n monitoring svc/grafana 3000:80 &
# Access: http://localhost:3000 (admin/admin123)

# Stop port-forwarding
pkill -f "kubectl port-forward"
```

### Common Prometheus Queries

#### Cluster Resources
```promql
# CPU usage by node
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage by node
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Pod CPU usage
rate(container_cpu_usage_seconds_total{pod!=""}[5m])

# Pod memory usage
container_memory_working_set_bytes{pod!=""}
```

#### Application Metrics
```promql
# HTTP request rate
rate(http_requests_total[5m])

# HTTP request duration
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Error rate
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
```

## Troubleshooting

### Common Issues
```bash
# Check pod status
kubectl get pods -n monitoring

# Check logs
kubectl logs -n monitoring deployment/prometheus-server
kubectl logs -n monitoring deployment/grafana

# Restart services
kubectl rollout restart deployment/prometheus-server -n monitoring
kubectl rollout restart deployment/grafana -n monitoring

# Check storage
kubectl get pv
kubectl get pvc -n monitoring
```

### Storage Issues
```bash
# Increase Prometheus storage
helm upgrade prometheus prometheus-community/prometheus \
    --namespace monitoring \
    --set server.persistentVolume.size=20Gi

# Increase Grafana storage  
helm upgrade grafana grafana/grafana \
    --namespace monitoring \
    --set persistence.size=20Gi
```

## Security Configuration

### Enable HTTPS (Optional)
```bash
# Generate TLS certificate
kubectl create secret tls monitoring-tls \
    --cert=monitoring.crt \
    --key=monitoring.key \
    -n monitoring

# Update Grafana with HTTPS
helm upgrade grafana grafana/grafana \
    --namespace monitoring \
    --set ingress.enabled=true \
    --set ingress.tls[0].secretName=monitoring-tls
```

### RBAC Configuration
```yaml
# monitoring-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "pods", "services"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
```

Apply with: `kubectl apply -f monitoring-rbac.yaml`