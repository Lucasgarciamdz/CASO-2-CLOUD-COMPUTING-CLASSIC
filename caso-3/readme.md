# Metabase en Kubernetes con Terraform

Este proyecto despliega una instancia de Metabase en Kubernetes utilizando Terraform y OpenStack. Está diseñado como parte de un trabajo para la materia Teleinformática en la Universidad de Mendoza.

## Autor

Lucas Garcia

## Descripción del Proyecto

Este proyecto automatiza el despliegue de Metabase, una herramienta de visualización de datos, junto con una base de datos MySQL en un clúster de Kubernetes. Utiliza Terraform para provisionar la infraestructura en OpenStack y configurar los recursos necesarios en Kubernetes a través de Rancher.

## Componentes del Proyecto

- **Terraform**: Para la provisión de infraestructura y configuración de Kubernetes.
- **Kubernetes**: Para orquestar los contenedores de Metabase y MySQL.
- **Rancher**: Para la gestión del clúster de Kubernetes.
- **Metabase**: Herramienta de visualización de datos.
- **MySQL**: Base de datos para almacenar los datos de Metabase.

## Recursos de Kubernetes Creados

- **Namespace**: `lucas-garcia-metabase`
- **Deployments**:
  - Metabase
  - MySQL
- **Services**:
  - Metabase (ClusterIP)
  - MySQL (ClusterIP)
- **Ingress**: Para exponer Metabase externamente
- **ConfigMaps**: Para configuración de Metabase y scripts de inicialización de la base de datos
- **Secrets**: Para almacenar credenciales sensibles
- **PersistentVolumeClaim**: Para el almacenamiento persistente de MySQL

## Prerrequisitos

- Terraform instalado
- Acceso a OpenStack
- Credenciales de Rancher

## Configuración

1. Copia el archivo `env-example.txt` a `.env`: `cp env-example.txt .env`
2. Edita el archivo `.env` y completa todas las variables requeridas:
- Credenciales de OpenStack
- Token de Rancher
- Credenciales para Metabase y MySQL
- Otras configuraciones específicas del proyecto

## Despliegue

1. Carga las variables de entorno: `source .export_env.sh` ó `export $(grep -v '^#' .env | xargs)`

2. Inicializa Terraform: `tofu init`
3. Aplica la configuración: `tofu apply`

El proceso realizará las siguientes acciones:
- Creará una máquina virtual con Kubernetes instalado
- Realizará login en Rancher usando el token proporcionado
- Creará un proyecto en Rancher
- Creará un namespace en Kubernetes
- Aplicará todos los archivos YAML del proyecto
- Realizará la carga inicial de la base de datos
- Configurará una pregunta y un dashboard en Metabase

## Acceso a Metabase

Una vez completado el despliegue, podrás acceder a Metabase a través de la URL proporcionada en la salida de Terraform. Utiliza las credenciales especificadas en el archivo `.env` para iniciar sesión.

## Estructura del Proyecto

- `main.tf`: Configuración principal de Terraform
- `variables.tf`: Definición de variables
- `output.tf`: Configuración de salidas
- `kubernetes/`: Directorio con archivos YAML de Kubernetes
- `deployment.yaml`: Configuraciones de deployments
- `service.yaml`: Definiciones de servicios
- `ingress.yaml`: Configuración del ingress
- `configmap.yaml`: ConfigMaps
- `secret.yaml`: Definición de secrets
- `pvc.yaml`: PersistentVolumeClaim para MySQL

## Notas Importantes

- Asegúrate de cambiar la contraseña del usuario admin de Metabase después del primer inicio de sesión.
- La base de datos está preconfigurada con los datos importados del archivo SQL proporcionado.
- Para acceder a los recursos de Kubernetes, utiliza la VM Docker como punto de entrada.

## Limpieza

Para eliminar todos los recursos creados: `tofu destroy`