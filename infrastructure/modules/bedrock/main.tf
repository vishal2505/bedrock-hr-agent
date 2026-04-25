# --- Bedrock Guardrail ---
resource "aws_bedrock_guardrail" "hr_agent" {
  name                      = "${var.project_name}-guardrail"
  blocked_input_messaging   = "I'm sorry, I cannot process this request as it contains sensitive information or prohibited content."
  blocked_outputs_messaging = "I'm sorry, I cannot provide this information as it may contain sensitive data."
  description               = "Guardrail for HR onboarding agent - blocks PII, salary negotiation, and legal disputes"

  content_policy_config {
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type            = "HATE"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type            = "INSULTS"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type            = "SEXUAL"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type            = "VIOLENCE"
    }
    filters_config {
      input_strength  = "NONE"
      output_strength = "NONE"
      type            = "MISCONDUCT"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "NONE"  # AWS restriction: PROMPT_ATTACK output must be NONE
      type            = "PROMPT_ATTACK"
    }
  }

  sensitive_information_policy_config {
    pii_entities_config {
      action = "BLOCK"
      type   = "US_SOCIAL_SECURITY_NUMBER"
    }
    pii_entities_config {
      action = "BLOCK"
      type   = "US_BANK_ACCOUNT_NUMBER"
    }
    pii_entities_config {
      action = "ANONYMIZE"
      type   = "EMAIL"
    }
  }

  topic_policy_config {
    topics_config {
      name       = "Salary Negotiation"
      definition = "Any discussion about negotiating salary, compensation packages, pay raises, or bonus structures"
      type       = "DENY"
      examples   = ["How can I negotiate a higher salary?", "What should I ask for in my compensation package?"]
    }
    topics_config {
      name       = "Legal Disputes"
      definition = "Any discussion about legal disputes, lawsuits, legal advice, or litigation"
      type       = "DENY"
      examples   = ["I want to sue the company", "Can you give me legal advice about my employment contract?"]
    }
  }

  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
  }

  tags = var.tags
}

# Keep a stable version to attach to the agent.
resource "aws_bedrock_guardrail_version" "hr_agent" {
  guardrail_arn = aws_bedrock_guardrail.hr_agent.guardrail_arn
  description   = "Production version"
}

# --- Knowledge Base ---
resource "aws_bedrockagent_knowledge_base" "hr_policies" {
  name     = "${var.project_name}-knowledge-base"
  role_arn = var.kb_role_arn

  description = "Knowledge base containing HR policy documents for the onboarding agent"

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.embedding_model_id}"
    }
  }

  storage_configuration {
    type = "S3_VECTORS"

    s3_vectors_configuration {
      vector_bucket_arn = var.vector_bucket_arn
      index_name        = var.vector_index_name
    }
  }

  tags = var.tags
}

resource "aws_bedrockagent_data_source" "hr_documents" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.hr_policies.id
  name              = "${var.project_name}-documents"

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn = var.documents_bucket_arn
    }
  }

  # S3 Vectors has a 2048-byte limit on filterable metadata per vector.
  # Bedrock stores chunk text + source metadata in that field, so chunks
  # must be small enough to stay under the limit.
  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"

      fixed_size_chunking_configuration {
        max_tokens         = 200
        overlap_percentage = 10
      }
    }
  }
}

# --- Bedrock Agent ---
resource "aws_bedrockagent_agent" "hr_agent" {
  agent_name                 = "hr-onboarding-agent"
  agent_resource_role_arn    = var.agent_role_arn
  foundation_model           = var.bedrock_model_id
  idle_session_ttl_in_seconds = 600

  instruction = <<-EOT
    You are an HR onboarding assistant. Help new employees by answering questions from company policies stored in the knowledge base. When needed, send welcome emails or log onboarding tasks. Always be professional, concise, and friendly.
  EOT

  description = "AI-powered HR onboarding assistant that helps new employees with policy questions, welcome emails, and task tracking"

  guardrail_configuration {
    guardrail_identifier = aws_bedrock_guardrail.hr_agent.guardrail_id
    guardrail_version    = aws_bedrock_guardrail_version.hr_agent.version
  }

  memory_configuration {
    enabled_memory_types = ["SESSION_SUMMARY"]
    storage_days         = 30
  }

  tags = var.tags
}

# --- Knowledge Base Association ---
resource "aws_bedrockagent_agent_knowledge_base_association" "hr_policies" {
  agent_id             = aws_bedrockagent_agent.hr_agent.agent_id
  knowledge_base_id    = aws_bedrockagent_knowledge_base.hr_policies.id
  description          = "HR policy documents including leave policy, IT policy, and code of conduct"
  knowledge_base_state = "ENABLED"
}

# --- Action Groups ---
resource "aws_bedrockagent_agent_action_group" "send_email" {
  agent_id                     = aws_bedrockagent_agent.hr_agent.agent_id
  agent_version                = "DRAFT"
  action_group_name            = "SendWelcomeEmail"
  action_group_executor {
    lambda = var.send_email_lambda_arn
  }
  description                  = "Sends a welcome email to a new employee"

  function_schema {
    member_functions {
      functions {
        name        = "send_welcome_email"
        description = "Send a welcome email to a new employee with their onboarding information"

        parameters {
          map_block_key = "employee_email"
          type          = "string"
          description   = "The email address of the new employee"
          required      = true
        }

        parameters {
          map_block_key = "employee_name"
          type          = "string"
          description   = "The full name of the new employee"
          required      = true
        }

        parameters {
          map_block_key = "start_date"
          type          = "string"
          description   = "The start date of the new employee (YYYY-MM-DD format)"
          required      = false
        }
      }
    }
  }
}

resource "aws_bedrockagent_agent_action_group" "log_task" {
  agent_id                     = aws_bedrockagent_agent.hr_agent.agent_id
  agent_version                = "DRAFT"
  action_group_name            = "LogOnboardingTask"
  action_group_executor {
    lambda = var.log_task_lambda_arn
  }
  description                  = "Logs an onboarding task for tracking"

  function_schema {
    member_functions {
      functions {
        name        = "log_onboarding_task"
        description = "Log a new onboarding task for a new employee"

        parameters {
          map_block_key = "task_title"
          type          = "string"
          description   = "Title of the onboarding task"
          required      = true
        }

        parameters {
          map_block_key = "task_description"
          type          = "string"
          description   = "Detailed description of the task"
          required      = true
        }

        parameters {
          map_block_key = "assigned_to"
          type          = "string"
          description   = "Name or email of the person assigned to this task"
          required      = true
        }

        parameters {
          map_block_key = "due_date"
          type          = "string"
          description   = "Due date for the task (YYYY-MM-DD format)"
          required      = false
        }
      }
    }
  }
}

# --- Agent Alias ---
# Must be created LAST — alias creation puts the agent into Versioning state,
# which blocks PrepareAgent calls from action groups and KB associations.
resource "aws_bedrockagent_agent_alias" "production" {
  agent_id         = aws_bedrockagent_agent.hr_agent.agent_id
  agent_alias_name = "production"
  description      = "Production alias for the HR onboarding agent"

  tags = var.tags

  depends_on = [
    aws_bedrockagent_agent_knowledge_base_association.hr_policies,
    aws_bedrockagent_agent_action_group.send_email,
    aws_bedrockagent_agent_action_group.log_task,
  ]
}
