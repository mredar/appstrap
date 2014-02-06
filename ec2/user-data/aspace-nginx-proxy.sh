#!/bin/bash
# cloudinit script
# https://help.ubuntu.com/community/CloudInit
# this gets run as root on the amazon machine when it boots up
# look in /var/log/cloud-init.log for logging
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

# This should be sharable across the various UCLDC machines using 
# appstrap & pkgsrc to build out the installed software
# just add your specific packages after this template file

# install packages we need from amazon's repo
yum -y update			# get the latest security updates

# install the rest of the software we need
# git is needed for the build
yum -y install git 
yum -y install nginx
#for launching cluster instances
yum -y install aws-cli
yum -y install jq
#for ansible, to add tenants
yum -y install autoconf
yum -y install gcc
yum -y install python-devel
yum -y install python-pip
pip install virtualenv

#setup necessary users
useradd -U mredar
su - mredar -c 'mkdir /home/mredar/.ssh'
su - mredar -c 'chmod 700 /home/mredar/.ssh'
su - mredar -c 'curl https://raw.github.com/ucldc/appstrap/master/cdl/ucldc-operator-keys.txt >> ~/.ssh/authorized_keys'
useradd -U btingle
su - btingle -c 'mkdir /home/btingle/.ssh'
su - btingle -c 'chmod 700 /home/btingle/.ssh'
su - btingle -c 'curl https://raw.github.com/ucldc/appstrap/master/cdl/ucldc-operator-keys.txt >> ~/.ssh/authorized_keys'



su - ec2-user -c 'curl https://raw.github.com/ucldc/appstrap/master/cdl/ucldc-operator-keys.txt >> ~/.ssh/authorized_keys'

su - ec2-user -c "git clone https://github.com/mredar/appstrap.git"
su - ec2-user -c "cd appstrap; git checkout aspace"
su - ec2-user -c "~/appstrap/ansible/init.sh"
cp /home/ec2-user/appstrap/ansible/templates/nginx/nginx.conf.j2 /etc/nginx/nginx.conf

chkconfig nginx on
/etc/init.d/nginx start
