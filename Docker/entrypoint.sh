#!/bin/bash

function checkVariables() {
  if [[ ${SLAPD_CONF} == "fresh-install" ]] ; then
    echo "configuring slapd for first run"
    echo ""
    [ -z "${LDAP_ADMIN_PASS}" ] && echo "Variable Error : LDAP_ADMIN_PASS --> Admin password for admin"
    [ -z "${LDAP_DOMAIN}" ] && echo "Variable Error : LDAP_DOMAIN --> Domain name for LDAP"
    [ -z "${LDAP_ORGANISATION}" ] && echo "Variable Error : LDAP_ORGANISATION --> Organisation name for LDAP domain"
    [ -z "${HTPASSWORD}" ] && echo "Variable Error : HTPASSWORD --> admin Password for accessing the PhpLdapAdmin UI"
    [ -z "${ALIAS}" ] && echo "Variable Error : ALIAS --> Alias for UI request"
    [[ "${SSL_CONFIG}" != [Y,y,N,n] ]] && echo "Variable Error : SSL_CONFIG --> SSL termination"
    if [[ "${SSL_CONFIG}" == [Y,y] ]] ; then
      [ -z "${SSL_CERT}" ] && echo "Variable Error : SSL_CERT --> If SSL_CONFIG enabled, cert path"
      [ -z "${SSL_KEY}" ] && echo "Variable Error : SSL_KEY --> If SSL_CONFIG enabled, key path"
      [ -z "${SSL_CACERT}" ] && echo "Variable Error : SSL_CACERT --> If SSL_CONFIG enabled, cacert path"
    fi
  else
    echo "slapd configured already, won't execute function : checkVariables()"
  fi
}

function setEnv() {
  export HOST_IP=`hostname -I | awk '{print $1}'`
  export DC_NAME=`echo ${LDAP_DOMAIN} | sed "s|\.|,dc=|g" | awk '{print "dc="$0}'`
  if [ -e /var/lib/ldap/DB_CONFIG ] ; then
    export SLAPD_CONF="configured"
  else
    export SLAPD_CONF="fresh-install"
  fi
}

function freshConf() {
  if [ ! "$(ls -A /etc/apache2/)" ] ; then
    cp -r /backup/apache2/. /etc/apache2
  fi
  if [ ! "$(ls -A /etc/phpldapadmin)" ] ; then
    cp -r /backup/phpldapadmin/. /etc/phpldapadmin
  fi
  chown -R :www-data /etc/phpldapadmin
  chown -R :www-data /etc/apache2
}

