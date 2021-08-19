#!/bin/bash

COL_NC='\e[0m' #No Color
COL_LIGHT_GREEN='\e[1;32m'
COL_LIGHT_RED='\e[1;31m'
TICK="[${COL_LIGHT_GREEN}✓${COL_NC}]"
CROSS="[${COL_LIGHT_RED}✗${COL_NC}]"
INFO="[i]"
DONE="${COL_LIGHT_GREEN} done!${COL_NC}"
OVER="\\r\\033[K"

#CONFIG
PASS_RESULTS='NULL'
RAW_GIT=https://raw.githubusercontent.com/HaziFlorinMarian/openlitespeed-autoinstall-centos7/master
WEB_DIR=/usr/local/lsws

#Password Generator
function GetRandomPassword {
    dd if=/dev/urandom bs=8 count=1 of=/tmp/gen_password >/dev/null 2>&1
    PASS_RESULTS=`cat /tmp/gen_password`
    rm /tmp/gen_password
    local DATE=`date`
    PASS_RESULTS=`echo "$PASS_RESULTS$RANDOM$DATE" |  md5sum | base64 | head -c 32`
}

GetRandomPassword
PWD_SQL_DATABASE=$PASS_RESULTS
PWD_PHP_MYADMIN=$PASS_RESULTS

#Checking SELinux
CheckSelinuxStatus() {
    local DEFAULT_SELINUX
    local CURRENT_SELINUX
    local SELINUX_ENFORCING=0
    if [[ -f /etc/selinux/config ]] && command -v getenforce &> /dev/null; then
        DEFAULT_SELINUX=$(awk -F= '/^SELINUX=/ {print $2}' /etc/selinux/config)
        case "${DEFAULT_SELINUX,,}" in
            enforcing)
                printf "  %b %bDefault SELinux: %s%b\\n" "${CROSS}" "${COL_LIGHT_RED}" "${DEFAULT_SELINUX}" "${COL_NC}"
                SELINUX_ENFORCING=1
                ;;
            *)
                printf "  %b %bDefault SELinux: %s%b\\n" "${TICK}" "${COL_LIGHT_GREEN}" "${DEFAULT_SELINUX}" "${COL_NC}"
                ;;
        esac
        CURRENT_SELINUX=$(getenforce)
        case "${CURRENT_SELINUX,,}" in
            enforcing)
                printf "  %b %bCurrent SELinux: %s%b\\n" "${CROSS}" "${COL_LIGHT_GREEN}" "${CURRENT_SELINUX}" "${COL_NC}"
                SELINUX_ENFORCING=1
                ;;
            *)
                printf "  %b %bCurrent SELinux: %s%b\\n" "${TICK}" "${COL_LIGHT_GREEN}" "${CURRENT_SELINUX}" "${COL_NC}"
                ;;
        esac
    else
        echo -e "  ${INFO} ${COL_LIGHT_GREEN}SELinux not detected${COL_NC}";
    fi
    if [[ "${SELINUX_ENFORCING}" -eq 1 ]]; then
        printf "  Open Lite Speed Web Server Auto Installer does not support SELinux, please disable SELinux on your system to continue with the installation.\\n"
        printf "\\n  %bSELinux Enforcing detected, exiting installer%b\\n" "${COL_LIGHT_RED}" "${COL_NC}";
		read -e -p "Disabled SELinux [y/N] : " disable_selinux
		if [[ ("$disable_selinux" == "y" || "$disable_selinux" == "Y") ]]; then
			sudo sed -i 's/enforcing/disabled/' /etc/selinux/config
			sudo sed -i 's/permissive/disabled/' /etc/selinux/config
			echo -e "  ${TICK} ${COL_LIGHT_GREEN}2sec Reboot System${COL_NC}";
			sleep 2
			reboot
		else
			clear
			exit 1
		fi
    fi
}

