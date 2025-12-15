output "instance_public_ip" {
  value = aws_instance.web_server[0].public_ip
}

output "instance_id" {
  value = aws_instance.web_server[0].id
}