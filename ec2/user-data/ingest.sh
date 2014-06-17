#!/bin/bash
# cloudinit script
# https://help.ubuntu.com/community/CloudInit
# this gets run as root on the amazon machine when it boots up
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

# This should be sharable across the various UCLDC machines using 
# appstrap & pkgsrc to build out the installed software
# just add your specific packages after this template file

# install packages we need from amazon's repo
yum -y update			# get the latest security updates

# make sure we use all the attached storage
resize2fs /dev/xvda1
mount /dev/sdb /var

# install the rest of the software we need
# git is needed for the build
yum -y install git 
yum -y install monit

# handles pkgsrc requirements
yum -y groupinstall "Development Tools"
# problem with new setuptools & pip. Need to remove earlier distribute
# and setuptools manually then install setuptools > 2 (Jan. 03, 2014)
rm -rf /usr/lib/python2.6/site-packages/distribute*
rm -rf /usr/lib/python2.6/site-packages/setuptools*
wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -O - | python
easy_install pip
pip install virtualenv
yum -y install python27-devel #needed for building python lxml
yum -y install libxml2-devel #needed for building python lxml
yum -y install libxml2-python #needed for building python lxml
yum -y install libxslt-devel #needed for building python lxml

pip install awscli  #not sure what version is installed on ec2 image - there is
#no aws executable
yum -y install ncurses-devel # needed to install pkgsrc python

yum -y install nginx #will proxy and control access to couchdb

yum -y install docker

su - ec2-user -c 'curl https://raw.github.com/tingletech/appstrap/master/cdl/ucldc-operator-keys.txt >> ~/.ssh/authorized_keys'

touch ~ec2-user/init.sh
chown ec2-user:ec2-user ~ec2-user/init.sh
chmod 700 ~ec2-user/init.sh
#### write the file
cat > ~ec2-user/init.sh <<EOSETUP
#!/usr/bin/env bash
cd
mkdir code
cd code
git clone -b ingest https://github.com/mredar/appstrap.git
cd appstrap/ansible
pwd
if [[ ! -d bin ]]; then
  ./init.sh
fi
set +u
. bin/activate
set -u
ansible-playbook -i host_inventory ingest-playbook.yml
EOSETUP

su - ec2-user -c ~ec2-user/init.sh
