# MediCore Application Load Balancer

resource "aws_lb" "application" {
  name               = "medicore-application-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  # Deploy the public-facing ALB across three Availability Zones.
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
    aws_subnet.public_c.id
  ]

  enable_deletion_protection       = false
  drop_invalid_header_fields       = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "medicore-application-alb"
    Tier = "Public"
    Role = "LoadBalancer"
  }
}

# Target Group for the private Web/Application instances

resource "aws_lb_target_group" "application" {
  name        = "medicore-application-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.medicore.id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = "/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "medicore-application-target-group"
    Tier = "Application"
  }
}

# HTTP Listener - redirect all HTTP traffic to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name = "medicore-http-listener"
  }
}

# HTTPS Listener - forward HTTPS traffic to the application target group
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.application.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = "arn:aws:acm:eu-west-2:202102860648:certificate/ab83c4a9-662e-4c7a-bd5e-f7427e7f0388"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }

  tags = {
    Name = "medicore-https-listener"
  }
}