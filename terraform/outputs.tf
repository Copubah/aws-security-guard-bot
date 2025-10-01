output "lambda_name" {
  value = aws_lambda_function.guardbot.function_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "quarantine_sg_id" {
  value = aws_security_group.quarantine.id
}
