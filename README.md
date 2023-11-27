# Fargate - Task Example (using CloudFormation)

## Prerequisites

### Create AWS account & generate AWS access key
https://portal.aws.amazon.com/billing/signup

### Set AWS access key environment variables
```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_DEFAULT_REGION=eu-west-1
```


## Fargate (ECS) Task

### Setup
Setup the Fargate Task.
```
APP_NAME=fargate-task-example-cloudformation TASK_NAME=example-task ./deploy/task-setup.sh
```

### Run
Run the Fargate Task.
```
APP_NAME=fargate-task-example-cloudformation TASK_NAME=example-task ./deploy/task-run.sh
```

### Cleanup
Cleanup the Fargate Task when it is no longer required.
```
APP_NAME=fargate-task-example-cloudformation TASK_NAME=example-task ./deploy/task-cleanup.sh
```
