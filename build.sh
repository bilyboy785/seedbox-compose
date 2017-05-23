#!/bin/bash
source includes/functions.sh
source includes/variables.sh

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
