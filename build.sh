#!/bin/bash
source includes/functions.sh
# This line MUST be present in all scripts executed by cron!
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

## PARAMETERS
RED='\e[0;31m'
GREEN='\033[0;32m'
BLUE='\e[0;36m'
YELLOW='\e[0;33m'
BWHITE='\e[1;37m'
NC='\033[0m'
DATE=`date +%d/%m/%Y-%H:%M:%S`
DOCKERLIST="/etc/apt/sources.list.d/docker.list"

if [ $USER = "root" ] ; then
  ## Display script infos 
  intro
  
  ## Upgrading system
  # upgrade_system
  
  ## Check for docker on system
  install_docker
  
  ## Check for LetsEncrypt packages on system
  install_letsencrypt
  
  ## Choose wich services will be installed
  choose_services
  
  ## Defines parameters for dockers : password, domains and replace it in docker-compose file
  define_parameters
fi
