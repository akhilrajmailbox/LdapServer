# LDAP Server

## Prerequisites

* We are using `devops-network` docker network for all devops deployment.
* You need at least Docker Engine 17.06.0  and docker-compose 1.18 for this to work.

```bash
docker --version
docker-compose --version
```

## Create Docker image from Dockerfile (optional, docker-compose will create docker image for you)

```bash
docker build -t akhilrajmailbox/ldap-server:1.0.0 . -f Dockerfile
```

## Create custom Docker network before deploying container (If the network is already created then ignore it)

*Note : Make sure that the subnet won't conflict with any other subnets*

```bash
docker network create --driver=bridge --subnet=172.31.0.0/16 devops-network
```

## Deploy LDAP as Docker container

```bash
docker-compose -f docker-compose.yml up -d
```

## Working with LDAP


* Login to LDAP server

```bash
docker exec -it LDAP /bin/bash
```

* Restarting LDAP

```bash
docker-compose -f docker-compose.yml restart
```

* stopping/starting LDAP

```
docker-compose -f docker-compose.yml stop/start
```

* login to LDAP ui

```
Username: cn=admin,dc=my,dc=devops,dc=example,dc=com
Password: LDAP_ADMIN_PASS
```

## Create Initial LDAP DB

```bash
ldapadd -x -D "cn=admin,dc=my,dc=devops,dc=example,dc=com" -H ldap://ldap-server:389 -f ldap_initial.ldif -W
```

## LDAP Client Query

* ldapsearch -o ldif-wrap=no

```bash
ldapsearch -o ldif-wrap=no -x -D "cn=Query User,dc=my,dc=devops,dc=example,dc=com" -h ldap-server -p 389 -b "dc=my,dc=devops,dc=example,dc=com" "(objectclass=*)" -w PASSWORD -LLL
or
ldapsearch -o ldif-wrap=no -x -D "cn=Query User,dc=my,dc=devops,dc=example,dc=com" -H ldaps://mydevops.example.com:30636 -b "dc=my,dc=devops,dc=example,dc=com" "(objectclass=*)" -w PASSWORD -LLL
or
ldapsearch -o ldif-wrap=no -x -D "cn=Query User,dc=my,dc=devops,dc=example,dc=com" -H ldap://ldap-server -b "dc=my,dc=devops,dc=example,dc=com" "(objectclass=*)" -w PASSWORD -LLL
```

* ldapadd

```bash
ldapadd -x -D "cn=admin,dc=my,dc=devops,dc=example,dc=com" -H ldap://ldap-server -f /tmp/ldapuser.ldif -w PASSWORD
```

* ldapdelete

```bash
ldapdelete -x -D "cn=admin,dc=my,dc=devops,dc=example,dc=com" -H ldap://ldap-server "cn=Jenkins Manager,ou=People,dc=my,dc=devops,dc=example,dc=com" -w PASSWORD
```

* ldapwhoami

```bash
ldapwhoami -H ldap://ldap-server -x
ldapwhoami -H ldapi:/// -x
ldapwhoami -H ldaps://mydevops.example.com:30636 -x -ZZ
ldapwhoami -H ldap://ldap-server -x -D "cn=Query User,ou=People,dc=my,dc=devops,dc=example,dc=com" -w password
```

* ldappasswd

```bash
ldappasswd -x "cn=Query User,ou=People,dc=my,dc=devops,dc=example,dc=com" -D "cn=Query User,ou=People,dc=my,dc=devops,dc=example,dc=com" -H ldap://ldap-server -s mysecretpass -w PASSWORD
```


[ldap client](https://www.thegeekstuff.com/2015/02/openldap-add-users-groups/)

[slapd conf](https://www.openldap.org/doc/admin24/runningslapd.html)