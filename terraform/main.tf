# get default VPC to create quarantine SG there
data "aws_vpc" "default" {
  default = true
}

# GuardDuty detector
resource "aws_guardduty_detector" "gd" {
  enable = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# SNS topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "security-guardbot-alerts"
}

# Quarantine security group - no ingress, no egress
resource "aws_security_group" "quarantine" {
  name        = "sg-quarantine-guardbot"
  description = "Quarantine SG - blocks all traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {}
  egress {}
}

# package lambda into zip using archive provider
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.zip"
}

# IAM assume role for lambda
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "guardbot-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Least privilege policy for Lambda to interact with EC2, SNS and logs
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:ModifyInstanceAttribute",
      "ec2:DescribeInstanceStatus",
      "sns:Publish",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "guardbot-inline-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

# Lambda function
resource "aws_lambda_function" "guardbot" {
  function_name = "guardduty-guardbot"
  handler       = "lambda_function.lambda_handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_role.arn
  filename      = data.archive_file.lambda_zip.output_path

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
      QUARANTINE_SG = aws_security_group.quarantine.id
    }
  }
}

# EventBridge rule for GuardDuty findings - filters severity numeric >= threshold
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name = "guardduty-findings-rule"

  event_pattern = jsonencode({
    source = ["aws.guardduty"]
    "detail-type" = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", var.finding_severity_threshold] }]
    }
  })
}

# EventBridge target to Lambda
resource "aws_cloudwatch_event_target" "to_lambda" {
  rule = aws_cloudwatch_event_rule.guardduty_findings.name
  arn  = aws_lambda_function.guardbot.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardbot.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}
