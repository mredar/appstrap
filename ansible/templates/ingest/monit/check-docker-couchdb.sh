#! /bin/bash

/usr/bin/docker ps -q | grep 7977e3a01348
exit $?
