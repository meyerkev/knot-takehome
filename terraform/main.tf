locals {
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}

# Generate a new private key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair using the public key
resource "aws_key_pair" "generated" {
  key_name   = "knot-takehome-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

# Create IAM role for EC2
resource "aws_iam_role" "ec2_ecr_role" {
  name = "ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Create policy for ECR read access
resource "aws_iam_role_policy" "ecr_read_policy" {
  name = "ecr-read-policy"
  role = aws_iam_role.ec2_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage"
        ]
        Resource = [aws_ecr_repository.knot_takehome.arn]
      },
      {
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      }
    ]
  })
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ecr-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

data "aws_ami" "ubuntu_24_04" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  # Canonical's AWS account ID
  owners = ["099720109477"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>5.1.2"

  name = "knot-takehome-vpc"
  cidr = "10.0.0.0/16"

  azs = local.availability_zones

  # TODO: Some regions have more than 4 AZ's
  public_subnets   = [for i, az in local.availability_zones : cidrsubnet("10.0.0.0/16", 8, i)]
  
  enable_dns_hostnames = true
  map_public_ip_on_launch = true
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"

  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu_24_04.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id = module.vpc.public_subnets[0]
  key_name  = aws_key_pair.generated.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ubuntu
              docker run -d -p 80:8000 ${var.docker_image}
              EOF
}