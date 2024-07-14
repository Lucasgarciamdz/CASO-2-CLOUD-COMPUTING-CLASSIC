resource "openstack_networking_router_v2" "metabase_router" {
  name                = "metabase-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.ext_net.id
}

resource "openstack_networking_network_v2" "metabase_net" {
  name           = "metabase-net"
  admin_state_up = "true"
  shared         = "false"
}

resource "openstack_networking_subnet_v2" "metabase_subnet" {
  name            = "metabase-subnet"
  network_id      = openstack_networking_network_v2.metabase_net.id
  cidr            = "172.19.0.0/24"
  ip_version      = 4
  enable_dhcp     = "true"
  dns_nameservers = ["8.8.8.8", "1.1.1.1"]
}

resource "openstack_networking_router_interface_v2" "metabase_router_iface_internal" {
  router_id = openstack_networking_router_v2.metabase_router.id
  subnet_id = openstack_networking_subnet_v2.metabase_subnet.id
}
