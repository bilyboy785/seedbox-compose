#!/bin/bash
source includes/functions.sh
# This line MUST be present in all scripts executed by cron!
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

## PARAMETERS
RED='\e[0;31m'
GREEN='\033[0;32m'
BLUEDARK='\033[0;34m'
BLUE='\e[0;36m'
YELLOW='\e[0;33m'
BWHITE='\e[1;37m'
NC='\033[0m'
CONFDIR="/etc/seedboxcompose"
DATE=`date +%d/%m/%Y-%H:%M:%S`
BACKUPDATE=`date +%d-%m-%Y-%H-%M-%S`
DOCKERLIST="/etc/apt/sources.list.d/docker.list"
IPADDRESS=$(ip a | grep eth0 | awk '/inet /{print substr($2,1)}' | cut -d\/ -f1)
FIRSTPORT="5050"
LASTPORT="8080"
SERVICES="includes/services"
FILEPORTPATH="/etc/seedboxcompose/ports.pt"
DOCKERCOMPOSEFILE="docker-compose.yml"
clear

if [ $USER = "root" ] ; then
	## Display script infos 
	intro
	## Create conf directory
	conf_dir
	## Check option for script lauching
	script_option
	case $SCRIPT in
		"INSTALL")
	    	if [[ ! -f "/etc/seedboxcompose/seedboxcompose.txt" ]]; then
			## Install base packages
			install_base_packages
		    	## Upgrading system
			upgrade_system
			## Check for docker on system
			install_docker
			## Installing base packages
			base_packages
			## Check for LetsEncrypt packages on system
			install_letsencrypt
			## Choose wich services install
			choose_services
			## Defines parameters for dockers : password, domains and replace it in docker-compose file
			define_parameters
			## Update docker-compose file
			install_services
			## Generate dockers apps running in background
			docker_compose
			## Create reverse proxy for each apps
			create_reverse
			## Validating Htpasswd
			valid_htpasswd
			## Resuming seedbox-compose installation
			resume_seedbox
	    	else
	    		exit 1
	    	fi
	  	;;
		"ADDUSER")
	    	add_user_htpasswd	
	  	;;
		"ADDDOCKAPP")
	    	echo ""
	  	;;
		"RESTARTDOCKER")
	    	restart_docker_apps
	  	;;
		"DELETEDOCKERS")
	    	delete_dockers
	  	;;
		"BACKUPCONF")
	    	backup_docker_conf
	esac
fi
