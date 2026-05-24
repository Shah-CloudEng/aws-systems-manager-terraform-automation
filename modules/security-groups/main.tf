# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-ALB-SG"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-ALB-SG"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "LoadBalancer"
  }
}

# ALB Ingress Rule - HTTP from Internet
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP traffic from internet"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  tags = {
    Name = "Allow-HTTP-Internet"
  }
}

# ALB Ingress Rule - HTTPS from Internet (Optional)
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS traffic from internet"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  tags = {
    Name = "Allow-HTTPS-Internet"
  }
}

# ALB Egress Rule - Allow all outbound
resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "Allow-All-Outbound"
  }
}

# Security Group for EC2 Instances
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-EC2-SG"
  description = "Security group for EC2 web servers"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-EC2-SG"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "WebServer"
  }
}

# EC2 Ingress Rule - HTTP from ALB only
resource "aws_vpc_security_group_ingress_rule" "ec2_http_from_alb" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow HTTP traffic from ALB only"

  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"

  tags = {
    Name = "Allow-HTTP-From-ALB"
  }
}

# EC2 Ingress Rule - SSH from allowed CIDR
resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow SSH from specified CIDR"

  cidr_ipv4   = var.allowed_ssh_cidr
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  tags = {
    Name = "Allow-SSH-Restricted"
  }
}

# EC2 Egress Rule - Allow all outbound
resource "aws_vpc_security_group_egress_rule" "ec2_egress" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow all outbound traffic"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "Allow-All-Outbound"
  }
}
