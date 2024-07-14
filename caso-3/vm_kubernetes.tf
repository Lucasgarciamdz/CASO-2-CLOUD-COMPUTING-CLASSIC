data "openstack_images_image_v2" "docker" {
  name        = "um-kube-tools"
  most_recent = true
}

data "openstack_compute_flavor_v2" "small" {
  vcpus = 1
  ram   = 2048
}

resource "openstack_compute_instance_v2" "docker_vm" {
  name              = var.vm_name
  image_id          = data.openstack_images_image_v2.docker.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = var.key_pair_name
  security_groups   = ["default"]
  availability_zone = "nodos-amd-2022"

  user_data = templatefile("init.sh", {
    configmap_yaml = templatefile("${path.module}/configmap.yaml", {
      NAMESPACE        = var.namespace
      METABASE_DB_NAME = var.metabase_db_name
      METABASE_DB_HOST = "mysql"
      MOBILITY_DB_NAME = var.mobility_db_name
    }),
    deploy_yaml = file("${path.module}/deploy.yaml"),
    ingress_yaml = file("${path.module}/ingress.yaml"),
    namespace_yaml = file("${path.module}/namespace.yaml"),
    network_yaml = file("${path.module}/network.yaml"),
    pvc_yaml = file("${path.module}/pvc.yaml"),
    secret_yaml = file("${path.module}/secrets.yaml"),
    service_yaml = file("${path.module}/services.yaml"),
    rancher_token = var.rancher_token,
    namespace = var.namespace,
    project_name = var.project_name,
    mobility_db_name = var.mobility_db_name,
    metabase_db_name = var.metabase_db_name,
    METABASE_MAIL = var.metabase_mail,
    METABASE_PASSWORD = var.metabase_password,
    METABASE_DB_USER = var.metabase_db_user,
    METABASE_DB_PASSWORD = var.metabase_db_password,
    MOBILITY_DB_USER = var.mobility_db_user,
    MOBILITY_DB_PASSWORD = var.mobility_db_password,
    MYSQL_ROOT_PASSWORD = var.mysql_root_password,
    MYSQL_USER = var.mysql_user,
    sql_file_url = var.sql_file_url
  })

  network {
    name = "net_umstack"
  }
}