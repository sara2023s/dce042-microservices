"""Generate taskdef.json and appspec.yml for CodeDeploy Blue/Green ECS deployment."""
import json
import os

SERVICE_NAME = os.environ["SERVICE_NAME"]
TASK_DEF_FAMILY = os.environ["TASK_DEF_FAMILY"]
EXECUTION_ROLE_ARN = os.environ["EXECUTION_ROLE_ARN"]
TASK_ROLE_ARN = os.environ["TASK_ROLE_ARN"]
FULL_IMAGE_URI = os.environ["FULL_IMAGE_URI"]
AWS_REGION = os.environ["AWS_REGION"]
CONTAINER_PORT = 5001

taskdef = {
    "family": TASK_DEF_FAMILY,
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": EXECUTION_ROLE_ARN,
    "taskRoleArn": TASK_ROLE_ARN,
    "containerDefinitions": [{
        "name": SERVICE_NAME,
        "image": FULL_IMAGE_URI,
        "essential": True,
        "portMappings": [{"containerPort": CONTAINER_PORT, "protocol": "tcp"}],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "/ecs/" + TASK_DEF_FAMILY,
                "awslogs-region": AWS_REGION,
                "awslogs-stream-prefix": "ecs"
            }
        }
    }]
}

with open("taskdef.json", "w") as f:
    json.dump(taskdef, f)

appspec = (
    "version: 0.0\n"
    "Resources:\n"
    "  - TargetService:\n"
    "      Type: AWS::ECS::Service\n"
    "      Properties:\n"
    '        TaskDefinition: "<TASK_DEFINITION>"\n'
    "        LoadBalancerInfo:\n"
    '          ContainerName: "' + SERVICE_NAME + '"\n'
    "          ContainerPort: " + str(CONTAINER_PORT) + "\n"
)

with open("appspec.yml", "w") as f:
    f.write(appspec)

print("taskdef.json:")
print(json.dumps(taskdef, indent=2))
print("\nappspec.yml:")
print(appspec)
