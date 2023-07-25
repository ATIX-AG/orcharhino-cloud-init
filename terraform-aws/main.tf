locals {
  user_data = file(var.file_path)
}

#VPC

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs            = var.vpc_azs
  public_subnets = var.vpc_public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

#Security group for the instance

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
  key_name               = var.ec2_key_name
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

# resource "aws_route53_zone" "primary" {
#   name = "example.com" # Replace with your domain name
  
# }

# resource "aws_route53_record" "orcharhino" {
#   zone_id = aws_route53_zone.primary.zone_id
#   name    = "www.example.com"
#   type    = "A"
#   ttl     = 300
#   records = ["IP-ADDRESS"]
# }

# additional /var storage


# resource "aws_volume_attachment" "this" {
#   device_name = "/var"
#   volume_id   = aws_ebs_volume.this.id
#   instance_id = module.ec2.id
# }

# resource "aws_ebs_volume" "this" {
#   availability_zone = element(local.azs, 0)
#   size              = 1

#   tags = local.tags
# }
