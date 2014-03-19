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
cd $DIR

EC2_SIZE="m1.small"
EC2_REGION=us-east-1

instance_solr=i-1bf2173a
instance_akara=i-acfd188d 
instance_harvest_nat=i-4a749f6a
declare -a instances=($instance_solr $instance_akara $instance_harvest_nat);
#set instance types
for id in "${instances[@]}"
do
    command="aws ec2 modify-instance-attribute --instance-id $id --instance-type {\"Value\":\"${EC2_SIZE}\"}"
    echo "CMD: $command"
    ret_val=`$command`
    echo "RET: $ret_val"
done

#Start the ingest machines
command="aws ec2 start-instances 
     --instance-ids i-1bf2173a i-acfd188d i-4a749f6a
     "
ret_val=`$command`
echo "Start RET VAL: $ret_val"

#instance_info=`aws ec2 describe-instances --region $EC2_REGION --instance-ids $instance_harvest_nat `
#echo "INSTANCE INFO", $instance_info

#NOTE: VPC instances DO NOT get a public dns until an elastic ip is assigned to them
# wait for the new ec2 machine to get to the "running" state
status_code=`aws ec2 describe-instances --region $EC2_REGION --instance-ids $instance_harvest_nat | jq ' .Reservations[0] | .Instances[0] | .State | .Code'`
echo "instance started, waiting for running state"
while [ "$status_code" != 16  ]
  do
  sleep 15
  echo "."
  status_code=`aws ec2 describe-instances --region $EC2_REGION --instance-ids $instance_harvest_nat | jq ' .Reservations[0] | .Instances[0] | .State | .Code'`
  echo "STATUS $status_code"
  done

echo "MAIN INSTANCE STARTED:$instance_harvest_nat"

#TODO: cleanup init file ec2_ingest_init.sh.gz

#VPC instances need allocation-id instead of public-ip
retval=`aws ec2 associate-address --region=$EC2_REGION --instance-id $instance_harvest_nat --allocation-id eipalloc-e5d53880`
echo "ASSOCIATE ELASTIC IP ADDRESS RETURNED: $retval"

#Create route to the UCLDC-ingest machine for NAT
create_route_ret=`aws ec2 create-route --route-table-id rtb-7a05f41f --destination-cidr-block 0.0.0.0/0 --instance-id $instance_harvest_nat`
echo "CREATE ROUTE RETURNED: $create_route_ret"

#TURN OFF SourceDestCheck so image can function as NAT
make_natable=`aws ec2 modify-instance-attribute --instance-id $instance_harvest_nat --no-source-dest-check`
