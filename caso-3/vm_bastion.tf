data "openstack_images_image_v2" "ubuntu_2204" {
  name        = "ubuntu_2204"
  most_recent = true
}

data "openstack_networking_network_v2" "ext_net" {
  name = "ext_net"
}

resource "openstack_compute_instance_v2" "metabase_bastion" {
  name              = var.vm_bastion_name
  image_id          = data.openstack_images_image_v2.ubuntu_2204.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = var.key_pair_name
  security_groups   = [openstack_compute_secgroup_v2.metabase_sg_bastion.name]
  availability_zone = "nodos-amd-2022"

  network {
    name = openstack_networking_network_v2.metabase_net.name
  }

  depends_on = [
    openstack_networking_subnet_v2.metabase_subnet,
  ]
}

resource "openstack_compute_floatingip_associate_v2" "metabase_bastion_fip" {
  floating_ip = openstack_networking_floatingip_v2.metabase_bastion_fip.address
  instance_id = openstack_compute_instance_v2.metabase_bastion.id
}
