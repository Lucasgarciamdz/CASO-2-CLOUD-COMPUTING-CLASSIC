resource "openstack_compute_secgroup_v2" "metabase_sg_load_balancer" {
  name        = "metabase_sg_load_balancer"
  description = "metabase_sg_load_balancer"

  rule {
    from_group_id = openstack_compute_secgroup_v2.metabase_sg_bastion.id
    from_port     = -1
    to_port       = -1
    ip_protocol   = "icmp"
  }
  rule {
    from_group_id = openstack_compute_secgroup_v2.metabase_sg_bastion.id
    from_port     = 22
    to_port       = 22
    ip_protocol   = "tcp"
  }
  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}