terraform {
  required_version = ">= 1.5.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "ml_api" {
  name      = "ml-api-${var.environment}"
  namespace = var.environment

  create_namespace = true

  chart = "../helm/ml-api"

  values = [
    file("../helm/ml-api/values-${var.environment}.yaml")
  ]

  wait = true
}
