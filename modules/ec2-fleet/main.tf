# EC2 Instances for Linux Web Server Fleet
resource "aws_instance" "web_servers" {
  count = var.instance_count

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile_name

  # Disable SSH key pair - using SSM Session Manager instead
  key_name = null

  # Enable detailed monitoring
  monitoring = true

  # Metadata options for IMDSv2 (security best practice)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Root volume configuration (Free Tier: 30 GB total EBS)
  root_block_device {
    volume_type           = "gp2" # gp2 is free tier eligible, gp3 is not
    volume_size           = 30    # Minimum required by Amazon Linux 2023 snapshot
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name        = "${var.project_name}-${var.environment}-WebServer-${count.index + 1}-RootVolume"
      Project     = var.project_name
      Environment = var.environment
    }
  }

  # NO USER DATA - All configuration via Systems Manager
  user_data = null

  # Tags for Systems Manager targeting
  tags = {
    Name        = "${var.project_name}-${var.environment}-WebServer-${count.index + 1}"
    Project     = var.project_name
    Environment = var.environment
    Role        = "WebServer"
    ManagedBy   = "SSM"
    ServerIndex = tostring(count.index + 1)
  }

  # Lifecycle management
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [ami]
  }
}
