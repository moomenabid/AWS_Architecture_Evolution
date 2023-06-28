provider "aws" {
  region = "us-east-1"
  access_key = "ACCESS_KEY_EXAMPLE"
  secret_key = "SECRET_KEY_EXAMPLE"
}

#1 create custom vpc with ipv6 and dns enabled
resource "aws_vpc" "adp-vpc1" {
  cidr_block       = "10.16.0.0/16"
  instance_tenancy = "default"
  assign_generated_ipv6_cidr_block = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = "adp-vpc1"
  }
}

locals {
  #This variable is the general ipv6 address format for the subnets based on the cidr of the vpc
  #example: if vpc ipv6 address equals 2600:1f18:638e:1e00::/56 then this local variable equals 2600:1f18:638e:1eXX::/64
  #subnet_addr_pattern        = join("/", [join("", [substr(split("/", aws_vpc.adp-vpc1.ipv6_cidr_block)[0], 0, 17),"XX","::"]), 64])
  subnet_addr_pattern        = join("/", [join("", [substr(split("/", aws_vpc.adp-vpc1.ipv6_cidr_block)[0], 0, length(split("/", aws_vpc.adp-vpc1.ipv6_cidr_block)[0])-4),"XX","::"]), 64])
}

#2 Implement multi-tier VPC subnets with enabling ipv6 (and enabling public ipv4 only for web tiers)

#### Subnets for AZ A
resource "aws_subnet" "sn-reserved-A" {
  vpc_id     = aws_vpc.adp-vpc1.id
  cidr_block = "10.16.0.0/20"
  availability_zone = "us-east-1a"
  ipv6_cidr_block = replace(local.subnet_addr_pattern,"XX","00")
  #ipv6_cidr_block = "2600:1f18:638e:1e00::/64"
  assign_ipv6_address_on_creation = "true"

  tags = {
    Name = "sn-reserved-A"
  }
}

resource "aws_subnet" "sn-db-A" {
  vpc_id     = aws_vpc.adp-vpc1.id
  cidr_block = "10.16.16.0/20"
  availability_zone = "us-east-1a"
  ipv6_cidr_block = replace(local.subnet_addr_pattern,"XX","01")
  assign_ipv6_address_on_creation = "true"

  tags = {
    Name = "sn-db-A"
  }
}

resource "aws_subnet" "sn-app-A" {
  vpc_id     = aws_vpc.adp-vpc1.id
  cidr_block = "10.16.32.0/20"
  availability_zone = "us-east-1a"
  ipv6_cidr_block = replace(local.subnet_addr_pattern,"XX","02")
  assign_ipv6_address_on_creation = "true"

  tags = {
    Name = "sn-app-A"
  }
}

resource "aws_subnet" "sn-web-A" {
  vpc_id     = aws_vpc.adp-vpc1.id
  cidr_block = "10.16.48.0/20"
  availability_zone = "us-east-1a"
  ipv6_cidr_block = replace(local.subnet_addr_pattern,"XX","03")
  assign_ipv6_address_on_creation = "true"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "sn-web-A"
  }
}

#### Subnets for AZ B

resource "aws_subnet" "sn-reserved-B" {
  vpc_id     = aws_vpc.adp-vpc1.id
  cidr_block = "10.16.64.0/20"
  availability_zone = "us-east-1b"
  ipv6_cidr_block = replace(local.subnet_addr_pattern,"XX","04")
  assign_ipv6_address_on_creation = "true"

  tags = {
    Name = "sn-reserved-B"
  }
}

resource "aws_subnet" "sn-db-B" {
  vpc_id     = aws_vpc.adp-vpc1.id
  cidr_block = "10.16.80.0/20"
  availability_zone = "us-east-1b"
  ipv6_cidr_block = replace(local.subnet_addr_pattern,"XX","05")
  assign_ipv6_address_on_creation = "true"

  tags = {
    Name = "sn-db-B"
  }
}

resource "aws_subnet" "sn-app-B" {
  vpc_id     = aws_vpc.adp-vpc1.id
  cidr_block = "10.16.96.0/20"
  availability_zone = "us-east-1b"
  ipv6_cidr_block = replace(local.subnet_addr_pattern,"XX","06")
  assign_ipv6_address_on_creation = "true"

  tags = {
    Name = "sn-app-B"
  }
}

