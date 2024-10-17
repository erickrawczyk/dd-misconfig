output "instance_public_ips" {
  description = "Public IPs of all EC2 instances"
  value       = [for instance in aws_instance.app_server : instance.public_ip]
}

output "ssh_commands" {
  description = "SSH commands to connect to each EC2 instance"
  value       = [for instance in aws_instance.app_server : "ssh -i private_key.pem ec2-user@${instance.public_ip}"]
}
