variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_cidr_blocks" {
  description = "Allowed CIDR blocks for SSH"
  type        = list(string)
  # Evil and wrong, but I'm never quite sure what my internet is
  default     = ["0.0.0.0/0"]
}

variable "docker_image" {
  description = "Docker image to run"
  type        = string
}
