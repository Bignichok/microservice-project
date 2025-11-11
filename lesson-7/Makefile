# Makefile for EKS + ECR + Helm deployment automation

.PHONY: help init plan apply destroy configure-kubectl build-image push-image deploy-helm check clean

# Variables
AWS_REGION ?= us-west-2
CLUSTER_NAME ?= lesson-7-eks-cluster
ECR_REPO_NAME ?= lesson-7-ecr

# Colors for output
YELLOW := \033[1;33m
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m

help: ## Show this help
	@echo "$(GREEN)Available commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check-tools: ## Check required tools
	@echo "$(GREEN)Checking tools...$(NC)"
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)terraform not found$(NC)"; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "$(RED)aws cli not found$(NC)"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "$(RED)kubectl not found$(NC)"; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "$(RED)helm not found$(NC)"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)docker not found$(NC)"; exit 1; }
	@echo "$(GREEN)All tools installed ✓$(NC)"

check-aws: ## Check AWS access
	@echo "$(GREEN)Checking AWS access...$(NC)"
	@aws sts get-caller-identity > /dev/null || { echo "$(RED)AWS not configured$(NC)"; exit 1; }
	@echo "$(GREEN)AWS access configured ✓$(NC)"

init: check-tools check-aws ## Initialize Terraform
	@echo "$(GREEN)Initializing Terraform...$(NC)"
	terraform init

plan: init ## Show Terraform plan
	@echo "$(GREEN)Creating Terraform plan...$(NC)"
	terraform plan

apply: init ## Apply Terraform changes
	@echo "$(GREEN)Applying Terraform changes...$(NC)"
	terraform apply

destroy: ## Destroy infrastructure
	@echo "$(RED)WARNING: This will destroy all infrastructure!$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	terraform destroy

get-ecr-url: ## Get ECR repository URL
	@terraform output -raw ecr_info | jq -r '.repository_url'

get-cluster-name: ## Get EKS cluster name
	@terraform output -raw eks_info | jq -r '.cluster_name'

configure-kubectl: ## Configure kubectl for EKS
	@echo "$(GREEN)Configuring kubectl...$(NC)"
	aws eks update-kubeconfig --region $(AWS_REGION) --name $$(make get-cluster-name)
	@echo "$(GREEN)kubectl configured ✓$(NC)"
	kubectl get nodes

login-ecr: ## Login to ECR
	@echo "$(GREEN)Logging into ECR...$(NC)"
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $$(make get-ecr-url)

build-image: ## Build Docker image
	@echo "$(GREEN)Building Docker image...$(NC)"
	@if [ ! -f "Dockerfile" ]; then \
		echo "$(RED)Dockerfile not found!$(NC)"; \
		echo "$(YELLOW)Create Dockerfile for your Django application$(NC)"; \
		exit 1; \
	fi
	docker build -t django-app .

tag-image: build-image ## Tag image for ECR
	@echo "$(GREEN)Tagging image for ECR...$(NC)"
	docker tag django-app:latest $$(make get-ecr-url):latest

push-image: login-ecr tag-image ## Push image to ECR
	@echo "$(GREEN)Pushing image to ECR...$(NC)"
	docker push $$(make get-ecr-url):latest

deploy-helm: configure-kubectl ## Deploy Helm chart
	@echo "$(GREEN)Deploying Helm chart...$(NC)"
	helm upgrade --install django-app ./lesson-7/charts/django-app \
		--set image.repository=$$(make get-ecr-url) \
		--set image.tag=latest \
		--wait

check-deployment: ## Check deployment status
	@echo "$(GREEN)Checking deployment...$(NC)"
	@echo "$(YELLOW)Pods:$(NC)"
	kubectl get pods -l app.kubernetes.io/name=django-app
	@echo "$(YELLOW)Services:$(NC)"
	kubectl get services -l app.kubernetes.io/name=django-app
	@echo "$(YELLOW)HPA:$(NC)"
	kubectl get hpa -l app.kubernetes.io/name=django-app

get-service-url: ## Get service URL
	@echo "$(GREEN)Getting service URL...$(NC)"
	@kubectl get service django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || echo "$(YELLOW)LoadBalancer not ready yet$(NC)"

logs: ## Show application logs
	kubectl logs -f deployment/django-app

clean-helm: ## Remove Helm release
	@echo "$(RED)Removing Helm release...$(NC)"
	helm uninstall django-app || true

clean-images: ## Clean local Docker images
	@echo "$(RED)Cleaning Docker images...$(NC)"
	docker rmi django-app:latest || true
	docker rmi $$(make get-ecr-url):latest || true

clean: clean-helm clean-images ## Full cleanup

# Combined commands
full-deploy: apply push-image deploy-helm check-deployment ## Full deployment
	@echo "$(GREEN)Full deployment completed!$(NC)"

# Development commands
dev-logs: ## Show logs of all components
	kubectl logs -f deployment/django-app &
	kubectl get events --watch &

dev-port-forward: ## Port forward for local access
	@echo "$(GREEN)Port forwarding 8080 -> 80$(NC)"
	kubectl port-forward service/django-app 8080:80

# Monitoring
watch-hpa: ## Watch HPA
	kubectl get hpa django-app --watch

watch-pods: ## Watch pods
	kubectl get pods -l app.kubernetes.io/name=django-app --watch

# Debugging
debug-pod: ## Create debug pod
	kubectl run debug --image=busybox --rm -it --restart=Never -- /bin/sh

describe-deployment: ## Detailed deployment info
	kubectl describe deployment django-app

describe-service: ## Detailed service info
	kubectl describe service django-app

describe-hpa: ## Detailed HPA info
	kubectl describe hpa django-app

# Testing
load-test: ## Run load test
	@echo "$(GREEN)Running load test...$(NC)"
	@echo "$(YELLOW)Open new terminal and run 'make watch-hpa' to monitor$(NC)"
	kubectl run load-generator --image=busybox --rm -it --restart=Never -- /bin/sh -c \
		"while true; do wget -q -O- http://django-app/; done"