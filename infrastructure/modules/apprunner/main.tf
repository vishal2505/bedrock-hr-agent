data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- ECR Repository for the backend image ---
resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# --- IAM Role: App Runner ECR access (lets App Runner pull from ECR) ---
resource "aws_iam_role" "apprunner_access" {
  name = "${var.project_name}-apprunner-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "build.apprunner.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr" {
  role       = aws_iam_role.apprunner_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# --- IAM Role: App Runner instance role (runtime permissions for the container) ---
resource "aws_iam_role" "apprunner_instance" {
  name = "${var.project_name}-apprunner-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "tasks.apprunner.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# Attach the existing app_backend_policy (Bedrock + DynamoDB) to the instance role
resource "aws_iam_role_policy_attachment" "apprunner_app_permissions" {
  role       = aws_iam_role.apprunner_instance.name
  policy_arn = var.app_backend_policy_arn
}

# --- App Runner Service (gated by var.enable) ---
# First terraform apply: enable=false, just creates ECR + IAM.
# After image push: enable=true, creates the service.
# Auto-deployments handle subsequent image pushes automatically.
resource "aws_apprunner_service" "backend" {
  count = var.enable ? 1 : 0

  service_name = "${var.project_name}-backend"

  source_configuration {
    auto_deployments_enabled = true

    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_access.arn
    }

    image_repository {
      image_identifier      = "${aws_ecr_repository.backend.repository_url}:latest"
      image_repository_type = "ECR"

      image_configuration {
        port = "8000"
        runtime_environment_variables = {
          AWS_REGION             = data.aws_region.current.id
          BEDROCK_AGENT_ID       = var.agent_id
          BEDROCK_AGENT_ALIAS_ID = var.agent_alias_id
          DYNAMODB_TABLE_NAME    = var.dynamodb_table_name
          FRONTEND_URL           = var.frontend_url
        }
      }
    }
  }

  instance_configuration {
    instance_role_arn = aws_iam_role.apprunner_instance.arn
    cpu               = "1024"
    memory            = "2048"
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/api/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }

  tags = var.tags
}
