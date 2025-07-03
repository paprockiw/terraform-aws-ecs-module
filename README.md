# ECS Cluster Terraform Module

This Terraform module provisions a fully-configurable ECS cluster on AWS using 
either **Fargate** or **EC2 launch type**, with optional support for an 
**Application Load Balancer (ALB)** and **CloudWatch logs**.

## Features

- ECS cluster creation (`Fargate` or `EC2`)
- Optional Application Load Balancer and Target Group
- CloudWatch Log Group for ECS container logging
- Auto Scaling Group and Launch Template for EC2 mode
- Fully configurable via variables

---

## Table of Contents

- [Usage](#usage)
- [Tasks and Services ](#tasks-and-services)
- [Resources Created](#resources-created)
- [Conditional Logic](#conditional-logic)
- [Input Variables](#input-variables)
- [Outputs](#outputs)
- [Notes](#notes)
- [Considerations](#considerations)

---

## Usage

```hcl
module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  account_num                = 123456789012
  platform                   = "myapp"
  environment                = "staging"
  region                     = "us-east-1"
  aws_vpc                    = "vpc-12345678910"
  service_launch_type        = "FARGATE"
  ecs_subnets                = ["subnet-abc123", "subnet-def456"]
  log_retention_days         = 14

  enable_alb                 = true
  internal_alb               = false
  alb_ecs_sgs                = ["sg-0123456789abcdef0"]
  alb_subnets                = ["subnet-xyz123", "subnet-uvw456"]
  alb_tg_port                = 80
  alb_tg_protocol            = "HTTP"
  alb_listener_port          = 80
  alb_listener_protocol      = "HTTP"

  ec2_ami_id                 = "ami-1234567890"
  ec2_instance_type          = "c1.medium"
  ec2_instance_profile_name  = "ecsInstanceProfile"
  asg_desired_capacity       = 2
  asg_min_size               = 1
  asg_max_size               = 3
}
```

---

## Tasks and Services
### Example: Defining and Running a Task on the ECS Cluster

After provisioning the ECS cluster using this module, you can deploy 
containerized applications by defining an ECS **Task Definition** and 
associating it with an ECS **Service**. Below is an example using two 
containers - `nginx` as a reverse proxy and `graphql` as the app backend - 
deployed on **Fargate** using **ALB integration**.

### ECS Task Definition

```hcl
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "graphql-nginx-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = "<EXECUTION-ROLE-ARN>"
  task_role_arn            = "<TASK-ROLE-ARN>"

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "<YOUR-ECR-REPO>.ecr.us-east-1.amazonaws.com/nginx-proxy"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/graphql-nginx"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "nginx"
        }
      }
    },
    {
      name      = "graphql"
      image     = "<YOUR-ECR-REPO>.ecr.us-east-1.amazonaws.com/graphql-app"
      essential = false
      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/graphql-nginx"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "graphql"
        }
      }
    }
  ])
}
```

### Service Definition
The service runs the task on the cluster. 

```
resource "aws_ecs_service" "ecs_service" {
  name            = "${var.purpose}-${var.environment}-ecs-service"
  cluster         = module.ecs_module.ecs_cluster_id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  launch_type     = var.service_launch_type
  desired_count   = var.service_desired_count

  network_configuration {
    subnets = [
      <SUBNET_ID_1>,
      <SUBNET_ID_2>
    ]
    security_groups  = [<SG1_ID>, <SG2_ID>]
    assign_public_ip = true
  }

  dynamic "load_balancer" {
    for_each = var.enable_alb ? [1] : []
    content {
      target_group_arn = module.ecs_module.ecs_target_groups[0].arn
      container_name   = "nginx"
      container_port   = var.service_container_port
    }
  }
}
```

---
## Resources Created

### ECS
- `aws_ecs_cluster`

### CloudWatch
- `aws_cloudwatch_log_group`

### ALB (optional)
- `aws_lb`
- `aws_lb_target_group`
- `aws_lb_listener`

### EC2 (optional, if `service_launch_type == "EC2"`)
- `aws_launch_template`
- `aws_autoscaling_group`

---

## Conditional Logic

- ALB is created **only if** `enable_alb = true`
- EC2 infrastructure is created **only if** `service_launch_type == "EC2"`

---

## Input Variables


### Core Variables
| Name                  | Type           | Default                   | Description                       |
| --------------------- | -------------- | ------------------------- | --------------------------------- |
| `account_num`         | `number`       | -                         | AWS account number                |
| `platform`            | `string`       | -                         | Name of the platform              |
| `environment`         | `string`       | -                         | Environment (e.g., dev, staging)  |
| `region`              | `string`       | -                         | AWS region                        |
| `aws_vpc`             | `string`       | -                         | VPC ID                            |
| `service_launch_type` | `string`       | `"FARGATE"`               | ECS service type: `FARGATE`/`EC2` |
| `ecs_subnets`         | `list(string)` | -                         | ECS subnet list                   |
| `log_retention_days`  | `number`       | `7`                       | CloudWatch log retention days     |

### ALB Variables
| Name                    | Type           | Description                     |
| ----------------------- | -------------- | ------------------------------- |
| `enable_alb`            | `bool`         | Enable ALB                      |
| `internal_alb`          | `bool`         | Internal or internet-facing ALB |
| `alb_ecs_sgs`           | `list(string)` | Security groups for ALB         |
| `alb_subnets`           | `list(string)` | Subnets for ALB                 |
| `alb_tg_port`           | `number`       | Target group port               |
| `alb_tg_protocol`       | `string`       | Target group protocol           |
| `alb_listener_port`     | `number`       | ALB listener port               |
| `alb_listener_protocol` | `string`       | ALB listener protocol           |

### EC2 Variables
| Name                        | Type     | Default                   | Description                     |
| --------------------------- | -------- | ------------------------- | ------------------------------- |
| `ec2_ami_id`                | `string` | `"ami-0ec3e36ea5ad3df41"` | ECS-optimized AMI ID            |
| `ec2_instance_type`         | `string` | `"c1.medium"`             | EC2 instance type               |
| `ec2_instance_profile_name` | `string` | `""`                      | EC2 instance profile name       |
| `asg_desired_capacity`      | `number` | `1`                       | Desired number of EC2 instances |
| `asg_min_size`              | `number` | `1`                       | Minimum number of EC2 instances |
| `asg_max_size`              | `number` | `1`                       | Maximum number of EC2 instances |

---

## Outputs

Name	Description
ecs_cluster_id	ID of the ECS cluster
ecs_target_groups	ALB Target Group(s) created for the cluster

---

## Notes

If Fargate is selected, EC2-related resources (launch template, ASG) will not be created.
Ensure the EC2 instance profile used has sufficient IAM permissions (e.g., ECS registration, CloudWatch logs).
ECS task definitions and services must be defined separately.
The ALB listener uses a basic forward rule to the target group and assumes the container exposes the defined port.

---

## Considerations

## ECS Configuration Options:

### Batch Job Scheduler
This is the default configuration. This is useful for setting up a scheduler 
to run batch jobs that don't need to be run as web services. Build cron jobs or 
a simple script that an AWS Lambda might not be appropriate for. 


### Service Container Platform
This can be set up by specifying `enable_alb` = true. Set this variable, and 
then setany other vars that you need to specify ALB configuration. Use this 
version of theconfiguration to set up containers that are run as services. This 
configuration isideal for deploying containerized microservices. Running an 
ALB will incur additional costs.


## EC2 vs Fargate (serverless)
You can specify which type of service you want the cluster to run under. Specify 
the `service_launch_type` variable as either `EC2` or `FARGATE`.

### EC2 
EC2 instances are likely to cost more since they run constantly and have an 
hourly cost. They are often faster since there is no cold start time 
associated with them that would increase latency. 

### Fargate
Fargate is a serverless compute option that runs your container on demand. It 
will cost less than a similar workload running on an EC2 instance. It may, 
however, have a coldstart time that adds to the latency of response time from 
the service running on the container.

