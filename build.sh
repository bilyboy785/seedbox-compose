#!/bin/bash

# This line MUST be present in all scripts executed by cron!
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

## PARAMETERS
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
DATE=`date +%d/%m/%Y-%H:%M:%S`

if [ $USER = "root" ] ; then
  dpkg-query -l docker
  echo $?
  if [ $? != 0 ]; then
    read -p "Docker is not installed, do you wan't to install it now ? (y/n) : " installDocker
      case $installDocker in
      "y")
        apt install docker
       ;;
      "n")
        echo "We'll not install Docker"
      ;;
      *)
        exit 0;
      ;;
      esac
  fi
  echo "Début !"
fi
