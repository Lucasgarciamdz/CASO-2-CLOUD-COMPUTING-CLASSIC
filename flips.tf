resource "openstack_networking_floatingip_v2" "metabase_bastion_fip" {
  description = "metabase-bastion-ip"
  pool        = "ext_net"
}

resource "openstack_networking_floatingip_v2" "metabase_load_balancer_fip" {
  description = "metabase-load-balancer-ip"
  pool        = "ext_net"
}
