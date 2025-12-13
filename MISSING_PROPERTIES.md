# 🚀 Quick Reference: Missing Properties & Configuration Checklist

## ❌ CRITICAL MISSING ITEMS (Must Fix Before Deployment)

### 1. **Jenkins Credentials** (REQUIRED)
```
Go to: Jenkins → Manage Jenkins → Credentials → Add Credentials

Add these TWO credentials:

1. AWS Account ID:
   - Kind: Secret text
   - Secret: YOUR_AWS_ACCOUNT_ID (e.g., 123456789012)
   - ID: aws-account-id
   
2. AWS Credentials:
   - Kind: AWS Credentials
   - ID: aws-credentials
   - Access Key ID: YOUR_AWS_ACCESS_KEY
   - Secret Access Key: YOUR_AWS_SECRET_KEY
```

### 2. **GitHub Webhook** (REQUIRED for auto-trigger)
```
GitHub Repository → Settings → Webhooks → Add webhook

Payload URL: http://YOUR_JENKINS_URL/github-webhook/
Content type: application/json
Events: Just the push event
Active: ✓ Checked
```

### 3. **Jenkins Tools** (REQUIRED)
```
Jenkins → Manage Jenkins → Global Tool Configuration

Maven:
  Name: Maven 3.9.11 (EXACT name)
  Install automatically: Yes
  Version: 3.9.11

JDK:
  Name: JDK 17 (EXACT name)
  Install automatically: Yes
  Version: jdk-17
```

### 4. **Jenkins Agent Prerequisites** (REQUIRED)
```bash
# SSH into Jenkins agent and run:

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install jq
sudo apt-get update && sudo apt-get install -y jq

# Verify
aws --version
jq --version
docker --version
```

### 5. **AWS Resources** (REQUIRED)
```bash
# Create ECR Repository
aws ecr create-repository --repository-name file-storage-app --region us-east-1

# Create ECS Cluster
aws ecs create-cluster --cluster-name file-storage-cluster --region us-east-1

# Update ecs-task-definition.json with your AWS Account ID, then:
aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json --region us-east-1

# Create CloudWatch Log Group
aws logs create-log-group --log-group-name /ecs/file-storage-app --region us-east-1

# Create ECS Service (update subnet and security group IDs)
aws ecs create-service \
  --cluster file-storage-cluster \
  --service-name file-storage-service \
  --task-definition file-storage-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxx],securityGroups=[sg-xxxxx],assignPublicIp=ENABLED}" \
  --region us-east-1
```

---

## 📝 Files Updated

### ✅ Jenkinsfile
**Changes Made:**
- ✓ Added GitHub webhook trigger
- ✓ Added AWS_ACCOUNT_ID credential reference
- ✓ Added prerequisite validation stage (AWS CLI, jq, Docker)
- ✓ Added AWS credentials binding for ECR/ECS
- ✓ Added branch-based deployment (only main/master deploys to ECS)
- ✓ Added better error handling and logging

### ✅ pom.xml
**Changes Made:**
- ✓ Added Spring Boot Actuator dependency for health checks

### ✅ application.properties
**Changes Made:**
- ✓ Added actuator health endpoint configuration
- ✓ Enabled database health check

### ✅ application-aws.properties
**Changes Made:**
- ✓ Added production actuator configuration
- ✓ Configured health endpoint for ECS health checks

### ✅ New Files Created
- ✓ `ecs-task-definition.json` - ECS task definition template
- ✓ `CICD_SETUP_GUIDE.md` - Comprehensive setup guide
- ✓ `MISSING_PROPERTIES.md` - This checklist

---

## 🔍 What Was Missing (Summary)

