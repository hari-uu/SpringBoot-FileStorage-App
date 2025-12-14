# Variables for Terraform configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "file-storage-app"
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "file-storage-app"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = "file-storage-cluster"
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
  default     = "file-storage-service"
}

variable "ecs_task_family" {
  description = "ECS task definition family name"
  type        = string
  default     = "file-storage-task"
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Memory for the task in MB (512, 1024, 2048, etc.)"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "db_host" {
  description = "Database host endpoint"
  type        = string
  default     = "localhost"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "filestorage_db"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for file storage"
  type        = string
  default     = "file-storage-bucket-demo"
}

variable "create_s3_bucket" {
  description = "Whether to create S3 bucket"
  type        = bool
  default     = false
}


variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for ECS tasks"
}
