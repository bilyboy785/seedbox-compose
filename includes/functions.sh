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
function script_option() {
	echo -e "${BLUE}## WELCOME TO SEEDBOX-COMPOSE ##${NC}"
	echo "This script will help you to make a complete seedbox with Rutorrent, Sonarr, Radarr and Jacket, based on Docker !"
	echo "Choose an option to launch the script (1, 2...) : "
	echo ""
	echo -e "	${GREEN}(1) Install the Seedbox${NC}"
	echo -e "	${GREEN}(2) Add an user to the Htaccess${NC}"
	echo -e "	${GREEN}(3) Add a docker App${NC}"
	echo -e "	${GREEN}(4) Restart docker machines${NC}"
	echo -e "	${GREEN}(5) Delete and clean all Dockers${NC}"
	echo ""
	read -p "	Your choice : " CHOICE
	echo ""
	case $CHOICE in
	"1")
	  echo -e "${BLUE}##############################${NC}"
	  echo -e "${BLUE}# INSTALLING SEEDBOX-COMPOSE #${NC}"
	  echo -e "${BLUE}##############################${NC}"
	  SCRIPT="INSTALL"
	  ;;
	"2")
	  SCRIPT="ADDUSER"
	  ;;
	"3")
	  echo -e "${BLUE}######################${NC}"
	  echo -e "${BLUE}# ADDING DOCKER APPS #${NC}"
	  echo -e "${BLUE}######################${NC}"
	  SCRIPT="ADDDOCKAPP"
	  ;;
	"4")
	  SCRIPT="RESTARTDOCKER"
	  echo -e "${BLUE}##########################${NC}"
	  echo -e "${BLUE}# RESTARTING DOCKER APPS #${NC}"
	  echo -e "${BLUE}##########################${NC}"
	  ;;
	"5")
	  SCRIPT="DELETEDOCKERS"
	  ;;
	esac
	
}

function upgrade_system() {
	DEBIANSOURCES="includes/sources.list.debian"
	UBUNTUSOURCES="includes/sources.list.ubuntu"
	SOURCESFOLDER="/etc/apt/sources.list"
	echo -e "${BLUE}## UPGRADING ##${NC}"
	echo "	* Installing gawk, curl & apt transport https"
	apt-get install -y gawk apt-transport-https ca-certificates curl gnupg2 software-properties-common > /dev/null 2>&1
	echo "	* Checking system OS release"
	SYSTEM=$(gawk -F= '/^NAME/{print $2}' /etc/os-release)
	echo "	* Removing default sources.list"
	mv $SOURCESFOLDER $SOURCESFOLDER\.bak > /dev/null 2>&1
	if [[ $(echo $SYSTEM | grep "Debian") != "" ]]; then
		echo "	* Creating new sources.list for Debian"
		mv $SOURCESFOLDER $SOURCESFOLDER.bak
		cat $DEBIANSOURCES >> $SOURCESFOLDER
		wget -q -O- https://www.dotdeb.org/dotdeb.gpg | apt-key add - | > /dev/null 2>&1
		wget -q -O- http://nginx.org/keys/nginx_signing.key | apt-key add - | > /dev/null 2>&1
		apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D > /dev/null 2>&1
	elif [[ $(echo $SYSTEM | grep "Ubuntu") ]]; then
		echo "	* Creating new sources.list for Ubuntu"
		cat $UBUNTUSOURCES >> $SOURCESFOLDER
	fi
	echo "	* Updating sources and upgrading system"
	apt-get update > /dev/null 2>&1
	apt-get upgrade -y > /dev/null 2>&1
	echo ""
}

function base_packages() {
	echo -e "${BLUE}## ZSH-OhMyZSH ##${NC}"
	echo -e "	* Installing ZSH & Git-core"
	apt-get install zsh git-core > /dev/null 2>&1
	echo -e "	* Cloning Oh-My-ZSH"
	wget -q https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O - | sh > /dev/null 2>&1
	sed -i -e 's/^\ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"bira\"/g' ~/.zshrc > /dev/null 2>&1
	sed -i -e 's/^\# DISABLE_AUTO_UPDATE=\"true\"/DISABLE_AUTO_UPDATE=\"true\"/g' ~root/.zshrc > /dev/null 2>&1
	echo ""
}

function install_docker() {
	echo -e "${BLUE}## DOCKER ##${NC}"
	dpkg-query -l docker > /dev/null 2>&1
  	if [ $? != 0 ]; then
		echo "Docker is not installed, it will be installed !"
		echo "	* Installing docker"
		apt-get install docker-engine > /dev/null 2>&1
		service docker start > /dev/null 2>&1
		echo "	* Installing docker-compose"
		curl -L --fail https://github.com/docker/compose/releases/download/1.12.0/run.sh > /usr/local/bin/docker-compose > /dev/null 2>&1
		chmod +x /usr/local/bin/docker-compose
		echo ""
	else
		echo "	* Docker is already installed !"
		echo ""
	fi
}

