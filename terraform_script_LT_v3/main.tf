provider "aws" {
  region = "us-east-1"
  access_key = "ACCESS_KEY_EXAMPLE"
  secret_key = "SECRET_KEY_EXAMPLE"
}

#1 data needed
data "aws_launch_template" "Wordpress" {
  name = "Wordpress"
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

#2 Create load balancer
resource "aws_lb" "ADPWORDPRESSALB" {
  name               = "ADPWORDPRESSALB"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  subnets            = [data.aws_subnet.sn-web-A.id, data.aws_subnet.sn-web-B.id, data.aws_subnet.sn-web-C.id]
  security_groups    = [data.aws_security_group.SGLoadBalancer.id]
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.ADPWORDPRESSALB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ADPWORDPRESSALBTG.arn
  }
}

resource "aws_lb_target_group" "ADPWORDPRESSALBTG" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.adp-vpc1.id
  health_check {
    path = "/"
    protocol = "HTTP"
    
  }
}

resource "aws_ssm_parameter" "ALBDNSNAME" {
  name        = "/ADP/Wordpress/ALBDNSNAME"
  description = "DNS Name of the Application Load Balancer for wordpress "
  type        = "String"
  value       = aws_lb.ADPWORDPRESSALB.dns_name
}

#3 Create autoscaling group
resource "aws_autoscaling_group" "ASG" {
  name                      = "ADPWORDPRESSASG"
  vpc_zone_identifier       = [data.aws_subnet.sn-web-A.id, data.aws_subnet.sn-web-B.id, data.aws_subnet.sn-web-C.id]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  #enabled_metrics           = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupInServiceCapacity", "GroupPendingInstances", "GroupPendingCapacity", "GroupTerminatingInstances", "GroupTerminatingCapacity", "GrouingCapacity", "WarmPoolWarmedCapacity", "WarmPoolTotalCapacity", "GroupAndWarmPoolDesiredCapacity", "GroupAndWarmPoolTotalCapacity"] #["Granularity"]
  desired_capacity   = 1
  max_size           = 3
  min_size           = 1
  tag {
    key                 = "Name"
    value               = "Wordpress-ASG"
    propagate_at_launch = true
  }

  launch_template {
    id      = data.aws_launch_template.Wordpress.id
    version = "$Latest"
  }
}

#4 Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "TG-ASG-Attach" {
  autoscaling_group_name = aws_autoscaling_group.ASG.id
  lb_target_group_arn    = aws_lb_target_group.ADPWORDPRESSALBTG.arn
}

#5 autoscaling policies
resource "aws_autoscaling_policy" "wordpresshighcpu" {
  name                   = "wordpresshighcpu"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ASG.name
}

resource "aws_autoscaling_policy" "wordpresslowcpu" {
  name                   = "wordpresslowcpu"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ASG.name
}

#6 cloudwatch alarms
resource "aws_cloudwatch_metric_alarm" "alarm_highcpu" {
  alarm_name          = "alarm_highcpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 40
  alarm_actions     = [aws_autoscaling_policy.wordpresshighcpu.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ASG.name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_lowcpu" {
  alarm_name          = "alarm_lowcpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 40
  alarm_actions     = [aws_autoscaling_policy.wordpresslowcpu.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ASG.name
  }
}