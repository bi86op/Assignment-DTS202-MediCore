# CloudWatch Alarm 1:
# Detects sustained high CPU utilisation across the application Auto Scaling Group.

resource "aws_cloudwatch_metric_alarm" "app_high_cpu" {
  alarm_name        = "medicore-app-high-cpu"
  alarm_description = "Triggers when average application EC2 CPU utilisation is at least 80 percent for three consecutive minutes."

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 3

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 80

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.application.name
  }

  treat_missing_data = "notBreaching"

  actions_enabled = false

  tags = {
    Name        = "medicore-app-high-cpu"
    Project     = "MediCore"
    Environment = "Development"
    ManagedBy   = "Terraform"
    Tier        = "Application"

  }
}

# CloudWatch Alarm 2:
# Detects failed EC2 status checks across the application Auto Scaling Group.

resource "aws_cloudwatch_metric_alarm" "app_status_check_failed" {
  alarm_name        = "medicore-app-status-check-failed"
  alarm_description = "Triggers when an application EC2 instance reports a failed status check."

  namespace   = "AWS/EC2"
  metric_name = "StatusCheckFailed"
  statistic   = "Maximum"

  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.application.name
  }

  treat_missing_data = "notBreaching"

  actions_enabled = false

  tags = {
    Name        = "medicore-app-status-check-failed"
    Project     = "MediCore"
    Environment = "Development"
    ManagedBy   = "Terraform"
    Tier        = "Application"
  }
}

# CloudWatch Alarm 3:
# Detects unhealthy application targets registered with the ALB target group.

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name        = "medicore-alb-unhealthy-hosts"
  alarm_description = "Triggers when one or more application targets behind the ALB are unhealthy."

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"
  statistic   = "Maximum"

  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1

  dimensions = {
    LoadBalancer = aws_lb.application.arn_suffix
    TargetGroup  = aws_lb_target_group.application.arn_suffix
  }

  treat_missing_data = "notBreaching"

  actions_enabled = false

  tags = {
    Name        = "medicore-alb-unhealthy-hosts"
    Project     = "MediCore"
    Environment = "Development"
    ManagedBy   = "Terraform"
    Tier        = "Application"
  }
}