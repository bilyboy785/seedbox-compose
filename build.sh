#!/bin/bash
source includes/functions.sh
# This line MUST be present in all scripts executed by cron!
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

## PARAMETERS
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
DATE=`date +%d/%m/%Y-%H:%M:%S`
DOCKERLIST="/etc/apt/sources.list.d/docker.list"

if [ $USER = "root" ] ; then
  install_docker
  instal_letsencrypt
  choose_services
  define_parameters
fi
