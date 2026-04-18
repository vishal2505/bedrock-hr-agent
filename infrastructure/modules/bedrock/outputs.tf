output "agent_id" {
  value = aws_bedrockagent_agent.hr_agent.agent_id
}

output "agent_alias_id" {
  value = aws_bedrockagent_agent_alias.production.agent_alias_id
}

output "knowledge_base_id" {
  value = aws_bedrockagent_knowledge_base.hr_policies.id
}

output "guardrail_id" {
  value = aws_bedrock_guardrail.hr_agent.guardrail_id
}
