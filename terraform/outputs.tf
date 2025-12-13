# Outputs from Terraform

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.app.arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.app.arn
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task_role.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app.name
}

output "security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "s3_bucket_name" {
  description = "S3 bucket name (if created)"
  value       = var.create_s3_bucket ? aws_s3_bucket.file_storage[0].id : "Not created"
}

output "jenkins_credentials_summary" {
  description = "Summary of values needed for Jenkins credentials"
  value = {
    aws_account_id = data.aws_caller_identity.current.account_id
    aws_region     = var.aws_region
    ecr_repository = var.ecr_repository_name
    ecs_cluster    = var.ecs_cluster_name
    ecs_service    = var.ecs_service_name
    ecs_task       = var.ecs_task_family
  }
}
