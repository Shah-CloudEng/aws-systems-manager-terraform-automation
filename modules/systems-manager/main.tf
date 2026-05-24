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
            "set -e",
            "",
            "# Log start time",
            "echo \"Starting Apache installation at $(date)\"",
            "",
            "# Update system packages",
            "echo \"Updating system packages...\"",
            "sudo dnf update -y",
            "",
            "# Install Apache HTTP Server",
            "echo \"Installing Apache HTTP Server...\"",
            "sudo dnf install -y httpd",
            "",
            "# Enable Apache to start on boot",
            "echo \"Enabling Apache service...\"",
            "sudo systemctl enable httpd",
            "",
            "# Start Apache service",
            "echo \"Starting Apache service...\"",
            "sudo systemctl start httpd",
            "",
            "# Get instance metadata",
            "INSTANCE_ID=$(ec2-metadata --instance-id | cut -d ' ' -f 2)",
            "HOSTNAME=$(hostname)",
            "PRIVATE_IP=$(ec2-metadata --local-ipv4 | cut -d ' ' -f 2)",
            "AZ=$(ec2-metadata --availability-zone | cut -d ' ' -f 2)",
            "",
            "# Create dynamic index.html with instance information",
            "echo \"Creating dynamic index.html...\"",
            "cat <<EOF | sudo tee /var/www/html/index.html",
            "<!DOCTYPE html>",
            "<html lang='en'>",
            "<head>",
            "    <meta charset='UTF-8'>",
            "    <meta name='viewport' content='width=device-width, initial-scale=1.0'>",
            "    <title>AWS Systems Manager - Linux Automation</title>",
            "    <style>",
            "        * { margin: 0; padding: 0; box-sizing: border-box; }",
            "        body {",
            "            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;",
            "            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);",
            "            min-height: 100vh;",
            "            display: flex;",
            "            align-items: center;",
            "            justify-content: center;",
            "            padding: 20px;",
            "        }",
            "        .container {",
            "            background: white;",
            "            border-radius: 15px;",
            "            box-shadow: 0 20px 60px rgba(0,0,0,0.3);",
            "            padding: 40px;",
            "            max-width: 700px;",
            "            width: 100%;",
            "        }",
            "        h1 {",
            "            color: #667eea;",
            "            margin-bottom: 10px;",
            "            font-size: 2.5em;",
            "        }",
            "        .subtitle {",
            "            color: #666;",
            "            margin-bottom: 30px;",
            "            font-size: 1.1em;",
            "        }",
            "        .info-card {",
            "            background: #f8f9fa;",
            "            border-left: 4px solid #667eea;",
            "            padding: 15px 20px;",
            "            margin: 15px 0;",
            "            border-radius: 5px;",
            "        }",
            "        .info-label {",
            "            font-weight: bold;",
            "            color: #333;",
            "            display: inline-block;",
            "            width: 150px;",
            "        }",
            "        .info-value {",
            "            color: #667eea;",
            "            font-family: 'Courier New', monospace;",
            "        }",
            "        .badge {",
            "            display: inline-block;",
            "            background: #28a745;",
            "            color: white;",
            "            padding: 5px 15px;",
            "            border-radius: 20px;",
            "            font-size: 0.9em;",
            "            margin-top: 20px;",
            "        }",
            "        .footer {",
            "            text-align: center;",
            "            margin-top: 30px;",
            "            color: #999;",
            "            font-size: 0.9em;",
            "        }",
            "    </style>",
            "</head>",
            "<body>",
            "    <div class='container'>",
            "        <h1>🚀 AWS Systems Manager</h1>",
            "        <div class='subtitle'>Linux Automation Project - Production Environment</div>",
            "        ",
            "        <div class='info-card'>",
            "            <span class='info-label'>Hostname:</span>",
            "            <span class='info-value'>$HOSTNAME</span>",
            "        </div>",
            "        ",
            "        <div class='info-card'>",
            "            <span class='info-label'>Instance ID:</span>",
            "            <span class='info-value'>$INSTANCE_ID</span>",
            "        </div>",
            "        ",
            "        <div class='info-card'>",
            "            <span class='info-label'>Private IP:</span>",
            "            <span class='info-value'>$PRIVATE_IP</span>",
            "        </div>",
            "        ",
            "        <div class='info-card'>",
            "            <span class='info-label'>Availability Zone:</span>",
            "            <span class='info-value'>$AZ</span>",
            "        </div>",
            "        ",
            "        <div class='badge'>✓ Managed by AWS Systems Manager</div>",
            "        ",
            "        <div class='footer'>",
            "            Deployed via Terraform & SSM Automation | No User Data Used",
            "        </div>",
            "    </div>",
            "</body>",
            "</html>",
            "EOF",
            "",
            "# Verify Apache is running",
            "echo \"Verifying Apache status...\"",
            "sudo systemctl status httpd --no-pager",
            "",
            "# Test web server",
            "echo \"Testing web server...\"",
            "curl -s http://localhost/ | head -5",
            "",
            "echo \"Apache installation completed successfully at $(date)\""
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

# SSM Association to apply Apache configuration automatically
resource "aws_ssm_association" "apply_apache_config" {
  name             = aws_ssm_document.install_apache.name
  association_name = "${var.project_name}-Apache-Deployment"

  # Target instances by tag
  targets {
    key    = "tag:Project"
    values = [var.project_name]
  }

  # Output location for command execution logs
  output_location {
    s3_bucket_name = var.s3_bucket_name
    s3_key_prefix  = "ssm-associations/apache-install"
  }

  # Compliance severity
  compliance_severity = "HIGH"

  # Maximum concurrency and error threshold
  max_concurrency = "50%"
  max_errors      = "0"

  parameters = {}

  tags = {
    Name        = "${var.project_name}-Apache-Deployment"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Optional: SSM Activation for on-premises servers (if needed in future)
# Uncomment if you want to manage hybrid environments

# resource "aws_ssm_activation" "hybrid_activation" {
#   name               = "${var.project_name}-Hybrid-Activation"
#   description        = "Activation for on-premises servers"
#   iam_role           = var.iam_role_arn
#   registration_limit = 10
#   
#   tags = {
#     Name        = "${var.project_name}-Hybrid-Activation"
#     Project     = var.project_name
#     Environment = var.environment
#   }
# }
