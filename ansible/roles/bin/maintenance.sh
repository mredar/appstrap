#! /usr/bin/env bash


state=$1

echo "STATE=$state"
if [[ $state == 'on' ]]; then
  sudo cp /home/ec2-user/bin/maintenance.html /usr/share/nginx/html/
elif [[ $state == 'off' ]]; then
  sudo rm /usr/share/nginx/html/maintenance.html
else
  echo "Usage: maintenance.sh on|off"
fi