show_ascii_okf() {
clear
echo -e ""
echo -e "${COL_LIGHT_GREEN} OOOOOOOOOOO   KKK   KKK  FFFFFFFF  LLL             AAAAA        SSSSSSSSSSS  HHH     HHH 
OOO       OOO  KKK  KKK   FFFFFFFF  LLL            AAA AAA       SSSSSSSSSSS  HHH     HHH
OOO       OOO  KKK KKK    FFF       LLL           AAA   AAA      SSS          HHH     HHH
OOO       OOO  KKKKK      FFFFFFFF  LLL          AAA     AAA     SSSSSSSSSSS  HHHHHHHHHHH${COL_LIGHT_RED}
OOO       OOO  KKKKK      FFFFFFFF  LLL         AAAAAAAAAAAAA    SSSSSSSSSSS  HHHHHHHHHHH
OOO       OOO  KKK KKK    FFF       LLL        AAAAAAAAAAAAAAA           SSS  HHH     HHH
OOO       OOO  KKK  KKK   FFF       LLLLLLLL  AAA           AAA  SSSSSSSSSSS  HHH     HHH
 OOOOOOOOOOO   KKK   KKK  FFF       LLLLLLLL AAA             AAA SSSSSSSSSSS  HHH     HHH${COL_NC}"
echo -e ""
echo -e "${COL_LIGHT_GREEN}Open Lite Speed Web Server Auto Installer - https://www.okflash.net${COL_NC}"
echo -e ""
if [[ "${EUID}" -eq 0 ]]; then
	echo -e "  ${TICK} ${COL_LIGHT_GREEN}Root Access${COL_NC}";
else
	echo -e "  ${CROSS} ${COL_LIGHT_RED}Root Access${COL_NC}";
	printf "  Openlitespeed Web Server Auto Installer, must use an account with root access to do the installation.\\n"
	printf "\\n  %bAccount does not have root access, exiting installer%b\\n" "${COL_LIGHT_RED}" "${COL_NC}";
	exit 1
fi
CheckSelinuxStatus
}

show_ascii_okf
echo -e ""
echo -e "::::::::::::::::::::::::::::::::::::::::::::::::::::"
echo -e "::: Choose a number, PHP version to be installed :::"
echo -e "::::::::::::::::::::::::::::::::::::::::::::::::::::"
echo -e ""
echo -e "    1. PHP 5.6"
echo -e "    2. PHP 7.0"
echo -e "    3. PHP 7.1"
echo -e "    4. PHP 7.2"
echo -e "    5. PHP 7.3"
echo -e "    6. PHP 7.4"
echo -e ""
read -e -p "::: SELECT NUMBER PHP VERSION : " phpversion

#Select PHP Version
if [[ ("$phpversion" == "1") ]]; then
	verphpinstall=56
elif [[ ("$phpversion" == "2") ]]; then
	verphpinstall=70
elif [[ ("$phpversion" == "3") ]]; then
	verphpinstall=71
elif [[ ("$phpversion" == "4") ]]; then
	verphpinstall=72
elif [[ ("$phpversion" == "5") ]]; then
	verphpinstall=73
elif [[ ("$phpversion" == "6") ]]; then
	verphpinstall=74
else
 exit 1
fi;

show_ascii_okf
echo -e ""
echo -e "::::::::::::::::::::::::::::::::::::::::::::::::::::::"
echo -e "::: Choose a number, Database type to be installed :::"
echo -e "::::::::::::::::::::::::::::::::::::::::::::::::::::::"
echo -e ""
echo -e "   1. MariaDB 10.3"
echo -e "   2. Percona Server 5.6"
echo -e ""
read -e -p "::: SELECT NUMBER DATABASE : " dbversion

if [[ ("$dbversion" == "1") ]]; then
	dbinstall="MariaDB 10.3"
elif [[ ("$dbversion" == "2") ]]; then
    dbinstall="Percona Server 5.6"
else
 exit 1
fi;

show_ascii_okf
echo -e ""
echo -e ":::::::::::::::::::::::"
echo -e "::: Install Proftpd :::"
echo -e ":::::::::::::::::::::::"
echo -e ""
read -e -p "::: Install Proftpd : [y/N] : " PROFTPD

show_ascii_okf
echo -e ""
echo -e "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
echo -e "::: You are sure you want to install the selected packages :::"
echo -e "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
echo -e ""
echo -e "   Database Type : $dbinstall"
echo -e "   PHP Version :  $verphpinstall"
echo -e "   Install Proftpd : $PROFTPD"
echo -e ""
read -e -p "::: Type (y) to start the installation or N to cancel [y/N] : " STARTINSTALL
clear

