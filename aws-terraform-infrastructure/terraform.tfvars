# vpc
vpc_name           = "orcharino-vpc"
vpc_cidr           = "10.0.0.0/16"
vpc_azs            = ["eu-central-1a", "eu-central-1b"]
vpc_public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
enable_nat_gateway = false
enable_vpn_gateway = false


#EC2

ec2_name = "orcharino-on-aws"
ec2_image = "ami-0cfdf91ea903a6111" #Rocky8 
ec2_instance_type = "t3a.medium" #4cores 16gb ram
ec2_key_name = "orcharino"
ec2_monitoring = false
