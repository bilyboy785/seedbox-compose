#!/bin/bash
source includes/functions.sh

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
IPADDRESS=$(hostname -I | cut -d\  -f1)
FIRSTPORT="5050"
LASTPORT="8080"
CURRENTDIR="$PWD"
BASEDIR="/opt/seedbox-compose"
CONFDIR="/etc/seedboxcompose"
SOURCESLIST="/etc/apt/sources.list"
DOCKERLIST="/etc/apt/sources.list.d/docker.list"
SERVICESAVAILABLE="$BASEDIR/includes/config/services-available"
SERVICES="$BASEDIR/includes/config/services"
SERVICESUSER="/etc/seedboxcompose/services-"
FILEPORTPATH="/etc/seedboxcompose/ports.pt"
PACKAGESFILE="$BASEDIRincludes/config/packages"
USERSFILE="/etc/seedboxcompose/users"
GROUPFILE="/etc/seedboxcompose/group"
INFOLOGS="/var/log/seedboxcompose.info.log"
ERRORLOGS="/var/log/seedboxcompose.error.log"

clear

if [ $USER = "root" ] ; then
	check_dir $PWD
	script_option
	case $SCRIPT in
		"INSTALL")
	    	if [[ ! -d "/etc/seedboxcompose/" ]]; then
	    		clear
		  		echo -e "${BLUE}##########################################${NC}"
		  		echo -e "${BLUE}###    INSTALLING SEEDBOX-COMPOSE      ###${NC}"
		  		echo -e "${BLUE}##########################################${NC}"
				conf_dir
				## Install base packages
				install_base_packages
			    ## Checking system version
				checking_system
				## Check for docker on system
				install_docker
				## Installing Nginx
				install_nginx
				## Installing ZSH
				install_zsh
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
				## Ask user to instal FTP
				install_ftp_server
				## Resuming seedbox-compose installation
				resume_seedbox
				## Backup dockers app Configuration
				backup_docker_conf
				#schedule_backup_seedbox
				## Display Teamspeak IDs
				##access_token_ts
				schedule_backup_seedbox
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
		"MANAGEAPPS")
	    	#under_developpment
			manage_apps
	  	;;
		"MANAGEUSERS")
			manage_users
		;;
		"RESTARTDOCKER")
			under_developpment
	    	#restart_docker_apps
	  	;;
		"UNINSTALL")
			#under_developpment
	    	uninstall_seedbox
	  	;;
		"BACKUPCONF")
	    	backup_docker_conf
	    ;;
	    "INSTALLFTPSERVER")
			install_ftp_server
		;;
		"GENERATECERT")
			generate_ssl_cert
		;;
	esac
fi
