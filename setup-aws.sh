#!/bin/bash

# AWS Setup Script for Jenkins CI/CD Pipeline
# This script will help you set up all required AWS resources

set -e  # Exit on error

echo "🚀 AWS Setup for Jenkins CI/CD Pipeline"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS CLI is installed${NC}"
echo ""

# Get AWS Account ID
echo "📋 Getting AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ Failed to get AWS Account ID. Please configure AWS CLI credentials.${NC}"
    echo "Run: aws configure"
    exit 1
fi

echo -e "${GREEN}✅ AWS Account ID: $AWS_ACCOUNT_ID${NC}"
echo ""

# Set region
AWS_REGION="us-east-1"
echo "📍 Using AWS Region: $AWS_REGION"
echo ""

# 1. Create ECR Repository
echo "1️⃣  Creating ECR Repository..."
if aws ecr describe-repositories --repository-names file-storage-app --region $AWS_REGION &>/dev/null; then
    echo -e "${YELLOW}⚠️  ECR repository 'file-storage-app' already exists${NC}"
else
    aws ecr create-repository \
        --repository-name file-storage-app \
        --region $AWS_REGION \
        --image-scanning-configuration scanOnPush=true
    echo -e "${GREEN}✅ ECR repository created${NC}"
fi
echo ""

# 2. Create CloudWatch Log Group
echo "2️⃣  Creating CloudWatch Log Group..."
if aws logs describe-log-groups --log-group-name-prefix /ecs/file-storage-app --region $AWS_REGION | grep -q "/ecs/file-storage-app"; then
    echo -e "${YELLOW}⚠️  Log group already exists${NC}"
else
    aws logs create-log-group \
        --log-group-name /ecs/file-storage-app \
        --region $AWS_REGION
    echo -e "${GREEN}✅ CloudWatch log group created${NC}"
fi
echo ""

# 3. Create IAM Roles
echo "3️⃣  Creating IAM Roles..."

# Create trust policy
cat > /tmp/ecs-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create Task Execution Role
if aws iam get-role --role-name ecsTaskExecutionRole &>/dev/null; then
    echo -e "${YELLOW}⚠️  ecsTaskExecutionRole already exists${NC}"
else
    aws iam create-role \
        --role-name ecsTaskExecutionRole \
        --assume-role-policy-document file:///tmp/ecs-trust-policy.json
    
    aws iam attach-role-policy \
        --role-name ecsTaskExecutionRole \
        --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
    
    echo -e "${GREEN}✅ ecsTaskExecutionRole created${NC}"
fi

# Create Task Role
if aws iam get-role --role-name ecsTaskRole &>/dev/null; then
    echo -e "${YELLOW}⚠️  ecsTaskRole already exists${NC}"
else
    aws iam create-role \
        --role-name ecsTaskRole \
        --assume-role-policy-document file:///tmp/ecs-trust-policy.json
    
    # Attach S3 policy (optional, for file storage)
    aws iam attach-role-policy \
        --role-name ecsTaskRole \
        --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
    
    echo -e "${GREEN}✅ ecsTaskRole created${NC}"
fi
echo ""

# 4. Update ecs-task-definition.json
echo "4️⃣  Updating ecs-task-definition.json..."
if [ -f "ecs-task-definition.json" ]; then
    # Create backup
    cp ecs-task-definition.json ecs-task-definition.json.backup
    
    # Replace placeholders
    sed -i.tmp "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" ecs-task-definition.json
    rm -f ecs-task-definition.json.tmp
    
    echo -e "${GREEN}✅ Task definition updated with Account ID: $AWS_ACCOUNT_ID${NC}"
else
    echo -e "${RED}❌ ecs-task-definition.json not found${NC}"
fi
echo ""

# 5. Create VPC resources (if needed)
echo "5️⃣  Checking VPC resources..."
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION)

