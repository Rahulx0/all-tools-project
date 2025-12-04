variable "vpc_cidr" {
    description = "The CIDR block for the VPC"
    type        = string
    default     = "10.124.0.0/16"  
}
variable "access_ip" {
    description = "The IP address allowed to access the resources"
    type        = string
    default     = "0.0.0.0/0"
  
}
variable "instance_type" {
    description = "The type of instance to use for the web server"
    type        = string
    default     = "t2.micro"
}
variable "main_instance_count" {
    description = "Number of main instances to create"
    type        = number
    default     = 1
}
variable "key_name" {
    description = "The name of the key pair"
    type        = string
    default     = "id_rsa"
}
variable "public_key_path" {
    description = "The path to the public key file"
    type        = string
    default     = "~/.ssh/id_rsa.pub"
}
variable "private_key_path" {
    description = "The path to the private key file"
    type        = string
    default     = "~/.ssh/id_rsa"
}
variable "new_hostname" {
    description = "The hostname to set for the instance"
    type        = string
    default     = "web-server"
}

