# Security Group allowing application traffic on port 8080 and administrative SSH
resource "aws_security_group" "taskflow_sg" {
  name        = "taskflow-api-sg-${var.environment}"
  description = "Security group for taskflow-api host allowing port 8080 and secure administration"

  ingress {
    description = "Allow inbound HTTP application traffic on port 8080"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = var.app_allowed_cidrs
  }

  ingress {
    description = "Allow restricted inbound SSH management traffic from designated CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  egress {
    description      = "Allow outbound internet traffic for package updates and container image pulls"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "taskflow-sg-${var.environment}"
    Environment = var.environment
  }
}

# Provisioned EC2 Compute Instance for taskflow-api host
resource "aws_instance" "taskflow_host" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.taskflow_sg.id]
  monitoring             = true

  # Enforce IMDSv2 to remediate security scan findings (tfsec AWS079 / checkov CKV_AWS_79)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Enforce encrypted root volume to remediate security scan findings (tfsec AWS005 / checkov CKV_AWS_8)
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20
    tags = {
      Name = "taskflow-root-volume"
    }
  }

  tags = {
    Name        = "taskflow-host-${var.environment}"
    Environment = var.environment
    Service     = "taskflow-api"
  }
}
