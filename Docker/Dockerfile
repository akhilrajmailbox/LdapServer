FROM ubuntu:14.04
RUN export DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN echo 'slapd/root_password password password' | debconf-set-selections \
	&& echo 'slapd/root_password_again password password' | debconf-set-selections \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y slapd ldap-utils phpldapadmin apache2-utils
	#gettext-base

RUN sed -i "s|password_hash|password_hash_custom|g" /usr/share/phpldapadmin/lib/TemplateRender.php \
	&& sed -i "s|<value id=\"/bin/tsh\">/bin/tsh</value>|<value id=\"/bin/bash\">/bin/bash</value>|g" /etc/phpldapadmin/templates/creation/posixAccount.xml \
	&& sed -i "s|<value id=\"/bin/csh\">/bin/csh</value>|<value id=\"/bin/zsh\">/bin/zsh</value>|g" /etc/phpldapadmin/templates/creation/posixAccount.xml \
	&& sed -i "s|^\$servers->setValue('server','name','My LDAP Server');|//\$servers->setValue('server','name','My LDAP Server');|g" /etc/phpldapadmin/config.php \
	&& sed -i "s|^\$servers->setValue('server','base',array('dc=example,dc=com'));|//\$servers->setValue('server','base',array('dc=example,dc=com'));|g" /etc/phpldapadmin/config.php \
	&& sed -i "s|^\$servers->setValue('login','bind_id','cn=admin,dc=example,dc=com');|//\$servers->setValue('login','bind_id','cn=admin,dc=example,dc=com');|g" /etc/phpldapadmin/config.php \
	&& sed -i "/^?>/i \$servers->setValue('login','anon_bind',false);" /etc/phpldapadmin/config.php \
	&& sed -i "/^?>/i \$config->custom->appearance['hide_template_warning'] = true;" /etc/phpldapadmin/config.php \
	# custom configuration will update later
	&& sed -i "/^?>/i //\$servers->setValue('server','name','LDAP_SERVER_NAME');" /etc/phpldapadmin/config.php \
	&& sed -i "/^?>/i //\$servers->setValue('server','base',array('DC_NAME'));" /etc/phpldapadmin/config.php \
	&& sed -i "/^?>/i //\$servers->setValue('login','bind_id','cn=DISPLAY_NAME,DC_NAME');" /etc/phpldapadmin/config.php

WORKDIR /backup
COPY sources sources
RUN cp -r /etc/apache2 /backup/apache2 \
	&& cp -r /etc/phpldapadmin /backup/phpldapadmin

WORKDIR /
COPY entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh
EXPOSE 389 636 80 443
ENTRYPOINT "/entrypoint.sh"