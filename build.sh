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
DATE=`date +%d/%m/%Y-%H:%M:%S`
BACKUPDATE=`date +%d-%m-%Y-%H-%M-%S`
IPADDRESS=$(ip a | grep eth0 | awk '/inet /{print substr($2,1)}' | cut -d\/ -f1)
FIRSTPORT="5050"
LASTPORT="8080"
CONFDIR="/etc/seedboxcompose"
DOCKERLIST="/etc/apt/sources.list.d/docker.list"
SERVICESAVAILABLE="includes/config/services-available"
SERVICES="includes/config/services"
SERVICESUSER="/etc/seedboxcompose/services-$SEEDUSER"
FILEPORTPATH="/etc/seedboxcompose/ports.pt"
INSTALLEDFILE="/etc/seedboxcompose/installed.ok"
USERSFILE="/etc/seedboxcompose/users"
DOCKERCOMPOSEFILE="/etc/seedboxcompose/docker-compose.yml"
INFOLOGS="/var/log/seedboxcompose.info.log"
ERRORLOGS="/var/log/seedboxcompose.error.log"

clear

if [ $USER = "root" ] ; then
	## Display script infos 
	## intro
	## Check option for script lauching
	script_option
	case $SCRIPT in
		"INSTALL")
	    	if [[ ! -d "/etc/seedboxcompose/" ]]; then
	  		echo -e "${BLUE}##########################################${NC}"
	  		echo -e "${BLUE}###    INSTALLING SEEDBOX-COMPOSE      ###${NC}"
	  		echo -e "${BLUE}##########################################${NC}"
			conf_dir
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
			## Defines parameters for dockers : password, domains and replace it in docker-compose file
			define_parameters
			## Choose wich services install
			choose_services
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
			## Backup dockers app Configuration
			backup_docker_conf
			## Display Teamspeak IDs
			access_token_ts
	    	else
			clear
			echo -e " ${RED}--> Seedbox-Compose already installed !${NC}"
	    		script_option
	    	fi
	  	;;
		"ADDUSER")
	    		add_user_htpasswd	
	  	;;
		"SCHEDULEBACKUP")
			schedule_backup_seedbox
		;;
	  	"DELETEHTACCESS")
			under_developpment
			#delete_htaccess
		;;
		"ADDDOCKAPP")
	    		#under_developpment
			add_docker_app
	  	;;
		"NEWSEEDBOXUSER")
			new_seedbox_user
		;;
		"RESTARTDOCKER")
	    		restart_docker_apps
	  	;;
		"DELETEDOCKERS")
			under_developpment
	    		#delete_dockers
	  	;;
		"BACKUPCONF")
	    		backup_docker_conf
	esac
fi
