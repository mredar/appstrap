#!/bin/bash
# Stop the ingest machines

set -eu
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # http://stackoverflow.com/questions/59895
cd $DIR

instance_solr=i-1bf2173a
instance_akara=i-acfd188d 
instance_harvest_nat=i-4a749f6a
declare -a instances=($instance_solr $instance_akara $instance_harvest_nat);
command="aws ec2 stop-instances 
     --instance-ids ${instances[@]}
     "
ret_val=`$command`
echo "RET:$ret_val"
