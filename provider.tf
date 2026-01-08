provider "ibm" {
  region = var.powervs_region
  zone   = var.powervs_zone
  
  # Autenticación vía variable de entorno (requerido en TechZone):
  # export IC_API_KEY="xxxx"
  # O mediante terraform.tfvars:
  # ibmcloud_api_key = "xxxx"
}