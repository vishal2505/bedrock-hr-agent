output "documents_bucket_id" {
  value = aws_s3_bucket.hr_documents.id
}

output "documents_bucket_arn" {
  value = aws_s3_bucket.hr_documents.arn
}

output "frontend_bucket_id" {
  value = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  value = aws_s3_bucket.frontend.arn
}

output "frontend_website_endpoint" {
  value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

# output "terraform_state_bucket_id" {
#   value = aws_s3_bucket.terraform_state.id
# }
