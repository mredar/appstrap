#!/bin/bash
# Stop the ingest machines

set -eu
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # http://stackoverflow.com/questions/59895
cd $DIR

. ./ingest_instances.sh
command="aws ec2 stop-instances 
     --instance-ids ${instances[@]}
     "
ret_val=`$command`
echo "RET:$ret_val"
