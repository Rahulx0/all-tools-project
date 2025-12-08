data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}



resource "random_id" "random_node_id" {
  byte_length = 2
  count       = var.main_instance_count
}

resource "aws_key_pair" "deployer_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "web_server" {
  count                  = var.main_instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet[count.index].id
  key_name               = aws_key_pair.deployer_key.key_name
  vpc_security_group_ids = [aws_security_group.project_security_group_1.id]
  tags = {
    Name = "web-server-${random_id.random_node_id[count.index].dec}"
  }
  provisioner "local-exec" {
command = "printf '\\n${self.public_ip}' >> aws_hosts"    
  }
  provisioner "local-exec" {
    when = destroy
    command = "sed -i '/^[0-9]/d' aws_hosts"
  }
}

resource "null_resource" "grafana_provisioner" {
  depends_on = [aws_instance.web_server]
  triggers = {
    always_run = timestamp()
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.web_server[0].public_ip
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      timeout     = "5m"
    }
    inline = ["echo \"Connection test successful ! Instance is reachable via SSH\""]
  } 

  provisioner "local-exec" {
    command = "ansible -i aws_hosts all -u ubuntu --private-key ${var.private_key_path} -m ping"
  }
  provisioner "local-exec" {
    // Add user and private key arguments
    command = "ansible-playbook -i aws_hosts -u ubuntu --private-key ${var.private_key_path} grafana.yml"
  }
  provisioner "local-exec" {
    // Add user and private key arguments
    command = "ansible-playbook -i aws_hosts -u ubuntu --private-key ${var.private_key_path} install_prometheus.yml"
  }
}