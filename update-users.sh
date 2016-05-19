#!/bin/bash
#
# Example usage: update-users.sh users.txt webdav.passwd webdav.conf
USER_FILE=$1
BASE_DIR=$2
CONF_DIR=$3
PASSWD_FILE=${CONF_DIR}/webdav.passwd
CONF_FILE=${CONF_DIR}/webdav.conf
rm -f $PASSWD_FILE
rm -f $CONF_FILE
cat > $CONF_FILE <<EOF
DocumentRoot /srv/webdav
EOF

while read user pass; do
	echo $user $pass
	(echo -n "${user}:webdav:" && echo -n "${user}:webdav:${pass}" | md5sum | awk '{print $1}' ) >> $PASSWD_FILE
	cat >> $CONF_FILE <<EOF
<Directory /srv/webdav/${user}>
    Options Indexes
    Order Allow,Deny
    Allow from all
    Require all granted
</Directory>

Alias /webdav/${user} /srv/webdav/${user}
<Location /webdav/${user}>
    Options Indexes
    DAV On
    AuthType Digest
    AuthName "webdav"
    AuthDigestProvider file
  
    AuthUserFile /etc/apache2/webdav/webdav.passwd
    Require user ${user}
</Location>
EOF

mkdir -p $BASE_DIR/$user

done < $USER_FILE

cat >> $CONF_FILE <<EOF
CustomLog /proc/self/fd/1 vhost_combined
ErrorLog /proc/self/fd/2
EOF