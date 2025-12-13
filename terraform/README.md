# 🚀 Terraform Infrastructure Setup

This directory contains Terraform configuration to automatically provision all AWS resources needed for the CI/CD pipeline.

---

## 📋 What Gets Created

Terraform will create the following AWS resources:

### **Core Infrastructure:**
- ✅ **ECR Repository** - For storing Docker images
- ✅ **ECS Cluster** - Container orchestration cluster
- ✅ **ECS Service** - Running your application
- ✅ **ECS Task Definition** - Container configuration

### **Networking & Security:**
- ✅ **Security Group** - Firewall rules for ECS tasks
- ✅ **VPC Configuration** - Uses default VPC and subnets

### **IAM Roles & Permissions:**
- ✅ **ECS Task Execution Role** - For pulling images and writing logs
- ✅ **ECS Task Role** - For application permissions (S3, etc.)

### **Monitoring:**
- ✅ **CloudWatch Log Group** - Application logs

### **Optional:**
- ⚪ **S3 Bucket** - For file storage (set `create_s3_bucket = true`)

---

## 🛠️ Prerequisites

1. **Install Terraform:**
   ```bash
   # macOS
   brew install terraform
   
   # Verify installation
   terraform version
   ```

2. **Configure AWS CLI:**
   ```bash
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Enter default region: us-east-1
   # Enter default output format: json
   ```

3. **Verify AWS credentials:**
   ```bash
   aws sts get-caller-identity
   ```

---

## 🚀 Quick Start

### **Step 1: Navigate to terraform directory**
```bash
cd terraform
```

### **Step 2: Initialize Terraform**
```bash
terraform init
```

This downloads required providers and sets up the backend.

### **Step 3: Review the plan**
```bash
terraform plan
```

This shows what resources will be created without actually creating them.

### **Step 4: Apply the configuration**
```bash
terraform apply
```

Type `yes` when prompted to create the resources.

### **Step 5: Save the outputs**
```bash
terraform output
```

This displays important values like AWS Account ID, ECR URL, etc.

---

## ⚙️ Customization

### **Option 1: Using terraform.tfvars**

Create a `terraform.tfvars` file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
# AWS Configuration
aws_region  = "us-east-1"
environment = "production"

# Application Configuration
app_name = "my-file-storage-app"

# Task Resources
task_cpu    = "1024"  # 1 vCPU
task_memory = "2048"  # 2 GB

# Service Configuration
desired_count = 2  # Run 2 instances

# Database Configuration
db_host = "my-rds-instance.us-east-1.rds.amazonaws.com"
db_name = "production_db"

# S3 Configuration
s3_bucket_name   = "my-unique-bucket-name-12345"
create_s3_bucket = true
```

### **Option 2: Using command-line variables**

```bash
terraform apply \
  -var="environment=production" \
  -var="desired_count=2" \
  -var="task_cpu=1024" \
  -var="task_memory=2048"
```

---

## 📊 Important Outputs

After running `terraform apply`, you'll get these outputs:

```bash
# Get AWS Account ID for Jenkins
terraform output aws_account_id

# Get ECR repository URL
terraform output ecr_repository_url

