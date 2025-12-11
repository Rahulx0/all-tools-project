output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_instance.web_server[0].public_ip
}