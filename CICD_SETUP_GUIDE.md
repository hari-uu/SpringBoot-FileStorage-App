# CI/CD Setup Guide: GitHub → Jenkins → ECR → ECS

## 📋 Prerequisites Checklist

### ✅ AWS Resources Required
- [ ] AWS Account ID
- [ ] ECR Repository: `file-storage-app`
- [ ] ECS Cluster: `file-storage-cluster`
- [ ] ECS Service: `file-storage-service`
- [ ] RDS MySQL Database (optional, for production)
- [ ] S3 Bucket: `file-storage-bucket` (optional)
- [ ] IAM Roles: `ecsTaskExecutionRole` and `ecsTaskRole`
- [ ] CloudWatch Log Group: `/ecs/file-storage-app`

### ✅ Jenkins Requirements
- [ ] Jenkins server accessible from GitHub (public URL or ngrok)
- [ ] Jenkins plugins installed:
  - GitHub Plugin
  - Pipeline Plugin
  - Docker Pipeline Plugin
  - AWS Steps Plugin
  - CloudBees AWS Credentials Plugin
- [ ] Jenkins tools configured:
  - Maven 3.9.11
  - JDK 17
  - Docker
- [ ] Jenkins agent with AWS CLI and jq installed

---

## 🔧 Step-by-Step Setup

### **1. Configure AWS Resources**

#### Create ECR Repository
```bash
aws ecr create-repository \
    --repository-name file-storage-app \
    --region us-east-1
```

#### Create ECS Cluster
```bash
aws ecs create-cluster \
    --cluster-name file-storage-cluster \
    --region us-east-1
```

#### Register ECS Task Definition
```bash
# First, update ecs-task-definition.json with your AWS Account ID
# Then register it:
aws ecs register-task-definition \
    --cli-input-json file://ecs-task-definition.json \
    --region us-east-1
```

#### Create ECS Service
```bash
aws ecs create-service \
    --cluster file-storage-cluster \
    --service-name file-storage-service \
    --task-definition file-storage-task \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxx],securityGroups=[sg-xxxxx],assignPublicIp=ENABLED}" \
    --region us-east-1
```

#### Create CloudWatch Log Group
```bash
aws logs create-log-group \
    --log-group-name /ecs/file-storage-app \
    --region us-east-1
```

---

### **2. Configure Jenkins Credentials**

Go to Jenkins → Manage Jenkins → Credentials → Add Credentials

#### Add AWS Account ID
- **Kind:** Secret text
- **Secret:** Your AWS Account ID (e.g., 123456789012)
- **ID:** `aws-account-id`
- **Description:** AWS Account ID

#### Add AWS Credentials
- **Kind:** AWS Credentials
- **ID:** `aws-credentials`
- **Access Key ID:** Your AWS Access Key
- **Secret Access Key:** Your AWS Secret Key
- **Description:** AWS Credentials for ECR and ECS

---

### **3. Configure Jenkins Tools**

Go to Jenkins → Manage Jenkins → Global Tool Configuration

#### Maven Configuration
- **Name:** `Maven 3.9.11` (must match Jenkinsfile)
- **Install automatically:** Yes
- **Version:** 3.9.11

#### JDK Configuration
- **Name:** `JDK 17` (must match Jenkinsfile)
- **Install automatically:** Yes
- **Version:** jdk-17

---

### **4. Install Required Tools on Jenkins Agent**

SSH into your Jenkins agent and install:

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install jq
sudo apt-get update
sudo apt-get install -y jq

# Verify installations
aws --version
jq --version
docker --version
```

---

### **5. Configure GitHub Webhook**

#### In Jenkins:
1. Go to your Jenkins job → Configure
2. Under "Build Triggers", check "GitHub hook trigger for GITScm polling"
3. Save

#### In GitHub:
1. Go to your repository → Settings → Webhooks → Add webhook
2. **Payload URL:** `http://your-jenkins-url/github-webhook/`
3. **Content type:** `application/json`
4. **Which events:** Select "Just the push event"
5. **Active:** Check this box
6. Click "Add webhook"

**Note:** Your Jenkins server must be publicly accessible. If running locally, use ngrok:
```bash
ngrok http 8080
# Use the ngrok URL in the webhook configuration
```

---

### **6. Create Jenkins Pipeline Job**

