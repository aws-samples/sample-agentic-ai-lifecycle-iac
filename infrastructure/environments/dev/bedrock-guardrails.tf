resource "aws_bedrock_guardrail" "example" {
  name                      = "example-guardrail"
  blocked_input_messaging   = "Sorry, your input was blocked."
  blocked_outputs_messaging = "Sorry, the output was blocked."
  description              = "Example Bedrock Guardrail"

  content_policy_config {
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type            = "HATE"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type            = "VIOLENCE"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type            = "SEXUAL"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type            = "INSULTS"
    }
  }

  sensitive_information_policy_config {
    pii_entities_config {
      action = "BLOCK"
      type   = "EMAIL"
    }
    pii_entities_config {
      action = "ANONYMIZE"
      type   = "PHONE"
    }
  }

  topic_policy_config {
    topics_config {
      name       = "financial-advice"
      definition = "Providing financial or investment advice"
      examples   = ["Should I invest in stocks?", "What's the best investment?"]
      type       = "DENY"
    }
  }

  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
    words_config {
      text = "blocked-word"
    }
  }
}

resource "aws_bedrock_guardrail_version" "example" {
  guardrail_arn = aws_bedrock_guardrail.example.guardrail_arn
  description   = "Version 1"
}