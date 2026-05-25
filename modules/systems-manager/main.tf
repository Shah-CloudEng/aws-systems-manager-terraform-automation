# SSM Document for Apache Installation and Configuration
resource "aws_ssm_document" "install_apache" {
  name            = "${var.project_name}-Install-Apache"
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Full server configuration: Apache, cloudadmin user, app directory, firewall"
    parameters    = {}
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "ConfigureServer"
        inputs = {
          runCommand = [
            "#!/bin/bash",
            "echo '===== Starting server configuration at '$(date)' ====='",
            "",
            "# ── Phase 4: Update OS ──────────────────────────────────────",
            "echo '[1/7] Updating OS packages...'",
            "dnf update -y",
            "",
            "# ── Phase 4 & 5: Install and start Apache ───────────────────",
            "echo '[2/7] Installing Apache...'",
            "dnf install -y httpd",
            "systemctl enable httpd",
            "systemctl start httpd",
            "echo 'Apache status:'",
            "systemctl is-active httpd",
            "",
            "# ── Phase 4 & 5: Firewall – open ports 80 and 443 ──────────",
            "echo '[3/7] Configuring firewall...'",
            "dnf install -y firewalld",
            "systemctl enable firewalld",
            "systemctl start firewalld",
            "firewall-cmd --permanent --add-service=http",
            "firewall-cmd --permanent --add-service=https",
            "firewall-cmd --reload",
            "echo 'Open firewall services:'",
            "firewall-cmd --list-services",
            "",
            "# ── Phase 6: Create cloudadmin user with sudo ────────────────",
            "echo '[4/7] Creating cloudadmin user...'",
            "if ! id cloudadmin &>/dev/null; then",
            "  useradd -m -s /bin/bash cloudadmin",
            "  usermod -aG wheel cloudadmin",
            "  echo 'cloudadmin created and added to wheel group'",
            "else",
            "  echo 'cloudadmin already exists'",
            "fi",
            "echo 'cloudadmin groups:'",
            "groups cloudadmin",
            "",
            "# ── Phase 6: Create application directory ───────────────────",
            "echo '[5/7] Creating application directory /var/www/internal-app...'",
            "mkdir -p /var/www/internal-app",
            "chown cloudadmin:apache /var/www/internal-app",
            "chmod 755 /var/www/internal-app",
            "",
            "# ── Phase 6: Get instance metadata (IMDSv2) ─────────────────",
            "echo '[6/7] Fetching instance metadata...'",
            "TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600')",
            "INSTANCE_ID=$(curl -s -H \"X-aws-ec2-metadata-token: $TOKEN\" http://169.254.169.254/latest/meta-data/instance-id)",
            "PRIVATE_IP=$(curl -s -H \"X-aws-ec2-metadata-token: $TOKEN\" http://169.254.169.254/latest/meta-data/local-ipv4)",
            "AZ=$(curl -s -H \"X-aws-ec2-metadata-token: $TOKEN\" http://169.254.169.254/latest/meta-data/placement/availability-zone)",
            "HOSTNAME=$(hostname)",
            "DEPLOY_TIME=$(date '+%Y-%m-%d %H:%M:%S UTC')",
            "",
            "# ── Phase 6: Write HTML to /var/www/internal-app ────────────",
            "echo '[7/7] Writing HTML page...'",
            "cat > /var/www/internal-app/index.html <<HTMLEOF",
            "<!DOCTYPE html>",
            "<html lang='en'>",
            "<head>",
            "  <meta charset='UTF-8'>",
            "  <title>AWS SSM - Linux Automation Capstone</title>",
            "  <style>",
            "    * { margin:0; padding:0; box-sizing:border-box; }",
            "    body { font-family:'Segoe UI',sans-serif; background:linear-gradient(135deg,#667eea,#764ba2); min-height:100vh; display:flex; align-items:center; justify-content:center; padding:20px; }",
            "    .container { background:white; border-radius:15px; box-shadow:0 20px 60px rgba(0,0,0,.3); padding:40px; max-width:720px; width:100%; }",
            "    h1 { color:#667eea; font-size:2em; margin-bottom:6px; }",
            "    .sub { color:#666; margin-bottom:28px; }",
            "    .success { background:#d4edda; border:1px solid #c3e6cb; border-radius:8px; padding:14px 20px; margin-bottom:20px; color:#155724; font-weight:bold; font-size:1.1em; }",
            "    .card { background:#f8f9fa; border-left:4px solid #667eea; padding:13px 18px; margin:10px 0; border-radius:5px; }",
            "    .label { font-weight:bold; color:#333; display:inline-block; width:170px; }",
            "    .value { color:#667eea; font-family:monospace; }",
            "    .badge { display:inline-block; background:#28a745; color:white; padding:5px 16px; border-radius:20px; margin-top:18px; margin-right:8px; font-size:.9em; }",
            "    .badge2 { background:#17a2b8; }",
            "    .footer { text-align:center; margin-top:24px; color:#999; font-size:.85em; }",
            "  </style>",
            "</head>",
            "<body>",
            "  <div class='container'>",
            "    <h1>AWS Systems Manager</h1>",
            "    <div class='sub'>Linux Fleet Automation Capstone &mdash; Production Fleet</div>",
            "    <div class='success'>Deployment Successful! Server is live and managed by SSM.</div>",
            "    <div class='card'><span class='label'>Instance ID:</span><span class='value'>$INSTANCE_ID</span></div>",
            "    <div class='card'><span class='label'>Hostname:</span><span class='value'>$HOSTNAME</span></div>",
            "    <div class='card'><span class='label'>Private IP:</span><span class='value'>$PRIVATE_IP</span></div>",
            "    <div class='card'><span class='label'>Availability Zone:</span><span class='value'>$AZ</span></div>",
            "    <div class='card'><span class='label'>Deployed At:</span><span class='value'>$DEPLOY_TIME</span></div>",
            "    <div class='card'><span class='label'>Team:</span><span class='value'>DevOps Automation Team</span></div>",
            "    <span class='badge'>Managed by AWS SSM</span>",
            "    <span class='badge badge2'>No SSH Used</span>",
            "    <div class='footer'>Deployed via Terraform &amp; SSM Run Command &mdash; No User Data, No Manual Config</div>",
            "  </div>",
            "</body>",
            "</html>",
            "HTMLEOF",
            "",
            "# Also serve from default Apache root so ALB health check passes",
            "cp /var/www/internal-app/index.html /var/www/html/index.html",
            "",
            "# Set ownership and permissions",
            "chown -R cloudadmin:apache /var/www/internal-app",
            "chmod 644 /var/www/internal-app/index.html",
            "chown apache:apache /var/www/html/index.html",
            "chmod 644 /var/www/html/index.html",
            "",
            "# ── Validation ───────────────────────────────────────────────",
            "echo '===== Validation ====='",
            "echo 'Apache:' $(systemctl is-active httpd)",
            "echo 'Firewall:' $(systemctl is-active firewalld)",
            "echo 'Open ports:' $(firewall-cmd --list-services)",
            "echo 'cloudadmin groups:' $(groups cloudadmin)",
            "echo 'App dir:' $(ls -la /var/www/internal-app/)",
            "echo 'Localhost test:' $(curl -s -o /dev/null -w '%%{http_code}' http://localhost/)",
            "echo '===== Configuration complete at '$(date)' ====='"
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

# SSM Association — runs on all instances tagged Project=LinuxAutomation
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
