# ECS optional ALB config
# This is bulit when we specify that we want an ALB for the cluster.

resource "aws_lb" "ecs_alb" {
  count              = var.enable_alb ? 1 : 0
  name               = "${var.platform}-${var.environment}-ecs-alb"
  internal           = var.internal_alb
  load_balancer_type = "application"
  security_groups    = var.alb_ecs_sgs
  subnets            = var.alb_subnets

  tags = {
    Name        = "${var.platform}-${var.environment}-ecs-alb"
    Environment = var.environment
    built_by    = "terraform"
  }
}

resource "aws_lb_target_group" "ecs_tg" {
  count       = var.enable_alb ? 1 : 0
  name        = "${var.platform}-${var.environment}-ecs-tg"
  port        = var.alb_tg_port
  protocol    = var.alb_tg_protocol
  vpc_id      = var.aws_vpc
  target_type = "ip"

  tags = {
    Name        = "${var.platform}-${var.environment}-ecs-tg"
    Environment = var.environment
    built_by    = "terraform"
  }
}

resource "aws_lb_listener" "ecs_listener" {
  count             = var.enable_alb ? 1 : 0
  load_balancer_arn = aws_lb.ecs_alb[0].arn
  port              = var.alb_listener_port
  protocol          = var.alb_listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg[0].arn
  }

  depends_on = [aws_lb_target_group.ecs_tg, aws_lb.ecs_alb]

  tags = {
    Name        = "${var.platform}-${var.environment}-ecs-listener"
    Environment = var.environment
    built_by    = "terraform"
  }
}

