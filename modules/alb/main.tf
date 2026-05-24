# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = true
  enable_cross_zone_load_balancing = true
  idle_timeout                     = var.idle_timeout

  # Access logs (optional - can be enabled later)
  access_logs {
    bucket  = var.s3_logs_bucket
    prefix  = "alb-access-logs"
    enabled = false # Set to true to enable access logs
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ALB"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "LoadBalancer"
  }
}

# Target Group for EC2 Web Servers
resource "aws_lb_target_group" "web_servers" {
  name     = "${var.project_name}-${var.environment}-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
  }

  # Deregistration delay
  deregistration_delay = 30

  # Stickiness configuration (optional)
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-TG"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "TargetGroup"
  }

  # Lifecycle
  lifecycle {
    create_before_destroy = true
  }
}

# Target Group Attachments - Register EC2 Instances
resource "aws_lb_target_group_attachment" "web_servers" {
  count = length(var.instance_ids)

  target_group_arn = aws_lb_target_group.web_servers.arn
  target_id        = var.instance_ids[count.index]
  port             = 80
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_servers.arn
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-HTTP-Listener"
    Project     = var.project_name
    Environment = var.environment
  }
}

# HTTPS Listener (Optional - requires ACM certificate)
# Uncomment when you have an SSL certificate

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web_servers.arn
#   }
#
#   tags = {
#     Name        = "${var.project_name}-${var.environment}-HTTPS-Listener"
#     Project     = var.project_name
#     Environment = var.environment
#   }
# }

# HTTP to HTTPS Redirect (Optional)
# Uncomment when you have HTTPS configured

# resource "aws_lb_listener" "http_redirect" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 80
#   protocol          = "HTTP"
#
#   default_action {
#     type = "redirect"
#
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }
