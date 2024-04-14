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

# Función para verificar si Apache está instalado
check_apache_installed() {
    dpkg -s apache2 &>/dev/null
    return $?
}

check_mariadb_installed() {
    dpkg -s mariadb-server &>/dev/null
    return $?
}


# Actualizar el sistema y preparar el entorno
if confirm "¿Deseas actualizar el sistema y preparar el entorno para PHP 8.3?"; then
    sudo apt update && sudo apt upgrade -y
    sudo apt install software-properties-common
    sudo add-apt-repository ppa:ondrej/php
else
    echo "Actualización y preparación omitidas."
fi

# Instalar PHP 8.3 y extensiones necesarias para GLPI
if confirm "¿Deseas instalar PHP 8.3 y las extensiones necesarias para GLPI?"; then
    sudo apt install php8.3 php8.3-common php8.3-cli php8.3-fpm php8.3-xml php8.3-curl php8.3-gd php8.3-intl php8.3-mysql php8.3-bz2 php8.3-zip php8.3-ldap php8.3-opcache
else
    echo "Instalación de PHP 8.3 y extensiones omitida."
fi

# Configurar PHP-FPM Pools para GLPI
if confirm "¿Deseas configurar PHP-FPM Pool para GLPI?"; then
    sudo cp /etc/php/8.3/fpm/pool.d/www.conf /etc/php/8.3/fpm/pool.d/glpi.conf
    # Edición del archivo glpi.conf
    sudo sed -i 's/\[www\]/\[glpi\]/' /etc/php/8.3/fpm/pool.d/glpi.conf
    sudo sed -i '/^user = www-data/c\user = www-data' /etc/php/8.3/fpm/pool.d/glpi.conf
    sudo sed -i '/^group = www-data/c\group = www-data' /etc/php/8.3/fpm/pool.d/glpi.conf
    sudo sed -i '/^listen = .*/c\listen = /run/php/php8.3-glpi.sock' /etc/php/8.3/fpm/pool.d/glpi.conf
    sudo sed -i '/^pm.max_children = .*/c\pm.max_children = 50' /etc/php/8.3/fpm/pool.d/glpi.conf
    sudo sed -i '/^pm.start_servers = .*/c\pm.start_servers = 5' /etc/php/8.3/fpm/pool.d/glpi.conf
    sudo sed -i '/^pm.min_spare_servers = .*/c\pm.min_spare_servers = 5' /etc/php/8.3/fpm/pool.d/glpi.conf
    sudo sed -i '/^pm.max_spare_servers = .*/c\pm.max_spare_servers = 35' /etc/php/8.3/fpm/pool.d/glpi.conf

    # Reiniciar PHP-FPM
    sudo systemctl restart php8.3-fpm
else
    echo "Configuración de PHP-FPM Pool para GLPI omitida."
fi

# Instalar Apache si no está instalado
if check_apache_installed; then
    echo "Apache ya está instalado."
else
    if confirm "Apache no está instalado. ¿Deseas instalarlo ahora?"; then
        sudo apt update
        sudo apt install apache2
        sudo systemctl start apache2
        sudo systemctl enable apache2
        echo "Apache ha sido instalado y configurado para iniciar automáticamente."
    else
        echo "Instalación de Apache omitida."
    fi
fi

# Activar módulos necesarios para Apache
if confirm "¿Deseas activar los módulos proxy_fcgi y setenvif para Apache?"; then
    sudo a2enmod proxy_fcgi setenvif
    sudo systemctl restart apache2
    echo "Módulos proxy_fcgi y setenvif activados y Apache reiniciado."
else
    echo "Activación de módulos omitida."
fi

# Configurar Apache para GLPI
if confirm "¿Deseas configurar Apache para GLPI?"; then
    sudo a2enmod rewrite
    # Verificar si el puerto 8080 ya está configurado en ports.conf
    if ! grep -q 'Listen 8080' /etc/apache2/ports.conf; then
        echo "Listen 8080" | sudo tee -a /etc/apache2/ports.conf
        echo "Configuración del puerto 8080 agregada a Apache."
    else
        echo "El puerto 8080 ya está configurado en Apache."
    fi

    # Configurar Virtual Host para GLPI
    sudo tee /etc/apache2/sites-available/glpi.conf > /dev/null <<EOF
<VirtualHost *:8080>
    ServerName glpi.bonsana.com
    DocumentRoot /var/www/html/glpi/public
    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php8.3-glpi.sock|fcgi://localhost/"
    </FilesMatch>
    <Directory /var/www/html/glpi/public>
        Require all granted
        RewriteEngine On
        RewriteCond %{HTTP:Authorization} ^(.+)$
        RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>
EOF
    echo "Virtual Host para GLPI configurado."
    sudo a2ensite glpi.conf
    sudo systemctl restart php8.3-fpm
    sudo systemctl restart apache2
    echo "Apache y PHP-FPM reiniciados para aplicar configuración."
else
    echo "Configuración Apache para GLPI omitida."
fi

# Instalar MariaDB si no está instalada
if check_mariadb_installed; then
    echo "MariaDB ya está instalada."
else
    if confirm "MariaDB no está instalada. ¿Deseas instalarla ahora?"; then
        sudo apt update
        sudo apt install mariadb-server
        sudo systemctl start mariadb
        sudo mysql_secure_installation
        echo "MariaDB ha sido instalada y configurada."
    else
        echo "Instalación de MariaDB omitida."
    fi
