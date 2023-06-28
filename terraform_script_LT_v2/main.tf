provider "aws" {
  region = "us-east-1"
  access_key = "ACCESS_KEY_EXAMPLE"
  secret_key = "SECRET_KEY_EXAMPLE"
}

#0 data needed
data "aws_ami" "amazon-linux" {
  filter {
    name   = "name"
    values = ["al2023-ami-2023.0.20230614.0-kernel-6.1-x86_64"]
  }
}

data "aws_security_group" "SGWordpress" {
  name = "SGWordpress"
}

data "aws_iam_instance_profile" "WordpressInstanceProfile" {
  name = "WordpressInstanceProfile"
}

data "aws_security_group" "SGEFS" {
  name = "SGEFS"
}

data "aws_security_group" "SGLoadBalancer" {
  name = "SGLoadBalancer"
}

data "aws_vpc" "adp-vpc1" {
  filter {
    name   = "cidr"
    values = ["10.16.0.0/16"]
  }
}

data "aws_subnet" "sn-web-A" {
  filter {
    name   = "cidr"
    values = ["10.16.48.0/20"]
  }
}

data "aws_subnet" "sn-web-B" {
  filter {
    name   = "cidr"
    values = ["10.16.112.0/20"]
  }
}

data "aws_subnet" "sn-web-C" {
  filter {
    name   = "cidr"
    values = ["10.16.176.0/20"]
  }
}

data "aws_subnet" "sn-db-A" {
  filter {
    name   = "cidr"
    values = ["10.16.16.0/20"]
  }
}

data "aws_subnet" "sn-db-B" {
  filter {
    name   = "cidr"
    values = ["10.16.80.0/20"]
  }
}

data "aws_subnet" "sn-db-C" {
  filter {
    name   = "cidr"
    values = ["10.16.144.0/20"]
  }
}

data "aws_subnet" "sn-app-A" {
  filter {
    name   = "cidr"
    values = ["10.16.32.0/20"]
  }
}

data "aws_subnet" "sn-app-B" {
  filter {
    name   = "cidr"
    values = ["10.16.96.0/20"]
  }
}

data "aws_subnet" "sn-app-C" {
  filter {
    name   = "cidr"
    values = ["10.16.160.0/20"]
  }
}

data "aws_ssm_parameter" "db_master_username" {
  name = "/ADP/Wordpress/DBUser"
}

data "aws_ssm_parameter" "db_master_password" {
  name = "/ADP/Wordpress/DBPassword"
}

data "aws_ssm_parameter" "db_name" {
  name = "/ADP/Wordpress/DBName"
}

data "aws_security_group" "SGDatabase" {
  name = "SGDatabase"
}

#1 create launch template version 1
resource "aws_launch_template" "Wordpress" {
  name = "Wordpress"
  description = "Single Server DB and App"
  image_id = data.aws_ami.amazon-linux.id # this ami corresponds to the AMI Amazon Linux
  instance_type = "t2.micro"
  key_name = "A4L"
  #security_group_names = [data.aws_security_group.SGWordpress.name]
  vpc_security_group_ids = [data.aws_security_group.SGWordpress.id]
  iam_instance_profile {
    name = data.aws_iam_instance_profile.WordpressInstanceProfile.name
  }
  user_data = filebase64("C:\\Users\\user\\Desktop\\project_architecture_evolution\\user_data.sh") 

}


#2 create db subnet group
resource "aws_db_subnet_group" "wordpress_rds_subnet_group" {
  name       = "wordpress_rds_subnet_group"
  description = "RDS Subnet Group for Wordpress"
  #subnet_ids = [data.aws_subnet.sn-web-A.id, data.aws_subnet.sn-web-B.id, data.aws_subnet.sn-web-C.id]
  subnet_ids = [data.aws_subnet.sn-db-A.id, data.aws_subnet.sn-db-B.id, data.aws_subnet.sn-db-C.id]
}

#3 create db instance
resource "aws_db_instance" "adpwordpress" {
  engine               = "mysql"
  engine_version       = "8.0.32"
  identifier           = "adpwordpress"
  username             = data.aws_ssm_parameter.db_master_username.value
  password             = data.aws_ssm_parameter.db_master_password.value
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.wordpress_rds_subnet_group.name
  vpc_security_group_ids = [data.aws_security_group.SGDatabase.id]
  availability_zone      = data.aws_subnet.sn-web-A.availability_zone
  db_name                = data.aws_ssm_parameter.db_name.value
  storage_type           = "gp2"
  allocated_storage      = 20
  skip_final_snapshot  = true
}


