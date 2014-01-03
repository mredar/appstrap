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

# install the rest of the software we need
# git is needed for the build
yum -y install git 

# handles pkgsrc requirements
yum -y groupinstall "Development Tools"
# problem with new setuptools & pip. Need to remove earlier distribute
# and setuptools manually then install setuptools > 2 (Jan. 03, 2014)
rm -rf /usr/lib/python2.6/site-packages/distribute*
rm -rf /usr/lib/python2.6/site-packages/setuptools*
wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -O - | python
easy_install pip
pip install virtualenv

pip install awscli  #not sure what version is installed on ec2 image - there is
#no aws executable
yum -y install python-devel  # needed to install(init?) virtualenv with local python
yum -y install ncurses-devel # needed to install pkgsrc python
yum -y install dialog
yum -y install openssl-devel
yum -y install libjpeg-devel
yum -y install freetype-devel
yum -y install libtiff-devel
yum -y install lcms-devel
yum install -y readline-devel libyaml-devel libffi-devel #needed for rvm

su - ec2-user -c 'curl https://raw.github.com/tingletech/appstrap/master/cdl/ucldc-operator-keys.txt >> ~/.ssh/authorized_keys'

useradd stanbol
touch ~stanbol/init.sh
chown stanbol:stanbol ~stanbol/init.sh
chmod 700 ~stanbol/init.sh
# write the file
cat > ~stanbol/init.sh <<EOSETUP
#!/usr/bin/env bash
cd
git clone -b stanbol https://github.com/mredar/appstrap.git
./appstrap/stacks/stack_stanbol #want this to finish, so below works
EOSETUP
su - stanbol -c ~stanbol/init.sh
rm ~stanbol/init.sh 
cp ~stanbol/init.d-monit /etc/init.d/monit
chmod 0755 /etc/init.d/monit
chkconfig --add monit
