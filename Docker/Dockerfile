FROM ubuntu:22.04
MAINTAINER Akhil Raj

RUN export DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN echo 'slapd/root_password password password' | debconf-set-selections \
	&& echo 'slapd/root_password_again password password' | debconf-set-selections \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y slapd ldap-utils apache2 php \
		php-cgi libapache2-mod-php php-mbstring php-common php-pear ldap-account-manager
	#gettext-base

RUN a2enconf php8.1-cgi
RUN sed -i "s|Require all denied|Require all granted|g" /etc/apache2/conf-enabled/ldap-account-manager.conf
	# # && sed -i "s|^posixAccount_loginShell: /bin/bash|posixAccount_loginShell: /bin/zsh|g" /var/lib/ldap-account-manager/config/templates/profiles/default.user \
	# && sed -i "s|^modules: posixAccount_shells.*|modules: posixAccount_shells: /bin/bash+::+/bin/zsh+::+/bin/dash+::+/bin/false+::+/bin/ksh+::+/bin/sh|g" /var/lib/ldap-account-manager/config/samba3.sample.conf \
	# && sed -i "s|^modules: posixAccount_shells.*|modules: posixAccount_shells: /bin/bash+::+/bin/zsh+::+/bin/dash+::+/bin/false+::+/bin/ksh+::+/bin/sh|g" /var/lib/ldap-account-manager/config/windows_samba4.sample.conf \
	# && sed -i "s|/bin/csh|/bin/zsh|g" /usr/share/ldap-account-manager/lib/modules/posixAccount.inc

WORKDIR /backup
COPY sources sources
RUN cp -r /etc/apache2 /backup/apache2 \
	&& cp -r /var/lib/ldap-account-manager /backup/lib-ldap-account-manager \
	&& cp -r /etc/ldap-account-manager /backup/etc-ldap-account-manager

WORKDIR /
COPY entrypoint.sh /
COPY envFromFile.sh /
RUN chmod a+x /envFromFile.sh /entrypoint.sh

EXPOSE 389 636 80 443
ENTRYPOINT "/entrypoint.sh"