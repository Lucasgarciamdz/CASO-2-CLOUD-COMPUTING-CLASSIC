resource "openstack_compute_secgroup_v2" "metabase_sg_db" {
  name        = "metabase_sg_db"
  description = "metabase_sg_db"

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
    from_group_id = openstack_compute_secgroup_v2.metabase_sg_app.id
    from_port     = 3306
    to_port       = 3306
    ip_protocol   = "tcp"
  }
}