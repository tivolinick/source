if [ $# -ne 1 ] ; then
  echo "USAGE: $0 username"
  exit 1
fi

if [ -f uidNo ] ; then
  uno=$(cat uidNo)
  uno=$(expr $uno + 1)
else
  uno=500
fi
echo $uno > uidNo

echo "
dn: uid=$1,ou=People,dc=ndf,dc=local
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
cn: $1
uid: $1
uidNumber: $uno
gidNumber: 100
homeDirectory: /home/$1
loginShell: /bin/bash
userPassword: {crypt}x
shadowLastChange: 17058
shadowMin: 0
shadowMax: 99999
shadowWarning: 7
" > $1.ldif
ldapadd -x -D "cn=ldapadm,dc=ndf,dc=local" -w 'passw0rd' -f $1.ldif
ldappasswd -s password123 -D "cn=ldapadm,dc=ndf,dc=local" -w 'passw0rd' -x "uid=$1,ou=People,dc=ndf,dc=local"
ldapsearch -x cn=$1 -b dc=ndf,dc=local


