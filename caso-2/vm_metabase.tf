resource "openstack_compute_instance_v2" "metabase_app" {
  name              = "metabase-app"
  image_id          = data.openstack_images_image_v2.srv-docker-ubuntu2204.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = var.key_name
  security_groups   = [openstack_compute_secgroup_v2.metabase_sg_app.name]
  availability_zone = "nodos-amd-2022"

  network {
    name = openstack_networking_network_v2.metabase_net.name
  }

  user_data = templatefile("${path.module}/metabase_init.sh", {
    db_name      = var.google_db_name
    db_user      = var.google_db_user
    db_password  = var.google_db_password
    db_host      = openstack_compute_instance_v2.metabase_db.network.0.fixed_ip_v4
    metabase_password = var.metabase_password
    metabase_mail = var.metabase_mail
  })

  depends_on = [
    openstack_networking_subnet_v2.metabase_subnet,
  ]
}
