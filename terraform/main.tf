locals {
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
  
  user_data = <<-EOF
              #!/bin/bash
              echo "Starting setup" >> /tmp/setup.log
              echo $(whoami) >> /tmp/setup.log
              apt-get update && apt-get upgrade -y
              echo "apt-get update and upgrade complete" >> /tmp/setup.log
              apt-get install -y docker.io unzip
              echo "docker.io and unzip installed" >> /tmp/setup.log
              systemctl enable docker
              systemctl start docker
              echo "docker.io started" >> /tmp/setup.log
              usermod -aG docker ubuntu
              echo "Adding user to docker group" >> /tmp/setup.log
              # Install awscli
              echo "Installing awscli" >> /tmp/setup.log
              apt-get install -y curl ca-certificates
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install || .aws/install --update
              rm awscliv2.zip
              rm -rf aws
              echo "awscli setup complete" >> /tmp/setup.log

              # Set up ECR_REPO_URL
              echo "ECR_REPO_URL=${var.ecr_repository_url}" >> /etc/environment
              
              # Login to ECR
              aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.ecr_repository_url}
              
              # Pull and run the container
              docker run -d -p 80:8000 ${var.docker_image}
              echo "container started" >> /tmp/setup.log
              EOF
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
        Resource = [
          "arn:aws:ecr:${var.region}:386145735201:repository/knot-takehome"
        ]
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

  user_data = local.user_data

  lifecycle {
    replace_triggered_by = [terraform_data.user_data_tracker.output]
  }
}

# This resource helps track user_data changes
resource "terraform_data" "user_data_tracker" {
  input = sha256(local.user_data)
}