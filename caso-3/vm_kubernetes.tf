data "openstack_images_image_v2" "docker" {
  name        = "um-kube-tools"
  most_recent = true
}

data "openstack_compute_flavor_v2" "small" {
  vcpus = 1
  ram   = 2048
}

resource "openstack_compute_instance_v2" "kubernetes_vm" {
  name              = var.vm_kube_name
  image_id          = data.openstack_images_image_v2.docker.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = var.key_pair_name
  security_groups   = [openstack_compute_secgroup_v2.metabase_sg_app.name]
  availability_zone = "nodos-amd-2022"

  network {
    name = openstack_networking_network_v2.metabase_net.name
  }

  depends_on = [
    openstack_networking_subnet_v2.metabase_subnet,
  ]

  user_data = templatefile("init.sh", {
    configmap_yaml = templatefile("${path.module}/configmap.yaml", {
      NAMESPACE        = var.namespace
      METABASE_DB_NAME = var.metabase_db_name
      METABASE_DB_HOST = "mysql"
      MOBILITY_DB_NAME = var.mobility_db_name
    }),
    deploy_yaml = templatefile("${path.module}/deploy.yaml",{
      NAMESPACE = var.namespace
    }),
    ingress_yaml = templatefile("${path.module}/ingress.yaml",{
      NAMESPACE = var.namespace
    }),
    namespace_yaml = templatefile("${path.module}/namespace.yaml",{
      NAMESPACE = var.namespace
    }),
    networkp_yaml = templatefile("${path.module}/networkp.yaml",{
      NAMESPACE = var.namespace
    }),
    pvc_yaml = templatefile("${path.module}/pvc.yaml",{
      NAMESPACE = var.namespace
    }),
    secret_yaml = templatefile("${path.module}/secrets.yaml",{
      NAMESPACE = var.namespace
    }),
    service_yaml = templatefile("${path.module}/services.yaml",{
      NAMESPACE = var.namespace
    }),
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
}