#!/bin/bash

if [ ! -f "main.tf" ]; then
  echo "Creating main.tf ..."
  cat > "main.tf" << EOF
# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "myTFResourceGroup"
  location = "westus2"
}
EOF
fi

echo "terraform init"
# Terraform init
terraform init || { echo "ERROR init "; exit 1; }

echo "terraform fmt"
# Terraform fmt
terraform fmt || { echo "ERROR  fmt "; exit 1; }

echo "terraform validate"
# Terraform validate
terraform validate || { echo "ERROR  validate "; exit 1; }

echo "terraform plan"
# Terraform plan
terraform plan -var-file="/Users/dino/Documents/AZURE/azure_client" || { echo "ERROR  plan "; exit 1; }

echo "-----------------------------"
echo "ALL step has been succeed ✅"

pip3 install InquirerPy

python3 validate.py

if [ $? -eq 0 ]; then
  terraform apply -var-file="/Users/dino/Documents/AZURE/azure_client" || { echo "ERROR  plan "; exit 1; }
fi
