#!/bin/bash

#####################################################
#
# OpenShift OKD "devcup" installation script
# Sindre Lindstad, 2018
# sindrelindstad.com
#
#####################################################

echo "Starting installation"

DIR="/srv/openshift"

IP=$(ip route get 1 | awk '{print $NF;exit}')
echo "! IP address: $IP"

if [ ! -z $1 ] 
then 
    : # Name provided
    OS_HOSTNAME="$1.$IP.nip.io"
else
    : # Name not provided
    OS_HOSTNAME="$IP.nip.io"
fi
echo "! Hostname set to $OS_HOSTNAME"

echo "* Preparing runtime environment..."
mkdir $DIR && cd $DIR
yum -y update
yum -y install docker wget

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
wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
tar -xvzf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
cp openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/oc /usr/sbin/
cp openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/kubectl /usr/sbin/
rm -rf openshift-origin-client-tools*

echo "{\"kind\": \"Route\",\"apiVersion\": \"v1\",\"metadata\": {\"name\": \"docker-registry.$OS_HOSTNAME\"},\"spec\": {\"host\": \"docker-registry.$OS_HOSTNAME\",\"to\": {\"kind\": \"Service\",\"name\": \"docker-registry\"},\"tls\": {\"termination\": \"edge\"}}}" > $DIR/registry-route.json

echo "* Running initial cluster setup..."
oc cluster up --public-hostname=$OS_HOSTNAME --routing-suffix=$OS_HOSTNAME --base-dir=$DIR
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin admin
oc project default
oc create -f $DIR/registry-route.json
oc project myproject

echo "* Configuring autostart..."
startscr="$DIR/os-devcup-up.sh"
stopscr="$DIR/os-devcup-down.sh"
echo cd $DIR > $startscr
echo "/usr/sbin/oc cluster up --public-hostname=$OS_HOSTNAME --routing-suffix=$OS_HOSTNAME --base-dir=$DIR" >> $startscr
echo "/usr/sbin/oc cluster down" > $stopscr
chmod +x $startscr
chmod +x $stopscr
echo "@reboot ( sleep 30 ; sh $startscr )" >> /var/spool/cron/root

echo ""
echo "Done!"
echo ""
echo "    You should now be able to access the web console on https://$OS_HOSTNAME:8443/console"
echo ""
echo "    The Docker registry should be exposed on docker-registry.$OS_HOSTNAME (remember to add this to the insecure-registries list on your Docker client)"
echo ""