#4 create efs and mount points
resource "aws_efs_file_system" "ADP-WORDPRESS-CONTENT" {
  creation_token = "ADP-WORDPRESS-CONTENT"
}

resource "aws_efs_mount_target" "mount_appA" {
  file_system_id = "${aws_efs_file_system.ADP-WORDPRESS-CONTENT.id}"
  subnet_id      = data.aws_subnet.sn-app-A.id
  security_groups = [data.aws_security_group.SGEFS.id] 
}

resource "aws_efs_mount_target" "mount_appB" {
  file_system_id = "${aws_efs_file_system.ADP-WORDPRESS-CONTENT.id}"
  subnet_id      = data.aws_subnet.sn-app-B.id
  security_groups = [data.aws_security_group.SGEFS.id] 
}

resource "aws_efs_mount_target" "mount_appC" {
  file_system_id = "${aws_efs_file_system.ADP-WORDPRESS-CONTENT.id}"
  subnet_id      = data.aws_subnet.sn-app-C.id
  security_groups = [data.aws_security_group.SGEFS.id] 
}

#5 create efs ssm parameter
resource "aws_ssm_parameter" "EFSFSID" {
  name        = "/ADP/Wordpress/EFSFSID"
  description = "File System ID for wordpress content (wp-content)"
  type        = "String"
  value       = aws_efs_file_system.ADP-WORDPRESS-CONTENT.id
}

# #6 Create load balancer
# resource "aws_lb" "A4LWORDPRESSALB" {
#   name               = "A4LWORDPRESSALB"
#   internal           = false
#   load_balancer_type = "application"
#   ip_address_type    = "ipv4"
#   subnets            = [data.aws_subnet.sn-web-A.id, data.aws_subnet.sn-web-B.id, data.aws_subnet.sn-web-C.id]
#   security_groups    = [data.aws_security_group.SGLoadBalancer.id]
# }

# resource "aws_lb_listener" "lb_listener" {
#   load_balancer_arn = aws_lb.A4LWORDPRESSALB.arn
#   port              = "80"
#   protocol          = "HTTP"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.A4LWORDPRESSALBTG.arn
#   }
# }

# resource "aws_lb_target_group" "A4LWORDPRESSALBTG" {
#   name     = "tf-example-lb-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = data.aws_vpc.a4l-vpc1.id
#   health_check {
#     path = "/"
#     protocol = "HTTP"
    
#   }
# }

# resource "aws_ssm_parameter" "ALBDNSNAME" {
#   name        = "/A4L/Wordpress/ALBDNSNAME"
#   description = "DNS Name of the Application Load Balancer for wordpress "
#   type        = "String"
#   value       = aws_lb.A4LWORDPRESSALB.dns_name
# }

# #7 Create autoscaling group
# resource "aws_autoscaling_group" "ASG" {
#   name                      = "A4LWORDPRESSASG"
#   vpc_zone_identifier       = [data.aws_subnet.sn-web-A.id, data.aws_subnet.sn-web-B.id, data.aws_subnet.sn-web-C.id]
#   health_check_type         = "EC2"
#   health_check_grace_period = 300
#   #enabled_metrics           = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupInServiceCapacity", "GroupPendingInstances", "GroupPendingCapacity", "GroupTerminatingInstances", "GroupTerminatingCapacity", "GrouingCapacity", "WarmPoolWarmedCapacity", "WarmPoolTotalCapacity", "GroupAndWarmPoolDesiredCapacity", "GroupAndWarmPoolTotalCapacity"] #["Granularity"]
#   desired_capacity   = 1
#   max_size           = 3
#   min_size           = 1
#   tag {
#     key                 = "Name"
#     value               = "Wordpress-ASG"
#     propagate_at_launch = true
#   }

#   launch_template {
#     id      = data.aws_launch_template.Wordpress.id
#     version = "$Latest"
#   }
# }

# # Create a new ALB Target Group attachment
# resource "aws_autoscaling_attachment" "TG-ASG-Attach" {
#   autoscaling_group_name = aws_autoscaling_group.ASG.id
#   lb_target_group_arn    = aws_lb_target_group.A4LWORDPRESSALBTG.arn
# }

