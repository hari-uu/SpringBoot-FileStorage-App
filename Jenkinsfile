pipeline {
    agent any
    
    // Trigger on GitHub push events
    triggers {
        githubPush()
    }
    
    environment {
        // AWS Configuration - REQUIRED: Set AWS_ACCOUNT_ID in Jenkins credentials
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_REPOSITORY = 'file-storage-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        
        // ECS Configuration
        ECS_CLUSTER = 'file-storage-cluster'
        ECS_SERVICE = 'file-storage-service'
        ECS_TASK_DEFINITION = 'file-storage-task'
        
        // Docker Configuration (Standard path for macOS Docker Desktop)
        DOCKER_HOST = 'unix:///var/run/docker.sock'
        
        // Branch to deploy (only main/master branch will deploy to ECS)
        DEPLOY_BRANCH = 'main'
    }
    
    // Tools configuration - Configure these in Jenkins Global Tool Configuration
    // Or comment out to use system Maven and JDK
    // tools {
    //     maven 'Maven 3.9.11'
    //     jdk 'JDK 17'
    // }
    
    stages {
        stage('Validate Prerequisites') {
            steps {
                script {
                    echo 'Checking required tools...'
                    sh '''
                        echo "Checking AWS CLI..."
                        aws --version || (echo "ERROR: AWS CLI not installed" && exit 1)
                        
                        echo "Checking jq..."
                        jq --version || (echo "ERROR: jq not installed" && exit 1)
                        
                        echo "Checking Docker..."
                        docker --version || (echo "ERROR: Docker not installed" && exit 1)
                        
                        echo "Branch: ${GIT_BRANCH}"
                        echo "Build Number: ${BUILD_NUMBER}"
                    '''
                }
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build JAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        
        // Temporarily skip tests - uncomment when tests are ready
        // stage('Run Tests') {
        //     steps {
        //         sh 'mvn test'
        //     }
        //     post {
        //         always {
        //             junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
        //         }
        //     }
        // }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    
                    // Pull base images to prevent timeouts/errors
                    sh 'docker pull maven:3.9.11-eclipse-temurin-17'
                    sh 'docker pull eclipse-temurin:17-jre'
                    
                    // Build for AMD64 architecture (Required for AWS Fargate)
                    sh "docker build --platform linux/amd64 -t ${ECR_REPOSITORY}:${IMAGE_TAG} ."
                    sh "docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REPOSITORY}:latest"
                    
                    echo 'Docker image built successfully for linux/amd64!'
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    // Using standard usernamePassword binding (works without AWS plugin)
                    // AWS Access Key -> username variable
                    // AWS Secret Key -> password variable
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh """
                            # Login to ECR
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                            
                            # Push images
                            docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                            docker tag ${ECR_REPOSITORY}:latest ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                            
                            docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                            docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                        """
                    }
                }
            }
        }
        
        stage('Deploy to ECS') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                script {
                    echo "Deploying to ECS from branch: ${env.GIT_BRANCH}"
                    
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh """
                            # Update ECS task definition with new image
                            TASK_DEFINITION=\$(aws ecs describe-task-definition --task-definition ${ECS_TASK_DEFINITION} --region ${AWS_REGION})
                            NEW_TASK_DEF=\$(echo \$TASK_DEFINITION | jq --arg IMAGE "${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}" '.taskDefinition | .containerDefinitions[0].image = \$IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities) | del(.registeredAt) | del(.registeredBy)')
                            
                            # Register new task definition
                            NEW_TASK_INFO=\$(aws ecs register-task-definition --region ${AWS_REGION} --cli-input-json "\$NEW_TASK_DEF")
                            NEW_REVISION=\$(echo \$NEW_TASK_INFO | jq '.taskDefinition.revision')
                            
                            # Update ECS service with new task definition
                            aws ecs update-service --cluster ${ECS_CLUSTER} --service ${ECS_SERVICE} --task-definition ${ECS_TASK_DEFINITION}:\$NEW_REVISION --region ${AWS_REGION}
                            
                            # Wait for service to stabilize
                            echo "Waiting for ECS service to stabilize..."
                            aws ecs wait services-stable --cluster ${ECS_CLUSTER} --services ${ECS_SERVICE} --region ${AWS_REGION}
                            
                            echo "Deployment completed successfully!"
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline succeeded! Application deployed successfully.'
        }
        failure {
            echo 'Pipeline failed! Check logs for details.'
        }
        always {
            script {
                echo 'Cleaning up Docker images...'
                sh """
                    docker image prune -f || true
                """
            }
        }
    }
}
