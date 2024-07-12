data "openstack_images_image_v2" "docker" {
  name        = "um-kube-tools"
  most_recent = true
}

data "openstack_compute_flavor_v2" "small" {
  vcpus = 1
  ram   = 2048
}

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
  default     = "metabase"
}

variable "metabase_db_password" {
  description = "Password for the Metabase DB"
  type        = string
  sensitive   = true
}

variable "mobility_db_user" {
  description = "User for the Mobilitec DB"
  type        = string
  default     = "mobility"
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
  default     = "mobility"
}


resource "openstack_compute_instance_v2" "docker_vm" {
  name              = "kube_vm"
  image_id          = data.openstack_images_image_v2.docker.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = "mac"
  security_groups   = ["default"]
  availability_zone = "nodos-amd-2022"

  user_data = templatefile("init.sh", {
    configmap_yaml = file("${path.module}/configmap.yaml"),
    deploy_yaml = file("${path.module}/deploy.yaml"),
    ingress_yaml = file("${path.module}/ingress.yaml"),
    namespace_yaml = file("${path.module}/namespace.yaml"),
    network_yaml = file("${path.module}/network.yaml"),
    pvc_yaml = file("${path.module}/pvc.yaml"),
    secret_yaml = file("${path.module}/secrets.yaml"),
    service_yaml = file("${path.module}/services.yaml"),
    rancher_token = var.rancher_token,
    METABASE_MAIL = var.metabase_mail,
    METABASE_PASSWORD = var.metabase_password,
    METABASE_DB_USER = var.metabase_db_user,
    METABASE_DB_PASSWORD = var.metabase_db_password,
    MOBILITY_DB_USER = var.mobility_db_user,
    MOBILITY_DB_PASSWORD = var.mobility_db_password,
    MYSQL_ROOT_PASSWORD = var.mysql_root_password,
    MYSQL_USER = var.mysql_user,
    sql_file_url = "https://drive.google.com/uc?export=download&id=1AC2uvs6f2t4qrhXpz5XowSxoVXR3TfvG"
  }
    )

  network {
    name = "net_umstack"
  }
}
