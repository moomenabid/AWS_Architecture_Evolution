# AWS Architecture Evolution
In this project we are going to evolve the architecture of a popular web application wordpress. The architecture will start with a manually built single instance, running the application and database, over the stages of the project we will evolve this until its a scalable and resilient architecture.  

The project consists of 6 stages, each implementing additional components of the architecture. 

Here is an overview of what we will do:

- Stage 1 - Setup the environment and manually build wordpress  
- Stage 2 - Automate the build using a Launch Template  
- Stage 3 - Split out the DB into RDS and Update the LT 
- Stage 4 - Split out the WP filesystem into EFS and Update the LT
- Stage 5 - Enable elasticity via a ASG & ALB
- Stage 6 - Cleanup

# STAGE 1 - Setup the environment and manually build wordpress
In stage 1 of this advanced project we will:
- Setup the environment which WordPress will run from. 
- Configure some SSM Parameters which the manual and automatic stages of this advanced project series will use
- and perform a manual install of wordpress and a database on the same EC2 instance. 

This is the starting point .. the common wordpress configuration which we will evolve over the coming project stages.

## STAGE 1A - Login to an AWS Account 
We need to login to an AWS account using a user with admin privileges (we need to donwload the corresponding access_key and secret_key and use them within our terraform code) and ensure our region is set to `us-east-1` `N. Virginia` region.  
Here is the corresponding terraform code
```terraform
provider "aws" {
  region = "us-east-1"
  access_key = "Access_Key_Example"
  secret_key = "Secret_Key_Example"
}
```
Then we have to go inside the folder **terraform_script_vpc** to launch the VPC and the infrastructure which WordPress will run from
To do that, we need to execute the following command
```powershell
terraform apply -auto-approve
```

Then we wait for the Apply to complete before continuing.
## STAGE 1B - Create an EC2 Instance to run wordpress
Now that we have our VPC, security groups, SSM parameters and infrastructure installed, here is what we will do to create an EC2 Instance to run wordpress:  
We select a `Free tier eligible` EC2 instance, we then select a public subnet from the VPC  we have just created via terraform, we then select the security group and instance profile role created via terraform.  
We then launch the instance.  
## STAGE 1C - Create SSM Parameter Store values for wordpress
Storing configuration information within the SSM Parameter store scales much better than attempting to script them in some way.
We have already created the necessary SSM parameters when we have run the previous terraform apply command 
## STAGE 1D - Connect to the instance and install wordpress
To do this, we will:  
Connect to the instance using `Session Manager`  

Ince connected to the machine, we switch to the root user and here is what we do next:  
### Bring in the parameter values from SSM
```
DBPassword=$(aws ssm get-parameters --region us-east-1 --names /ADP/Wordpress/DBPassword --with-decryption --query Parameters[0].Value)
DBPassword=`echo $DBPassword | sed -e 's/^"//' -e 's/"$//'`

DBRootPassword=$(aws ssm get-parameters --region us-east-1 --names /ADP/Wordpress/DBRootPassword --with-decryption --query Parameters[0].Value)
DBRootPassword=`echo $DBRootPassword | sed -e 's/^"//' -e 's/"$//'`

DBUser=$(aws ssm get-parameters --region us-east-1 --names /ADP/Wordpress/DBUser --query Parameters[0].Value)
DBUser=`echo $DBUser | sed -e 's/^"//' -e 's/"$//'`

DBName=$(aws ssm get-parameters --region us-east-1 --names /ADP/Wordpress/DBName --query Parameters[0].Value)
DBName=`echo $DBName | sed -e 's/^"//' -e 's/"$//'`

DBEndpoint=$(aws ssm get-parameters --region us-east-1 --names /ADP/Wordpress/DBEndpoint --query Parameters[0].Value)
DBEndpoint=`echo $DBEndpoint | sed -e 's/^"//' -e 's/"$//'`

```

### Install Pre-Reqs and start some services

```
sudo dnf install wget php-mysqlnd httpd php-fpm php-mysqli mariadb105-server php-json php php-devel stress -y
sudo systemctl enable httpd
sudo systemctl enable mariadb
sudo systemctl start httpd
sudo systemctl start mariadb

```

### Set the MariaDB Root Password

```
sudo mysqladmin -u root password $DBRootPassword
```

### Download and extract Wordpress

```
sudo wget http://wordpress.org/latest.tar.gz -P /var/www/html
cd /var/www/html
sudo tar -zxvf latest.tar.gz
sudo cp -rvf wordpress/* .
sudo rm -R wordpress
sudo rm latest.tar.gz
```
### Configure the wordpress wp-config.php file 

```
sudo cp ./wp-config-sample.php ./wp-config.php
sudo sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
sudo sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
sudo sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php
```
### Fix Permissions on the filesystem

