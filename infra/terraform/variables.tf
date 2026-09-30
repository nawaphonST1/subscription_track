variable "aws_region" {
  type        = string
  description = "Target AWS region for infrastructure deployment"
  default     = "us-east-1"
}

variable "aws_access_key" {
  type        = string
  description = "AWS access key (mock key used for LocalStack)"
  default     = "test"
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret key (mock key used for LocalStack)"
  default     = "test"
  sensitive   = true
}

variable "localstack_endpoint" {
  type        = string
  description = "Endpoint URL for LocalStack AWS emulation"
  default     = "http://localhost:4566"
}

variable "environment" {
  type        = string
  description = "Deployment environment name"
  default     = "production"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the host node"
  default     = "t3.medium"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for the Linux host instance"
  default     = "ami-0c7217cdde317cfec" # Canonical Ubuntu 22.04 LTS or mock AMI
}

variable "server_port" {
  type        = number
  description = "Port exposed by taskflow-api service"
  default     = 8080
}

variable "ssh_allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks permitted for SSH management access (restricted for security)"
  default     = ["10.0.0.0/16", "192.168.0.0/16"]
}

variable "app_allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks permitted for HTTP application traffic"
  default     = ["0.0.0.0/0"]
}