resource "aws_subnet" "sn-web-B" {
  vpc_id     = aws_vpc.adp-vpc1.id
  cidr_block = "10.16.112.0/20"
  availability_zone = "us-east-1b"
  ipv6_cidr_block = replace(local.subnet_addr_pattern,"XX","07")
  assign_ipv6_address_on_creation = "true"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "sn-web-B"
  }
}

#### Subnets for AZ C

resource "aws_subnet" "sn-reserved-C" {
  vpc_id     = aws_vpc.adp-vpc1.id
  cidr_block = "10.16.128.0/20"
  availability_zone = "us-east-1c"
  ipv6_cidr_block = replace(local.subnet_addr_pattern,"XX","08")
  assign_ipv6_address_on_creation = "true"

  tags = {
    Name = "sn-reserved-C"
  }
}

resource "aws_subnet" "sn-db-C" {
  vpc_id     = aws_vpc.adp-vpc1.id
  cidr_block = "10.16.144.0/20"
  availability_zone = "us-east-1c"
  ipv6_cidr_block = replace(local.subnet_addr_pattern,"XX","09")
  assign_ipv6_address_on_creation = "true"

  tags = {
    Name = "sn-db-C"
  }
}

resource "aws_subnet" "sn-app-C" {
  vpc_id     = aws_vpc.adp-vpc1.id
  cidr_block = "10.16.160.0/20"
  availability_zone = "us-east-1c"
  ipv6_cidr_block = replace(local.subnet_addr_pattern,"XX","0a")
  assign_ipv6_address_on_creation = "true"

  tags = {
    Name = "sn-app-C"
  }
}

resource "aws_subnet" "sn-web-C" {
  vpc_id     = aws_vpc.adp-vpc1.id
  cidr_block = "10.16.176.0/20"
  availability_zone = "us-east-1c"
  ipv6_cidr_block = replace(local.subnet_addr_pattern,"XX","0b")
  assign_ipv6_address_on_creation = "true"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "sn-web-C"
  }
}

#3 Create an internet gateway and attach it to vpc 

resource "aws_internet_gateway" "adp-vpc-igw" {

  tags = {
    Name = "adp-vpc-igw"
  }
}

resource "aws_internet_gateway_attachment" "adp-vpc-igw-attach" {
  internet_gateway_id = aws_internet_gateway.adp-vpc-igw.id
  vpc_id              = aws_vpc.adp-vpc1.id
}

#4 Create route table and associate it with public subnets
####Create route table
resource "aws_route_table" "adp-vpc1-rt-web" {
  vpc_id = aws_vpc.adp-vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.adp-vpc-igw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.adp-vpc-igw.id
  }

  tags = {
    Name = "adp-vpc1-rt-web"
  }
}

####Associate route table with public subnets
resource "aws_route_table_association" "rt-sn-web-A" {
  subnet_id      = aws_subnet.sn-web-A.id
  route_table_id = aws_route_table.adp-vpc1-rt-web.id
}

resource "aws_route_table_association" "rt-sn-web-B" {
  subnet_id      = aws_subnet.sn-web-B.id
  route_table_id = aws_route_table.adp-vpc1-rt-web.id
}

resource "aws_route_table_association" "rt-sn-web-C" {
  subnet_id      = aws_subnet.sn-web-C.id
  route_table_id = aws_route_table.adp-vpc1-rt-web.id
}

#5 Creating all necessary security groups

