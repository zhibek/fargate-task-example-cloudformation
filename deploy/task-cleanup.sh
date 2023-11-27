#!/usr/bin/env bash

# Stop on any error
set -e

# Use env vars or defaults for input variables
APP_NAME="${APP_NAME:=}"
TASK_NAME="${TASK_NAME:=}"
STAGE="${STAGE:=dev}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:=eu-west-1}"

# Validate input variables are set
[ -z "${APP_NAME}" ] && echo "ERROR: APP_NAME env var must be set!" && exit 1;
[ -z "${TASK_NAME}" ] && echo "ERROR: TASK_NAME env var must be set!" && exit 1;

# Build STACK_NAME
STACK_NAME="${APP_NAME}-${STAGE}"

# Set BASEDIR holding script path
BASEDIR=$(dirname "$0")

# Check AWS auth
if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
  echo "ERROR: AWS authentication requires AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY env vars are set!"
  exit 1
fi

echo "STACK_NAME=${STACK_NAME}"
echo "TASK_NAME=${TASK_NAME}"
echo "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"
echo ""

# Delete images in container registry in ECR if it exists
echo "Check ECR container registry..."
CONTAINER_REGISTRY_EXISTS=$(aws ecr describe-repositories \
  --repository-names "${STACK_NAME}/${TASK_NAME}" \
  --output text \
  --query "repositories[].[repositoryName]" \
  || true \
)
if [ -n "${CONTAINER_REGISTRY_EXISTS}" ]; then
  echo "Deleting images from ECR container registry..."
  aws ecr batch-delete-image \
    --repository-name "${STACK_NAME}/${TASK_NAME}" \
    --image-ids imageTag=latest
fi

# Delete stack with CloudFormation
echo "Deleting stack with CloudFormation..."
aws cloudformation delete-stack \
  --stack-name ${STACK_NAME}

# Wait until stack is deleted
echo "Waiting until stack is deleted..."
aws cloudformation wait stack-delete-complete \
  --stack-name ${STACK_NAME}


# Keep this statement until the end!
echo "***** Cleanup complete! *****"