| Item | Status | Impact |
|------|--------|--------|
| AWS_ACCOUNT_ID environment variable | ❌ Missing | **CRITICAL** - Pipeline will fail |
| GitHub webhook trigger | ❌ Missing | **CRITICAL** - No auto-trigger |
| Jenkins credentials (aws-account-id) | ❌ Missing | **CRITICAL** - Cannot access ECR |
| Jenkins credentials (aws-credentials) | ❌ Missing | **CRITICAL** - Cannot push to ECR/ECS |
| AWS CLI on Jenkins agent | ❌ Missing | **CRITICAL** - Deployment will fail |
| jq on Jenkins agent | ❌ Missing | **CRITICAL** - Deployment will fail |
| Branch filtering | ❌ Missing | **HIGH** - All branches deploy |
| Health check endpoint | ❌ Missing | **HIGH** - ECS can't monitor health |
| ECS task definition file | ❌ Missing | **HIGH** - No deployment template |
| Prerequisite validation | ❌ Missing | **MEDIUM** - Unclear error messages |

---

## 🎯 Quick Test

After setting up everything, test with:

```bash
# 1. Test GitHub webhook
git checkout -b test/pipeline
echo "# Test" >> README.md
git add .
git commit -m "test: trigger pipeline"
git push origin test/pipeline

# 2. Check GitHub webhook delivery
# Go to: GitHub → Settings → Webhooks → Recent Deliveries
# Should show 200 OK response

# 3. Check Jenkins
# Jenkins should automatically start building

# 4. Verify ECR image
aws ecr describe-images --repository-name file-storage-app --region us-east-1

# 5. For main/master branch, verify ECS deployment
aws ecs describe-services \
  --cluster file-storage-cluster \
  --services file-storage-service \
  --region us-east-1
```

---

## 🔐 Security Notes

**NEVER commit these to Git:**
- AWS Access Keys
- AWS Secret Keys
- Database passwords
- Any credentials

**Use:**
- Jenkins credentials store
- AWS Secrets Manager
- Environment variables in ECS task definition

---

## 📞 Troubleshooting Quick Fixes

### Pipeline doesn't trigger on push
```
1. Check GitHub webhook delivery (Settings → Webhooks)
2. Verify Jenkins URL is publicly accessible
3. Check Jenkins has GitHub plugin installed
4. Verify webhook URL ends with /github-webhook/
```

### AWS credentials error
```
1. Verify credentials exist in Jenkins (Manage Jenkins → Credentials)
2. Check credential IDs match Jenkinsfile exactly
3. Test AWS CLI manually on Jenkins agent
```

### Docker push to ECR fails
```
1. Verify ECR repository exists
2. Check AWS credentials have ECR permissions
3. Ensure Docker is running on Jenkins agent
```

### ECS deployment fails
```
1. Verify ECS cluster and service exist
2. Check task definition is registered
3. Verify security groups allow traffic
4. Check CloudWatch logs: /ecs/file-storage-app
```

---

## ✅ Final Checklist Before First Deployment

- [ ] Jenkins credentials configured (aws-account-id, aws-credentials)
- [ ] Jenkins tools configured (Maven 3.9.11, JDK 17)
- [ ] AWS CLI installed on Jenkins agent
- [ ] jq installed on Jenkins agent
- [ ] Docker available on Jenkins agent
- [ ] GitHub webhook configured and active
- [ ] ECR repository created
- [ ] ECS cluster created
- [ ] ECS task definition registered
- [ ] ECS service created
- [ ] CloudWatch log group created
- [ ] IAM roles created (ecsTaskExecutionRole, ecsTaskRole)
- [ ] Security groups configured
- [ ] VPC and subnets configured
- [ ] ecs-task-definition.json updated with your AWS Account ID
- [ ] Database endpoint updated in task definition (if using RDS)
- [ ] S3 bucket created (if using S3)

---

## 🎉 You're Ready!

Once all items above are checked, push to main/master branch and watch your code automatically:
1. Trigger Jenkins via GitHub webhook
2. Build and test
3. Create Docker image
4. Push to ECR
5. Deploy to ECS
6. Service goes live! 🚀
