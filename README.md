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
We open the `IPv4 Public IP` of the instance  in a new tab  
We should see the wordpress welcome page  

## STAGE 1 - FINISH  
We can now move to stage 2

# Stage 2 - Automate the build using a Launch Template  
In stage 2 of this project we are going to create a launch template which can automate the build of WordPress.
The architecture will still use the single instance for both the WordPress application and database, the only change will be an automatic build rather than manual.  

Before proceeding, we delete the instance we created manually in the previous step and we import into terraform all the necessary data of the ressources we have already created in the initial stage via the **data** option field in terraform


## STAGE 2A - Create the Launch Template
We created the launch template by applying this terraform code
```terraform
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

Then we log in and we create a post 

And now we have an auto built WordPress instance
** we won't terminate the instance this time - we're going to migrate the database in stage 3**

## STAGE 2 - FINISH  

This configuration has several limitations :-

- ~~The application and database are built manually, taking time and not allowing automation~~ FIXED
- ~~^^ it was slow and annoying ... that was the intention.~~ FIXED  

- The database and application are on the same instance, neither can scale without the other
- The database of the application is on an instance, scaling IN/OUT risks this media
- The application media and UI store is local to an instance, scaling IN/OUT risks this media
- Customer Connections are to an instance directly ... no health checks/auto healing
- The IP of the instance is hardcoded into the database ....


we can now move onto STAGE3
# Stage 3 - Split out the DB into RDS and Update the LT 
In stage 3 we will be splitting out the database functionality from the EC2 instance .. running MariaDB to an RDS instance running the MySQL Engine.  
This will allow the DB and Instance to scale independently, and will allow the data to be secure past the lifetime of the EC2 instance.  
## STAGE 3A - Create RDS Subnet Group
A subnet group is what allows RDS to select from a range of subnets to put its databases inside  
In this case we will give it a selection of 3 subnets sn-db-A / B and C  
RDS can then decide freely which to use.  

Here is the terraform code used:  
```terraform
#2 create db subnet group
resource "aws_db_subnet_group" "wordpress_rds_subnet_group" {
  name       = "wordpress_rds_subnet_group"
  description = "RDS Subnet Group for Wordpress"
  subnet_ids = [data.aws_subnet.sn-db-A.id, data.aws_subnet.sn-db-B.id, data.aws_subnet.sn-db-C.id]
}
```
## STAGE 3B - Create RDS Instance
In this sub stage of this project, we are going to provision an RDS instance using the subnet group to control placement within the VPC.   
Here is the terraform code
```terraform
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
```
** this will take some time to create ... it will need to be fully ready before we move to the next step **
## STAGE 3C - Migrate WordPress data from MariaDB to RDS
### Populate Environment Variables
We are going to do an export of the SQL database running on the local ec2 instance

First we will run these commands to populate variables with the data from Parameter store  
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

### Take a Backup of the local DB

To take a backup of the database run

```
mysqldump -h $DBEndpoint -u $DBUser -p$DBPassword $DBName > adpWordPress.sql
```

### Restore that Backup into RDS
First we will update the value of the SSM parameter `/ADP/Wordpress/DBEndpoint` to point to the `adpWordPressdb` instance's `endpoint`  
Then we:  
Update the DbEndpoint environment variable with 

```
DBEndpoint=$(aws ssm get-parameters --region us-east-1 --names /ADP/Wordpress/DBEndpoint --query Parameters[0].Value)
DBEndpoint=`echo $DBEndpoint | sed -e 's/^"//' -e 's/"$//'`
```

Restore the database export into RDS using

```
mysql -h $DBEndpoint -u $DBUser -p$DBPassword $DBName < adpWordPress.sql 
```
### Change the WordPress config file to use RDS
this command will substitute `localhost` in the config file for the contents of `$DBEndpoint` which is the RDS instance

```
sudo sed -i "s/'localhost'/'$DBEndpoint'/g" /var/www/html/wp-config.php
```

## STAGE 3D - Stop the MariaDB Service

```
sudo systemctl disable mariadb
sudo systemctl stop mariadb
```


## STAGE 3E - Test WordPress
We open the `IPv4 Public IP` of the instance  in a new tab  
We should see the blog, working, even though MariaDB on the EC2 instance is stopped and disabled
Its now running using RDS  
## STAGE 3F - Update the LT so it doesnt install 
We then update the launch template and hence create a new version of the template by locating and removing the following lines
Locate and remove the following lines

```
systemctl enable mariadb
systemctl start mariadb
mysqladmin -u root password $DBRootPassword