```
sudo usermod -a -G apache ec2-user   
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www
sudo find /var/www -type d -exec chmod 2775 {} \;
sudo find /var/www -type f -exec chmod 0664 {} \;
```
### Create Wordpress User, set its password, create the database and configure permissions

```
sudo echo "CREATE DATABASE $DBName;" >> /tmp/db.setup
sudo echo "CREATE USER '$DBUser'@'localhost' IDENTIFIED BY '$DBPassword';" >> /tmp/db.setup
sudo echo "GRANT ALL ON $DBName.* TO '$DBUser'@'localhost';" >> /tmp/db.setup
sudo echo "FLUSH PRIVILEGES;" >> /tmp/db.setup
sudo mysql -u root --password=$DBRootPassword < /tmp/db.setup
sudo rm /tmp/db.setup
```

### Test Wordpress is installed
Open the `IPv4 Public IP` of the instance  in a new tab  
We should see the wordpress welcome page  

## STAGE 1 - FINISH  
We can now move to stage 2

# Stage 2 - Automate the build using a Launch Template  
In stage 2 of this project we are going to create a launch template which can automate the build of WordPress.
The architecture will still use the single instance for both the WordPress application and database, the only change will be an automatic build rather than manual.  

Before proceeding, we delete the instance we created manually in the previous step.  

## STAGE 2A - Create the Launch Template
We created the launch template by applying this terraform code
```terraform
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
```
What we did here is we created a launch template from the free tier `Amazon Machine Image` called `Amazon Linux 2023 AMI`, we then provided the instance with the right `security group` called `ADPVPC-SGWordpress` and the right `IAM instance profile` called `ADPVPC-WordpressInstanceProfile`  

## STAGE 2B - Add Userdata
We then added the configuration which will build the instance from the local file "C:\Users\user\Desktop\project_architecture_evolution\user_data.sh", this file when executed at the first launch of the instance provides the wordpress installation we did manually in the previous stage, here is the content of this file.  
```
#!/bin/bash -xe

DBPassword=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/DBPassword --with-decryption --query Parameters[0].Value)
DBPassword=`echo $DBPassword | sed -e 's/^"//' -e 's/"$//'`

DBRootPassword=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/DBRootPassword --with-decryption --query Parameters[0].Value)
DBRootPassword=`echo $DBRootPassword | sed -e 's/^"//' -e 's/"$//'`

DBUser=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/DBUser --query Parameters[0].Value)
DBUser=`echo $DBUser | sed -e 's/^"//' -e 's/"$//'`

DBName=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/DBName --query Parameters[0].Value)
DBName=`echo $DBName | sed -e 's/^"//' -e 's/"$//'`

DBEndpoint=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/DBEndpoint --query Parameters[0].Value)
DBEndpoint=`echo $DBEndpoint | sed -e 's/^"//' -e 's/"$//'`

dnf -y update

dnf install wget php-mysqlnd httpd php-fpm php-mysqli mariadb105-server php-json php php-devel stress -y

systemctl enable httpd
systemctl enable mariadb
systemctl start httpd
systemctl start mariadb

mysqladmin -u root password $DBRootPassword

wget http://wordpress.org/latest.tar.gz -P /var/www/html
cd /var/www/html
tar -zxvf latest.tar.gz
cp -rvf wordpress/* .
rm -R wordpress
rm latest.tar.gz

sudo cp ./wp-config-sample.php ./wp-config.php
sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php
sed -i "s/'localhost'/'$DBEndpoint'/g" wp-config.php

usermod -a -G apache ec2-user   
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

echo "CREATE DATABASE $DBName;" >> /tmp/db.setup
echo "CREATE USER '$DBUser'@'localhost' IDENTIFIED BY '$DBPassword';" >> /tmp/db.setup
echo "GRANT ALL ON $DBName.* TO '$DBUser'@'localhost';" >> /tmp/db.setup
echo "FLUSH PRIVILEGES;" >> /tmp/db.setup
mysql -u root --password=$DBRootPassword < /tmp/db.setup
rm /tmp/db.setup


```

## STAGE 2C - Launch an instance using it
We then went to aws console and did the following to launch an instance from the template we just created:   
Select the launch template  called `Wordpress`  
Click `Actions` and `Launch instance from template`
Scroll down to `Network settings` and under `Subnet` select `sn-pub-A`  
Scroll to `Resource Tags` click `Add tag`, set `Key` to `Name` and `Value` to `Wordpress-LT` (this is useful to know the instances we launched from Launch template)
Click `Launch Instance`  
## STAGE 2D - Test
*we wait until the instance is running with 2/2 status checks before contuining*  

We then open the `IPv4 Public IP` in a new tab  
We then see the WordPress welcome page  







