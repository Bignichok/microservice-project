#!/bin/bash

# Script to setup Docker registry credentials for Jenkins
# This script should be run after Jenkins is deployed

set -e

echo "Setting up Docker registry credentials for Jenkins..."

# Variables
JENKINS_NAMESPACE="jenkins"
AWS_REGION="${AWS_REGION:-us-west-2}"
ECR_REPOSITORY_URL="${ECR_REPOSITORY_URL}"

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl is not installed or not in PATH"
        exit 1
    fi
}

# Function to check if aws CLI is available
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed or not in PATH"
        exit 1
    fi
}

# Function to create Docker config secret
create_docker_secret() {
    echo "Creating Docker registry secret..."
    
    # Get ECR login token
    ECR_TOKEN=$(aws ecr get-login-password --region $AWS_REGION)
    ECR_REGISTRY=$(echo $ECR_REPOSITORY_URL | cut -d'/' -f1)
    
    # Create Docker config
    DOCKER_CONFIG=$(echo -n "${ECR_TOKEN}" | base64 -w 0)
    
    # Create Kubernetes secret
    kubectl create secret generic docker-config \
        --namespace=$JENKINS_NAMESPACE \
        --from-literal=.dockerconfigjson="{\"auths\":{\"${ECR_REGISTRY}\":{\"username\":\"AWS\",\"password\":\"${ECR_TOKEN}\",\"auth\":\"$(echo -n "AWS:${ECR_TOKEN}" | base64 -w 0)\"}}}" \
        --type=kubernetes.io/dockerconfigjson \
        --dry-run=client -o yaml | kubectl apply -f -
    
    echo "Docker registry secret created successfully!"
}

# Function to create GitHub credentials (if needed)
create_github_secret() {
    echo "Note: Please create GitHub credentials manually in Jenkins UI:"
    echo "1. Go to Jenkins > Manage Jenkins > Credentials"
    echo "2. Add Username/Password credential with ID 'github-credentials'"
    echo "3. Use your GitHub username and Personal Access Token"
}

# Main execution
main() {
    echo "🚀 Starting Jenkins setup..."
    
    check_kubectl
    check_aws_cli
    
    # Wait for Jenkins namespace to be ready
    echo "Waiting for Jenkins namespace to be ready..."
    kubectl wait --for=condition=Ready namespace/$JENKINS_NAMESPACE --timeout=300s
    
    # Create Docker registry secret
    create_docker_secret
    
    # Show next steps
    echo ""
    echo "✅ Setup completed!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Access Jenkins UI and configure GitHub credentials"
    echo "2. Create a new Pipeline job"
    echo "3. Point it to your repository with the Jenkinsfile"
    echo ""
    
    # Get Jenkins URL
    JENKINS_URL=$(kubectl get svc jenkins -n $JENKINS_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [ -n "$JENKINS_URL" ]; then
        echo "🔗 Jenkins URL: http://$JENKINS_URL"
    else
        echo "ℹ️  Jenkins URL will be available once LoadBalancer is ready"
        echo "   Run: kubectl get svc jenkins -n $JENKINS_NAMESPACE"
    fi
    
    echo ""
    echo "🔑 Default Jenkins credentials:"
    echo "   Username: admin"
    echo "   Password: admin123!"
    
    create_github_secret
}

main "$@"