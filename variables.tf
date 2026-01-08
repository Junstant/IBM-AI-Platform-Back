###############################################################################
# variables.tf
# Variables de entrada para el despliegue automatizado en TechZone
###############################################################################

variable "powervs_region" {
  description = "Región de PowerVS (ej: us-south, eu-de)"
  type        = string
  default     = "us-south"
}

variable "powervs_zone" {
  description = "Zona de PowerVS (ej: us-south, eu-de-1)"
  type        = string
  default     = "us-south"
}

variable "workspace_guid" {
  description = "PowerVS Workspace GUID (pi_cloud_instance_id)"
  type        = string
}

variable "ssh_key_name" {
  description = "Nombre de la clave SSH en PowerVS"
  type        = string
  default     = "techzone-ai-platform-key"
}

variable "ssh_public_key" {
  description = "Clave SSH pública para acceso a la instancia"
  type        = string
}

variable "vm_name" {
  description = "Nombre de la instancia PowerVS"
  type        = string
  default     = "ai-platform-s1022"
}

variable "vm_sys_type" {
  description = "Tipo de sistema PowerVS"
  type        = string
  default     = "s1022"
  
  validation {
    condition     = contains(["s922", "s1022", "e980", "e1080"], var.vm_sys_type)
    error_message = "sys_type debe ser: s922, s1022, e980 o e1080"
  }
}

variable "vm_proc_type" {
  description = "Tipo de procesador (shared o dedicated)"
  type        = string
  default     = "shared"
  
  validation {
    condition     = contains(["shared", "dedicated"], var.vm_proc_type)
    error_message = "proc_type debe ser 'shared' o 'dedicated'"
  }
}

variable "vm_cores" {
  description = "Cantidad de cores de CPU"
  type        = number
  default     = 25
}

variable "vm_memory_gb" {
  description = "Memoria RAM en GB"
  type        = number
  default     = 120
}

variable "image_name" {
  description = "Nombre de la imagen del SO en PowerVS"
  type        = string
  default     = "CentOS-Stream-9"
}

variable "data_volume_size_gb" {
  description = "Tamaño del volumen de datos adicional en GB"
  type        = number
  default     = 50
}

variable "repo_back_url" {
  description = "URL del repositorio Git del backend"
  type        = string
  default     = "https://github.com/Junstant/IBM-AI-Platform-Back.git"
}

variable "repo_front_url" {
  description = "URL del repositorio Git del frontend"
  type        = string
  default     = "https://github.com/Junstant/IBM-AI-Platform-Front.git"
}

variable "huggingface_token" {
  description = "Token de HuggingFace para descargar modelos"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Contraseña de PostgreSQL"
  type        = string
  default     = "root"
  sensitive   = true
}
