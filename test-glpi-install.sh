#!/bin/bash

sudo apt install curl

# Inicializar contadores
total_tests=0
passed_tests=0
failed_tests=0
failed_items=()

# Función para verificar la instalación de un paquete
check_package() {
    ((total_tests++))
    dpkg -s $1 &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Paquete $1 está instalado."
        ((passed_tests++))
    else
        echo "Paquete $1 NO está instalado."
        ((failed_tests++))
        failed_items+=("$1")
    fi
}

# Función para verificar si un servicio está corriendo
check_service_running() {
    ((total_tests++))
    systemctl is-active --quiet $1
    if [ $? -eq 0 ]; then
        echo "Servicio $1 está corriendo."
        ((passed_tests++))
    else
        echo "Servicio $1 NO está corriendo."
        ((failed_tests++))
        failed_items+=("$1 service")
    fi
}

# Verificar Apache, MariaDB, PHP y GLPI
check_package apache2
check_package mariadb-server
check_package php8.3
check_package php8.3-common
check_package php8.3-cli
check_package php8.3-fpm
check_package php8.3-xml
check_package php8.3-curl
check_package php8.3-gd
check_package php8.3-intl
check_package php8.3-mysql
check_package php8.3-bz2
check_package php8.3-zip
check_package php8.3-ldap
check_package php8.3-opcache

# Verificar si GLPI está instalado
((total_tests++))
if [ -d "/var/www/html/glpi" ]; then
    echo "GLPI está instalado en /var/www/html/glpi."
    ((passed_tests++))
else
    echo "GLPI NO está instalado en /var/www/html/glpi."
    ((failed_tests++))
    failed_items+=("GLPI directory")
fi

# Verificar servicios
check_service_running apache2
check_service_running mariadb
check_service_running php8.3-fpm

# Verificar archivos de configuración de GLPI
((total_tests++))
if [ -f "/etc/glpi/local_define.php" ]; then
    echo "Archivo de configuración de GLPI local_define.php existe."
    ((passed_tests++))
else
    echo "Archivo de configuración de GLPI local_define.php NO existe."
    ((failed_tests++))
    failed_items+=("GLPI local_define.php")
fi

# Test final para verificar el acceso a GLPI y la cadena específica en la página
((total_tests++))
echo "Verificando acceso a GLPI en http://localhost:8080/install/install.php..."
web_content=$(curl -s http://localhost:8080/install/install.php)
if echo "$web_content" | grep -q "GLPI SETUP"; then
    echo "La página de GLPI cargó correctamente y contiene la cadena esperada."
    ((passed_tests++))
else
    echo "GLPI no cargó correctamente o no contiene la cadena esperada."
    ((failed_tests++))
    failed_items+=("GLPI web page content")
fi

# Resumen de los resultados
echo "--------------------------------"
echo "Resumen de pruebas:"
echo "Total de pruebas: $total_tests"
echo "Pruebas pasadas: $passed_tests"
echo "Pruebas fallidas: $failed_tests"
if [ $failed_tests -ne 0 ]; then
    echo "Items que fallaron las pruebas:"
    for item in "${failed_items[@]}"; do
        echo " - $item"
    done
fi