fi

# Crear usuario y base de datos para GLPI
if confirm "¿Deseas crear una base de datos y un usuario para GLPI?"; then
    # Ejecutar comandos SQL desde el shell script
    sudo mysql -uroot -e "
    CREATE DATABASE IF NOT EXISTS glpi;
    CREATE USER IF NOT EXISTS 'glpi'@'localhost' IDENTIFIED BY 'B0ns4n4';
    GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';
    GRANT SELECT ON \`mysql\`.\`time_zone_name\` TO 'glpi'@'localhost';
    FLUSH PRIVILEGES;"
    echo "Base de datos y usuario para GLPI han sido creados."
else
    echo "Creación de base de datos y usuario para GLPI omitida."
fi

# Instalar GLPI
if confirm "¿Deseas instalar GLPI?"; then
    cd /var/www/html
    wget https://github.com/glpi-project/glpi/releases/download/10.0.14/glpi-10.0.14.tgz
    tar -xvzf glpi-10.0.14.tgz

    # Crear y configurar archivo downstream.php
    echo "<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
    require_once GLPI_CONFIG_DIR . '/local_define.php';
}" | sudo tee /var/www/html/glpi/inc/downstream.php

    # Mover directorios de configuración y archivos
    sudo mv /var/www/html/glpi/config /etc/glpi
    sudo mv /var/www/html/glpi/files /var/lib/glpi
    sudo mv /var/lib/glpi/_log /var/log/glpi

    # Crear local_define.php
    echo "<?php
define('GLPI_VAR_DIR', '/var/lib/glpi');
define('GLPI_DOC_DIR', GLPI_VAR_DIR);
define('GLPI_CRON_DIR', GLPI_VAR_DIR . '/_cron');
define('GLPI_DUMP_DIR', GLPI_VAR_DIR . '/_dumps');
define('GLPI_GRAPH_DIR', GLPI_VAR_DIR . '/_graphs');
define('GLPI_LOCK_DIR', GLPI_VAR_DIR . '/_lock');
define('GLPI_PICTURE_DIR', GLPI_VAR_DIR . '/_pictures');
define('GLPI_PLUGIN_DOC_DIR', GLPI_VAR_DIR . '/_plugins');
define('GLPI_RSS_DIR', GLPI_VAR_DIR . '/_rss');
define('GLPI_SESSION_DIR', GLPI_VAR_DIR . '/_sessions');
define('GLPI_TMP_DIR', GLPI_VAR_DIR . '/_tmp');
define('GLPI_UPLOAD_DIR', GLPI_VAR_DIR . '/_uploads');
define('GLPI_CACHE_DIR', GLPI_VAR_DIR . '/_cache');
define('GLPI_LOG_DIR', '/var/log/glpi');
?>" | sudo tee /etc/glpi/local_define.php

    # Establecer permisos adecuados
    sudo chown root:root /var/www/html/glpi/ -R
    sudo chown www-data:www-data /etc/glpi -R
    sudo chown www-data:www-data /var/lib/glpi -R
    sudo chown www-data:www-data /var/log/glpi -R
    sudo chown www-data:www-data /var/www/html/glpi/marketplace -Rf
    sudo find /var/www/html/glpi/ -type f -exec chmod 0644 {} \;
    sudo find /var/www/html/glpi/ -type d -exec chmod 0755 {} \;
    sudo find /etc/glpi -type f -exec chmod 0644 {} \;
    sudo find /etc/glpi -type d -exec chmod 0755 {} \;
    sudo find /var/lib/glpi -type f -exec chmod 0644 {} \;
    sudo find /var/lib/glpi -type d -exec chmod 0755 {} \;
    sudo find /var/log/glpi -type f -exec chmod 0644 {} \;
    sudo find /var/log/glpi -type d -exec chmod 0755 {} \;

    # Configurar Apache para GLPI
    sudo a2dissite 000-default.conf
    sudo a2enmod rewrite
    sudo a2ensite glpi.conf
    sudo systemctl restart apache2

    for CONFIG_FILE in /etc/php/8.3/cli/php.ini /etc/php/8.3/fpm/php.ini; do
        if [ -f "$CONFIG_FILE" ]; then
            echo "Actualizando configuración en $CONFIG_FILE"
            sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 20M/' $CONFIG_FILE
            sudo sed -i 's/post_max_size = .*/post_max_size = 20M/' $CONFIG_FILE
            sudo sed -i 's/max_execution_time = .*/max_execution_time = 60/' $CONFIG_FILE
            sudo sed -i 's/max_input_vars = .*/max_input_vars = 5000/' $CONFIG_FILE
            sudo sed -i 's/memory_limit = .*/memory_limit = 256M/' $CONFIG_FILE
            sudo sed -i 's/session.cookie_httponly = .*/session.cookie_httponly = On/' $CONFIG_FILE
            sudo sed -i "s/;date.timezone =.*/date.timezone = America\/Bogota/" $CONFIG_FILE
        else
            echo "Archivo de configuración $CONFIG_FILE no encontrado."
        fi
    done
    echo "La configuración de PHP ha sido actualizada."
    sudo systemctl restart php8.3-fpm # Reiniciar PHP-FPM para aplicar los cambios
    echo "GLPI ha sido instalado y configurado."
else
    echo "Instalación de GLPI omitida."
fi

echo "Script completado."
