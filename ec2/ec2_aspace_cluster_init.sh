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

yum -y install monit


yum -y groupinstall "Development Tools"
yum -y install python-devel
yum -y install MySQL-python
easy_install pip
# as of 20150531, pip not on root path (/usr/local/bin)
/usr/local/bin/pip install virtualenv

/usr/local/bin/pip install boto_rsync      # put this in the system python
/usr/local/bin/pip install awscli  #not sure what version is installed on ec2 image - there is

#mount attached ebs
mkfs -t ext4 /dev/sdb
mkdir /aspace
mount /dev/sdb /aspace
chown ec2-user:ec2-user /aspace
mkdir /aspace/aspace.local
chown ec2-user:ec2-user /aspace/aspace.local
ln -s /aspace/aspace.local /aspace.local #put on bigger data disk
chown  ec2-user:ec2-user /aspace.local
#######
cp /etc/fstab /etc/fstab.orig
echo "/dev/sdb  /aspace ext4 defaults 0 2" >> /etc/fstab 

su - ec2-user -c 'curl https://raw.github.com/ucldc/appstrap/master/cdl/ucldc-operator-keys.txt >> ~/.ssh/authorized_keys'

##useradd aspace
touch ~ec2-user/init.sh
chown ec2-user:ec2-user ~ec2-user/init.sh
chmod +x ~ec2-user/init.sh
# write the file
cat > /home/ec2-user/init.sh <<EOSETUP
#!/usr/bin/env bash
cd
git clone https://github.com/mredar/appstrap.git
pushd appstrap/ansible
git checkout aspace
pwd
if [[ ! -d bin ]]; then
  ./init.sh
fi
. ./bin/activate
ansible-playbook -i host_inventory aspace-cluster-playbook.yml
EOSETUP


su - ec2-user -c /home/ec2-user/init.sh

cp /aspace/aspace-cluster.init /etc/init.d/aspace-cluster
chmod +x /etc/init.d/aspace-cluster
chkconfig --add aspace-cluster

echo 'set httpd port 2812 and use address localhost allow localhost' >> /etc/monit.conf
echo 'set mailserver localhost' >> /etc/monit.conf
echo 'set alert mark.redar@ucop.edu' >> /etc/monit.conf

#rm ~aspace/init.sh 
#cp ~aspace/init.d-monit /etc/init.d/monit
#chmod 0755 /etc/init.d/monit
chkconfig --add monit
service monit start
# t2.micro's don't come with any swap; let's add 1G
## to do -- add test for micro
# http://cloudstory.in/2012/02/adding-swap-space-to-amazon-ec2-linux-micro-instance-to-increase-the-performance/
# http://www.matb33.me/2012/05/03/wordpress-on-ec2-micro.html
/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
/sbin/mkswap /var/swap.1
/sbin/swapon /var/swap.1
# in case we get rebooted, add swap to fstab
cat >> /etc/fstab << FSTAB
/var/swap.1 swap swap defaults 0 0
FSTAB
# t2.micro memory optimizations
