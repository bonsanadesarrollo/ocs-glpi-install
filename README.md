# Instalación Automatizada de OCS Inventory y GLPI

Este repositorio contiene scripts para automatizar la instalación de OCS Inventory y GLPI en un servidor Ubuntu 22.04.

## Descripción

OCS (Open Computers and Software) Inventory y GLPI (Gestionnaire Libre de Parc Informatique) son dos plataformas de código abierto que permiten la gestión de inventario y la mesa de ayuda IT, respectivamente. Este conjunto de scripts facilita la configuración de un entorno de servidor para desplegar estas aplicaciones de manera eficiente y consistente.

## Estructura del Repositorio
```bash
test-glpi-install.sh # Script de pruebas para verificar la instalación de GLPI
test-ocs-install.sh # Script de pruebas para verificar la instalación de OCS Inventory
glpi-install.sh # Script de instalación de GLPI
ocs-install.sh # Script de instalación de OCS Inventory
```

## Uso
Para utilizar los scripts de este repositorio, siga los pasos a continuación:
1. Clonar el repositorio en su servidor Ubuntu 22.04.

```bash
git clone https://github.com/bonsanadesarrollo/ocs-glpi-install.git
cd ocs-glpi-install
chmod +x *.sh
```

Ejecute el script install-and-test-all.sh para iniciar la instalación y las pruebas de OCS Inventory y GLPI.
```bash
# Instalar OCS Inventory
./ocs-install.sh
# Compruebe si la instalacion  de OCS Inventory es existosa corriendo esta prueba
./test-ocs-install.sh
# Instalar GLPI
./glpi-install.sh
# Compruebe si la instalacion  de GLPI es existosa corriendo esta prueba
./test-glpi-install.sh
```


## Prerequisitos
Antes de ejecutar los scripts, asegúrese de que su servidor cumpla con los siguientes requisitos:

Una instalación limpia de Ubuntu 22.04.
Acceso a internet para descargar paquetes necesarios.
Privilegios de superusuario (sudo).
