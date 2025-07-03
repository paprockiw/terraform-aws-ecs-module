# Resources for EC2--built if specified.

# Launch Template for ECS Instances (Only builds if service_launch_type is EC2)
resource "aws_launch_template" "ec2_launch_template" {
  for_each = var.service_launch_type == "EC2" ? toset(["enabled"]) : toset([])

  name_prefix   = "${var.platform}-${var.environment}-ecs-template"
  image_id      = var.ec2_ami_id
  instance_type = var.ec2_instance_type

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  user_data = base64encode(<<EOF
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name}" >> /etc/ecs/ecs.config
EOF
  )
}

# Auto Scaling Group for ECS Instances (Only builds if service_launch_type is EC2)
resource "aws_autoscaling_group" "ecs_asg" {
  for_each = var.service_launch_type == "EC2" ? toset(["enabled"]) : toset([])

  desired_capacity     = var.asg_desired_capacity
  min_size             = var.asg_min_size
  max_size             = var.asg_max_size
  vpc_zone_identifier  = var.ecs_subnets

  launch_template {
    id      = aws_launch_template.ec2_launch_template["enabled"].id
    version = "$Latest"
  }
}