function install_letsencrypt() {
	echo -e "${BLUE}## LETS ENCRYPT ##${NC}"
	if [ ! -d "/etc/letsencrypt" ]; then
		echo "	* Lets'Encrypt is not installed. It will be installed"
		apt install git-core
		git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
		echo ""
	else
		echo "	* Let's Encrypt is already installed !"
		echo ""
	fi
}

function choose_services() {
	echo -e "${BLUE}## SERVICES ##${NC}"
	echo -e "${BWHITE}Nginx, MariaDB, Nextcloud, RuTorrent/rTorrent, Sonarr, Radarr, Jackett and Docker WebUI will be installed by default !${NC}"
	echo "--> Choose wich services you want to add (default set to no) : "
	read -p "	* Plex and PlexPy ? (y/n) : " PLEXINSTALL
	if [[ $PLEXINSTALL == "y" ]]; then
		echo -e "		${GREEN}Plex will be installed${NC}"
		cat includes/dockerapps/plex-docker.yml >> docker-compose-base.yml
		cat includes/dockerapps/plexpy-docker.yml >> docker-compose-base.yml
	else
		echo -e "		${RED}Plex will no be installed${NC}"
	fi
	read -p "	* ZeroBin ? (y/n) : " ZEROBININSTALL
	if [[ $ZEROBININSTALL == "y" ]]; then
		echo -e "		${GREEN}Zerobin will be installed${NC}"
		cat includes/dockerapps/zerobin-docker.yml >> docker-compose-base.yml
	else
		echo -e "		${RED}Zerobin will no be installed${NC}"
	fi
	read -p "	* Lufi & Lutim ? (y/n) : " LUFILUTIMINSTALL
	if [[ $LUFILUTIMINSTALL == "y" ]]; then
		echo -e "		${GREEN}Lufi&Lutim will be installed${NC}"
		cat includes/dockerapps/lufi-docker.yml >> docker-compose-base.yml
		cat includes/dockerapps/lutim-docker.yml >> docker-compose-base.yml
	else
		echo -e "		${RED}Lufi&Lutim will no be installed${NC}"
	fi
	echo ""
}

function define_parameters() {
	echo -e "${BLUE}## USER INFORMATIONS ##${NC}"
	read -p "	* Choose user wich run dockers (default $USER). If user doesn't exist, it will be added : " CURRUSER
	if [[ $CURRUSER == "" ]]; then
		USERID=$(id -u $USER)
		GRPID=$(id -g $USER)
	else
		egrep "^$CURRUSER" /etc/passwd >/dev/null
		if [ $? -eq 0 ]; then
			USERID=$(id -u $CURRUSER)
			GRPID=$(id -g $CURRUSER)
		else
			read -s -p "	Enter password : " PASSWORD
			PASS=$(perl -e 'print crypt($ARGV[0], "password")' $PASSWORD)
			useradd -m -p $PASS $CURRUSER > /dev/null 2>&1
			[ $? -eq 0 ] && echo "User has been added to system !" || echo "Failed to add a user !"
			USERID=$(id -u $CURRUSER)
			GRPID=$(id -g $CURRUSER)
		fi
	fi
	CURRTIMEZONE=$(cat /etc/timezone)
	read -p "	* Please specify your Timezone (default $CURRTIMEZONE) : " TIMEZONEDEF
	if [[ $TIMEZONEDEF == "" ]]; then
		TIMEZONE=$CURRTIMEZONE
	else
		TIMEZONE=$TIMEZONEDEF
	fi
	echo ""
	echo -e "${BLUE}## GENERAL INFORMATIONS ##${NC}"
	read -p "	Please enter an email address : " CONTACTEMAIL
	read -p "	Enter your domain name : " DOMAIN
	echo ""
	add_user_htpasswd
	## Function to replace parameters in docker-compose file
	echo ""
	replace_parameters $TIMEZONE $USERID $GRPID $CONTACTEMAIL $DOMAIN # $MARIADBROOTPASSWD $MARIADBNEXTCLOUDPASSWD $NEXTCLOUDADMIN $NEXTCLOUDADMINPASSWD $MAXUPLOADSIZENEXTCLOUD
}

