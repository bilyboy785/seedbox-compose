#!/bin/bash
function intro() {
	echo ""
	echo "########################################################"
	echo "###                                                  ###"
	echo "###                  SEEDBOX-COMPOSE                 ###"
	echo "###   Deploy a complete Seedbox with Docker easily   ###"
	echo "###               Author : bilyboy785                ###"
	echo "###                Version : 1.0                     ###"
	echo "###       Publication date : 2017-03-26              ###"
	echo "###            Update date : 2017-03-27              ###"
	echo "###                                                  ###"
	echo "########################################################"
	echo ""
}

function install_docker() {
	echo "## DOCKER ##"
	dpkg-query -l docker >> /dev/null
  	if [ $? != 0 ]; then
		echo "Docker is not installed, it will be installed !"
		echo "deb https://apt.dockerproject.org/repo debian-jessie main" > $DOCKERLIST
		apt update
		apt install docker docker-engine docker-compose
		echo ""
	else
		echo "Docker is already installed !"
		echo ""
	fi
}

function install_letsencrypt() {
	echo "## LETS ENCRYPT ##"
	if [ ! -d "/etc/letsencrypt" ]; then
		read -p "Lets'Encrypt is not installed. Do you plan to generate certificates ? (y/n) : " installLetsencrypt
		apt install git-core
		git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
		echo ""
	else
		echo "Let's Encrypt is already installed !"
		echo ""
	fi
}

function choose_services() {
	echo "## SERVICES ##"
	echo "Nginx, MariaDB, Nextcloud, RuTorrent/rTorrent, Sonarr, Radarr, Jackett and Docker WebUI will be installed by default !"
	echo "Choose wich services you want to add (default set to no) : "
	read -p "	Plex and PlexPy ? (y/n) : " PLEXINSTALL
	read -p "	ZeroBin ? (y/n) : " ZEROBININSTALL
	read -p "	Lufi & Lutim ? (y/n) : " LUFILUTIMINSTALL
	if [ $PLEXINSTALL = "y" ]; then
		cat includes/plex-docker.yml >> docker-compose.yml
		cat includes/plexpy-docker.yml >> docker-compose.yml
	fi
	if [ $ZEROBININSTALL = "y" ]; then
		cat includes/zerobin-docker.yml >> docker-compose.yml
	fi
	if [ $LUFILUTIMINSTALL = "y" ]; then
		cat includes/lufi-docker.yml >> docker-compose.yml
		cat includes/lutim-docker.yml >> docker-compose.yml
	fi
	echo ""
}

function define_parameters() {
	echo "## PARAMETERS ##"
	read -p "Choose user wich run dockers ($USER ?) : " CURRUSER
	if [[ $CURRUSER == "" ]]; then
		USERID=$(id -u $USER)
		GRPID=$(id -g $USER)
	else
		if [ $(id -u $CURRUSER) = "1" ]; then
			echo "User doesn't exist !"
		else
			USERID=$(id -u $CURRUSER)
			GRPID=$(id -g $CURRUSER)
		fi
	fi
	CURRTIMEZONE=$(cat /etc/timezone)
	read -p "Please specify your Timezone (Detected : $CURRTIMEZONE) : " TIMEZONEDEF
	if [[ $TIMEZONEDEF == "" ]]; then
		TIMEZONE=$CURRTIMEZONE
	else
		TIMEZONE=$TIMEZONEDEF
	fi
	read -p "Please enter an email address : " CONTACTEMAIL
	replace_parameters $TIMEZONE $USERID $GRPID $CONTACTEMAIL
}

function replace_parameters() {
string='foo bar qux'
one="${string/ /.}"
	DOCKERFILE=$(cat docker-compose-base.yml)
	echo $DOCKERFILE
	DOCKERFILEV1="${DOCKERFILE//%UID%/$2}"
	echo $DOCKERFILEV1
	# sed "s/%TIMEZONE%/$1/g" "docker-compose-base.yml" > docker-compose-base.tmp
	# sed "s/%UID%/$2/g" "docker-compose-base.tmp" > docker-compose-base.tmp
	# sed "s/%GID%/$3/g" "docker-compose-base.tmp" > docker-compose-base.tmp
	# sed "s/%LUFI_LUTIM_CONTACT%/$4/g" "docker-compose-base.tmp" > docker-compose.yml
}