resource "aws_security_group" "SGWordpress" {
  name        = "SGWordpress"
  description = "Control access to Wordpress Instance(s)"
  vpc_id      = aws_vpc.adp-vpc1.id

  ingress {
    description = "Allow HTTP IPv4 IN"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow HTTP IPv4 OUT"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow HTTPS IPv4 OUT"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    description              = "Allow MySQL OUT"
    from_port                = 3306
    to_port                  = 3306
    protocol                 = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description              = "Allow NFS/EFS IPv4 OUT"
    from_port                = 2049
    to_port                  = 2049
    protocol                 = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "SGDatabase" {
  name        = "SGDatabase"
  description = "Control access to Database"
  vpc_id      = aws_vpc.adp-vpc1.id

  ingress {
    description              = "Allow MySQL IN"
    from_port                = 3306
    to_port                  = 3306
    protocol                 = "tcp"
    security_groups = [aws_security_group.SGWordpress.id]
  }
}

resource "aws_security_group" "SGLoadBalancer" {
  name        = "SGLoadBalancer"
  description = "Control access to Load Balancer"
  vpc_id      = aws_vpc.adp-vpc1.id

  ingress {
    description = "Allow HTTP IPv4 IN"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow HTTP IPv4 OUT"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.SGWordpress.id]
  }
}

resource "aws_security_group" "SGEFS" {
  name        = "SGEFS"
  description = "Control access to EFS"
  vpc_id      = aws_vpc.adp-vpc1.id

  ingress {
    description              = "Allow NFS/EFS IPv4 IN"
    from_port                = 2049
    to_port                  = 2049
    protocol                 = "tcp"
    security_groups = [aws_security_group.SGWordpress.id]
  }
}

#6 Create instance profile role for the wordpress EC2 instance
resource "aws_iam_role" "WordpressRole" {
  name               = "WordpressRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess"
  ]
}

resource "aws_iam_instance_profile" "WordpressInstanceProfile" {
  name  = "WordpressInstanceProfile"
  role = aws_iam_role.WordpressRole.name
}

#7 Creating all necessary SSM parameters 
resource "aws_ssm_parameter" "DBUser" {
  name        = "/ADP/Wordpress/DBUser"
  description = "Wordpress Database User"
  type        = "String"
  value       = "adpwordpressuser"
}

resource "aws_ssm_parameter" "DBName" {
  name        = "/ADP/Wordpress/DBName"
  description = "Wordpress Database Name"
  type        = "String"
  value       = "adpwordpressdb"
}

resource "aws_ssm_parameter" "DBEndpoint" {
  name        = "/ADP/Wordpress/DBEndpoint"
  description = "Wordpress Endpoint Name"
  type        = "String"
  value       = "localhost"
}

resource "aws_ssm_parameter" "DBPassword" {
  name        = "/ADP/Wordpress/DBPassword"
  description = "Wordpress DB Password"
  type        = "SecureString"
  value       = "4n1m4l54L1f3"
}

resource "aws_ssm_parameter" "DBRootPassword" {
  name        = "/ADP/Wordpress/DBRootPassword"
  description = "Wordpress DBRoot Password"
  type        = "SecureString"
  value       = "4n1m4l54L1f3"
}

# #8 Create the EC2 instance 
# data "aws_ami" "amazon-linux" {
#   filter {
#     name   = "name"
#     values = ["al2023-ami-2023.0.20230614.0-kernel-6.1-x86_64"]
#     #values = ["amzn2-ami-kernel-5.10-hvm-2.0.20230612.0-x86_64-gp2"]
#   }
# }

# resource "aws_instance" "Wordpress-Manual" {
#   ami           = data.aws_ami.amazon-linux.id # this ami corresponds to the AMI Amazon Linux 
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.sn-web-A.id
#   associate_public_ip_address = "true"
#   ipv6_address_count = 1
#   vpc_security_group_ids = [aws_security_group.SGWordpress.id, aws_security_group.SGWordpress_ssh.id]
#   iam_instance_profile = "${aws_iam_instance_profile.WordpressInstanceProfile.name}"
#   key_name = "A4L"
  
#   tags = {
#     Name = "Wordpress-Manual"
#   }
# }





# #5 Create an EC2 instance to test network access for a public subnet
# #### Create security group
# resource "aws_security_group" "A4L-BASTION-SG" {
#   name        = "A4L-BASTION-SG"
#   description = "A4L-BASTION-SG"
#   vpc_id      = aws_vpc.adp-vpc1.id

#   ingress {
#     description      = "SSH from anywhere"
#     from_port        = 22
#     to_port          = 22
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }
# }

# #### Create EC2 instance in public subnet sn-web-A
# resource "aws_instance" "A4L-BASTION" {
#   ami           = "ami-0889a44b331db0194" # this ami corresponds to the AMI Amazon Linux 2
#   instance_type = "t2.micro"
#   key_name = "A4L"
#   subnet_id     = aws_subnet.sn-web-A.id
#   associate_public_ip_address = "true"
#   ipv6_address_count = 1
#   vpc_security_group_ids = [aws_security_group.A4L-BASTION-SG.id]
  
#   tags = {
#     Name = "A4L-BASTION"
#   }
# }

# #6 Create NAT gateway and attach it to private subnets via routing

# #### Create NAT gateway in public subnet sn-web-A
# resource "aws_eip" "eip-natgw-A" {
  
#   # To ensure proper ordering, we add an explicit dependency on the Internet Gateway for the VPC.
#   depends_on = [aws_internet_gateway.bdp-vpc-igw]
# }

