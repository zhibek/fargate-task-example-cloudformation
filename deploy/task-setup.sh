#!/usr/bin/env bash

# Stop on any error
set -e

# Use env vars or defaults for input variables
APP_NAME="${APP_NAME:=}"
TASK_NAME="${TASK_NAME:=}"
STAGE="${STAGE:=dev}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:=eu-west-1}"
DEBUG="${DEBUG:=}"

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

# Determine AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
  --query "Account" \
  --output text \
)
if [ -z "${AWS_ACCOUNT_ID}" ]; then
  echo "ERROR: Problem detecting AWS_ACCOUNT_ID"
  exit 1
fi

# Build container variables
CONTAINER_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
CONTAINER_IMAGE=${CONTAINER_REGISTRY}/${STACK_NAME}/${TASK_NAME}:latest

echo "STACK_NAME=${STACK_NAME}"
echo "TASK_NAME=${TASK_NAME}"
echo "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"
echo "AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}"
echo "CONTAINER_REGISTRY=${CONTAINER_REGISTRY}"
echo "CONTAINER_IMAGE=${CONTAINER_IMAGE}"
echo "DEBUG=${DEBUG}"
echo ""

# Deploy stack with CloudFormation
echo "Deploying stack with CloudFormation..."
aws cloudformation deploy \
  --template-file ${BASEDIR}/cloudformation.yml \
  --stack-name ${STACK_NAME} \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    TaskName=$TASK_NAME \
    ContainerImage=$CONTAINER_IMAGE

# Authenticate with ECR container registry
echo "Authenticating with ECR container registry..."
aws ecr get-login-password \
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
    --no-cli-pager
fi


# Keep this statement until the end!
echo "***** Deploy complete! *****"