if [ "$DEFAULT_VPC" != "None" ] && [ -n "$DEFAULT_VPC" ]; then
    echo -e "${GREEN}✅ Default VPC found: $DEFAULT_VPC${NC}"
    
    # Get subnets
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --query "Subnets[*].SubnetId" --output text --region $AWS_REGION)
    echo -e "${GREEN}✅ Subnets: $SUBNETS${NC}"
    
    # Get default security group
    SECURITY_GROUP=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$DEFAULT_VPC" "Name=group-name,Values=default" --query "SecurityGroups[0].GroupId" --output text --region $AWS_REGION)
    echo -e "${GREEN}✅ Security Group: $SECURITY_GROUP${NC}"
else
    echo -e "${YELLOW}⚠️  No default VPC found. You'll need to create VPC resources.${NC}"
fi
echo ""

# 6. Create ECS Cluster
echo "6️⃣  Creating ECS Cluster..."
if aws ecs describe-clusters --clusters file-storage-cluster --region $AWS_REGION | grep -q "file-storage-cluster"; then
    echo -e "${YELLOW}⚠️  ECS cluster already exists${NC}"
else
    aws ecs create-cluster \
        --cluster-name file-storage-cluster \
        --region $AWS_REGION
    echo -e "${GREEN}✅ ECS cluster created${NC}"
fi
echo ""

# 7. Register Task Definition
echo "7️⃣  Registering ECS Task Definition..."
if [ -f "ecs-task-definition.json" ]; then
    aws ecs register-task-definition \
        --cli-input-json file://ecs-task-definition.json \
        --region $AWS_REGION
    echo -e "${GREEN}✅ Task definition registered${NC}"
else
    echo -e "${RED}❌ ecs-task-definition.json not found${NC}"
fi
echo ""

# 8. Create ECS Service
echo "8️⃣  Creating ECS Service..."

# Get first two subnets
SUBNET_ARRAY=($SUBNETS)
SUBNET1=${SUBNET_ARRAY[0]}
SUBNET2=${SUBNET_ARRAY[1]:-$SUBNET1}

if aws ecs describe-services --cluster file-storage-cluster --services file-storage-service --region $AWS_REGION | grep -q "file-storage-service"; then
    echo -e "${YELLOW}⚠️  ECS service already exists${NC}"
else
    if [ -n "$SUBNET1" ] && [ -n "$SECURITY_GROUP" ]; then
        aws ecs create-service \
            --cluster file-storage-cluster \
            --service-name file-storage-service \
            --task-definition file-storage-task \
            --desired-count 1 \
            --launch-type FARGATE \
            --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1,$SUBNET2],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}" \
            --region $AWS_REGION
        echo -e "${GREEN}✅ ECS service created${NC}"
    else
        echo -e "${YELLOW}⚠️  Skipping service creation - VPC resources not available${NC}"
        echo "You can create it manually later with the command shown in CICD_SETUP_GUIDE.md"
    fi
fi
echo ""

# Summary
echo "=========================================="
echo -e "${GREEN}🎉 AWS Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "📋 Summary:"
echo "  AWS Account ID: $AWS_ACCOUNT_ID"
echo "  Region: $AWS_REGION"
echo "  ECR Repository: file-storage-app"
echo "  ECS Cluster: file-storage-cluster"
echo "  ECS Service: file-storage-service"
echo ""
echo "📝 Next Steps:"
echo "  1. Add Jenkins credentials:"
echo "     - aws-account-id: $AWS_ACCOUNT_ID"
echo "     - aws-credentials: Your AWS Access Key/Secret"
echo ""
echo "  2. Commit and push the updated ecs-task-definition.json:"
echo "     git add ecs-task-definition.json"
echo "     git commit -m 'chore: update task definition with AWS Account ID'"
echo "     git push origin main"
echo ""
echo "  3. Trigger Jenkins build"
echo ""
echo -e "${GREEN}✅ Ready to deploy!${NC}"
