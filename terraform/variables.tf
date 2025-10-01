variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "lambda_runtime" {
  type    = string
  default = "python3.10"
}

variable "finding_severity_threshold" {
  description = "Minimum numeric severity to trigger remediation"
  type        = number
  default     = 7
}
