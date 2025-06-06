# Techeazy DevOps EC2 Auto Deploy with Terraform
 

This project automates the provisioning of an AWS EC2 instance, sets up Java and Maven, builds a Spring Boot project from GitHub, runs it, and automatically shuts down the instance after 30 minutes.

**Prerequisites**
Before you begin, ensure you have the following installed:

Terraform

AWS CLI

AWS credentials configured via aws configure

 **Project Structure**
.
├── main.tf              # Terraform resources (EC2, security group, key, etc.)
├── variables.tf         # Terraform variables
├── outputs.tf           # Terraform outputs (IP, URL, key path)
├── user_data.sh         # EC2 startup script for app setup

**How It Works**

1.Creates an RSA SSH key pair.
2.Provisions an Ubuntu 22.04 EC2 instance in us-east-2.
3.Installs:

    3.1.Java 21

    3.2.Maven

    3.3.Git

4.Clones the Spring Boot project from GitHub.

5.Builds it using Maven.

6.Runs the JAR on port **80**.

7.Schedules an automatic shutdown after **30 minutes** using at.

**Deploy**

**Initialize Terraform**
`terraform init`

**Apply the Configuration**
`terraform apply`
When prompted, type yes.

**Outputs**

> After apply, Terraform will print:

       EC2 public IP

       App URL (http://<public-ip>)

       Path to SSH private key

 **Access EC2**
chmod 600 techeazy-terraform-key.pem
ssh -i techeazy-terraform-key.pem ubuntu@<public-ip>

 **Re-Deploy**
  If you need to re-run:

**terraform destroy -auto-approve
terraform apply**

**App Info**
**GitHub Repo:** techeazy-devops

**Port:** 80

**Shutdown Timer:** 30 minutes from launch

**Notes**
Make sure your IP is allowed by AWS Security Group (by default it allows 0.0.0.0/0).

You can change the shutdown time in user_data.sh under SHUTDOWN_MINUTES.

**Destroy Infrastructure**
`terraform destroy`
~