echo "CREATE DATABASE $DBName;" >> /tmp/db.setup
echo "CREATE USER '$DBUser'@'localhost' IDENTIFIED BY '$DBPassword';" >> /tmp/db.setup
echo "GRANT ALL ON $DBName.* TO '$DBUser'@'localhost';" >> /tmp/db.setup
echo "FLUSH PRIVILEGES;" >> /tmp/db.setup
mysql -u root --password=$DBRootPassword < /tmp/db.setup
rm /tmp/db.setup
```

# STAGE 3 - FINISH  

This configuration has several limitations :-

- ~~The application and database are built manually, taking time and not allowing automation~~ FIXED  
- ~~^^ it was slow and annoying ... that was the intention.~~ FIXED  
- ~~The database and application are on the same instance, neither can scale without the other~~ FIXED  
- ~~The database of the application is on an instance, scaling IN/OUT risks this media~~ FIXED  

- The application media and UI store is local to an instance, scaling IN/OUT risks this media
- Customer Connections are to an instance directly ... no health checks/auto healing
- The IP of the instance is hardcoded into the database ....


We can now move onto STAGE 4

# Stage 4 - Split out the WP filesystem into EFS and Update the LT
In stage 4 of this project we will be creating an EFS file system designed to store the wordpress locally stored media. This area stores any media for posts uploaded when creating the post as well as theme data. By storing this on a shared file system it means that the data can be used across all instances in a consistent way, and it lives on past the lifetime of the instance.  
## STAGE 4A - Create EFS File System
### File System Settings
We will first create an elastic file system with it's mount targets which are the network interfaces in the VPC which our instances will connect with, they will be located in the subnets `sn-App-A`, `sn-App-B` and `sn-App-C`.
For this we use the following terraform code:  
```terraform
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
```

## STAGE 4B - Add an fsid to parameter store

Now that the file system has been created, we need to add another parameter store value for the file system ID so that the automatically built instance(s) can load this safely.  
```terraform
#5 create efs ssm parameter
resource "aws_ssm_parameter" "EFSFSID" {
  name        = "/ADP/Wordpress/EFSFSID"
  description = "File System ID for wordpress content (wp-content)"
  type        = "String"
  value       = aws_efs_file_system.ADP-WORDPRESS-CONTENT.id
}
```

## STAGE 4C - Connect the file system to the EC2 instance & copy data
To do so, we connect to the instance and we do the following:  
First we need to install the amazon EFS utilities to allow the instance to connect to EFS. EFS is based on NFS which is standard and the EFS tooling makes things easier.  
```
sudo dnf -y install amazon-efs-utils
```

Next we need to migrate the existing media content from wp-content into EFS, and this is a multi step process.

First, we copy the content to a temporary location and make a new empty folder.  
```
cd /var/www/html
sudo mv wp-content/ /tmp
sudo mkdir wp-content
```

then get the efs file system ID from parameter store

```
EFSFSID=$(aws ssm get-parameters --region us-east-1 --names /ADP/Wordpress/EFSFSID --query Parameters[0].Value)
EFSFSID=`echo $EFSFSID | sed -e 's/^"//' -e 's/"$//'`
```
Next we add a line to /etc/fstab to configure the EFS file system to mount as /var/www/html/wp-content/

```
echo -e "$EFSFSID:/ /var/www/html/wp-content efs _netdev,tls,iam 0 0" >> /etc/fstab
```

```
mount -a -t efs defaults
```

now we need to copy the origin content data back in and fix permissions

```
mv /tmp/wp-content/* /var/www/html/wp-content/
```

```
chown -R ec2-user:apache /var/www/

```

## STAGE 4D - Test that the wordpress app can load the media
We then reboot the EC2 wordpress instance
```
reboot
```
## STAGE 4E - Update the launch template with the config to automate the EFS part
Next you will update the launch template so that it automatically mounts the EFS file system during its provisioning process. This means that in the next stage, when you add autoscaling, all instances will have access to the same media store ...allowing the platform to scale.
 


