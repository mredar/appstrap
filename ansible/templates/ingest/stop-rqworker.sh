#! /bin/bash
set -x
/bin/cat {{ role_home_dir.stdout }}/log/rqworker-${1}.pid | /usr/bin/xargs kill
