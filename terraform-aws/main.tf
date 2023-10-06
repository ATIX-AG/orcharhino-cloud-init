locals {
  user_data = file(var.file_path)
}

resource "random_string" "random" {
  length  = 6
  special = false
}

# VPC

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs            = var.vpc_azs
  public_subnets = var.vpc_public_subnets

  enable_nat_gateway = var.vpc_enable_nat_gateway
  enable_vpn_gateway = var.vpc_enable_vpn_gateway

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


# Security group

resource "aws_security_group" "orcharino" {
  name_prefix = "orcharino-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Orcharhino installer GUI"
    from_port   = 8015
    to_port     = 8015
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# EC2 instance

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name                   = var.ec2_name
  ami                    = var.ec2_image
  instance_type          = var.ec2_instance_type
  key_name               = module.key_pair.key_pair_name
  monitoring             = var.ec2_monitoring
  vpc_security_group_ids = [aws_security_group.orcharino.id]
  subnet_id              = module.vpc.public_subnets[0]

  associate_public_ip_address = true
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 30
    },
  ]

  user_data_base64 = base64encode(local.user_data)

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


# Create EC2 keypair

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "orcharhino-key-${random_string.random.id}"
  create_private_key = true
}

resource "local_sensitive_file" "private_key" {
    content  = module.key_pair.private_key_pem
    filename = "./local/orcharhino-ssh-key-${random_string.random.id}.pem"
    file_permission = "0600"
}


# Create ssh-config

resource local_file "ssh-config" {
  filename = "./local/ssh-config"
  file_permission = "0644"
  content = <<EOT
Host orcharhino
    Hostname ${module.ec2_instance.public_ip}
    User tux
    IdentityFile ${local_sensitive_file.private_key.filename}
EOT
}


# Route53 configuration

#resource "aws_route53_zone" "primary" {
#   name = "example.com"  # Replace with your domain name
#}

#resource "aws_route53_record" "orcharhino" {
#  zone_id = aws_route53_zone.primary.zone_id
#  name    = "www.example.com"
#  type    = "A"
#  ttl     = 300
#  records = ["IP-ADDRESS"]
#}


# Additional /var storage

#resource "aws_volume_attachment" "this" {
#  device_name = "/var"
#  volume_id   = aws_ebs_volume.this.id
#  instance_id = module.ec2.id
#}

#resource "aws_ebs_volume" "this" {
#  availability_zone = element(local.azs, 0)
#  size              = 1
#  tags = local.tags
#}
