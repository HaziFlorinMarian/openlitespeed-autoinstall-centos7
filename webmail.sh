# !/bin/bash

RAW_GIT=https://raw.githubusercontent.com/HaziFlorinMarian/openlitespeed-autoinstall-centos7/master
WEB_DIR=/usr/local/lsws

echo "Domain name (Without www):"
read DOMAIN

groupadd vmail -g 2222 
useradd vmail -r -g 2222 -u 2222 -d /var/vmail -m -c "mail user" 

yum remove exim sendmail 
yum install -y postfix cronie

cp /etc/postfix/main.cf{,.orig}

cat << EOF >> /etc/postfix/main.cf

mydomain = $DOMAIN

myhostname = mail.$DOMAIN
queue_directory = /var/spool/postfix
command_directory = /usr/sbin
daemon_directory = /usr/libexec/postfix
data_directory = /var/lib/postfix
mail_owner = postfix
unknown_local_recipient_reject_code = 550
alias_maps = hash:/etc/postfix/aliases
alias_database = $alias_maps

inet_interfaces = all
inet_protocols = ipv4
mydestination = $myhostname, localhost.$mydomain, localhost

debug_peer_level = 2
debugger_command =
         PATH=/bin:/usr/bin:/usr/local/bin:/usr/X11R6/bin
         ddd $daemon_directory/$process_name $process_id & sleep 5

sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix
mailq_path = /usr/bin/mailq.postfix
setgid_group = postdrop
html_directory = no
manpage_directory = /usr/share/man
sample_directory = /usr/share/doc/postfix-2.6.6/samples
readme_directory = /usr/share/doc/postfix-2.6.6/README_FILES

relay_domains = *
virtual_alias_maps=hash:/etc/postfix/vmail_aliases
virtual_mailbox_domains=hash:/etc/postfix/vmail_domains
virtual_mailbox_maps=hash:/etc/postfix/vmail_mailbox

virtual_mailbox_base = /var/vmail
virtual_minimum_uid = 2222
virtual_transport = virtual
virtual_uid_maps = static:2222
virtual_gid_maps = static:2222

smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = /var/run/dovecot/auth-client
smtpd_sasl_security_options = noanonymous
smtpd_sasl_tls_security_options = $smtpd_sasl_security_options
smtpd_sasl_local_domain = $mydomain
broken_sasl_auth_clients = yes

smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination

EOF

touch /etc/postfix/vmail_domains
cat << EOF > /etc/postfix/vmail_domains
$DOMAIN OK
EOF

touch /etc/postfix/vmail_mailbox
cat << EOF > /etc/postfix/vmail_mailbox
admin@$DOMAIN           $DOMAIN/admin/
no-reply@$DOMAIN     $DOMAIN/no-reply/
EOF

touch /etc/postfix/vmail_aliases
cat << EOF > /etc/postfix/vmail_aliases
admin@$DOMAIN           admin@$DOMAIN
no-reply@$DOMAIN     no-reply@$DOMAIN
EOF


postmap /etc/postfix/vmail_domains
postmap /etc/postfix/vmail_mailbox
postmap /etc/postfix/vmail_aliases
touch /etc/postfix/aliases

sed -i 's/#submission inet n       -       n       -       -       smtpd/submission inet n       -       n       -       -       smtpd/g' /etc/postfix/master.cf


yum -y install dovecot
cp /etc/dovecot/dovecot.conf{,.orig}

cat << EOF >> /etc/dovecot/dovecot.conf

listen = *
ssl = no
protocols = imap lmtp
disable_plaintext_auth = no
auth_mechanisms = plain login
mail_access_groups = vmail
default_login_user = vmail
first_valid_uid = 2222
first_valid_gid = 2222
mail_location = maildir:~/Maildir
mail_location = maildir:/var/vmail/%d/%n

passdb {
    driver = passwd-file
    args = scheme=SHA1 /etc/dovecot/passwd
}
userdb {
    driver = static
    args = uid=2222 gid=2222 home=/var/vmail/%d/%n allow_all_users=yes
}
service auth {
    unix_listener auth-client {
        group = postfix
        mode = 0660
        user = postfix
    }
    user = root
}
service imap-login {
  process_min_avail = 1
  user = vmail
}

EOF


CLEARPASSWORD=$(cat /dev/urandom | env LC_CTYPE=C tr -dc a-zA-Z0-9 | head -c 16; echo)

touch /root/.EmailPassword
echo $CLEARPASSWORD >> /root/.EmailPassword

ENCRYPTEDPASSWORD=$(doveadm pw -s sha1 -p $CLEARPASSWORD | cut -d '}' -f2)

touch /etc/dovecot/passwd
cat << EOF > /etc/dovecot/passwd
admin@$DOMAIN:$ENCRYPTEDPASSWORD
no-reply@$DOMAIN:$ENCRYPTEDPASSWORD
EOF

chown root /etc/dovecot/passwd
chmod 600 /etc/dovecot/passwd

sudo systemctl restart postfix
sudo systemctl restart dovecot
sudo systemctl enable postfix
sudo systemctl enable dovecot

firewall-cmd --permanent --add-port=25/tcp
firewall-cmd --permanent --add-port=587/tcp
firewall-cmd --permanent --add-port=143/tcp
firewall-cmd --permanent --add-port=993/tcp
firewall-cmd --reload

mkdir -p /home/mail.$DOMAIN/logs
curl -L "http://sourceforge.net/projects/roundcubemail/files/latest/download?source=files" > /home/mail.$DOMAIN/roundcube-latest.tar.gz
tar -zxf /home/mail.$DOMAIN/roundcube-latest.tar.gz -C /home/mail.$DOMAIN
rm /home/mail.$DOMAIN/roundcube-latest.tar.gz
mv /home/mail.$DOMAIN/roundcube* /home/mail.$DOMAIN/html

MYSQL_PASSWORD=$(cat /root/.MariaDB)

mysql -u root -p$MYSQL_PASSWORD << EOF
CREATE DATABASE IF NOT EXISTS roundcubemail;
GRANT ALL PRIVILEGES ON roundcubemail . * TO "roundcube"@"localhost" IDENTIFIED BY "$MYSQL_PASSWORD";
FLUSH PRIVILEGES;
quit
EOF

mysql -uroundcube -p$MYSQL_PASSWORD roundcubemail < /home/mail.$DOMAIN/html/SQL/mysql.initial.sql
cp /home/mail.$DOMAIN/html/config/config.inc.php.sample /home/mail.$DOMAIN/html/config/config.inc.php

sudo sed -i 's/roundcube:pass/roundcube:'"$MYSQL_PASSWORD"'/' /home/mail.$DOMAIN/html/config/config.inc.php




/usr/local/lsws/bin/lswsctrl reload