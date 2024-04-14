#!/bin/bash

# Función para verificar la presencia de un paquete
check_package() {
    if dpkg -l | grep -qw $1; then
        echo "OK: $1 está instalado."
    else
        echo "ERROR: $1 NO está instalado."
    fi
}

# Función para verificar la versión de PHP
check_php_version() {
    if php -v | grep -q "PHP 7.4"; then
        echo "OK: PHP 7.4 está instalado."
    else
        echo "ERROR: PHP 7.4 NO está instalado."
    fi
}

# Función para verificar el servicio Apache
check_service() {
    if systemctl is-active --quiet $1; then
        echo "OK: El servicio $1 está corriendo."
    else
        echo "ERROR: El servicio $1 NO está corriendo."
    fi
}

# Función para verificar módulos Perl
check_perl_module() {
    if perl -M$1 -e ';' 2>/dev/null; then
        echo "OK: El módulo Perl $1 está instalado."
    else
        echo "ERROR: El módulo Perl $1 NO está instalado."
    fi
}

# Verificaciones de paquetes
echo "Comprobando paquetes..."
check_package apache2
check_package mariadb-server
check_package php7.4
check_package libxml-simple-perl
check_package libdbi-perl
check_package libdbd-mysql-perl
check_package libapache-dbi-perl
check_package libnet-ip-perl
check_package libsoap-lite-perl
check_package libarchive-zip-perl
check_package make
check_package build-essential
check_package libio-compress-perl
check_package nano

# Verificar la versión de PHP
check_php_version

# Verificaciones de servicios
echo "Comprobando servicios..."
check_service apache2
check_service mariadb

# Verificar módulos Perl
echo "Comprobando módulos Perl..."
check_perl_module XML::Entities
check_perl_module Mojolicious
check_perl_module Switch
check_perl_module Plack::Handler

echo "Comprobaciones completadas."
