## 💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥 ##
## This file is maintained in the `terraform` ##
## repo, any changes *will* be overwritten!!  ##
## 💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥 ##

# From StackOverflow: https://stackoverflow.com/a/20566812
UNAME:= $(shell uname)
ifeq ($(UNAME),Darwin)
		OS_X  := true
		SHELL := /bin/bash
else
		OS_DEB  := true
		SHELL := /bin/bash
endif

TERRAFORM:= $(shell command -v terraform 2> /dev/null)
TERRAFORM_VERSION:= "0.11.7"

ifeq ($(OS_X),true)
		TERRAFORM_MD5:= $(shell md5 -q `which terraform`)
		TERRAFORM_REQUIRED_MD5:= 1188a85a63146493fb34b46632e2c7e6
else
		TERRAFORM_MD5:= $(shell md5sum - < `which terraform` | tr -d ' -')
		TERRAFORM_REQUIRED_MD5:= e3ca816e38daefb6500c8a6466a8352c
endif

default:
	@echo "Creates a Terraform system from a template."
	@echo "The following commands are available:"
	@echo " - init               : sets up the project for use"
	@echo " - init-plugins       : installs the plugins needed"
	@echo " - upgrade            : will pull the latest framework files"
	@echo " - plan               : runs terraform plan for an environment"
	@echo " - apply              : runs terraform apply for an environment"
	@echo " - destroy            : will delete the entire project's infrastructure"

check:
	@echo "Checking Terraform version... expecting md5 of [${TERRAFORM_REQUIRED_MD5}], found [${TERRAFORM_MD5}]"
	@if [ "${TERRAFORM_MD5}" != "${TERRAFORM_REQUIRED_MD5}" ]; then echo "Please ensure you are running terraform ${TERRAFORM_VERSION}."; exit 1; fi

init: check
	@# Figure out how to make this optional so that it only runs when you call init - want it to print out the message from default.
ifndef TERRAFORM
		$(error "terraform is not available please install it")
endif

	$(call check_defined, SYSTEM_NAME, Please set the SYSTEM_NAME to a value you want to call this one, i.e. allocations, investor-admin, funding-allocations, etc. Typically this should match what you would call the repo and / or the actual system.)
	@echo ""
	@echo "💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥"
	@echo "💥  Here be dragons. Please only run this if you know what you are doing.  💥"
	@echo "💥  If you don't, now is a good time to press ctrl+c ...                   💥 "
	@echo "💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥 💥"
	@echo ""
	@read -p "Press enter to continue"

	@if [ -a remote_state.tf ]; then echo "Already initialized, doing nothing. You probably wanted to run init-plugins"; exit 1; fi;

	@echo "Creating the system with name [$(value SYSTEM_NAME)]..."
	@sed 's/SYSTEM_NAME/'"$(value SYSTEM_NAME)"'/' framework/remote_state.tf > remote_state.tf

	@echo "Initializing the s3 backend..."
	@cp framework/common.tf common.tf
	@terraform init -backend=true -backend-config="profile=<my-org>-master" -force-copy

	@terraform workspace new development
	@terraform workspace new testing
	@terraform workspace new staging
	@terraform workspace new production

	@echo "Backends initialized!"

	@echo "Creating skeleton project..."
	@echo "💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀"

	@cp framework/common.tf ./
	@touch $(value SYSTEM_NAME).tf
	@touch $(value SYSTEM_NAME)-config.tf
	@touch $(value SYSTEM_NAME)-secrets.tf

	@echo "All done, ready to create the infrastructure! 💥"

	@rm -rf .git


init-plugins: check
	@echo "Initializing the Terraform plugins..."
	@terraform init -backend=true -backend-config="profile=<my-org>-master"


plan: check
	$(call check_defined, ENV, Please set the ENV to plan for. Values should be development, testing, staging or production)
	@terraform fmt

	@echo "Pulling the required modules..."
	@terraform get

	@echo 'Switching to the [$(value ENV)] environment ...'
	@terraform workspace select $(value ENV)

	@terraform plan  \
	  -var-file="framework/$(value ENV).tfvars" \
		-var-file="system_vars/$(value ENV).tfvars" \
		-out $(value ENV).plan


apply: check
	$(call check_defined, ENV, Please set the ENV to apply. Values should be development, testing, staging or production)

	@echo 'Switching to the [$(value ENV)] environment ...'
	@terraform workspace select $(value ENV)

	@echo "Will be applying the following to [$(value ENV)] environment:"
	@terraform show -no-color $(value ENV).plan

	@terraform apply $(value ENV).plan
	@rm $(value ENV).plan


destroy: check
	@echo "Switching to the [$(value ENV)] environment ..."
	@terraform workspace select $(value ENV)

	@echo "## 💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥 ##"
	@echo "Are you really sure you want to completely destroy [$(value ENV)] environment ?"
	@echo "## 💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥 ##"
	@read -p "Press enter to continue"
	@terraform destroy \
		-var-file="framework/$(value ENV).tfvars" \
		-var-file="system_vars/$(value ENV).tfvars"


upgrade:
	@echo 'Preparing to upgrade the Makefile and common Terraform files...'
	@read -p "Press enter to continue"
	@mkdir _upgrade
	@git clone git@github.com:<my-org>/terraform.git _upgrade

	@echo "Upgrading common.tf..."
	@rm -f common.tf
	@mv _upgrade/framework/common.tf ./

	@echo "Upgrading environment var files..."
	@rm -f framework/*
	@mv _upgrade/framework/*.tfvars framework/

	@echo "Upgrading Makefile..."
	@rm -f Makefile
	@mv _upgrade/Makefile ./

	@echo "Upgrading remotes.tf.sample..."
	@rm -f remotes.tf.sample
	@mv _upgrade/framework/remotes.tf.sample ./

	@echo "Cleaning up"
	@rm -rf _upgrade

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))
