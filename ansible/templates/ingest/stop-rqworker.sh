#! /bin/bash
if [[ -n "$DEBUG" ]]; then 
  set -x
fi

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

/bin/cat {{ role_home_dir.stdout }}/log/rqworker-${1}.pid | /usr/bin/xargs kill
/bin/rm {{ role_home_dir.stdout }}/log/rqworker-${1}.pid
