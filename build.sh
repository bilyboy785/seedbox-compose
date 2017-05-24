#!/bin/bash
source includes/functions.sh
source includes/variables.sh

clear

if [ $USER = "root" ] ; then
	check_dir $PWD
	script_option
	case $SCRIPT in
		"INSTALL")
	    	first_install
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