function bootStrap() {
  if [[ ${SLAPD_CONF} == "fresh-install" ]] ; then
cat <<EOF | debconf-set-selections
slapd slapd/internal/generated_adminpw password ${LDAP_ADMIN_PASS}
slapd slapd/internal/adminpw password ${LDAP_ADMIN_PASS}
slapd slapd/password2 password ${LDAP_ADMIN_PASS}
slapd slapd/password1 password ${LDAP_ADMIN_PASS}
#slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/domain string ${LDAP_DOMAIN}
slapd shared/organization string ${LDAP_ORGANISATION}
slapd slapd/backend string HDB
slapd slapd/purge_database boolean false
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
EOF
    dpkg-reconfigure -f noninteractive slapd

    ## Configure phpLDAPadmin
    if [[ ! -f /etc/apache2/htpasswd ]] && [[ ${HTPASSWORD} != "" ]] ; then
      htpasswd -b -c /etc/apache2/htpasswd admin ${HTPASSWORD}
    fi

    sed -i "s|^//\$servers->setValue('server','name','LDAP_SERVER_NAME');|\$servers->setValue('server','name','${LDAP_SERVER_NAME}');|g" /etc/phpldapadmin/config.php
    sed -i "s|^//\$servers->setValue('server','base',array('DC_NAME'));|\$servers->setValue('server','base',array('${DC_NAME}'));|g" /etc/phpldapadmin/config.php
    sed -i "s|^//\$servers->setValue('login','bind_id','cn=DISPLAY_NAME,DC_NAME');|//\$servers->setValue('login','bind_id','cn=DISPLAY_NAME,${DC_NAME}');|g" /etc/phpldapadmin/config.php

    if [ ! -e /etc/phpldapadmin/apache.conf-org ]; then
      cp -r /etc/phpldapadmin/apache.conf /etc/phpldapadmin/apache.conf-org
    fi
    sed -i "s|Alias /phpldapadmin /usr/share/phpldapadmin/htdocs|Alias /${ALIAS} /usr/share/phpldapadmin/htdocs|g" /etc/phpldapadmin/apache.conf

    if [[ ${SSL_CONFIG} == "y" || ${SSL_CONFIG} == "Y" ]] ; then
      echo ""
      echo "configuring slapd & phpldapadmin with ssl"
      ( echo "cat <<EOF > /etc/apache2/sites-available/ssl_ldap_80.conf" ; cat /backup/sources/ssl_ldap_80.conf.tmpl) | sh
      ( echo "cat <<EOF > /etc/apache2/sites-available/ssl_ldap_443.conf" ; cat /backup/sources/ssl_ldap_443.conf.tmpl) | sh
      # envsubst < /backup/sources/ssl_ldap_80.conf.tmpl > /etc/apache2/sites-available/ssl_ldap_80.conf
      # envsubst < /backup/sources/ssl_ldap_443.conf.tmpl > /etc/apache2/sites-available/ssl_ldap_443.conf
    else
      ( echo "cat <<EOF > /etc/apache2/sites-available/ldap_80.conf" ; cat /backup/sources/ldap_80.conf.tmpl) | sh
      # envsubst < /backup/sources/ldap_80.conf.tmpl > /etc/apache2/sites-available/ldap_80.conf
      mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/ldap.conf
    fi
  else
    echo "slapd configured already, won't execute function : bootStrap()"
  fi
}

function configModify() {
  if [[ ${SLAPD_CONF} == "fresh-install" ]] ; then
    slapd -h "ldapi:///"
    sleep 2
    if [[ ${SSL_CONFIG} == [Y,y] ]] ; then
      ( echo "cat <<EOF > /backup/sources/ldapssl.ldif" ; cat /backup/sources/ldapssl.ldif.tmpl) | sh
      # envsubst < /backup/sources/ldapssl.ldif.tmpl > /backup/sources/ldapssl.ldif
      ldapmodify -H ldapi:/// -Y EXTERNAL -f /backup/sources/ldapssl.ldif
    fi
    ldapmodify -H ldapi:/// -Y EXTERNAL -f /backup/sources/disable_anon_frontend.ldif
    ldapmodify -H ldapi:/// -Y EXTERNAL -f /backup/sources/disable_anon_backend.ldif
    pidof slapd | xargs kill -9
    # ps -ef | grep -v grep | grep -i slapd | awk '{print $2}' | xargs kill -9
  else
    echo "slapd configured already, won't execute function : configModify()"
  fi
}

function serviceStart() {
  checkVariables
  setEnv
  freshConf
  bootStrap
  configModify
  if [[ ${SSL_CONFIG} == [Y,y] ]] ; then
    a2ensite ssl_ldap_80.conf
    a2ensite ssl_ldap_443.conf
  else
    a2ensite ldap_80.conf
    a2ensite ldap.conf
  fi
  a2dissite 000-default.conf
  a2enmod rewrite
  a2enmod ssl
  pidof apache2 | xargs kill -9
  service apache2 restart
  echo -e "Starting slapd\nAdmin Username : cn=admin,${DC_NAME}"
  if [[ ${SSL_CONFIG} == [Y,y] ]] ; then
    slapd -d0 -h "ldap:/// ldaps:///"
  else
    slapd -d0 -h "ldap:///"
  fi
}


serviceStart
