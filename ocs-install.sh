#!/bin/bash

# Función para solicitar confirmación del usuario
confirm() {
    read -p "$1 (Y/n): " response
    case "$response" in
        [nN][oO]|[nN])
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# Función para verificar si MariaDB está instalada
check_mariadb_installed() {
    dpkg -s mariadb-server &>/dev/null
    return $?
}

# Configurar la zona horaria
unlink /etc/localtime
ln -s /usr/share/zoneinfo/America/Bogota /etc/localtime

# Actualización del sistema
if confirm "¿Deseas actualizar el sistema?"; then
    apt update && apt upgrade -y
else
    echo "Actualización omitida."
fi

# Instalar dependencias necesarias para OCS Inventory
apt install -y libxml-simple-perl libdbi-perl libdbd-mysql-perl libapache-dbi-perl libnet-ip-perl libsoap-lite-perl libarchive-zip-perl make build-essential libio-compress-perl nano

# Instalación de Apache
if confirm "¿Deseas instalar Apache?"; then
    apt install apache2 -y
    a2enmod perl
    systemctl restart apache2
else
    echo "Instalación de Apache omitida."
fi

# Agregar el repositorio de PHP de Ondřej y actualizar
if confirm "¿Deseas instalar PHP 7.4 y sus módulos?"; then
    LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y
    apt update
    apt install php7.4 php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring php7.4-curl php7.4-xml php7.4-soap -y
else
    echo "Instalación de PHP 7.4 omitida."
fi

# Instalar y configurar MariaDB
if confirm "¿Deseas instalar MariaDB?"; then
    apt install mariadb-server -y
    systemctl start mariadb
    systemctl enable mariadb
    mysql_secure_installation
    # Configurar MariaDB con base de datos y usuario para OCS Inventory
echo "Configurando MariaDB con base de datos y usuario para OCS Inventory..."
mysql -u root <<EOF
CREATE DATABASE ocsweb;
CREATE USER 'ocs'@'localhost' IDENTIFIED BY 'ocs';
GRANT ALL PRIVILEGES ON ocsweb.* TO 'ocs'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
else
    echo "Instalación de MariaDB omitida."
fi


# Instalar módulos Perl adicionales
if confirm "¿Instalar módulos Perl adicionales?"; then
    cpan install XML::Entities
    perl -MCPAN -e 'install Mojolicious'
    perl -MCPAN -e 'install Switch'
    perl -MCPAN -e 'install Plack::Handler'

    # Instalar módulos Perl adicionales
    cpan install XML::Entities
    perl -MCPAN -e 'install Mojolicious'
    perl -MCPAN -e 'install Switch'
    perl -MCPAN -e 'install Plack::Handler'
else
    echo "Instalación de módulos Perl adicionales omitida."
fi

# Configurar php.ini para Apache y CLI

if confirm "¿Configurar php.ini para Apache y CLI?"; then

    PHP_INI_APACHE="/etc/php/7.4/apache2/php.ini"
    PHP_INI_CLI="/etc/php/7.4/cli/php.ini"

    # Función para configurar php.ini
    configure_php_ini() {
        sed -i 's/^short_open_tag = .*/short_open_tag = On/' $1
        sed -i 's/^post_max_size = .*/post_max_size = 1024M/' $1
        sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 256M/' $1
    }

    echo "Configurando PHP para Apache..."
    configure_php_ini $PHP_INI_APACHE
    echo "Configurando PHP para CLI..."
    configure_php_ini $PHP_INI_CLI
else
    echo "Configuracion de php.ini para Apache y CLI omitida"
fi    

# Preguntar si se desea instalar OCS Inventory
if confirm "¿Deseas instalar OCS Inventory?"; then
    echo "Instalando OCS Inventory..."
    # Cambiar al directorio /opt
    cd /opt
    # Descargar OCS Inventory
    wget https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/2.12.1/OCSNG_UNIX_SERVER-2.12.1.tar.gz
    # Descomprimir el archivo
    tar -xzvf OCSNG_UNIX_SERVER-2.12.1.tar.gz
    # Cambiar al directorio descomprimido
    cd OCSNG_UNIX_SERVER-2.12.1
    # Ejecutar el script de configuración
    ./setup.sh
    # Habilitar la configuración de Apache para OCS Inventory
    a2enconf ocsinventory-reports.conf
    a2enconf z-ocsinventory-server.conf
    # Cambiar el propietario de los archivos necesarios a www-data
    chown -R www-data:www-data /var/lib/ocsinventory-reports/
    # Reiniciar Apache para aplicar los cambios
    systemctl restart apache2
else
    echo "Instalación de OCS Inventory omitida."
fi

echo "Instalación completada."
