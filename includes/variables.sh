#!/bin/bash

## PARAMETERS
### SYNTAX COLORATION
RED='\e[0;31m'
GREEN='\033[0;32m'
BLUEDARK='\033[0;34m'
BLUE='\e[0;36m'
YELLOW='\e[0;33m'
BWHITE='\e[1;37m'
NC='\033[0m'

### DATE - TIME
DATE=`date +%d/%m/%Y-%H:%M:%S`
BACKUPDATE=`date +%d-%m-%Y-%H-%M-%S`

### NETWORK PARAMS
IPADDRESS=$(hostname -I | cut -d\  -f1)
FIRSTPORT="5050"
LASTPORT="8080"

### CUSTOMS DIRECTORIES
CURRENTDIR="$PWD"
BASEDIR="/opt/seedbox-compose"
CONFDIR="/etc/seedboxcompose"
SOURCESLIST="/etc/apt/sources.list"
DOCKERLIST="/etc/apt/sources.list.d/docker.list"
SERVICESAVAILABLE="$BASEDIR/includes/config/services-available"
SERVICES="$BASEDIR/includes/config/services"
SERVICESUSER="/etc/seedboxcompose/services-"
FILEPORTPATH="/etc/seedboxcompose/ports.pt"
PACKAGESFILE="$BASEDIR/includes/config/packages"
USERSFILE="/etc/seedboxcompose/users"
GROUPFILE="/etc/seedboxcompose/group"

### LOGS FILES
INFOLOGS="/var/log/seedboxcompose.info.log"
ERRORLOGS="/var/log/seedboxcompose.error.log"
