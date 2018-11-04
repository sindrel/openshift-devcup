# OpenShift OKD all-in-one installation (devcup)
Works on CentOS 7 + OpenShift OKD 3.11

## What's this?
Devcup is a script that provides you with a fully working installation of OpenShift on one server. It sets up firewall rules, installs dependencies, and deploys an installation of OpenShift OKD using the "oc cluster up" method. 

It is ment for semi-persistent development use. It's got persistent storage, a working Docker repository, survives a reboot, and it uses nip.io for DNS resolution.

## Usage
(as root, on the server you wish to deploy it to)

```yum -y install git```

```git clone https://github.com/sindrel/openshift-devcup.git```

```sh openshift-devcup/install-os-devcup.sh <optional_cluster_name>```

## Prerequisites
Installation only requires a *clean installation* of CentOS 7.
If you intend to deploy this to an existing server, please revise the script before launching it, as it might break things.

## What you get
After running the script you should have a working installation of OpenShift OKD:

- *Web console* exposed on https://name.ipaddress.nip.io:8443/console (i.e. https://example.192.168.1.10.nip.io:8443/console).
- *Docker-registry* exposed on https://docker-registry.name.ipaddress.nip.io (i.e. docker-registry.example.192.168.1.10.nip.io).

## What it does

- Installs Docker
- Configures the firewall to allow for incoming traffic on port 80/443/8443 (web console)
- Installs the OC command line tool
- Runs the "oc console up" installation
- Gives the 'admin' user cluster-admin privileges
- Creates a docker registry route
- Configures automatic start on boot

## Troubleshooting
If you try to access the web console on https://name.ipaddress.nip.io:8443/ but you're redirected to 127.0.0.1 (localhost), it's due to a bug in OpenShift. 
If you use the full path https://name.ipaddress.nip.io:8443/console it should work without issues.
