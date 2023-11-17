# Fargate - Task Example (using CloudFormation)

## Prerequisites

### Create AWS account & generate AWS access key
https://portal.aws.amazon.com/billing/signup

### Set AWS access key environment variables
```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```


## Fargate (ECS) Task

### Setup
Setup the Fargate Task.
```
./deploy/task-setup.sh
```

### Run
Run the Fargate Task.
```
./deploy/task-run.sh
```

### Cleanup
Cleanup the Fargate Task when it is no longer required.
```
./deploy/task-cleanup.sh
```
