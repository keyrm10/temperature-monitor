terraform {
  required_version = ">= 1.11.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.26.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.2.0"
    }
  }
}

data "sops_file" "azure_secrets" {
  source_file = "${path.module}/azure.enc.yaml"
}

locals {
  azure_secrets = yamldecode(data.sops_file.azure_secrets.raw)
}

provider "azurerm" {
  features {}
  subscription_id = local.azure_secrets.AZURE_SUBSCRIPTION_ID
  client_id       = local.azure_secrets.AZURE_CLIENT_ID
  client_secret   = local.azure_secrets.AZURE_CLIENT_SECRET
  tenant_id       = local.azure_secrets.AZURE_TENANT_ID
}