1. Jenkins → New Item → Pipeline
2. **Name:** `file-storage-app-pipeline`
3. **Pipeline Definition:** Pipeline script from SCM
4. **SCM:** Git
5. **Repository URL:** Your GitHub repository URL
6. **Credentials:** Add your GitHub credentials if private repo
7. **Branch Specifier:** `*/main` (or `*/master`)
8. **Script Path:** `Jenkinsfile`
9. Save

---

### **7. Update Application Properties**

Ensure your `application-aws.properties` has environment variable placeholders:

```properties
# These will be injected by ECS task definition
spring.datasource.url=jdbc:mysql://${DB_HOST}:3306/${DB_NAME}
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}
aws.s3.bucket-name=${S3_BUCKET_NAME}
aws.s3.region=${AWS_REGION}
```

---

### **8. Update ECS Task Definition**

Edit `ecs-task-definition.json` and replace:
- `YOUR_AWS_ACCOUNT_ID` with your actual AWS Account ID
- `your-rds-endpoint.rds.amazonaws.com` with your RDS endpoint
- Update IAM role ARNs
- Update secrets ARNs in AWS Secrets Manager

---

### **9. Create IAM Roles**

#### ECS Task Execution Role
```bash
aws iam create-role \
    --role-name ecsTaskExecutionRole \
    --assume-role-policy-document file://task-execution-assume-role.json

aws iam attach-role-policy \
    --role-name ecsTaskExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

#### ECS Task Role (for S3 access)
```bash
aws iam create-role \
    --role-name ecsTaskRole \
    --assume-role-policy-document file://task-assume-role.json

# Attach S3 policy
aws iam attach-role-policy \
    --role-name ecsTaskRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

---

## 🚀 Testing the Pipeline

### Test the Complete Flow:

1. **Make a code change:**
   ```bash
   git checkout -b feature/test-pipeline
   echo "// Test change" >> src/main/java/com/filestorage/FileStorageApplication.java
   git add .
   git commit -m "Test: Trigger Jenkins pipeline"
   git push origin feature/test-pipeline
   ```

2. **Check GitHub webhook delivery:**
   - GitHub → Settings → Webhooks → Recent Deliveries
   - Should show successful delivery (200 response)

3. **Monitor Jenkins:**
   - Jenkins should automatically trigger the build
   - Watch the console output for each stage

4. **Verify ECR:**
   ```bash
   aws ecr describe-images \
       --repository-name file-storage-app \
       --region us-east-1
   ```

5. **Verify ECS deployment (only for main/master branch):**
   ```bash
   aws ecs describe-services \
       --cluster file-storage-cluster \
       --services file-storage-service \
       --region us-east-1
   ```

---

## 🔍 Troubleshooting

### Common Issues:

#### 1. **GitHub webhook not triggering Jenkins**
- Check Jenkins is publicly accessible
- Verify webhook URL is correct
- Check webhook delivery in GitHub settings

#### 2. **AWS credentials error**
- Verify credentials are correctly configured in Jenkins
- Check IAM user has ECR and ECS permissions

#### 3. **Docker build fails**
- Ensure Docker is running on Jenkins agent
- Check Dockerfile syntax

#### 4. **ECS deployment fails**
- Verify ECS cluster and service exist
- Check task definition is registered
- Ensure security groups allow traffic
- Check CloudWatch logs for container errors

#### 5. **Missing tools error**
- Install AWS CLI and jq on Jenkins agent
- Restart Jenkins after installation

---

## 📊 Pipeline Flow

```
GitHub Push
    ↓
GitHub Webhook
    ↓
Jenkins Triggered
    ↓
Validate Prerequisites
    ↓
Checkout Code
    ↓
Build JAR (Maven)
    ↓
Run Tests
    ↓
Build Docker Image
    ↓
Push to ECR
    ↓
Deploy to ECS (main/master only)
    ↓
Service Stabilized ✅
```

---

## 🔐 Security Best Practices

1. **Never commit credentials** to Git
2. **Use AWS Secrets Manager** for sensitive data
3. **Use IAM roles** with least privilege
4. **Enable VPC** for ECS tasks
5. **Use private subnets** with NAT gateway
6. **Enable encryption** for ECR images
7. **Scan Docker images** for vulnerabilities
8. **Use HTTPS** for Jenkins webhook

---

## 📝 Next Steps

- [ ] Set up RDS database
- [ ] Configure S3 bucket
- [ ] Add health check endpoint in Spring Boot
- [ ] Set up Application Load Balancer
- [ ] Configure auto-scaling for ECS
- [ ] Add monitoring and alerting
- [ ] Set up staging environment
- [ ] Implement blue-green deployment
