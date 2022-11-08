# LDAP Server

[LAM Setup](./LAM-Setup.md)

## Create Docker image from Dockerfile

```bash
docker build -t akhilrajmailbox/ldap-server:lam-1.0.0 -f Dockerfile
```

## Deploy Ldap stack to Swarm

### Prerequisites

*  The client and daemon API must both be at least 1.24 to use this command. Use the docker version command on the client to check your client and daemon API versions.
* You need at least Docker Engine 19.03.0+ for this to work (Compose specification: 3.8).

```bash
docker version
```

### Create custom Docker network before deploying container (If the network is already created then ignore it)

*Note : Make sure that the subnet won't conflict with any other subnets*

```bash
docker network create --driver=overlay --subnet=172.29.1.0/24 swarm-network
```

### Create docker secret

```bash
echo "SomeSecretPass" | docker secret create LDAP_ADMIN_PASS_SECRET -
echo "SomeSecretPass" | docker secret create LDAP_HTPASSWORD_SECRET -
docker secret create MY_SSL_CERT_SECRET ./example.crt
docker secret create MY_SSL_KEY_SECRET ./example.key
docker secret create MY_SSL_BUNDLE_SECRET ./example-bundle.crt
```

## Create Directory structure for swarm deployment

```bash
mkdir -p /DevOps/ldap-server/{apache2,lib-ldap-account-manager,etc-ldap-account-manager,ldap,ldapdb-backups,slapd.d}
```

### Deploy

```bash
docker stack deploy --compose-file=Ldap-swarm.yml ldap-stack
```

### Removing ldap stack

```bash
docker stack rm ldap-stack
```

### Working with ldap

* List the stack

```bash
docker stack ls
```

* List the tasks in the stack

```bash
docker stack ps ldap-stack
```

* List the services in the stack

```bash
docker stack services ldap-stack
```

* find the docker conatiner ID and Login to ldap-stack server

```bash
docker exec -it $(docker ps -q -f name=ldap-stack) /bin/bash
```

* Restarting ldap-stack

```bash
docker stack deploy --compose-file=Ldap-swarm.yml ldap-stack
```

* check the logs of ldap-stack server

```bash
docker logs -f $(docker ps -q -f name=ldap-stack)
```

* login to LDAP ui

```
Username: cn=admin,dc=devops,dc=example,dc=com
Password: LDAP_ADMIN_PASS
```

## Create Initial LDAP DB

```bash
ldapadd -x -D "cn=admin,dc=devops,dc=example,dc=com -H ldap://ldap-server:389 -f ldap_initial.ldif -W
```

## LDAP Client Query

* ldapsearch -o ldif-wrap=no

```bash
ldapsearch -o ldif-wrap=no -x -D "cn=Query User,dc=devops,dc=example,dc=com -h ldap-server -p 389 -b "dc=devops,dc=example,dc=com "(objectclass=*)" -w PASSWORD -LLL
or
ldapsearch -o ldif-wrap=no -x -D "cn=Query User,dc=devops,dc=example,dc=com -H ldaps://devops.example.com:30636 -b "dc=devops,dc=example,dc=com "(objectclass=*)" -w PASSWORD -LLL
or
ldapsearch -o ldif-wrap=no -x -D "cn=Query User,dc=devops,dc=example,dc=com -H ldap://ldap-server -b "dc=devops,dc=example,dc=com "(objectclass=*)" -w PASSWORD -LLL
```

* ldapadd

```bash
ldapadd -x -D "cn=admin,dc=devops,dc=example,dc=com -H ldap://ldap-server -f /tmp/ldapuser.ldif -w PASSWORD
```

* ldapdelete

```bash
ldapdelete -x -D "cn=admin,dc=devops,dc=example,dc=com -H ldap://ldap-server "cn=Jenkins Manager,ou=People,dc=devops,dc=example,dc=com -w PASSWORD
```

* ldapwhoami

```bash
ldapwhoami -H ldap://ldap-server -x
ldapwhoami -H ldapi:/// -x
ldapwhoami -H ldaps://devops.example.com:30636 -x -ZZ
ldapwhoami -H ldap://ldap-server -x -D "cn=Query User,ou=People,dc=devops,dc=example,dc=com -w password
```

* ldappasswd

```bash
ldappasswd -x "cn=Query User,ou=People,dc=devops,dc=example,dc=com -D "cn=Query User,ou=People,dc=devops,dc=example,dc=com -H ldap://ldap-server -s mysecretpass -w PASSWORD
```


[ldap client](https://www.thegeekstuff.com/2015/02/openldap-add-users-groups/)

[slapd conf](https://www.openldap.org/doc/admin24/runningslapd.html)