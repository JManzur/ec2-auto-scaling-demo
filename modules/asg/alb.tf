resource "aws_lb" "app" {
  name                       = "${var.name_prefix}-ALB"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.external.id]
  subnets                    = [var.public_subnet[0], var.public_subnet[1]]
  enable_deletion_protection = false

  tags = { Name = "${var.name_prefix}-ALB" }
}

resource "aws_lb_target_group" "app" {
  count       = 2
  name        = count.index == 0 ? "Farm-1" : "Farm-2"
  port        = var.demo_app["port"]
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  tags = { Name = count.index == 0 ? "Farm-1" : "Farm-2" }

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.demo_app["healthcheck"]
    unhealthy_threshold = "2"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = var.demo_app["port"]
  protocol          = "HTTP"

  tags = { Name = "${var.name_prefix}-Listener" }

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.app[0].arn
        weight = 1 #(Optional) The range is 0 to 999
      }

      target_group {
        arn    = aws_lb_target_group.app[1].arn
        weight = 1 #(Optional) The range is 0 to 999
      }

      stickiness {
        enabled  = false
        duration = 1
      }
    }
  }
}