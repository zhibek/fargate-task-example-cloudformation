#!/usr/bin/env bash

# Stop on any error
set -e

STAGE=${STAGE:=dev}
STACK_NAME="${STACK_NAME:=fargate-task-example-cloudformation-${STAGE}}"
TASK_NAME="${TASK_NAME:=example-task}"
DEBUG=${DEBUG:=}

# Set BASEDIR holding script path
BASEDIR=$(dirname "$0")

# Check AWS auth
if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
  echo "ERROR: AWS authentication requires AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY env vars are set!"
  exit 1
fi

# Determine AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
if [ -z "${AWS_ACCOUNT_ID}" ]; then
  echo "ERROR: Problem detecting AWS_ACCOUNT_ID"
  exit 1
fi

# Set AWS_REGION to default if not provided as env var
if [ -z "${AWS_REGION}" ]; then
  AWS_REGION="eu-west-1"
fi

# Build container variables
CONTAINER_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
CONTAINER_IMAGE=${CONTAINER_REGISTRY}/${TASK_NAME}:latest

echo "STACK_NAME=${STACK_NAME}"
echo "TASK_NAME=${TASK_NAME}"
echo "AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}"
echo "AWS_REGION=${AWS_REGION}"
echo "CONTAINER_REGISTRY=${CONTAINER_REGISTRY}"
echo "CONTAINER_IMAGE=${CONTAINER_IMAGE}"
echo "DEBUG=${DEBUG}"
echo ""

# Deploy stack with CloudFormation
echo "Deploying stack with CloudFormation..."
aws cloudformation deploy \
  --template-file ${BASEDIR}/cloudformation.yml \
  --stack-name ${STACK_NAME} \
  --region ${AWS_REGION} \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    TaskName=$TASK_NAME \
    ContainerImage=$CONTAINER_IMAGE

# Authenticate with ECR container registry
echo "Authenticating with ECR container registry..."
aws ecr get-login-password \
  --region ${AWS_REGION} \
  | docker login \
    --username AWS \
    --password-stdin \
    ${CONTAINER_REGISTRY}

# Build+tag+push Docker image
echo "Building+tagging+pushing Docker image..." 
docker build \
  -t ${TASK_NAME} \
  ${BASEDIR}/..
docker tag \
  ${TASK_NAME}:latest \
  ${CONTAINER_IMAGE}
docker push \
  ${CONTAINER_IMAGE}

# Display stack logs in DEBUG mode
if [ -n "${DEBUG}" ]; then
  echo "Showing CloudFormation stack logs..."
  aws cloudformation describe-stack-events \
    --stack-name ${STACK_NAME} \
    --region ${AWS_REGION} \
    --no-cli-pager
fi


# Keep this statement until the end!
echo "***** Deploy complete! *****"
