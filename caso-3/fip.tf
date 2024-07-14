resource "openstack_networking_floatingip_v2" "metabase_bastion_fip" {
  description = "metabase-bastion-ip"
  pool        = "ext_net"
}