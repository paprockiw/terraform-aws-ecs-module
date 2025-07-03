# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.platform}-${var.environment}-cluster"
}

# ECS CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.platform}-${var.environment}"
  retention_in_days = var.log_retention_days
}

