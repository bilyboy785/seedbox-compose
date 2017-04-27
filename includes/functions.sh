#!/bin/bash
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
		        echo "$RED Exiting$NC"
		    ;;
		    *)
		        exit 0;
		    ;;
		esac
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
		        echo "$RED Exiting$NC"
		    ;;
		    *)
		        exit 0;
		    ;;
		esac
	else
		echo "letsencrypt ok"
	fi
}

function choose_services() {
	echo "Some services will be installed by default : Nginx, MariaDB, Nextcloud, RuTorrent/rTorrent, Sonarr, Radarr and Docker WebUI !"
}
function define_parameter() {
	read -p "Please enter user ID you want to run dockers : " USERID
	read -p "Please enter group ID you want to run dockers : " GRPID
	read -p "Please enter
}
