#! /bin/bash

/usr/bin/docker ps -q | grep cbd4bb13b88f
exit $?
