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

# STAGE 1A - Login to an AWS Account 
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
