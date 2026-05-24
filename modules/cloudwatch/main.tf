# CloudWatch Log Group for Systems Manager
resource "aws_cloudwatch_log_group" "ssm_logs" {
  name              = "/aws/ssm/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-SSM-LogGroup"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "SSMLogging"
  }
}

# CloudWatch Log Group for EC2 instances
resource "aws_cloudwatch_log_group" "ec2_logs" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-EC2-LogGroup"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "EC2Logging"
  }
}

# CloudWatch Log Stream for SSM Run Command
resource "aws_cloudwatch_log_stream" "ssm_run_command" {
  name           = "ssm-run-command"
  log_group_name = aws_cloudwatch_log_group.ssm_logs.name
}

# CloudWatch Log Stream for SSM Associations
resource "aws_cloudwatch_log_stream" "ssm_associations" {
  name           = "ssm-associations"
  log_group_name = aws_cloudwatch_log_group.ssm_logs.name
}

# CloudWatch Log Stream for Patch Manager
resource "aws_cloudwatch_log_stream" "patch_manager" {
  name           = "patch-manager"
  log_group_name = aws_cloudwatch_log_group.ssm_logs.name
}

# CloudWatch Metric Alarm for EC2 CPU utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-High-CPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors EC2 CPU utilization"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = "${var.project_name}-${var.environment}"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-High-CPU-Alarm"
    Project     = var.project_name
    Environment = var.environment
  }
}

# CloudWatch Metric Alarm for ALB unhealthy targets
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.project_name}-${var.environment}-Unhealthy-Targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alert when ALB has unhealthy targets"
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.project_name}-${var.environment}-Unhealthy-Targets-Alarm"
    Project     = var.project_name
    Environment = var.environment
  }
}

# CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "EC2 CPU Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average" }],
            [".", "RequestCount", { stat = "Sum" }],
            [".", "HealthyHostCount", { stat = "Average" }],
            [".", "UnHealthyHostCount", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "ALB Metrics"
        }
      },
      {
        type = "log"
        properties = {
          query  = "SOURCE '${aws_cloudwatch_log_group.ssm_logs.name}' | fields @timestamp, @message | sort @timestamp desc | limit 20"
          region = data.aws_region.current.name
          title  = "Recent SSM Logs"
        }
      }
    ]
  })
}

# Data source for current region
data "aws_region" "current" {}
