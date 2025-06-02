variable "region" {
  description = "AWS region"
  type        = string
}

variable "ami" {
  description = "AMI ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_cidr_blocks" {
  description = "Allowed CIDR blocks for SSH"
  type        = list(string)
}

variable "docker_image" {
  description = "Docker image to run"
  type        = string
}