# Get all Jenkins-related values
terraform output jenkins_credentials_summary
```

---

## 🔄 Updating Infrastructure

### **Modify resources:**
1. Edit the `.tf` files or `terraform.tfvars`
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to apply changes

### **Scale the service:**
```bash
terraform apply -var="desired_count=3"
```

---

## 🗑️ Destroying Resources

To delete all created resources:

```bash
terraform destroy
```

**⚠️ WARNING:** This will delete:
- ECS service and tasks
- ECR repository and all images
- CloudWatch logs
- IAM roles
- Security groups

---

## 📝 Common Commands

| Command | Description |
|---------|-------------|
| `terraform init` | Initialize Terraform |
| `terraform plan` | Preview changes |
| `terraform apply` | Create/update resources |
| `terraform destroy` | Delete all resources |
| `terraform output` | Show output values |
| `terraform state list` | List all resources |
| `terraform fmt` | Format configuration files |
| `terraform validate` | Validate configuration |

---

## 🔐 Jenkins Integration

After running Terraform, configure Jenkins with these values:

### **1. Get AWS Account ID:**
```bash
terraform output aws_account_id
```

Add to Jenkins:
- **Credentials → Add → Secret text**
- **ID:** `aws-account-id`
- **Secret:** (paste the account ID)

### **2. Add AWS Credentials:**
- **Credentials → Add → AWS Credentials**
- **ID:** `aws-credentials`
- **Access Key ID:** Your AWS access key
- **Secret Access Key:** Your AWS secret key

### **3. Verify Jenkinsfile matches Terraform:**

The Jenkinsfile should use these values (automatically set):
```groovy
ECR_REPOSITORY = 'file-storage-app'
ECS_CLUSTER = 'file-storage-cluster'
ECS_SERVICE = 'file-storage-service'
ECS_TASK_DEFINITION = 'file-storage-task'
```

---

## 🎯 Complete Workflow

### **Initial Setup:**
```bash
# 1. Navigate to terraform directory
cd terraform

# 2. Initialize Terraform
terraform init

# 3. Create resources
terraform apply

# 4. Save outputs
terraform output > ../terraform-outputs.txt

# 5. Get AWS Account ID for Jenkins
terraform output aws_account_id
```

### **Configure Jenkins:**
1. Add `aws-account-id` credential (from terraform output)
2. Add `aws-credentials` credential
3. Trigger Jenkins build

### **Deploy Application:**
```bash
# Push code to GitHub
git add .
git commit -m "feat: deploy with Terraform infrastructure"
git push origin main

# Jenkins will automatically:
# - Build the application
# - Create Docker image
# - Push to ECR (created by Terraform)
# - Deploy to ECS (created by Terraform)
```

---

## 🔍 Troubleshooting

### **Error: "No default VPC found"**
```bash
# Create a default VPC
aws ec2 create-default-vpc
```

### **Error: "Bucket name already exists"**
```bash
# S3 bucket names must be globally unique
# Change s3_bucket_name in terraform.tfvars
```

### **Error: "Insufficient permissions"**
```bash
# Ensure your AWS user has these permissions:
# - AmazonECS_FullAccess
# - AmazonEC2ContainerRegistryFullAccess
# - IAMFullAccess
# - CloudWatchLogsFullAccess
```

### **View Terraform state:**
```bash
terraform state list
terraform state show aws_ecs_cluster.main
```

---

## 📚 File Structure

```
terraform/
├── main.tf                    # Main infrastructure configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example variables file
├── .gitignore                 # Git ignore for Terraform files
└── README.md                  # This file
```

---

## 🎉 Benefits of Using Terraform

✅ **Infrastructure as Code** - Version control your infrastructure
✅ **Reproducible** - Create identical environments easily
✅ **Automated** - No manual clicking in AWS console
✅ **Safe** - Preview changes before applying
✅ **Documented** - Configuration is self-documenting
✅ **Reversible** - Easy to destroy and recreate

---

## 🔄 Next Steps

After Terraform creates your infrastructure:

1. ✅ Configure Jenkins credentials (see above)
2. ✅ Push code to GitHub
3. ✅ Jenkins builds and deploys automatically
4. ✅ Monitor in AWS Console:
   - ECS → Clusters → file-storage-cluster
   - ECR → Repositories → file-storage-app
   - CloudWatch → Log groups → /ecs/file-storage-app

---

## 💡 Tips

- **Always run `terraform plan`** before `apply`
- **Use workspaces** for multiple environments:
  ```bash
  terraform workspace new production
  terraform workspace select production
  ```
- **Store state remotely** for team collaboration (S3 + DynamoDB)
- **Use modules** for reusable infrastructure components

---

## 📞 Support

If you encounter issues:
1. Check `terraform plan` output
2. Review AWS CloudWatch logs
3. Verify AWS credentials and permissions
4. Check the main `CICD_SETUP_GUIDE.md` for general setup help
