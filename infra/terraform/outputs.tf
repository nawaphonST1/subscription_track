output "instance_id" {
  description = "ID of the provisioned EC2 compute instance"
  value       = aws_instance.taskflow_host.id
}

output "instance_address" {
  description = "Public IP or host address of the provisioned taskflow-api instance"
  value       = coalesce(aws_instance.taskflow_host.public_ip, aws_instance.taskflow_host.private_ip, "127.0.0.1")
}

output "instance_private_ip" {
  description = "Private IP address of the provisioned instance"
  value       = aws_instance.taskflow_host.private_ip
}

output "security_group_id" {
  description = "ID of the security group attached to the host"
  value       = aws_security_group.taskflow_sg.id
}
