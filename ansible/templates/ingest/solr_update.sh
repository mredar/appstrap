#! /bin/bash
# Run as role user
if [[ -n "$DEBUG" ]]; then 
  set -x
fi

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

. {{ role_home_dir.stdout }}/.harvester-env

cd {{ role_home_dir.stdout }}/workers_local/

export EMAIL_RETURN_ADDRESS=ucldc@example.edu

set +u
. ./bin/activate
set -o nounset


python {{ role_home_dir.stdout }}/code/harvester/harvester/solr_updater.py
python {{ role_home_dir.stdout }}/code/harvester/harvester/grab_solr_index.py

