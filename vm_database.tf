data "external" "env_vars" {
  program = ["bash", "${path.module}/read_env_vars.sh"]
}

resource "openstack_compute_instance_v2" "metabase_db" {
  name              = "metabase-db"
  image_id          = data.openstack_images_image_v2.srv-mysql-ubuntu1804.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = var.key_name
  security_groups   = [openstack_compute_secgroup_v2.metabase_sg_db.name]
  availability_zone = "nodos-amd-2022"

  user_data = templatefile("${path.module}/db_init.sh", {
    google_mobility_sql = file("${path.module}/google-mobility.sql"),
    GOOGLE_DB_PASSWORD  = data.external.env_vars.result["GOOGLE_DB_PASSWORD"]
  })

  network {
    name = openstack_networking_network_v2.metabase_net.name
  }
  depends_on = [
    openstack_networking_subnet_v2.metabase_subnet,
  ]
}
