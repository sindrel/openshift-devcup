#!/bin/bash

#####################################################
#
# OpenShift OKD "devcup" installation script
# Sindre Lindstad, 2018
# sindrelindstad.com
#
#####################################################

DIR="/srv/openshift"
GITHUB_URL="https://github.com/openshift/origin/releases/download"
VERSION=$1

if [ "$#" -ne 2 ]; then
    echo "Argument(s) missing - please specify version and name"
    exit 1
fi

echo "Installing OpenShift $VERSION..."

echo "Please provide desired admin password, followed by [ENTER]:"
echo -n "Password: "
read -s ADMIN_PASS
echo "Confirm: "
read -s ADMIN_PASS2

if [ "$ADMIN_PASS" != "$ADMIN_PASS2" ]; then
    echo "! Passwords did not match"
    exit 1
fi

IP=$(ip route get 1 | awk '{print $NF;exit}')
echo "! IP address: $IP"

if [ ! -z $2 ] 
then 
    : # Name provided
    OS_HOSTNAME="$2.$IP.nip.io"
else
    : # Name not provided
    OS_HOSTNAME="$IP.nip.io"
fi
echo "! Hostname set to $OS_HOSTNAME"

if [ "$VERSION" == "3.9" ]; then
    OC_VERSION="v3.9.0"
    OC_FILE="openshift-origin-client-tools-v3.9.0-191fece-linux-64bit"
    OC_STARTUP="oc cluster up --public-hostname=$OS_HOSTNAME --routing-suffix=$OS_HOSTNAME --host-data-dir=$DIR/data --host-config-dir=$DIR/config --host-pv-dir=$DIR/pv --host-volumes-dir=$DIR/volumes --use-existing-config=true"
    OC_MASTERCFG="$DIR/config/master"
elif [ "$VERSION" == "3.10" ]; then
    echo "Untested!"
    exit 1
    #OC_VERSION="v3.10.0"
    #OC_FILE="openshift-origin-client-tools-v3.10.0-rc.0-c20e215-linux-64bit"
    #OC_STARTUP="oc cluster up --public-hostname=$OS_HOSTNAME --routing-suffix=$OS_HOSTNAME --base-dir=$DIR" 
    #OC_MASTERCFG="$DIR/openshift-apiserver"
elif [ "$VERSION" == "3.11" ]; then
    OC_VERSION="v3.11.0"
    OC_FILE="openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit"
    OC_STARTUP="oc cluster up --public-hostname=$OS_HOSTNAME --routing-suffix=$OS_HOSTNAME --base-dir=$DIR" 
    OC_MASTERCFG="$DIR/openshift-apiserver"
else 
    echo "! Version $VERSION unknown"
    echo "Stopped"
    exit 1
fi

echo "* Preparing runtime environment..."
mkdir $DIR && cd $DIR
yum -y update
yum -y install docker wget httpd-tools

echo "* Adding nip.io hostnames to hosts file"
echo "$IP $OS_HOSTNAME" >> /etc/hosts
echo "$IP docker-registry.$OS_HOSTNAME" >> /etc/hosts

echo "* Configuring docker..."
echo "{ \"insecure-registries\": [ \"172.30.0.0/16\", \"docker-registry.$OS_HOSTNAME\" ] }" > /etc/docker/daemon.json
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

echo "* Configuring firewall..."
firewall-cmd --permanent --new-zone dockerc
firewall-cmd --permanent --zone dockerc --add-source 172.17.0.0/16
firewall-cmd --permanent --zone dockerc --add-port 8443/tcp
firewall-cmd --permanent --zone dockerc --add-port 53/udp
firewall-cmd --permanent --zone dockerc --add-port 8053/udp
firewall-cmd --permanent --zone public --add-port 8443/tcp 
firewall-cmd --permanent --zone public --add-port 80/tcp
firewall-cmd --permanent --zone public --add-port 443/tcp
firewall-cmd --reload

echo "* Installing OC..."
wget $GITHUB_URL/$OC_VERSION/$OC_FILE.tar.gz
tar -xvzf $OC_FILE.tar.gz
cp $OC_FILE/oc /usr/sbin/
cp $OC_FILE/kubectl /usr/sbin/
rm -rf openshift-origin-client-tools*

echo "* Running initial cluster setup..."
$OC_STARTUP
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin admin
oc project myproject

echo "* Configuring autostart..."
startscr="$DIR/os-devcup-up.sh"
stopscr="$DIR/os-devcup-down.sh"
echo cd $DIR > $startscr
echo "$OC_STARTUP" >> $startscr
echo "/usr/sbin/oc cluster down" > $stopscr
chmod +x $startscr
chmod +x $stopscr
echo "@reboot ( sleep 30 ; sh $startscr )" >> /var/spool/cron/root

echo "* Configuring htpasswd authentication..."
oc cluster down
htpasswd -c -b $OC_MASTERCFG/users.htpasswd admin $ADMIN_PASS
MASTER_CFG_FILE=$OC_MASTERCFG/master-config.yaml
sed -i -e "s@mappingMethod:\ claim@mappingMethod:\ add@g" $MASTER_CFG_FILE
sed -i -e "s@name:\ anypassword@name:\ htpasswd@g" $MASTER_CFG_FILE
sed -i -e "s@kind:\ AllowAllPasswordIdentityProvider@kind:\ HTPasswdPasswordIdentityProvider\n\ \ \ \ \ \ file:\ /var/lib/origin/openshift.local.config/master/users.htpasswd@g" $MASTER_CFG_FILE

echo "* Restarting OpenShift..."
sleep 5
$OC_STARTUP

clear
echo ""
echo "Done!"
echo ""
echo "    You should now be able to access the web console on https://$OS_HOSTNAME:8443/console"
echo ""
echo "    To add a login, run:"
echo "    htpasswd $OC_MASTERCFG/users.htpasswd <user_name>"
echo ""
echo "    To remove a login, run:"
echo "    htpasswd -D $OC_MASTERCFG/users.htpasswd <user_name>"
echo ""
