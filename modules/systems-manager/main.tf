# SSM Document for Apache Installation and Configuration
resource "aws_ssm_document" "install_apache" {
  name            = "${var.project_name}-Install-Apache"
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Install and configure Apache web server on Amazon Linux 2023"
    parameters    = {}
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "InstallAndConfigureApache"
        inputs = {
          runCommand = [
            "#!/bin/bash",
            "",
            "echo \"Starting Apache installation at $(date)\"",
            "",
            "# Install and start Apache",
            "dnf update -y",
            "dnf install -y httpd",
            "systemctl enable httpd",
            "systemctl start httpd",
            "",
            "# Get instance metadata using IMDSv2",
            "TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600')",
            "INSTANCE_ID=$(curl -s -H \"X-aws-ec2-metadata-token: $TOKEN\" http://169.254.169.254/latest/meta-data/instance-id)",
            "PRIVATE_IP=$(curl -s -H \"X-aws-ec2-metadata-token: $TOKEN\" http://169.254.169.254/latest/meta-data/local-ipv4)",
            "AZ=$(curl -s -H \"X-aws-ec2-metadata-token: $TOKEN\" http://169.254.169.254/latest/meta-data/placement/availability-zone)",
            "HOSTNAME=$(hostname)",
            "",
            "# Write the HTML page",
            "cat > /var/www/html/index.html <<HTMLEOF",
            "<!DOCTYPE html>",
            "<html lang='en'>",
            "<head>",
            "  <meta charset='UTF-8'>",
            "  <title>AWS Systems Manager - Linux Automation</title>",
            "  <style>",
            "    * { margin: 0; padding: 0; box-sizing: border-box; }",
            "    body { font-family: 'Segoe UI', sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }",
            "    .container { background: white; border-radius: 15px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); padding: 40px; max-width: 700px; width: 100%; }",
            "    h1 { color: #667eea; margin-bottom: 10px; font-size: 2.2em; }",
            "    .subtitle { color: #666; margin-bottom: 30px; font-size: 1.1em; }",
            "    .card { background: #f8f9fa; border-left: 4px solid #667eea; padding: 15px 20px; margin: 12px 0; border-radius: 5px; }",
            "    .label { font-weight: bold; color: #333; display: inline-block; width: 160px; }",
            "    .value { color: #667eea; font-family: monospace; }",
            "    .badge { display: inline-block; background: #28a745; color: white; padding: 5px 15px; border-radius: 20px; margin-top: 20px; }",
            "    .footer { text-align: center; margin-top: 25px; color: #999; font-size: 0.9em; }",
            "  </style>",
            "</head>",
            "<body>",
            "  <div class='container'>",
            "    <h1>AWS Systems Manager</h1>",
            "    <div class='subtitle'>Linux Automation - Production Environment</div>",
            "    <div class='card'><span class='label'>Instance ID:</span><span class='value'>$INSTANCE_ID</span></div>",
            "    <div class='card'><span class='label'>Hostname:</span><span class='value'>$HOSTNAME</span></div>",
            "    <div class='card'><span class='label'>Private IP:</span><span class='value'>$PRIVATE_IP</span></div>",
            "    <div class='card'><span class='label'>Availability Zone:</span><span class='value'>$AZ</span></div>",
            "    <div class='badge'>Managed by AWS Systems Manager</div>",
            "    <div class='footer'>Deployed via Terraform and SSM Automation - No SSH or User Data used</div>",
            "  </div>",
            "</body>",
            "</html>",
            "HTMLEOF",
            "",
            "# Verify",
            "systemctl status httpd --no-pager",
            "echo \"Done at $(date)\""
          ]
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-Install-Apache"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "WebServerAutomation"
  }
}

# SSM Association to run Apache install on all tagged instances
resource "aws_ssm_association" "apply_apache_config" {
  name             = aws_ssm_document.install_apache.name
  association_name = "${var.project_name}-Apache-Deployment"

  targets {
    key    = "tag:Project"
    values = [var.project_name]
  }

  output_location {
    s3_bucket_name = var.s3_bucket_name
    s3_key_prefix  = "ssm-associations/apache-install"
  }

  compliance_severity = "HIGH"
  max_concurrency     = "50%"
  max_errors          = "0"

  tags = {
    Name        = "${var.project_name}-Apache-Deployment"
    Project     = var.project_name
    Environment = var.environment
  }
}
