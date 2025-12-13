# Terraform configuration for Spring Boot File Storage App
# This creates all required AWS resources for the CI/CD pipeline

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to get subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ECR Repository for Docker images
resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "File Storage App Repository"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECR Lifecycle Policy to keep only recent images
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7

  tags = {
    Name        = "File Storage App Logs"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "ECS Task Execution Role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task (application permissions)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.app_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "ECS Task Role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Policy for S3 access (if using S3 for file storage)
resource "aws_iam_role_policy" "ecs_task_s3_policy" {
  name = "${var.app_name}-s3-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${var.s3_bucket_name}",
        "arn:aws:s3:::${var.s3_bucket_name}/*"
      ]
    }]
  })
}

# Security Group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ECS Tasks Security Group"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "File Storage App Cluster"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = var.ecs_task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = var.app_name
    image     = "${aws_ecr_repository.app.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "aws"
      },
      {
        name  = "AWS_REGION"
        value = var.aws_region
      },
      {
        name  = "DB_HOST"
        value = var.db_host
      },
      {
        name  = "DB_NAME"
        value = var.db_name
      },
      {
        name  = "S3_BUCKET_NAME"
        value = var.s3_bucket_name
      }
    ]

    # Uncomment if using AWS Secrets Manager for DB credentials
    # secrets = [
    #   {
    #     name      = "DB_USERNAME"
    #     valueFrom = aws_secretsmanager_secret.db_username.arn
    #   },
    #   {
    #     name      = "DB_PASSWORD"
    #     valueFrom = aws_secretsmanager_secret.db_password.arn
    #   }
    # ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = {
    Name        = "File Storage App Task Definition"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  # Optional: Load balancer configuration
  # Uncomment if you want to add an Application Load Balancer
  # load_balancer {
  #   target_group_arn = aws_lb_target_group.app.arn
  #   container_name   = var.app_name
  #   container_port   = 8080
  # }

  tags = {
    Name        = "File Storage App Service"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Ignore changes to desired_count for auto-scaling
  lifecycle {
    ignore_changes = [desired_count]
  }
}

# Optional: S3 Bucket for file storage
resource "aws_s3_bucket" "file_storage" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = var.s3_bucket_name

  tags = {
    Name        = "File Storage Bucket"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "file_storage" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.file_storage[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "file_storage" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.file_storage[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
