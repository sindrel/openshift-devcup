# OpenShift OKD all-in-one installation (devcup)
Works on CentOS 7 + OpenShift OKD 3.9/3.11

## What's this?
Devcup is a script that provides you with a fully working installation of OpenShift on one server. It sets up firewall rules, installs dependencies, and deploys an installation of OpenShift OKD using the "oc cluster up" method. 

It is ment for semi-persistent development use. It's got persistent storage, a working Docker repository, survives a reboot, and it uses nip.io for DNS resolution.

## Usage
(as root, on the server you wish to deploy it to)

```yum -y install git```

```git clone https://github.com/sindrel/openshift-devcup.git```

```sh openshift-devcup/install-os-devcup.sh <version> <cluster_name>```

Valid versions are: 3.9, 3.11.

If you do not wish to specify a cluster name, simply provide an empty string ('').

## Prerequisites
Installation only requires a *clean installation* of CentOS 7.
If you intend to deploy this to an existing server, please revise the script before launching it, as it might break things.

## What you get
After running the script you should have a working installation of OpenShift OKD:

- *Web console* exposed on https://name.ipaddress.nip.io:8443/console (i.e. https://example.192.168.1.10.nip.io:8443/console). (See the troubleshooting section below)

## What it does

- Installs Docker
- Configures the firewall to allow for incoming traffic on port 80/443/8443 (web console)
- Installs the OC command line tool
- Runs the "oc console up" installation
- Gives the 'admin' user cluster-admin privileges
- Configures automatic start on boot

## Troubleshooting
### Web console redirects to 127.0.0.1
If you try to access the web console on https://name.ipaddress.nip.io:8443/ but you're redirected to 127.0.0.1 (localhost), it's due to a bug in OpenShift. 
If you use the full path https://name.ipaddress.nip.io:8443/console it should work without issues.

### Docker registry issues
There seems to be some issues with proxying of the Docker registry. If you're unable to reach it from the external route, try using the internal route (172.30.1.1:5000). If you know how to solve this, let me know.
