data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3vectors_vector_bucket" "kb" {
  vector_bucket_name = "${var.project_name}-kb-vectors"
}

locals {
  # Construct ARN manually — the resource does not export .arn
  vector_bucket_arn = "arn:aws:s3vectors:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:bucket/${aws_s3vectors_vector_bucket.kb.vector_bucket_name}"
}