function replace_parameters() {
	DOCKERCOMPOSE='docker-compose-base.yml'
	NGINXPROXY='includes/nginxproxy'
	CLOUDDOMAIN="cloud.$5"
	JACKETDOMAIN="jackett.$5"
	RADARRDOMAIN="radarr.$5"
	SONARRDOMAIN="sonarr.$5"
	UIDOCKERDOMAIN="dockerui.$5"
	RUTORRENTDOMAIN="rutorrent.$5"
	SECRET=$(date +%s | md5sum | head -c 32)
	sed -i "s|%TIMEZONE%|$1|g" $DOCKERCOMPOSE
	sed -i "s|%UID%|$2|g" $DOCKERCOMPOSE
	sed -i "s|%GID%|$3|g" $DOCKERCOMPOSE
	sed -i "s|%JACKETT_DOMAIN%|$JACKETDOMAIN|g" $NGINXPROXY/jackett.conf
	sed -i "s|%RADARR_DOMAIN%|$RADARRDOMAIN|g" $NGINXPROXY/radarr.conf
	sed -i "s|%SONARR_DOMAIN%|$SONARRDOMAIN|g" $NGINXPROXY/uifordocker.conf
	sed -i "s|%DOCKERUI_DOMAIN%|$UIDOCKERDOMAIN|g" $NGINXPROXY/sonarr.conf
	sed -i "s|%RUTORRENT_DOMAIN%|$RUTORRENTDOMAIN|g" $NGINXPROXY/rutorrent.conf
	cp $DOCKERCOMPOSE docker-compose.yml
}

function docker_compose() {
	echo -e "${BLUE}## DOCKERCOMPOSE ##${NC}"
	echo "	* Starting docker..."
	service docker restart
	echo "	* Docker-composing"
	docker-compose up -d > /dev/null 2>&1
	valid_htpasswd
}

function add_user_htpasswd() {
	HTFOLDER="/dockers/nginx/conf/"
	HTTEMPFOLDER="/tmp/"
	HTFILE=".htpasswd"
	echo -e "${BLUE}## HTPASSWD MANAGER ##${NC}"
	read -p "	Enter an username for HTACCESS : " HTUSER
	read -s -p "	Enter password : " HTPASSWORD
	if [[ ! -f $HTFOLDER$HTFILE ]]; then
		htpasswd -c -b $HTTEMPFOLDER$HTFILE $HTUSER $HTPASSWORD
	else
		htpasswd -b $HTFOLDER$HTFILE $HTUSER $HTPASSWORD
	fi
}

function valid_htpasswd() {
	HTFOLDER="/dockers/nginx/conf/"
	HTTEMPFOLDER="/tmp/"
	HTFILE=".htpasswd"
	cat $HTTEMPFOLDER$HTFILE >> $HTFOLDER$HTFILE
}

function add_user() {
	# Script to add a user to Linux system
	if [ $(id -u) -eq 0 ]; then
		read -p "Enter username : " USERNAME
		read -s -p "Enter password : " PASSWORD
		egrep "^$USERNAME" /etc/passwd >/dev/null
		if [ $? -eq 0 ]; then
			echo "$USERNAME exists!"
			exit 1
		else
			PASS=$(perl -e 'print crypt($ARGV[0], "password")' $PASSWORD)
			useradd -m -p $PASS $USERNAME
			[ $? -eq 0 ] && echo "User has been added to system !" || echo "Failed to add a user !"
		fi
	else
		echo "Only root may add a user to the system"
		exit 2
	fi
}

function create_reverse() {
	echo -e "${BLUE}## REVERSE PROXY ##${NC}"
	SITEFOLDER="/dockers/nginx/sites-enabled"
	REVERSEFOLDER="includes/nginxproxy"
	CONFFOLDER="/tmp/seedboxdocker/includes/nginxproxy"
	for file in $CONFFOLDER/*.conf
	do
		FILE=$(echo $file | grep nginxproxy | cut -d\/ -f6)
		echo "	* Creating reverse for $FILE"
		cat $REVERSEFOLDER/$FILE >> $SITEFOLDER/$FILE
	done
	echo "	* Restarting Nginx..."
	docker restart nginx > /dev/null 2>&1
}

function delete_dockers() {
	echo -e "${BLUE}##########################${NC}"
	echo -e "${BLUE}## CLEANING DOCKER APPS ##${NC}"
	echo -e "${BLUE}##########################${NC}"
	echo "	* Stopping dockers..."
	docker stop $(docker ps) > /dev/null 2>&1
	echo "	* Removing dockers..."
	docker rm $(docker ps -a) > /dev/null 2>&1
	read -p "	*Do you want to delete all docker's configuration files ? (y/n) " DELETECONF
	if [[ $DELETECONF == "y" ]]; then
		echo "	* Deleting files..."
		rm /dockers -R
	fi
}

function restart_docker_apps() {
	DOCKERS=$(docker ps --format "{{.Names}}")
	echo $DOCKERS
	#i=1
	#for APP in $DOCKERS;
		#echo "	* $i - $APP"
		#$i=$((i+1))
	#done
}
