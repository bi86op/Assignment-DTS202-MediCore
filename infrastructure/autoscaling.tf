# MediCore Web/Application Auto Scaling Group

resource "aws_autoscaling_group" "application" {
  name = "medicore-application-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  # Deploy application instances across the three private subnets.
  vpc_zone_identifier = [
    aws_subnet.private_app_a.id,
    aws_subnet.private_app_b.id,
    aws_subnet.private_app_c.id
  ]

  target_group_arns = [
    aws_lb_target_group.application.arn
  ]

  launch_template {
    id      = aws_launch_template.application.id
    version = "$Latest"
  }

  # EC2 health checks are used initially.
  # This will later be changed to ELB after the ALB is attached.
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "medicore-application-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "MediCore"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "Application"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }
}

# Scale out the application tier by one instance
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "medicore-application-scale-out"
  autoscaling_group_name = aws_autoscaling_group.application.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

