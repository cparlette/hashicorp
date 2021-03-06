# Hashicorp Examples

This project will utilize various tools from Hashicorp (currently Packer, Terraform, and Consul) to deploy a set of web servers behind a load balancer.

## Prerequisites

### Install Terraform

Download Terraform for your operating system from the [Terraform Download page](https://www.terraform.io/downloads.html).  Make sure the executable is in your PATH.

### Install Packer

Download Packer for your operating system from the [Packer Download page](https://www.packer.io/downloads.html).  Make sure the executable is in your PATH.

### Install Packer2Terraform

This current project uses [Packer2Terraform](https://github.com/saymedia/packer2terraform) to take the output from Packer and form a .tf file with the generated AMI ID.  Follow the instructions from the Packer2Terraform Github page for installation.  Note that you'll need to have [Go](https://golang.org/doc/install) installed on your system.

### Set up credentials

The "credentials.tfvars" file has 4 values that need to be set for your connection.  The "access_key" and "secret_key" values can be obtained from your AWS account.  The "public_key_path" and "key_name" values will be used for SSH access to the EC2 instances that get built by Terraform.

For Packer to work properly, you'll have to proved the AWS access_key and secret_key at the top of the packer-ubuntu_with_nginx_consul_php.json file.

## Building the Environment

### Build the base image with Packer

```
packer -machine-readable build packer-ubuntu_with_nginx_consul_php.json | packer2terraform > packer_amis.tf
```

This will take a base image of Ubuntu and perform the following steps:
- Update all installed packages
- Install Nginx, Unzip, and PHP5-fpm
- Download Consul and Consul-template and put the binaries in /usr/bin
- Download Upstart config files to run consul as a service
- Download PHP and Nginx configs to show a simple webpage

The AMI that is generated will be stored in a Terraform-friendly format.

### See what Terraform will do

```
terraform plan
```

### Execute the Terraform plan

```
terraform apply
```

## End result

This will fully deploy an environment in AWS with the following items:
- VPC
- Internet Gateway
- Routes
- Subnets
- Security Groups
- ELB
- Keypair
- EC2 instances

There will be 3 EC2 instances behind the ELB that all have Nginx installed.  These 3 servers all serve a basic PHP page that displays the server's IP address to show the load balancer working.  These 3 EC2 instances all have Consul agents running as well, and have all been joined as members to the same Consul cluster.