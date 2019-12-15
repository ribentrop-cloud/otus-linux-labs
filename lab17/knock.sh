#!/usr/bin/env bash
#
# Knockport script
# https://wiki.archlinux.org/index.php/Port_knocking
#
# Usage: knock.sh 192.168.254.1 6699 9966
HOST=$1
shift
for ARG in "$@"
do
        nmap -Pn --host-timeout 100 --max-retries 0 -p $ARG $HOST
done
