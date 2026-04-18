output "vector_bucket_arn" {
  value = local.vector_bucket_arn
}

output "vector_bucket_name" {
  value = aws_s3vectors_vector_bucket.kb.vector_bucket_name
}