if [[ ("$STARTINSTALL" == "y" || "$STARTINSTALL" == "Y") ]]; then

	yum -y install epel-release
	yum -y install wget certbot openssl firewalld
	rpm -ivh http://rpms.litespeedtech.com/centos/litespeed-repo-1.1-1.el7.noarch.rpm
	yum -y update
	yum clean all
	
	if [[ ("$PROFTPD" == "y" || "$PROFTPD" == "Y") ]]; then
		yum -y install proftpd
		sed -i "s/ProFTPD server/$HOSTNAME/g" /etc/proftpd.conf
	fi;
	
    mkdir -p /home/defaultdomain/{html,logs}
    yum -y install openlitespeed
	
	if [[ ("$verphpinstall" == "56" || "$verphpinstall" == "70" || "$verphpinstall" == "71" || "$verphpinstall" == "72" || "$verphpinstall" == "73" || "$verphpinstall" == "74") ]]; then
		yum -y install lsphp$verphpinstall lsphp$verphpinstall-bcmath lsphp$verphpinstall-common lsphp$verphpinstall-dba lsphp$verphpinstall-dbg lsphp$verphpinstall-devel lsphp$verphpinstall-enchant lsphp$verphpinstall-gd lsphp$verphpinstall-gmp lsphp$verphpinstall-imap lsphp$verphpinstall-intl lsphp$verphpinstall-json lsphp$verphpinstall-ldap lsphp$verphpinstall-mbstring lsphp$verphpinstall-mysqlnd lsphp$verphpinstall-odbc lsphp$verphpinstall-opcache lsphp$verphpinstall-pdo lsphp$verphpinstall-pear lsphp$verphpinstall-pecl-apcu-devel lsphp$verphpinstall-pecl-igbinary lsphp$verphpinstall-pecl-igbinary-devel lsphp$verphpinstall-pecl-mcrypt lsphp$verphpinstall-pecl-memcache lsphp$verphpinstall-pecl-msgpack lsphp$verphpinstall-pecl-msgpack-devel lsphp$verphpinstall-pgsql lsphp$verphpinstall-process lsphp$verphpinstall-pspell lsphp$verphpinstall-recode lsphp$verphpinstall-snmp lsphp$verphpinstall-soap lsphp$verphpinstall-tidy lsphp$verphpinstall-xml lsphp$verphpinstall-xmlrpc lsphp$verphpinstall-zip
	fi;

	if [[ ("$dbversion" == "1") ]]; then
		wget -O /etc/yum.repos.d/MariaDB.repo $RAW_GIT/repository/MariaDB.repo
		yum -y update
		yum -y install MariaDB-server MariaDB-client
	elif [[ ("$dbversion" == "2") ]]; then
		yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
		yum -y install http://repo.percona.com/centos/7/RPMS/x86_64/Percona-Server-selinux-56-5.6.45-rel86.1.el7.noarch.rpm	
		yum -y update
		yum list | grep percona
		yum install Percona-Server-server-56
	fi;
	
	
	touch $WEB_DIR/domain
	mv -f $WEB_DIR/conf/vhosts/Example/ $WEB_DIR/conf/vhosts/defaultdomain/
	rm -f $WEB_DIR/conf/vhosts/defaultdomain/vhconf.conf
	rm -f $WEB_DIR/conf/httpd_config.conf
	rm -f $WEB_DIR/admin/conf/admin_config.conf
	wget -O $WEB_DIR/conf/vhosts/defaultdomain/vhconf.conf $RAW_GIT/config/vhconf.conf
	wget -O $WEB_DIR/conf/httpd_config.conf $RAW_GIT/config/httpd_config.conf
	wget -O $WEB_DIR/admin/conf/admin_config.conf $RAW_GIT/config/admin_config.conf
	chown lsadm:lsadm $WEB_DIR/conf/vhosts/defaultdomain/vhconf.conf
	chown lsadm:lsadm $WEB_DIR/conf/httpd_config.conf
	chown lsadm:lsadm $WEB_DIR/admin/conf/admin_config.conf
	chmod +x /usr/bin/lsws
	wget -O $WEB_DIR/conf/templates/incl.conf $RAW_GIT/templates/incl.conf
	wget -O $WEB_DIR/conf/templates/vhconf.conf $RAW_GIT/templates/vhconf.conf
	
	touch /home/defaultdomain/html/.htaccess
	touch /home/defaultdomain/logs/{error.log,access.log}

cat << EOT > /home/defaultdomain/html/index.php
<?php
echo "www.hazi.ro - PHP successfully installed!";
?>
EOT

chown -R nobody:nobody /home/defaultdomain/html/

