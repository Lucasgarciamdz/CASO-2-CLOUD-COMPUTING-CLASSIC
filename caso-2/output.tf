output "Detalle" {
  description = "🏗️ Resumen de la infraestructura desplegada"
  value = <<EOT
====================================
🚀 Infraestructura Metabase Desplegada
====================================

🔐 Acceso de Administración:
----------------------------
Bastion Host: ${openstack_networking_floatingip_v2.metabase_bastion_fip.address}
Usuario: ubuntu
Comando SSH: ssh -A ubuntu@${openstack_networking_floatingip_v2.metabase_bastion_fip.address}

🌐 Acceso a la Aplicación:
--------------------------
URL Metabase: http://${openstack_networking_floatingip_v2.metabase_load_balancer_fip.address}
Usuario inicial: [La que configuraste en var.metabase_mail]
Contraseña: [La que configuraste en var.metabase_password]

💻 Detalles de las Instancias:
------------------------------
- 🛡️ Bastion: ${openstack_compute_instance_v2.metabase_bastion.name}
  IP Interna: ${openstack_compute_instance_v2.metabase_bastion.network[0].fixed_ip_v4}
- 🔄 Load Balancer: ${openstack_compute_instance_v2.metabase_load_balancer.name}
  IP Interna: ${openstack_compute_instance_v2.metabase_load_balancer.network[0].fixed_ip_v4}
- 📊 Aplicación Metabase: ${openstack_compute_instance_v2.metabase_app.name}
  IP Interna: ${openstack_compute_instance_v2.metabase_app.network[0].fixed_ip_v4}
- 🗄️ Base de Datos: ${openstack_compute_instance_v2.metabase_db.name}
  IP Interna: ${openstack_compute_instance_v2.metabase_db.network[0].fixed_ip_v4}

🌐 Detalles de Red:
-------------------
- Red: ${openstack_networking_network_v2.metabase_net.name}
- Subred: ${openstack_networking_subnet_v2.metabase_subnet.name} (${openstack_networking_subnet_v2.metabase_subnet.cidr})
- Router: ${openstack_networking_router_v2.metabase_router.name}

🛡️ Grupos de Seguridad:
------------------------
- ${openstack_compute_secgroup_v2.metabase_sg_bastion.name}
- ${openstack_compute_secgroup_v2.metabase_sg_load_balancer.name}
- ${openstack_compute_secgroup_v2.metabase_sg_app.name}
- ${openstack_compute_secgroup_v2.metabase_sg_db.name}

📝 Notas:
---------
- Recuerda cambiar la contraseña del usuario admin de Metabase después del primer inicio de sesión.
- Para acceder a las instancias internas, utiliza el Bastion Host como punto de entrada.
- La base de datos está preconfigurada con los datos importados del archivo SQL proporcionado.

EOT
}