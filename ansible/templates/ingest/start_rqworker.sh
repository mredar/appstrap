export EMAIL_RETURN_ADDRESS=ucldc@ucop.edu
rqworker -c rqw-settings --pid ~/pid/rqw-$BASHPID &> pid/rqw-log-$BASHPID &