mkdir $WEB_DIR/phpmyadmin
mkdir $WEB_DIR/phpmyadmin/{html,logs}
mkdir $WEB_DIR/conf/vhosts/phpmyadmin
mkdir $WEB_DIR/conf/cert/phpmyadmin
touch $WEB_DIR/phpmyadmin/logs/error.log
touch $WEB_DIR/phpmyadmin/logs/access.log
wget -O $WEB_DIR/conf/vhosts/phpmyadmin/vhconf.conf $RAW_GIT/config/phpmyadmin_vhconf.conf
wget --no-check-certificate -O $WEB_DIR/phpmyadmin/html/phpmyadmin.tar.gz https://files.phpmyadmin.net/phpMyAdmin/4.8.2/phpMyAdmin-4.8.2-all-languages.tar.gz
cd $WEB_DIR/phpmyadmin/html/
tar -xzvf phpmyadmin.tar.gz
mv phpMyAdmin-4.8.2-all-languages/* ./
wget -O config.inc.php $RAW_GIT/config/config.inc.php
sed -i "s/#BLOWFISH#/$PWD_PHP_MYADMIN/g" config.inc.php
mkdir tmp
rm -f phpmyadmin.tar.gz && rm -rf phpMyAdmin-4.8.2-all-languages
cd /
chown -R lsadm:lsadm $WEB_DIR/phpmyadmin/
mkdir /var/lib/php/session
chown -R nobody:nobody /var/lib/php/session

# Generate cerificare for PMA
openssl genrsa -out $WEB_DIR/conf/cert/phpmyadmin/phpmyadmin.key 2048
openssl rsa -in $WEB_DIR/conf/cert/phpmyadmin/phpmyadmin.key -out $WEB_DIR/conf/cert/phpmyadmin/phpmyadmin.key
openssl req -sha256 -new -key $WEB_DIR/conf/cert/phpmyadmin/phpmyadmin.key -out $WEB_DIR/conf/cert/phpmyadmin/phpmyadmin.csr -subj "/CN=localhost"
openssl x509 -req -sha256 -days 365 -in $WEB_DIR/conf/cert/phpmyadmin/phpmyadmin.csr -signkey $WEB_DIR/conf/cert/phpmyadmin/phpmyadmin.key -out $WEB_DIR/conf/cert/phpmyadmin/phpmyadmin.crt

# Open port Needed in Firewall
firewall-cmd --zone=public --permanent --add-port=21/tcp
firewall-cmd --zone=public --permanent --add-port=80/tcp
firewall-cmd --zone=public --permanent --add-port=443/tcp
firewall-cmd --zone=public --permanent --add-port=7080/tcp
firewall-cmd --zone=public --permanent --add-port=8090/tcp
firewall-cmd --reload

# Generate SSL for Webadmin
mkdir $WEB_DIR/conf/cert/admin
openssl genrsa -out $WEB_DIR/conf/cert/admin/admin.key 2048
openssl rsa -in $WEB_DIR/conf/cert/admin/admin.key -out $WEB_DIR/conf/cert/admin/admin.key
openssl req -sha256 -new -key $WEB_DIR/conf/cert/admin/admin.key -out $WEB_DIR/conf/cert/admin/admin.csr -subj "/CN=localhost"
openssl x509 -req -sha256 -days 365 -in $WEB_DIR/conf/cert/admin/admin.csr -signkey $WEB_DIR/conf/cert/admin/admin.key -out $WEB_DIR/conf/cert/admin/admin.crt


#Setting MySQL
systemctl start mariadb && systemctl start proftpd && $WEB_DIR/bin/lswsctrl start
mysql -uroot -v -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -uroot -v -e "DROP DATABASE test;"
mysql -uroot -v -e "DELETE FROM mysql.user WHERE User='';"
mysql -uroot -v -e "use mysql;update user set Password=PASSWORD('$PWD_SQL_DATABASE') where user='root'; flush privileges;"

# Save Password Database
cat << EOT > /root/.MariaDB
$PWD_SQL_DATABASE
EOT

# Create PHP symlink
ln -s /usr/local/lsws/$verphpinstall/bin/lsphp /usr/bin/php

systemctl enable proftpd
systemctl enable mariadb

elif [[ ("$STARTINSTALL" == "n" || "$STARTINSTALL" == "N") ]]; then
clear
exit 1
set -e
show_ascii_okf
echo -e "::::::::::::::::::::::::::::::::"
echo -e "::: Installation is canceled :::"
echo -e "::::::::::::::::::::::::::::::::"
fi;
