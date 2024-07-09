resource "openstack_compute_secgroup_v2" "metabase_sg_bastion" {
  name        = "metabase_sg_bastion"
  description = "metabase_sg_bastion"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
    cidr        = "0.0.0.0/0"
  }
}