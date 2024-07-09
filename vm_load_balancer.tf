resource "openstack_compute_instance_v2" "metabase_load_balancer" {
  name              = "metabase-load-balancer"
  image_id          = data.openstack_images_image_v2.srv_nginx_ubuntu1804.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = var.key_name
  security_groups   = [openstack_compute_secgroup_v2.metabase_sg_load_balancer.name]
  availability_zone = "nodos-amd-2022"

  user_data = templatefile("${path.module}/load_balancer_init.sh", {
    app_ip = openstack_compute_instance_v2.metabase_app.network.0.fixed_ip_v4
  })

  network {
    name = openstack_networking_network_v2.metabase_net.name
  }

  depends_on = [
    openstack_networking_subnet_v2.metabase_subnet,
  ]
}

resource "openstack_compute_floatingip_associate_v2" "metabase_load_balancer_fip" {
  floating_ip = openstack_networking_floatingip_v2.metabase_load_balancer_fip.address
  instance_id = openstack_compute_instance_v2.metabase_load_balancer.id
}
