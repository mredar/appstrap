#!/bin/bash
# Create the ingest VPC and instances for the first time.

# Currently VPC, subnets and nat machine creation done on AWI web interface.
# This just then configures the nat machine to be a harvester machine.
# should be able to add configuring of the solr machine and akara machines
# in the VPC

# this script runs on a machine where "Universal Command Line Interface for Amazon Web Services"
# https://github.com/aws/aws-cli is installed and is authenticated to amazon web services
# AWS_ACCESS_KEY and AWS_SECRET_ACCESS_KEY environment variables must be set
# 
# This script also requires installation of jq : http://stedolan.github.io/jq/

# like a russia doll, this script 
#    -   creates a script that runs as root on a brand new amazon linux ec2 

set -eu
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # http://stackoverflow.com/questions/59895
AMI_EBS="ami-bba18dd2"
AMI_NAT="ami-4f9fee26" #Image for nat machine
EC2_SIZE="t1.micro"
EC2_SIZE="m1.large"
EC2_REGION=us-east-1
cd $DIR

#Run & provision Solr instance
cat user-data/solr.sh > ec2_solr_init.sh
gzip ec2_solr_init.sh

command="aws ec2 run-instances 
     --region $EC2_REGION 
     --subnet subnet-fddeca89
     --monitoring file://monitoring.json
     --instance-type $EC2_SIZE                       
     --count 1:1                                   
     --image-id $AMI_EBS                             
     --user-data file://ec2_solr_init.sh.gz
     --key-name UCLDC-ingest-private
     --block-device-mappings file://block-devices-ucldc-ingest.json
     --security-group-ids sg-47c06122
     --iam-instance-profile Name=s3-readonly"

instance=`$command | jq '.Instances[0] | .InstanceId' -r`

echo "DONE WITH INGEST SOLR INSTANCE LAUNCH: $instance"

name_cmd="aws ec2 create-tags --region $EC2_REGION --resources ${instance} --tags Key=Name,Value=UCLDC-ingest-solr Key=project,Value=ucldc"
tags=`$name_cmd`

echo tags
echo "DONE WITH NAMING"

cat user-data/akara.sh > ec2_akara_init.sh
gzip ec2_akara_init.sh

#TODO: Run & provision Akara instance
command="aws ec2 run-instances 
     --region $EC2_REGION 
     --subnet subnet-fddeca89
     --monitoring file://monitoring.json
     --instance-type $EC2_SIZE                       
     --count 1:1                                   
     --image-id $AMI_EBS                             
     --user-data file://ec2_akara_init.sh.gz
     --key-name UCLDC-ingest-private
     --security-group-ids sg-47c06122
     --iam-instance-profile Name=s3-readonly"

instance=`$command | jq '.Instances[0] | .InstanceId' -r`

echo "DONE WITH INGEST AKARA INSTANCE LAUNCH: $instance"

name_cmd="aws ec2 create-tags --region $EC2_REGION --resources ${instance} --tags Key=Name,Value=UCLDC-ingest-akara Key=project,Value=ucldc"
tags=`$name_cmd`

echo tags

cat user-data/ingest.sh > ec2_ingest_init.sh

# only on the t1.micro, tune swap
if [ "$EC2_SIZE" == 't1.micro' ]; then
  cat >> ec2_ingest_init.sh << DELIM
# t1.micro's don't come with any swap; let's add 1G
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
# t1.micro memory optimizations
DELIM

fi

gzip ec2_ingest_init.sh

command="aws ec2 run-instances 
     --subnet subnet-54427312
     --region $EC2_REGION 
     --monitoring file://monitoring.json
     --instance-type $EC2_SIZE                       
     --count 1:1                                   
     --image-id $AMI_NAT                             
     --user-data file://ec2_ingest_init.sh.gz
     --key-name UCLDC_keypair_0
     --block-device-mappings file://block-devices-ucldc-ingest.json
     --security-group-ids sg-fcc06199 sg-47c06122
     --iam-instance-profile Name=ingest-control"

echo "ec2 launch command $command"

# launch an ec2 and grab the instance id
instance=`$command | jq '.Instances[0] | .InstanceId' -r`

echo "DONE WITH INSTANCE LAUNCH: $instance"

name_cmd="aws ec2 create-tags --region $EC2_REGION --resources ${instance} --tags Key=Name,Value=UCLDC-ingest Key=project,Value=ucldc"
tags=`$name_cmd`

echo tags
echo "DONE WITH NAMING"

instance_info=`aws ec2 describe-instances --region $EC2_REGION --instance-ids $instance `
echo "INSTANCE INFO", $instance_info

#NOTE: VPC instances DO NOT get a public dns until an elastic ip is assigned to them
# wait for the new ec2 machine to get its hostname
status_code=`aws ec2 describe-instances --region $EC2_REGION --instance-ids $instance | jq ' .Reservations[0] | .Instances[0] | .State | .Code'`
echo "instance started, waiting for running state"
while [ "$status_code" != 16  ]
  do
  sleep 15
  echo "."
  status_code=`aws ec2 describe-instances --region $EC2_REGION --instance-ids $instance | jq ' .Reservations[0] | .Instances[0] | .State | .Code'`
  echo "STATUS $status_code"
  done

echo "INSTANCE:$instance"

#TODO: cleanup init file ec2_ingest_init.sh.gz

#VPC instances need allocation-id instead of public-ip
retval=`aws ec2 associate-address --region=$EC2_REGION --instance-id $instance --allocation-id eipalloc-e5d53880`
echo "ASSOCIATE ELASTIC IP ADDRESS RETURNED: $retval"

#Create route to the UCLDC-ingest machine for NAT
create_route_ret=`aws ec2 create-route --route-table-id rtb-7a05f41f --destination-cidr-block 0.0.0.0/0 --instance-id $instance`
echo "CREATE ROUTE RETURNED: $create_route_ret"

#TURN OFF SourceDestCheck so image can function as NAT
make_natable=`aws ec2 modify-instance-attribute --instance-id $instance --no-source-dest-check`
