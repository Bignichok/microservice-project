pipeline {
    agent {
        kubernetes {
            label 'kaniko-build'
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    imagePullPolicy: Always
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
      readOnly: true
  - name: git
    image: alpine/git:latest
    command:
    - cat
    tty: true
  - name: yq
    image: mikefarah/yq:latest
    command:
    - cat
    tty: true
  volumes:
  - name: docker-config
    secret:
      secretName: docker-config
"""
        }
    }
    
    environment {
        ECR_REPOSITORY_URL = "${env.ECR_REPOSITORY_URL}"
        AWS_DEFAULT_REGION = "${env.AWS_REGION}"
        IMAGE_TAG = "${BUILD_NUMBER}"
        CHART_REPO_URL = "https://github.com/Bignichok/microservice-project.git"
        CHART_REPO_BRANCH = "main"
        CHART_PATH = "charts/django-app"
        APP_REPO_URL = "https://github.com/Bignichok/django-microservice.git"
        APP_REPO_BRANCH = "main"
    }
    
    stages {
        stage('Checkout Application Code') {
            steps {
                container('git') {
                    script {
                        // Clone the Django application repository
                        sh """
                            git clone -b ${APP_REPO_BRANCH} ${APP_REPO_URL} app-repo
                            cd app-repo
                            git log -1 --pretty=format:"%h - %an, %ar : %s"
                        """
                    }
                }
            }
        }
        
        stage('Prepare Build Context') {
            steps {
                container('git') {
                    script {
                        // Prepare the build context
                        sh """
                            ls -la app-repo/
                            # Check if Dockerfile exists
                            if [ -f app-repo/Dockerfile ]; then
                                echo "Dockerfile found in app repository"
                            else
                                echo "Creating basic Django Dockerfile"
                                cat > app-repo/Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    build-essential \\
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Run the application
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
EOF
                            fi
                            
                            # Create requirements.txt if it doesn't exist
                            if [ ! -f app-repo/requirements.txt ]; then
                                echo "Creating basic requirements.txt"
                                cat > app-repo/requirements.txt << 'EOF'
Django==4.2.7
gunicorn==21.2.0
psycopg2-binary==2.9.7
EOF
                            fi
                        """
                    }
                }
            }
        }
        
        stage('Build and Push Docker Image') {
            steps {
                container('kaniko') {
                    script {
                        // Get ECR login command
                        sh """
                            echo "Building Docker image with tag: ${IMAGE_TAG}"
                            
                            # Build and push using Kaniko
                            /kaniko/executor \\
                                --context=./app-repo \\
                                --dockerfile=./app-repo/Dockerfile \\
                                --destination=${ECR_REPOSITORY_URL}:${IMAGE_TAG} \\
                                --destination=${ECR_REPOSITORY_URL}:latest \\
                                --cache=true \\
                                --cache-ttl=24h
                        """
                    }
                }
            }
        }
        
        stage('Checkout Chart Repository') {
            steps {
                container('git') {
                    script {
                        // Clone the chart repository
                        sh """
                            git clone -b ${CHART_REPO_BRANCH} ${CHART_REPO_URL} chart-repo
                        """
                    }
                }
            }
        }
        
        stage('Update Helm Chart') {
            steps {
                container('yq') {
                    script {
                        // Update the image tag in values.yaml
                        sh """
                            cd chart-repo
                            
                            echo "Current values.yaml content:"
                            cat ${CHART_PATH}/values.yaml
                            
                            echo "Updating image repository and tag..."
                            yq eval '.image.repository = "${ECR_REPOSITORY_URL}"' -i ${CHART_PATH}/values.yaml
                            yq eval '.image.tag = "${IMAGE_TAG}"' -i ${CHART_PATH}/values.yaml
                            
                            echo "Updated values.yaml content:"
                            cat ${CHART_PATH}/values.yaml
                        """
                    }
                }
            }
        }
        
        stage('Push Updated Chart') {
            steps {
                container('git') {
                    withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                        script {
                            sh """
                                cd chart-repo
                                
                                # Configure git
                                git config user.name "Jenkins CI"
                                git config user.email "jenkins@microservice-project.local"
                                
                                # Stage changes
                                git add ${CHART_PATH}/values.yaml
                                
                                # Check if there are changes to commit
                                if git diff --cached --quiet; then
                                    echo "No changes to commit"
                                else
                                    # Commit and push changes
                                    git commit -m "CI: Update image tag to ${IMAGE_TAG} for build ${BUILD_NUMBER}"
                                    
                                    # Push using credentials
                                    git remote set-url origin https://\${GIT_USERNAME}:\${GIT_PASSWORD}@github.com/Bignichok/microservice-project.git
                                    git push origin ${CHART_REPO_BRANCH}
                                    
                                    echo "Successfully pushed updated chart with image tag: ${IMAGE_TAG}"
                                fi
                            """
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "Pipeline completed for build ${BUILD_NUMBER}"
            echo "Image pushed: ${ECR_REPOSITORY_URL}:${IMAGE_TAG}"
        }
        success {
            echo "✅ Pipeline successful!"
            echo "🐳 Docker image built and pushed: ${ECR_REPOSITORY_URL}:${IMAGE_TAG}"
            echo "📊 Helm chart updated with new image tag"
            echo "🚀 ArgoCD will automatically sync the changes"
        }
        failure {
            echo "❌ Pipeline failed!"
            echo "Check logs for details"
        }
        cleanup {
            sh 'rm -rf app-repo chart-repo || true'
        }
    }
}