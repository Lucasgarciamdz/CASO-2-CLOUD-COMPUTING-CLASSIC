output "Detalle" {
  description = "🏗️ Resumen de la infraestructura desplegada"
  value = <<EOT
====================================
🚀 Infraestructura Metabase en Kubernetes
====================================

🔐 Acceso de Administración:
----------------------------
VM Docker: ${openstack_compute_instance_v2.docker_vm.network.0.fixed_ip_v4}
Usuario: ubuntu
Comando SSH: ssh ubuntu@${openstack_compute_instance_v2.docker_vm.network.0.fixed_ip_v4}

🌐 Acceso a la Aplicación:
--------------------------
URL Metabase: https://lucasg-metabase.my.kube.um.edu.ar
Usuario inicial: [La que configuraste en var.metabase_mail]
Contraseña: [La que configuraste en var.metabase_password]

💻 Detalles del Despliegue:
---------------------------
- 📊 Aplicación Metabase: Deployment/metabase
  Namespace: var.namespace
- 🗄️ Base de Datos MySQL: Deployment/mysql
  Namespace: var.namespace

🌐 Detalles de Kubernetes:
--------------------------
- Namespace: var.namespace
- Ingress: metabase-ingress
- Services: 
  - metabase (ClusterIP)
  - mysql (ClusterIP)

🛡️ Recursos de Kubernetes:
---------------------------
- ConfigMap: metabase-config, db-init-script
- Secret: metabase-secrets
- PersistentVolumeClaim: mysql-pv-claim

📊 Dashboard:
-------------
URL del Dashboard: https://lucasg-metabase.my.kube.um.edu.ar/dashboard/1

🔍 Comandos Útiles:
-------------------
Verificar estado de Metabase:
kubectl get pods -n lucas-garcia-metabase -l app=metabase

Verificar estado de MySQL:
kubectl get pods -n lucas-garcia-metabase -l app=mysql

Ver logs de Metabase:
kubectl logs -n lucas-garcia-metabase -l app=metabase

Ver logs de MySQL:
kubectl logs -n lucas-garcia-metabase -l app=mysql

📝 Notas:
---------
- Recuerda cambiar la contraseña del usuario admin de Metabase después del primer inicio de sesión.
- La base de datos está preconfigurada con los datos importados del archivo SQL proporcionado.
- Para acceder a los recursos de Kubernetes, utiliza la VM Docker como punto de entrada.

EOT
}