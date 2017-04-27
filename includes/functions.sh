#!/bin/bash
function intro() {
	echo ""
	echo "########################################################"
	echo "###                                                  ###"
	echo "###                  SEEDBOX-COMPOSE                 ###"
	echo "###   Deploy a complete Seedbox with Docker easily   ###"
	echo "###               Author : bilyboy785                ###"
	echo "###                Version : 1.0                     ###"
	echo "###           Publication date : 2017-03-26          ###"
	echo "###               Update date : 2017-03-27           ###"
	echo "###                                                  ###"
	echo "########################################################"
	echo ""
}

function install_docker() {
	dpkg-query -l docker >> /dev/null
  	if [ $? != 0 ]; then
		read -p "Docker is not installed, do you wan't to install it now ? (y/n) : " installDocker
		case $installDocker in
		    "y")
		    	echo "deb https://apt.dockerproject.org/repo debian-jessie main" > $DOCKERLIST
		        apt update
		        apt install docker docker-engine docker-compose
		    ;;
		    "n")
		        echo "We'll not install Docker"
		        echo "Exiting"
		    ;;
		    *)
		        exit 0;
		    ;;
		esac
	else
		echo "Docker is already installed !"
	fi
}

function install_letsencrypt() {
	if [! -d "/etc/letsencrypt" ]; then
		read -p "Lets'Encrypt is not installed. Do you plan to generate certificates ? (y/n) : " installLetsencrypt
		case $installLetsencrypt in
		    "y")
		    	apt install git-core
		    	git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
		   		cd /opt/letsencrypt
		    ;;
		    "n")
		        echo "We'll not install LetsEncrypt"
		        echo "Exiting"
		    ;;
		    *)
		        exit 0;
		    ;;
		esac
	else
		echo "Let's Encrypt is already installed !"
	fi
}

function choose_services() {
	echo "Some services will be installed by default : Nginx, MariaDB, Nextcloud, RuTorrent/rTorrent, Sonarr, Radarr, Jackett and Docker WebUI !"
	echo "Choose wich services you want to install additionaly : "
	read -p "Plex and PlexPy ? (y/n) " PLEXINSTALL
	read -p "ZeroBin ? (y/n) " ZEROBININSTALL
	read -p "Lufi & Lutim ? (y/n) " LUFILUTIMINSTALL
}

function define_parameters() {
	read -p "Please enter user ID you want to run dockers : " USERID
	read -p "Please enter group ID you want to run dockers : " GRPID
	TIMEZONEDEF=$(cat /etc/timezone)
	read -p "Please specify your Timezone (Detected timezone : $TIMEZONEDEF by default) : " TIMEZONE
	if [ $TIMEZONE = "" ]; then
		$TIMEZONE = $TIMEZONEDEF
	fi
	echo $TIMEZONE
}
