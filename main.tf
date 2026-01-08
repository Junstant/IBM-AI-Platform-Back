###############################################################################
# main.tf
# Despliegue automatizado de AI Platform en PowerVS (IBM Cloud)
# - Crea red pública para acceso SSH desde internet
# - Crea/adjunta clave SSH en el workspace PowerVS
# - Resuelve imagen del SO por nombre
# - Crea volumen de datos adicional (50 GB)
# - Crea instancia PowerVS (S1022 / 25 cores / 120 GB) con cloud-init
# - Cloud-init descarga setup.sh desde GitHub y ejecuta despliegue automático
###############################################################################

locals {
  # Generar cloud-init dinámicamente con las variables
  cloud_init_content = templatefile("${path.module}/cloud-init.yaml", {
    repo_back_url      = var.repo_back_url
    repo_front_url     = var.repo_front_url
    huggingface_token  = var.huggingface_token
    db_password        = var.db_password
  })
}

# Hash de cloud-init para forzar recreación si cambia
resource "terraform_data" "cloudinit_hash" {
  input = sha256(local.cloud_init_content)
}

# Crear red pública para acceso SSH desde internet
resource "ibm_pi_network" "public_network" {
  pi_cloud_instance_id = var.workspace_guid
  pi_network_name      = "${var.vm_name}-public-net"
  pi_network_type      = "pub-vlan"
  
  # DNS público de Google para salida a internet
  pi_dns = ["8.8.8.8", "8.8.4.4"]
}

# Clave SSH almacenada en el workspace PowerVS
resource "ibm_pi_key" "ssh" {
  pi_cloud_instance_id = var.workspace_guid
  pi_key_name          = var.ssh_key_name
  pi_ssh_key           = var.ssh_public_key
}

# Resolver ID de imagen por nombre
data "ibm_pi_image" "os" {
  pi_cloud_instance_id = var.workspace_guid
  pi_image_name        = var.image_name
}

# Crear volumen de datos adicional (50 GB)
resource "ibm_pi_volume" "data_volume" {
  pi_cloud_instance_id = var.workspace_guid
  pi_volume_name       = "${var.vm_name}-data-vol"
  pi_volume_size       = var.data_volume_size_gb
  pi_volume_type       = "tier3"  # tier1 (SSD), tier3 (HDD) - más económico
  pi_volume_shareable  = false
}

# Crear la instancia PowerVS
resource "ibm_pi_instance" "vm" {
  pi_cloud_instance_id = var.workspace_guid

  pi_instance_name = var.vm_name
  pi_sys_type      = var.vm_sys_type
  pi_proc_type     = var.vm_proc_type
  pi_processors    = var.vm_cores
  pi_memory        = var.vm_memory_gb

  pi_image_id      = data.ibm_pi_image.os.id
  pi_key_pair_name = ibm_pi_key.ssh.key_id

  # Evitar pinning estricto de CPU/memoria
  pi_pin_policy = "none"

  # Adjuntar red pública
  pi_network {
    network_id = ibm_pi_network.public_network.network_id
  }

  # Adjuntar volumen de datos
  pi_volume_ids = [ibm_pi_volume.data_volume.volume_id]

  # Cloud-init bootstrap (ejecuta setup automático en primer boot)
  pi_user_data = local.cloud_init_content

  # Asegurar que VM se reemplaza si cloud-init cambia
  lifecycle {
    replace_triggered_by = [
      terraform_data.cloudinit_hash
    ]
  }

  # Dependencias explícitas
  depends_on = [
    ibm_pi_network.public_network,
    ibm_pi_volume.data_volume,
    ibm_pi_key.ssh
  ]
}

###############################################################################
# Outputs
###############################################################################

output "vm_id" {
  description = "ID de la instancia PowerVS"
  value       = ibm_pi_instance.vm.id
}

output "vm_name" {
  description = "Nombre de la instancia PowerVS"
  value       = ibm_pi_instance.vm.pi_instance_name
}

output "vm_external_ip" {
  description = "IP pública para acceso SSH y frontend (usar esta IP en VITE_API_HOST)"
  value       = ibm_pi_instance.vm.pi_network[0].external_ip
}

output "ssh_command" {
  description = "Comando SSH para conectarse a la instancia"
  value       = "ssh root@${ibm_pi_instance.vm.pi_network[0].external_ip}"
}

output "frontend_url" {
  description = "URL del frontend (disponible después del despliegue completo)"
  value       = "http://${ibm_pi_instance.vm.pi_network[0].external_ip}:2012"
}

output "public_network_id" {
  description = "ID de la red pública creada"
  value       = ibm_pi_network.public_network.network_id
}

output "data_volume_id" {
  description = "ID del volumen de datos adicional (50 GB)"
  value       = ibm_pi_volume.data_volume.volume_id
}

output "workspace_guid" {
  description = "PowerVS Workspace GUID"
  value       = var.workspace_guid
}

output "deployment_status" {
  description = "Estado del despliegue"
  value       = <<-EOT
  
  ========================================
  🚀 DESPLIEGUE DE AI PLATFORM INICIADO
  ========================================
  
  📡 IP Externa: ${ibm_pi_instance.vm.pi_network[0].external_ip}
  🔑 SSH: ssh root@${ibm_pi_instance.vm.pi_network[0].external_ip}
  🌐 Frontend (después de ~15-20 min): http://${ibm_pi_instance.vm.pi_network[0].external_ip}:2012
  
  📋 Cloud-init está ejecutando el setup automático:
     1. Instalando dependencias del sistema
     2. Clonando repositorios desde GitHub
     3. Descargando modelos de HuggingFace
     4. Construyendo contenedores Docker
     5. Iniciando servicios
  
  ⏱️  El proceso tarda aproximadamente 15-20 minutos
  
  📊 Para monitorear el progreso:
     ssh root@${ibm_pi_instance.vm.pi_network[0].external_ip}
     tail -f /var/log/cloud-init-output.log
  
  ✅ Cuando termine, el frontend estará disponible en:
     http://${ibm_pi_instance.vm.pi_network[0].external_ip}:2012
  
  ========================================
  EOT
}