# resource "aws_nat_gateway" "bdp-vpc1-natgw-A" {
#   allocation_id = aws_eip.eip-natgw-A.id
#   subnet_id     = aws_subnet.sn-app-A.id

#   tags = {
#     Name = "bdp-vpc1-natgw-A"
#   }

#   depends_on = [aws_internet_gateway.bdp-vpc-igw]
# }

# #### Create NAT gateway in public subnet sn-web-B
# resource "aws_eip" "eip-natgw-B" {
#   depends_on = [aws_internet_gateway.bdp-vpc-igw]
# }

# resource "aws_nat_gateway" "bdp-vpc1-natgw-B" {
#   allocation_id = aws_eip.eip-natgw-B.id
#   subnet_id     = aws_subnet.sn-app-B.id

#   tags = {
#     Name = "bdp-vpc1-natgw-B"
#   }

#   depends_on = [aws_internet_gateway.bdp-vpc-igw]
# }

# #### Create NAT gateway in public subnet sn-web-C
# resource "aws_eip" "eip-natgw-C" {
#   depends_on = [aws_internet_gateway.bdp-vpc-igw]
# }

# resource "aws_nat_gateway" "bdp-vpc1-natgw-C" {
#   allocation_id = aws_eip.eip-natgw-C.id
#   subnet_id     = aws_subnet.sn-app-C.id

#   tags = {
#     Name = "bdp-vpc1-natgw-C"
#   }

#   depends_on = [aws_internet_gateway.bdp-vpc-igw]
# }

# #7 Create routes for private subnets to make use of NAT gateways

# #### For AZ A
# resource "aws_route_table" "bdp-vpc1-rt-privateA" {
#   vpc_id = aws_vpc.bdp-vpc1.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_nat_gateway.bdp-vpc1-natgw-A.id
#   }
  
#   tags = {
#     Name = "bdp-vpc1-rt-privateA"
#   }
# }

# resource "aws_route_table_association" "rt-sn-app-A" {
#   subnet_id      = aws_subnet.sn-app-A.id
#   route_table_id = aws_route_table.bdp-vpc1-rt-privateA.id
# }

# resource "aws_route_table_association" "rt-sn-db-A" {
#   subnet_id      = aws_subnet.sn-db-A.id
#   route_table_id = aws_route_table.bdp-vpc1-rt-privateA.id
# }

# #### For AZ B
# resource "aws_route_table" "bdp-vpc1-rt-privateB" {
#   vpc_id = aws_vpc.bdp-vpc1.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_nat_gateway.bdp-vpc1-natgw-B.id
#   }
  
#   tags = {
#     Name = "bdp-vpc1-rt-privateB"
#   }
# }

# resource "aws_route_table_association" "rt-sn-app-B" {
#   subnet_id      = aws_subnet.sn-app-B.id
#   route_table_id = aws_route_table.bdp-vpc1-rt-privateB.id
# }

# resource "aws_route_table_association" "rt-sn-db-B" {
#   subnet_id      = aws_subnet.sn-db-B.id
#   route_table_id = aws_route_table.bdp-vpc1-rt-privateB.id
# }

# #### For AZ C
# resource "aws_route_table" "bdp-vpc1-rt-privateC" {
#   vpc_id = aws_vpc.bdp-vpc1.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_nat_gateway.bdp-vpc1-natgw-C.id
#   }
  
#   tags = {
#     Name = "bdp-vpc1-rt-privateC"
#   }
# }

# resource "aws_route_table_association" "rt-sn-app-C" {
#   subnet_id      = aws_subnet.sn-app-C.id
#   route_table_id = aws_route_table.bdp-vpc1-rt-privateC.id
# }

# resource "aws_route_table_association" "rt-sn-db-C" {
#   subnet_id      = aws_subnet.sn-db-C.id
#   route_table_id = aws_route_table.bdp-vpc1-rt-privateC.id
# }

# #8 Create an EC2 instance to test network access from a private subnet
# #### Create EC2 instance in public subnet sn-app-A
# resource "aws_instance" "A4L-INTERNAL-TEST" {
#   ami           = "ami-0889a44b331db0194"
#   instance_type = "t2.micro"
#   key_name = "A4L"
#   subnet_id     = aws_subnet.sn-app-A.id
#   ipv6_address_count = 1
#   vpc_security_group_ids = [aws_security_group.A4L-BASTION-SG.id]
  
#   tags = {
#     Name = "A4L-INTERNAL-TEST"
#   }
# }