data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3vectors_vector_bucket" "kb" {
  vector_bucket_name = "${var.project_name}-kb-vectors"
}

# Index must exist before Bedrock Knowledge Base is created.
# Titan Embeddings V2 default output dimension = 1024.
resource "aws_s3vectors_index" "kb" {
  vector_bucket_name = aws_s3vectors_vector_bucket.kb.vector_bucket_name
  index_name         = "${var.project_name}-kb-index"
  dimension          = 1024
  distance_metric    = "cosine"
  data_type          = "float32"
}

locals {
  # aws_s3vectors_vector_bucket does not export .arn — construct it manually
  vector_bucket_arn = "arn:aws:s3vectors:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:bucket/${aws_s3vectors_vector_bucket.kb.vector_bucket_name}"
}
