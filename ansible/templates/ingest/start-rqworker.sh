#! /bin/bash
cd {{ role_home_dir.stdout }}/code/harvester/

. ./bin/activate

if [ -e {{ role_home_dir.stdout }}/log/rqworker-${1}.pid ]; then
    #is running already?
    worker_pid=`/bin/cat {{ role_home_dir.stdout }}/log/rqworker-${1}.pid`
    ps -A | grep $worker_pid
    if [ $? -eq 0 ]; then
	echo "worker-${1} appears to be running at PID $worker_pid"
        exit 13
    fi
fi


rqworker -c rqw-settings --pid {{ role_home_dir.stdout}}/log/rqworker-${1}.pid &> {{ role_home_dir.stdout }}/log/rqworker-${1}.log &
