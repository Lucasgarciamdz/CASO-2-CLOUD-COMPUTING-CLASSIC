variable "metabase_mail" {
  description = "Mail for the Metabase user"
  type        = string
  sensitive   = true
}

variable "metabase_password" {
  description = "Password for the Metabase user"
  type        = string
  sensitive   = true
}

variable "metabase_db_user" {
  description = "User for the Metabase DB"
  type        = string
}

variable "metabase_db_password" {
  description = "Password for the Metabase DB"
  type        = string
  sensitive   = true
}

variable "mobility_db_user" {
  description = "User for the Mobilitec DB"
  type        = string
}

variable "mobility_db_password" {
  description = "Password for the Mobilitec DB"
  type        = string
  sensitive   = true
}

variable "rancher_token" {
  description = "Bearer Token for Rancher"
  type        = string
  sensitive   = true
}

variable "mysql_root_password" {
  description = "Password for the MySQL root user"
  type        = string
  sensitive   = true
}

variable "mysql_user" {
  description = "User for the MySQL DB"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "metabase_db_name" {
  description = "Name of the Metabase database"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "mobility_db_name" {
  description = "Name of the mobility database"
  type        = string
}

variable "sql_file_url" {
  description = "URL of the SQL file to be imported"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the key pair to use"
  type        = string
}

variable "vm_kube_name" {
  description = "Name of the Kube VM"
  type        = string
}

variable "vm_bastion_name" {
  description = "Name of the Bastion VM"
  type        = string
}