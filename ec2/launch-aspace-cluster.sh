#!/bin/bash
# launch an EC2 server and install application

# this script runs on a machine where "Universal Command Line Interface for Amazon Web Services"
# https://github.com/aws/aws-cli is installed and is authenticated to amazon web services
# AWS_ACCESS_KEY and AWS_SECRET_ACCESS_KEY environment variables must be set
# 
# This script also requires installation of jq : http://stedolan.github.io/jq/

# like a russia doll, this script 
#    -   creates a script that runs as root on a brand new amazon linux ec2 

set -eu
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # http://stackoverflow.com/questions/59895
AMI_EBS="ami-05355a6c"
AMI_EBS_HVM="ami-b66ed3de"
AMI_EBS=$AMI_EBS_HVM
EC2_SIZE="t2.micro"
EC2_REGION=us-east-1
cd $DIR

if [ "$#" -ne 1 ]; then
  echo "Usage: launch-aspace-cluster <tenant-name>"
  exit 11;
fi
tenant=$1
echo "TENANT = $tenant"

zone=`cat placement.json|jq '.AvailabilityZone' -r`

cat user-data/aspace-cluster.sh > ec2_aspace_cluster_init.sh

# only on the t2.micro, tune swap
if [ "$EC2_SIZE" == 't2.micro' ]; then
  cat >> ec2_aspace_cluster_init.sh << DELIM
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
DELIM

fi

#gzip ec2_aspace_cluster_init.sh


command="aws ec2 run-instances 
     --subnet subnet-7355145b
     --region $EC2_REGION 
     --monitoring file://monitoring.json
     --instance-type $EC2_SIZE                       
     --count 1:1                                   
     --image-id $AMI_EBS_HVM                             
     --user-data file://ec2_aspace_cluster_init.sh
     --key-name aspace-cluster
     --disable-api-termination
     --block-device-mappings file://block-devices-aspace.json
     --iam-instance-profile Name=s3-readonly"

echo "ec2 launch command is: $command"

# launch an ec2 and grab the instance id
ret_val_launch=`$command`
instance=`echo $ret_val_launch | jq '.Instances[0] | .InstanceId' -r`
zone=`echo $ret_val_launch | jq '.Instances[0] | .Placement | .AvailabilityZone' -r`

echo "DONE WITH INSTANCE LAUNCH: $instance"
echo "Availability zone=$zone"

name_cmd="aws ec2 create-tags --region $EC2_REGION --resources ${instance} --tags Key=Name,Value=aspace-cluster-$tenant Key=project,Value=aspace"
tags=`$name_cmd`

echo tags
echo "DONE WITH NAMING"

#machines in vpc do not get PublicDnsName
#Wait for the state to be: "State": { "Code": 16, "Name": "running" }, 
running=`aws ec2 describe-instances --region $EC2_REGION --instance-ids $instance | jq ' .Reservations[0] | .Instances[0] | .State | .Code'`
echo "instance started, waiting for it to be running "
while [ "$running" != '16' ]
  do
  sleep 15
  echo "."
  running=`aws ec2 describe-instances --region $EC2_REGION --instance-ids $instance | jq ' .Reservations[0] | .Instances[0] | .State | .Code'`
  done

echo "INSTANCE:$instance"

#Tag volumes attached
volumes=`aws ec2 describe-instances --region us-east-1 --instance-ids $instance |jq ' .Reservations[0] | .Instances[0] | .BlockDeviceMappings | .[] | .Ebs | .VolumeId' | tr \" \  | tr \n \  `

echo "VOLUMES: $volumes"

ip_instance=`aws ec2 describe-instances --region $EC2_REGION --instance-ids $instance | jq ' .Reservations[0] | .Instances[0] | .PrivateIpAddress '` 
echo "IP: $ip_instance"

tags2=`aws ec2 create-tags --region $EC2_REGION --resources ${volumes} --tags Key=Name,Value=aspace-cluster Key=project,Value=aspace`

#TODO: cleanup init file ec2_aspace_cluster_init.sh.gz

#Associate with our aspace front end elastic ip address
#retval=`aws ec2 associate-address --region=$EC2_REGION --instance-id $instance --public-ip 184.72.236.50`
#echo "ASSOCIATE ELASTIC IP ADDRESS RETURNED: $retval"

