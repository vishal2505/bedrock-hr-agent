output "ecr_repository_url" {
  description = "ECR repo URL the backend image is pushed to"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.backend.name
}

output "service_url" {
  description = "Public HTTPS URL of the App Runner service (empty if not yet enabled)"
  value       = try("https://${aws_apprunner_service.backend[0].service_url}", "")
}

output "service_arn" {
  description = "ARN of the App Runner service (empty if not yet enabled)"
  value       = try(aws_apprunner_service.backend[0].arn, "")
}
