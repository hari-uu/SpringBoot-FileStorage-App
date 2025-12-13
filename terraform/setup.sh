#!/bin/bash

# Quick Terraform Setup Script
# This script automates the Terraform infrastructure setup

set -e

echo "🚀 Terraform Quick Setup for File Storage App"
echo "=============================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed${NC}"
    echo ""
    echo "Install Terraform:"
    echo "  macOS: brew install terraform"
    echo "  Linux: https://learn.hashicorp.com/tutorials/terraform/install-cli"
    exit 1
fi

echo -e "${GREEN}✅ Terraform is installed: $(terraform version | head -n1)${NC}"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not configured${NC}"
    echo ""
    echo "Configure AWS CLI:"
    echo "  aws configure"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ AWS CLI is configured${NC}"
echo -e "   Account ID: ${YELLOW}${AWS_ACCOUNT_ID}${NC}"
echo ""

# Navigate to terraform directory
cd "$(dirname "$0")"

# Initialize Terraform
echo "1️⃣  Initializing Terraform..."
terraform init
echo -e "${GREEN}✅ Terraform initialized${NC}"
echo ""

# Create terraform.tfvars if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    echo "2️⃣  Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${GREEN}✅ Created terraform.tfvars${NC}"
    echo -e "${YELLOW}⚠️  Review and customize terraform.tfvars before applying${NC}"
    echo ""
fi

# Validate configuration
echo "3️⃣  Validating Terraform configuration..."
terraform validate
echo -e "${GREEN}✅ Configuration is valid${NC}"
echo ""

# Format configuration
echo "4️⃣  Formatting Terraform files..."
terraform fmt
echo -e "${GREEN}✅ Files formatted${NC}"
echo ""

# Show plan
echo "5️⃣  Generating Terraform plan..."
echo ""
terraform plan
echo ""

# Ask for confirmation
echo "=============================================="
echo -e "${YELLOW}Ready to create AWS infrastructure?${NC}"
echo ""
echo "This will create:"
echo "  - ECR Repository"
echo "  - ECS Cluster and Service"
echo "  - IAM Roles"
echo "  - Security Groups"
echo "  - CloudWatch Log Groups"
echo ""
read -p "Do you want to proceed? (yes/no): " -r
echo ""

if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "6️⃣  Applying Terraform configuration..."
    terraform apply -auto-approve
    echo ""
    echo -e "${GREEN}✅ Infrastructure created successfully!${NC}"
    echo ""
    
    # Show outputs
    echo "=============================================="
    echo "📋 Important Information for Jenkins:"
    echo "=============================================="
    echo ""
    terraform output jenkins_credentials_summary
    echo ""
    
    echo "AWS Account ID for Jenkins credential:"
    echo -e "${YELLOW}$(terraform output -raw aws_account_id)${NC}"
    echo ""
    
    echo "ECR Repository URL:"
    echo -e "${YELLOW}$(terraform output -raw ecr_repository_url)${NC}"
    echo ""
    
    echo "=============================================="
    echo -e "${GREEN}🎉 Setup Complete!${NC}"
    echo "=============================================="
    echo ""
    echo "Next Steps:"
    echo "1. Add Jenkins credentials:"
    echo "   - aws-account-id: $(terraform output -raw aws_account_id)"
    echo "   - aws-credentials: Your AWS Access Key/Secret"
    echo ""
    echo "2. Push code to GitHub to trigger deployment"
    echo ""
    echo "3. Monitor deployment:"
    echo "   - ECS Console: https://console.aws.amazon.com/ecs"
    echo "   - CloudWatch Logs: https://console.aws.amazon.com/cloudwatch"
    echo ""
else
    echo -e "${YELLOW}⚠️  Terraform apply cancelled${NC}"
    echo ""
    echo "To apply later, run:"
    echo "  cd terraform"
    echo "  terraform apply"
fi
