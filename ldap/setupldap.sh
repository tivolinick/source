#! /bin/sh
# install stuff
yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel
systemctl start slapd
systemctl enable slapd

# check its there
netstat -antup | grep -i 389

# open up the firewall
firewall-cmd --permanent --add-port=389/tcp
firewall-cmd --permanent --add-port=636/tcp
firewall-cmd --permanent --add-port=9830/tcp
firewall-cmd --reload

iptables -A INPUT -p tcp --dport 389 -j ACCEPT
iptables -A INPUT -p tcp --dport 636 -j ACCEPT
iptables -A INPUT -p tcp --dport 9830 -j ACCEPT

# set ldap admin password to passw0rd
pass=$(slappasswd -h {SSHA} -s passw0rd)
#{SSHA}5DgQFFt4WpZ7rTLCJSsjOT73R/PSJV0U

# setup ldap 1 - create a config file
echo "dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=ndf,dc=local

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=ldapadm,dc=ndf,dc=local

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $pass
" > db.ldif
ldapmodify -Y EXTERNAL  -H ldapi:/// -f db.ldif

# restrict the monitor access only to ldap root (ldapadm) user not to others.
echo '
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=ldapadm,dc=ndf,dc=local" read by * none
' > monitor.ldif
#ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif

cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown ldap:ldap /var/lib/ldap/*
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

echo '
dn: dc=ndf,dc=local
dc: ndf
objectClass: top
objectClass: domain

dn: cn=ldapadm ,dc=ndf,dc=local
objectClass: organizationalRole
cn: ldapadm
description: LDAP Manager

dn: ou=People,dc=ndf,dc=local
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=ndf,dc=local
objectClass: organizationalUnit
ou: Group
' > base.ldif

ldapadd -x -W -D "cn=ldapadm,dc=ndf,dc=local" -f base.ldif


