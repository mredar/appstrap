#! /bin/bash
if [[ -n "$DEBUG" ]]; then 
  set -x
fi

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

cd {{ role_home_dir.stdout }}/code/harvester/

export EMAIL_RETURN_ADDRESS=ucldc@ucop.edu

set +u
. ./bin/activate
set -o nounset

if [ -e {{ role_home_dir.stdout }}/log/rqworker-${1}.pid ]; then
    #is running already?
    worker_pid=`/bin/cat {{ role_home_dir.stdout }}/log/rqworker-${1}.pid`
    if ps -A | grep -q "$worker_pid"; then
	echo "worker-${1} appears to be running at PID $worker_pid"
        exit 13
    fi
fi


rqworker -c rqw-settings --pid {{ role_home_dir.stdout}}/log/rqworker-${1}.pid &> {{ role_home_dir.stdout }}/log/rqworker-${1}.log &
