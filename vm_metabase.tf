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

  user_data = <<-EOF
    #!/bin/bash
    echo "Starting metabase_init.sh" >> /var/log/metabase_init.log
    docker run -d -p 3000:3000 --name metabase metabase/metabase >> /var/log/metabase_init.log 2>&1
    if [ $? -eq 0 ]; then
      echo "Metabase started successfully" >> /var/log/metabase_init.log
    else
      echo "Failed to start Metabase" >> /var/log/metabase_init.log
    fi
  EOF

  depends_on = [
    openstack_networking_subnet_v2.metabase_subnet,
  ]
}
