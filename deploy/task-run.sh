#!/usr/bin/env bash

# Stop on any error
set -e

STAGE=${STAGE:=dev}
STACK_NAME="${STACK_NAME:=fargate-task-example-cloudformation-${STAGE}}"
TASK_NAME="${TASK_NAME:=example-task}"

# Set BASEDIR holding script path
BASEDIR=$(dirname "$0")

# Check AWS auth
if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
  echo "ERROR: AWS authentication requires AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY env vars are set!"
  exit 1
fi

# Set AWS_REGION to default if not provided as env var
if [ -z "${AWS_REGION}" ]; then
  AWS_REGION="eu-west-1"
fi

echo "STACK_NAME=${STACK_NAME}"
echo "TASK_NAME=${TASK_NAME}"
echo "AWS_REGION=${AWS_REGION}"
echo ""

# Find AWS Subnet ID
echo "Finding AWS Subnet ID..."
AWS_SUBNET_ID=$(aws ec2 describe-subnets --region ${AWS_REGION} --max-items 1 --filter Name=default-for-az,Values=true --query Subnets[].[SubnetId] --output text | head -n 1)
echo "AWS_SUBNET_ID=${AWS_SUBNET_ID}"
if [ -z "${AWS_SUBNET_ID}" ]; then
  echo "ERROR: Could not find AWS Subnet ID!"
  exit 1
fi

# Find AWS Security Group
echo "Finding AWS Security Group..."
AWS_SECURITYGROUP_ID=$(aws ec2 describe-security-groups --region ${AWS_REGION} --max-items 1 --filter Name=group-name,Values=default --query SecurityGroups[].[GroupId] --output text | head -n 1)
echo "AWS_SECURITYGROUP_ID=${AWS_SECURITYGROUP_ID}"
if [ -z "${AWS_SECURITYGROUP_ID}" ]; then
  echo "ERROR: Could not find AWS Security Group ID!"
  exit 1
fi

# Run ECS task
echo "Running task with ECS..."
aws ecs run-task \
  --cluster ${STACK_NAME} \
  --task-definition ${TASK_NAME} \
  --region ${AWS_REGION} \
  --launch-type FARGATE \
  --network-configuration '{"awsvpcConfiguration": {"subnets": ["'"${AWS_SUBNET_ID}"'"],"securityGroups": ["'"${AWS_SECURITYGROUP_ID}"'"],"assignPublicIp": "ENABLED"}}' \
  --no-cli-pager


# Keep this statement until the end!
echo "***** Run complete! *****"