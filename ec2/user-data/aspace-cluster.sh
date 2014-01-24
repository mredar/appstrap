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


yum -y groupinstall "Development Tools"
yum -y install python-devel
yum -y install MySQL-python
easy_install pip
pip install virtualenv

###pip install boto_rsync      # put this in the system python
###pip install awscli  #not sure what version is installed on ec2 image - there is

su - ec2-user -c 'curl https://raw.github.com/tingletech/appstrap/master/cdl/ucldc-operator-keys.txt >> ~/.ssh/authorized_keys'

useradd aspace
touch ~aspace/init.sh
chown aspace:aspace ~aspace/init.sh
chmod +x ~aspace/init.sh
# write the file
cat > ~aspace/init.sh <<EOSETUP
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

su - aspace -c ~aspace/init.sh

sed 's,/aspace,/home/aspace/aspace,' /home/aspace/aspace/aspace-cluster.init  > /etc/init.d/aspace-cluster
chmod +x /etc/init.d/aspace-cluster
chkconfig --add aspace-cluster

su - aspace -c ~aspace/init.sh
#rm ~aspace/init.sh 
cp ~aspace/init.d-monit /etc/init.d/monit
chmod 0755 /etc/init.d/monit
chkconfig --add monit

