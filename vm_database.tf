variable "google_db_password" {
  description = "Password for the Google DB"
  type        = string
  sensitive   = true
}

resource "openstack_compute_instance_v2" "metabase_db" {
  name              = "metabase-db"
  image_id          = data.openstack_images_image_v2.srv-mysql-ubuntu1804.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = var.key_name
  security_groups   = [openstack_compute_secgroup_v2.metabase_sg_db.name]
  availability_zone = "nodos-amd-2022"

  user_data = templatefile("${path.module}/db_init.sh", {
    db_name      = "google"
    db_user      = "googleuser"
    db_password  = var.google_db_password
    sql_file_url = "https://drive.google.com/uc?export=download&id=1AC2uvs6f2t4qrhXpz5XowSxoVXR3TfvG"
  })

  network {
    name = openstack_networking_network_v2.metabase_net.name
  }
  depends_on = [
    openstack_networking_subnet_v2.metabase_subnet,
  ]
}

