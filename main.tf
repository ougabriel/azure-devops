

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.53.0"
    }
  }
}

provider "azurerm" {
  subscription_id   = "85c7908d-8028-4894-af5d-1991ee8f0450"
  client_id         = "8652c37d-012b-4019-9aa5-619dc5425efc"
  client_secret     = "bqd8Q~wxdA8NVzEAj8Efxngif_3l4sg7exxJqauY"
  tenant_id         = "37bb0008-2586-4514-a753-d1092d7259f2"
  features {
    resource_group {
       prevent_deletion_if_contains_resources = false
     }
  }
}
locals {
  resource_group="app-grp"
  location="North Europe"  
}


resource "azurerm_resource_group" "app_grp"{
  name=local.resource_group
  location=local.location
}

resource "azurerm_app_service_plan" "primary_plan" {
  name                = "primary-plan1000"
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.app_grp.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "primary_webapp" {
  name                = "primaryapp1000"
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.app_grp.name
  app_service_plan_id = azurerm_app_service_plan.primary_plan.id
   site_config {    
    dotnet_framework_version = "v6.0"
  }
   source_control {
    repo_url           = "https://github.com/ougabriel/azuredemo"
    branch             = "main"
    manual_integration = true
    use_mercurial      = false
  }
}

resource "azurerm_app_service_plan" "secondary_plan" {
  name                = "secondary-plan1000"
  location            = "UK South"
  resource_group_name = azurerm_resource_group.app_grp.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "secondary_webapp" {
  name                = "secondaryapp1000"
  location            = "UK South"
  resource_group_name = azurerm_resource_group.app_grp.name
  app_service_plan_id = azurerm_app_service_plan.secondary_plan.id
   site_config {    
    dotnet_framework_version = "v6.0"
  }
   source_control {
    repo_url           = "https://github.com/ougabriel/azuredemo"
    branch             = "main"
    manual_integration = true
    use_mercurial      = false
  }
}

// Here we are creating a Traffic Manager Profile

resource "azurerm_traffic_manager_profile" "traffic_profile" {
  name                   = "traffic-profile2000"
  resource_group_name    = azurerm_resource_group.app_grp.name
  traffic_routing_method = "Priority"
   dns_config {
    relative_name = "traffic-profile2000"
    ttl           = 100
  }
  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 2
  }
  }


resource "azurerm_traffic_manager_azure_endpoint" "primary_endpoint" {
  name               = "primary-endpoint"
  profile_id         = azurerm_traffic_manager_profile.traffic_profile.id
  priority           = 1
  weight             = 100
  target_resource_id = azurerm_app_service.primary_webapp.id
}


resource "azurerm_traffic_manager_azure_endpoint" "secondary_endpoint" {
  name               = "secondary-endpoint"
  profile_id         = azurerm_traffic_manager_profile.traffic_profile.id
  priority           = 2
  weight             = 100
  target_resource_id = azurerm_app_service.secondary_webapp.id
}
