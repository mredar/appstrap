#! /bin/bash

# see if the ingest is idle

. {{ role_home_dir.stdout }}/workers_local/bin/activate

# use rqinfo to get q status.
# first check workers, if not "idle" then say system is not idle
ret_value=`python /usr/local/bin/ingest_is_idle.py`
