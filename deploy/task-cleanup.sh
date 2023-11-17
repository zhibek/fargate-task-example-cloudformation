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

# Delete stack with CloudFormation
echo "Deleting stack with CloudFormation..."
aws cloudformation delete-stack \
  --stack-name ${STACK_NAME} \
  --region ${AWS_REGION}

# Delete container registry in ECR if it exists
echo "Check ECR container registry..."
CONTAINER_REGISTRY_EXISTS=$(aws ecr describe-repositories --repository-names ${TASK_NAME} --region ${AWS_REGION} --output text --query "repositories[].[repositoryName]" || true)
if [ -n "${CONTAINER_REGISTRY_EXISTS}" ]; then
  echo "Deleting ECR container registry..."
  aws ecr batch-delete-image \
    --repository-name ${TASK_NAME} \
    --region ${AWS_REGION} \
    --image-ids imageTag=latest
  aws ecr delete-repository \
    --repository-name ${TASK_NAME} \
    --region ${AWS_REGION}
fi

# Wait until stack is deleted
echo "Waiting until stack is deleted..."
aws cloudformation wait stack-delete-complete \
  --stack-name ${STACK_NAME} \
  --region ${AWS_REGION}


# Keep this statement until the end!
echo "***** Cleanup complete! *****"
