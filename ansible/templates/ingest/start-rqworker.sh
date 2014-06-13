#! /bin/bash
cd {{ role_home_dir.stdout }}/code/harvester/

. ./bin/activate

if [ -e {{ role_home_dir.stdout }}/log/rqworker-${1}.pid ]; then
    rm {{ role_home_dir.stdout }}/log/rqworker-${1}.pid
fi

rqworker -c rqw-settings --pid {{ role_home_dir.stdout}}/log/rqworker-${1}.pid &> {{ role_home_dir.stdout }}/log/rqworker-${1}.log &
