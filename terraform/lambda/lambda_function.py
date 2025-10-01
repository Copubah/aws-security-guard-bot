import os
import json
import boto3
from datetime import datetime

ec2 = boto3.client('ec2')
sns = boto3.client('sns')

SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
QUARANTINE_SG = os.environ.get('QUARANTINE_SG')  # should be sg-xxxxx

def quarantine_instance(instance_id):
    # describe instance to get its network interfaces
    resp = ec2.describe_instances(InstanceIds=[instance_id])
    enis = []
    for r in resp.get('Reservations', []):
        for inst in r.get('Instances', []):
            for ni in inst.get('NetworkInterfaces', []):
                enis.append(ni['NetworkInterfaceId'])

    if not enis:
        return False, "no ENIs found"

    # set the ENI's security groups to the quarantine SG
    for eni in enis:
        ec2.modify_network_interface_attribute(NetworkInterfaceId=eni, Groups=[QUARANTINE_SG])

    return True, f"quarantined ENIs: {enis}"

def lambda_handler(event, context):
    now = datetime.utcnow().isoformat()
    detail = event.get('detail', {})
    finding_type = detail.get('type', 'Unknown')
    message = {
        "time": now,
        "finding_type": finding_type,
        "detail": detail
    }

    # Try common paths for instance id in GuardDuty finding
    instance_id = None
    resource = detail.get('resource', {})
    if resource:
        inst_details = resource.get('instanceDetails', {}) or {}
        instance_id = inst_details.get('instanceId')

    action = "none"
    try:
        if instance_id:
            ok, msg = quarantine_instance(instance_id)
            action = msg
        else:
            action = "no ec2 instance in finding"
    except Exception as e:
        action = f"error during remediation: {str(e)}"

    payload = {
        "finding_summary": message,
        "action": action
    }

    # publish to SNS for alerting
    if SNS_TOPIC_ARN:
        sns.publish(TopicArn=SNS_TOPIC_ARN, Subject="GuardBot Alert", Message=json.dumps(payload, default=str))

    return {"status": "ok", "action": action}
