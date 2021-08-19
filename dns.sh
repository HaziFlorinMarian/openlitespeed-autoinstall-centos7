#!/bin/bash

read -e -p "Enter domain name (without www) : " DOMAIN_NAME
yum install -y bind bind-utils


sudo sed -i 's/{ 127.0.0.1; };/{ any; };/g' /etc/named.conf
sudo sed -i 's/localhost;/any;/g' /etc/named.conf
sudo sed -i 's/recursion.*/recursion no;/' /etc/named.conf

sudo sed -i 's@include "/etc/named.root.key";@include "/etc/named.root.key";'"\n\n"'};@g' /etc/named.conf
sudo sed -i 's@include "/etc/named.root.key";@include "/etc/named.root.key";'"\n\t"'file "/etc/named/'"$DOMAIN_NAME"'.db";@g' /etc/named.conf
sudo sed -i 's@include "/etc/named.root.key";@include "/etc/named.root.key";'"\n\t"'type master;@g' /etc/named.conf
sudo sed -i 's@include "/etc/named.root.key";@include "/etc/named.root.key";'"\n\n"'zone "'"$DOMAIN_NAME"'" {@g' /etc/named.conf

IP=$(curl --silent http://www.cpanel.net/showip.cgi)

touch /etc/named/$DOMAIN_NAME.db
cat << EOF >> /etc/named/$DOMAIN_NAME.db
$TTL    604800
@       IN      SOA     ns1.$DOMAIN_NAME.       admin.$DOMAIN_NAME. (
                        2018101901;     Serial
                        3H;             Refresh
                        15M;            Retry
                        2W;             Expiry
                        1D );           Minimum
 
; name servers - NS records
        IN      NS      ns1.$DOMAIN_NAME.
        IN      NS      ns2.$DOMAIN_NAME.
 
; name servers - A records
ns1.$DOMAIN_NAME.       IN      A       $IP
ns2.$DOMAIN_NAME.       IN      A       $IP
 
; other records
$DOMAIN_NAME.				IN			A			$IP
$DOMAIN_NAME.			0	IN			MX	0		$DOMAIN_NAME.
@									IN			TXT			"v=spf1 a mx ip4:$IP ~all"
localhost						0	IN			A			127.0.0.1
www								0	IN			CNAME		$DOMAIN_NAME.
mail							0	IN			A			$IP
EOF

sudo sed -i 's/    604800/$TTL    604800/g' /etc/named/$DOMAIN_NAME.db


systemctl enable named
systemctl start named
systemctl status named

#Allow on Firewall
sudo systemctl start firewalld
firewall-cmd --zone=public --permanent --add-port=53/tcp
firewall-cmd --zone=public --permanent --add-port=53/udp
firewall-cmd --reload
