## 💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥 ##
## This file is maintained in the `terraform` ##
## repo, any changes *will* be overwritten!!  ##
## 💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥 ##

provider "template" {
  version = "1.0"
}

provider "aws" {
  version = "1.7"
  region  = "${var.aws_region}"
  profile = "<my-org>-master"

  assume_role {
    role_arn = "arn:aws:iam::${lookup(var.aws_account_ids, terraform.workspace)}:role/administrator"
  }
}

variable "aws_region" {
  type    = "string"
  default = "eu-west-1"
}

variable "terraform_state_bucket" {
  type    = "string"
  default = "<my-org>-terraform-state"
}

variable "terraform_state_bucket_region" {
  type    = "string"
  default = "eu-west-1"
}

variable "aws_account_id" {
  type = "string"
}

variable "environments" {
  type = "list"

  default = [
    "development",
    "testing",
    "staging",
    "production",
  ]
}

variable "aws_account_ids" {
  type = "map"

  default = {
    development = "not_set"
    testing     = "not_set"
    staging     = "not_set"
    production  = "not_set"

    master = "not_set"
  }
}

# These are AWS account IDs for Application Load Balancers
variable "alb_logging_account_ids" {
  type = "map"

  default = {
    us-east-1    = "127311923021"
    us-east-2    = "033677994240"
    us-west-1    = "027434742980"
    us-west-2    = "797873946194"
    eu-central-1 = "054676820928"
    eu-west-1    = "156460612806"
    eu-west-2    = "652711504416"
    eu-west-3    = "009996457667"
  }
}

variable "external_public_apex_dns_domain" {
  type = "string"
}

variable "internal_dns_domain" {
  type    = "string"
  default = "internal.<my-org>"
}

# This is used when you need to host something on <my-org>. I.e. Chef, Jenkins.
# This shouldn't be used for things like bastion boxes as the production
# environment will be *.<my-org>, not production.<my-org>.
variable "private_apex_dns_domain_no_env_prefix" {
  type    = "string"
  default = "<my-org>"
}

variable "<my-org>_offices" {
  type = "list"

  default = [
    "cape_town"
  ]
}

variable "<my-org>_office_cidrs" {
  type = "map"

  default = {
    cape_town     = "1.2.3.4/32"
  }
}

variable "<my-org>_aws_cidrs" {
  type = "map"

  default = {
    master_jump  = "1.2.3.4/32"
    master_nat_1 = "1.2.3.4/32"
    master_nat_2 = "1.2.3.4/32"

    development_jump  = "1.2.3.4/32"
    development_nat_1 = "1.2.3.4/32"
    development_nat_2 = "1.2.3.4/32"

    testing_jump  = "1.2.3.4/32"
    testing_nat_1 = "1.2.3.4/32"
    testing_nat_2 = "1.2.3.4/32"

    staging_jump  = "1.2.3.4/32"
    staging_nat_1 = "1.2.3.4/32"
    staging_nat_2 = "1.2.3.4/32"

    production_jump  = "1.2.3.4/32"
    production_nat_1 = "1.2.3.4/32"
    production_nat_2 = "1.2.3.4/32"
  }
}

variable "github_ip_cidrs" {
  type = "map"

  default = {
    block_1 = "192.30.252.0/22"
    block_2 = "185.199.108.0/22"
  }
}

variable "aws_cli_and_python_install_user_data" {
  type = "string"

  default = <<EOF
#!/bin/bash
apt-get install -y python
curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py
/usr/local/bin/pip install awscli
EOF
}
