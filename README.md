# AWS Security Guard Bot
- AWS Security Guard Bot is an automated security response solution built with Terraform and AWS services.  
It listens to GuardDuty findings, routes them through EventBridge,and triggers a Lambda function that can quarantine compromised EC2 instances and send real-time alerts via SNS.  



## Architecture
    A[GuardDuty] --> B[EventBridge Rule]
    B --> C[Lambda Function]
    C --> D[Quarantine EC2 Instance]
    C --> E[SNS Notifications]


## Features

- Automated threat detection with GuardDuty
- Event-driven response using EventBridge
- Quarantines suspicious EC2 instances by modifying security groups
- Sends notifications via Amazon SNS (Email or SMS)
- Infrastructure fully managed with Terraform
- Modular and extensible Lambda functions in Python

 
## Architecture Diagram
          +----------------+
          |   GuardDuty    |
          +-------+--------+
                  |
                  v
          +----------------+
          |  EventBridge   |
          +-------+--------+
                  |
                  v
          +----------------+
          |    Lambda      |
          |  (Python Bot)  |
          +-------+--------+
                  |
         +--------+--------+
         | Quarantine EC2  |
         |  + Notify via   |
         |      SNS        |
         +----------------+




## Prerequisites
- Terraform >= 1.5
- AWS CLI configured with admin credentials
- Python 3.9+
- An AWS account with GuardDuty enabled


## Deployment
- Clone the repo
- git clone https://github.com/Copubah/aws-security-guard-bot.git
- cd aws-security-guard-bot/terraform


## Initialize and plan
- terraform init
- terraform plan


## Apply changes
- terraform apply


## Subscribe to SNS
- Check the output for your SNS topic ARN.
- Confirm your email/SMS subscription to start receiving alerts.

## Testing
- Trigger a sample GuardDuty finding (or simulate with AWS CLI).

## Verify:
- EC2 instance is quarantined (security group updated).
- Notification is sent via SNS.

## Clean Up
- To avoid unwanted charges, destroy all resources when done:
- terraform destroy

 ## Future Enhancements
- Add Slack or Discord integration for alerts
- Support for AWS Security Hub findings
- Extend to quarantine IAM roles or S3 buckets

## License

This project is licensed under the MIT License. See LICENSE
 for details.


