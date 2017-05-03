#!/bin/bash
function intro() {
	echo ""
	echo -e "${BLUE}########################################################"
	echo -e "###                                                  ###"
	echo -e "###                  SEEDBOX-COMPOSE                 ###"
	echo -e "###   Deploy a complete Seedbox with Docker easily   ###"
	echo -e "###               Author : bilyboy785                ###"
	echo -e "###                Version : 1.0                     ###"
	echo -e "###       Publication date : 2017-03-26              ###"
	echo -e "###            Update date : 2017-03-27              ###"
	echo -e "###                                                  ###"
	echo -e "########################################################${NC}"
	echo -e ""
}
function script_option() {
	echo -e "${BLUE}### WELCOME TO SEEDBOX-COMPOSE ###${NC}"
	echo "This script will help you to make a complete seedbox with Rutorrent, Sonarr, Radarr and Jacket, based on Docker !"
	echo "Choose an option to launch the script (1, 2...) : "
	echo ""
	echo -e "	${BWHITE}[1] - ${GREEN}Install the Seedbox${NC}"
	echo -e "	${BWHITE}[2] - ${GREEN}Add an user to the Htaccess${NC}"
	echo -e "	${BWHITE}[3] - ${GREEN}Add a docker App${NC}"
	echo -e "	${BWHITE}[4] - ${GREEN}Restart docker machines${NC}"
	echo -e "	${BWHITE}[5] - ${GREEN}Backup dockers conf${NC}"
	echo -e "	${BWHITE}[6] - ${GREEN}Delete and clean all Dockers${NC}"
	echo ""
	read -p "	Your choice : " CHOICE
	echo ""
	case $CHOICE in
	"1")
	  echo -e "${BLUE}##########################################${NC}"
	  echo -e "${BLUE}###    INSTALLING SEEDBOX-COMPOSE      ###${NC}"
	  echo -e "${BLUE}##########################################${NC}"
	  SCRIPT="INSTALL"
	  ;;
	"2")
	  SCRIPT="ADDUSER"
	  ;;
	"3")
	  echo -e "${BLUE}##########################################${NC}"
	  echo -e "${BLUE}###         ADDING DOCKER APPS         ###${NC}"
	  echo -e "${BLUE}##########################################${NC}"
	  SCRIPT="ADDDOCKAPP"
	  ;;
	"4")
	  SCRIPT="RESTARTDOCKER"
	  echo -e "${BLUE}##########################################${NC}"
	  echo -e "${BLUE}###       RESTARTING DOCKER APPS       ###${NC}"
	  echo -e "${BLUE}##########################################${NC}"
	  ;;
	"5")
	   SCRIPT="BACKUPCONF"
	  ;;
	"6")
	  SCRIPT="DELETEDOCKERS"
	  ;;
	esac
	
}

function conf_dir() {
	if [[ ! -d "$CONFDIR" ]]; then
		mkdir $CONFDIR > /dev/null 2>&1
	fi
}

function upgrade_system() {
	DEBIANSOURCES="includes/sources.list.debian"
	UBUNTUSOURCES="includes/sources.list.ubuntu"
	DOCKERLIST="/etc/apt/sources.list.d/docker.list"
	SOURCESFOLDER="/etc/apt/sources.list"
	echo ""
	echo -e "${BLUE}### UPGRADING ###${NC}"
	echo " * Installing gawk, curl, gnup2, apache2-utils, unzip & apt-transport-https"
	apt-get install -y gawk apache2-utils unzip apt-transport-https ca-certificates curl gnupg2 software-properties-common > /dev/null 2>&1
	if [[ $? = 0 ]]; then
		echo -e "	${BWHITE}--> Packages installation done !${NC}"
	else
		echo -e "	${RED}--> Error while installing packages, please see logs${NC}"
	fi
	echo " * Checking system OS release"
	SYSTEM=$(gawk -F= '/^NAME/{print $2}' /etc/os-release)
	echo -e "	${BWHITE}--> System detected : $SYSTEM${NC}"
	if [[ $(echo $SYSTEM | grep "Debian") != "" ]]; then
		echo " * Creating docker.list for $SYSTEM"
		echo "deb https://apt.dockerproject.org/repo debian-jessie main" > $DOCKERLIST
		apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D > /dev/null 2>&1
		if [[ $? = 0 ]]; then
			echo -e "	${BWHITE}--> Docker.list successfully created !${NC}"
		else
			echo -e "	${RED}--> Error adding the Key P80.POOL.SKS for Docker's Repo${NC}" 	
		fi
	elif [[ $(echo $SYSTEM | grep "Ubuntu") ]]; then
		echo " * Creating docker.list for $SYSTEM"
		apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D > /dev/null 2>&1
		apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /dev/null 2>&1
		apt-get update > /dev/null 2>&1
	fi
	echo " * Updating sources and upgrading system"
	apt-get update > /dev/null 2>&1
	apt-get upgrade -y > /dev/null 2>&1
	if [[ $? = 0 ]]; then
		echo -e "	${BWHITE}--> System upgraded successfully !${NC}"
	fi
	echo ""
}

function base_packages() {
	echo -e "${BLUE}### ZSH-OhMyZSH ###${NC}"
	ZSHDIR="/usr/share/zsh"
	if [[ ! -d "$ZSHDIR" ]]; then
		echo -e " * Installing ZSH & Git-core"
		apt-get install -y zsh git-core > /dev/null 2>&1
		echo -e " * Cloning Oh-My-ZSH"
		wget -q https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O - | sh > /dev/null 2>&1
		sed -i -e 's/^\ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"bira\"/g' ~/.zshrc > /dev/null 2>&1
		sed -i -e 's/^\# DISABLE_AUTO_UPDATE=\"true\"/DISABLE_AUTO_UPDATE=\"true\"/g' ~root/.zshrc > /dev/null 2>&1
	else
		echo -e " * ZSH is already installed !"
	fi
	echo ""
}

function install_docker() {
	echo -e "${BLUE}### DOCKER ###${NC}"
	dpkg-query -l docker > /dev/null 2>&1
  	if [ $? != 0 ]; then
		echo "Docker is not installed, it will be installed !"
		echo " * Installing Docker"
		apt-get install -y docker-engine > /dev/null 2>&1
		service docker start > /dev/null 2>&1
		echo " * Installing Docker-compose"
		curl -L https://github.com/docker/compose/releases/download/1.12.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose > /dev/null 2>&1
		chmod +x /usr/local/bin/docker-compose
		echo ""
	else
		echo " * Docker is already installed !"
		echo ""
	fi
}

function install_letsencrypt() {
	echo -e "${BLUE}### LETS ENCRYPT ###${NC}"
	LEDIR="/opt/letsencrypt"
	if [[ ! -d "$LEDIR" ]]; then
		echo " * Installing Lets'Encrypt"
		apt install -y git-core > /dev/null 2>&1
		git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt > /dev/null 2>&1
		echo ""
	else
		echo " * Let's Encrypt is already installed !"
		echo ""
	fi
}

function choose_services() {
	echo -e "${BLUE}### SERVICES ###${NC}"
	echo -e "${BWHITE}Nginx, MariaDB, Nextcloud, RuTorrent/rTorrent, Sonarr, Radarr, Jackett and Docker WebUI will be installed by default !${NC}"
	echo "--> Choose wich services you want to add (default set to no) : "
	#read -p "	* H5ai Index ? (y/n) : " H5AIINSTALL
	#if [[ $H5AIINSTALL == "y" ]]; then
	#	echo -e "		${GREEN}H5ai will be installed${NC}"
	#	echo "h5ai" >> "includes/services"
	#else
	#	echo -e "		${RED}H5ai will no be installed${NC}"
	#fi
	read -p "	* Plex ? (y/n) : " PLEXINSTALL
	if [[ $PLEXINSTALL == "y" ]]; then
		echo -e "		${GREEN}Plex will be installed${NC}"
		echo "plex" >> "includes/services"
	else
		echo -e "		${RED}Plex will no be installed${NC}"
	fi
	read -p "	* PlexPy ? (y/n) : " PLEXPYINSTALL
	if [[ $PLEXPYINSTALL == "y" ]]; then
		echo -e "		${GREEN}PlexPy will be installed${NC}"
		echo "plexpy" >> "includes/services"
	else
		echo -e "		${RED}PlexPy will no be installed${NC}"
	fi
	read -p "	* ZeroBin ? (y/n) : " ZEROBININSTALL
	if [[ $ZEROBININSTALL == "y" ]]; then
		echo -e "		${GREEN}Zerobin will be installed${NC}"
		echo "zerobin" >> "includes/services"
	else
		echo -e "		${RED}Zerobin will no be installed${NC}"
	fi
	read -p "	* Lufi  ? (y/n) : " LUFIINSTALL
	if [[ $LUFIINSTALL == "y" ]]; then
		echo -e "		${GREEN}Lufi will be installed${NC}"
		echo "lufi" >> "includes/services"
	else
		echo -e "		${RED}Lufi will no be installed${NC}"
	fi
	read -p "	* Lutim ? (y/n) : " LUTIMINSTALL
	if [[ $LUTIMINSTALL == "y" ]]; then
		echo -e "		${GREEN}Lutim will be installed${NC}"
		echo "lutim" >> "includes/services"
	else
		echo -e "		${RED}Lutim will no be installed${NC}"
	fi
	echo ""
}

function define_parameters() {
	echo -e "${BLUE}### USER INFORMATIONS ###${NC}"
	read -p "	* Create new user : " SEEDUSER
	egrep "^$SEEDUSER" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		USERID=$(id -u $SEEDUSER)
		GRPID=$(id -g $SEEDUSER)
	else
		read -s -p "	* Enter password : " PASSWORD
		PASS=$(perl -e 'print crypt($ARGV[0], "password")' $PASSWORD)
		useradd -m -p $PASS $SEEDUSER > /dev/null 2>&1
		[ $? -eq 0 ] && echo "User has been added to system !" || echo "Failed to add a user !"
		USERID=$(id -u $SEEDUSER)
		GRPID=$(id -g $SEEDUSER)
	fi
	add_user_htpasswd $SEEDUSER $PASSWORD
	CURRTIMEZONE=$(cat /etc/timezone)
	read -p "	* Please specify your Timezone (default $CURRTIMEZONE) : " TIMEZONEDEF
	if [[ $TIMEZONEDEF == "" ]]; then
		TIMEZONE=$CURRTIMEZONE
	else
		TIMEZONE=$TIMEZONEDEF
	fi
	echo ""
	echo -e "${BLUE}## GENERAL INFORMATIONS ##${NC}"
	read -p "	* Please enter an email address : " CONTACTEMAIL
	read -p "	* Enter your domain name : " DOMAIN
	echo ""
}

function add_user_htpasswd() {
	HTFOLDER="/dockers/nginx/conf/"
	HTTEMPFOLDER="/tmp/"
	HTFILE=".htpasswd"
	if [[ $1 == "" ]]; then
		echo ""
		echo -e "${BLUE}## HTPASSWD MANAGER ##${NC}"
		read -p "	* Enter an username for HTACCESS : " HTUSER
		read -s -p "	* Enter password : " HTPASSWORD
	else
		HTUSER=$1
		HTPASSWORD=$2
	fi
	if [[ ! -f $HTFOLDER$HTFILE ]]; then
		htpasswd -c -b $HTTEMPFOLDER$HTFILE $HTUSER $HTPASSWORD
	else
		htpasswd -b $HTFOLDER$HTFILE $HTUSER $HTPASSWORD
	fi
}

function install_services() {
	touch $DOCKERCOMPOSEFILE
	if [[ -f "$FILEPORTPATH" ]]; then
		declare -i PORT=$(cat $FILEPORTPATH | tail -1)
	else
		declare -i PORT=$FIRSTPORT
	fi
	for line in $(cat $SERVICES);
	do
		NGINXPROXYFILE="includes/nginxproxy/$line.conf"
		NGINXFINALPROXY="/dockers/nginx/sites-enabled/$line.conf"
		cat "includes/dockerapps/$line.yml" >> $DOCKERCOMPOSEFILE
		sed -i "s|%TIMEZONE%|$TIMEZONE|g" $DOCKERCOMPOSEFILE
		sed -i "s|%UID%|$USERID|g" $DOCKERCOMPOSEFILE
		sed -i "s|%GID%|$GRPID|g" $DOCKERCOMPOSEFILE
		sed -i "s|%PORT%|$PORT|g" $DOCKERCOMPOSEFILE
		sed -i "s|%USER%|$SEEDUSER|g" $DOCKERCOMPOSEFILE
		sed -i "s|%EMAIL%|$CONTACTEMAIL|g" $DOCKERCOMPOSEFILE
		sed -i "s|%DOMAIN%|$line.$DOMAIN|g" $NGINXPROXYFILE
		sed -i "s|%PORT%|$PORT|g" $NGINXPROXYFILE
		PORT=$PORT+1
	done
	echo $PORT >> $FILEPORTPATH
}

function replace_parameters() {
	DOCKERCOMPOSE='docker-compose.yml'
	NGINXPROXY='includes/nginxproxy'
	CLOUDDOMAIN="cloud.$5"
	JACKETDOMAIN="jackett.$5"
	RADARRDOMAIN="radarr.$5"
	SONARRDOMAIN="sonarr.$5"
	UIDOCKERDOMAIN="dockerui.$5"
	RUTORRENTDOMAIN="rutorrent.$5"
	SECRET=$(date +%s | md5sum | head -c 32)
	touch $FILEPORTPATH
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
	echo -e "${BLUE}### DOCKERCOMPOSE ###${NC}"
	echo "	* Starting docker..."
	service docker restart
	echo "	* Docker-composing"
	docker-compose up -d ## > /dev/null 2>&1
	echo ""
}

function valid_htpasswd() {
	HTFOLDER="/home/$SEEDUSER/dockers/nginx/conf/"
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
	echo -e "${BLUE}### REVERSE PROXY ###${NC}"
	SITEFOLDER="/home/$SEEDUSER/dockers/nginx/sites-enabled/"
	REVERSEFOLDER="includes/nginxproxy/"
	for line in $(cat $SERVICES);
	do
		FILE=$line.conf
		echo "	* Creating reverse for $FILE"
		cat $REVERSEFOLDER$FILE >> $SITEFOLDER$FILE
	done
	echo "	* Restarting Nginx..."
	docker restart nginx > /dev/null 2>&1
	USERDIR="/home/$SEEDUSER"
	chown $CURRUSER: $USERDIR/downloads/{medias,movies,tv} -R
	chmod 775 $USERDIR/downloads/{medias,movies,tv} -R
	resuming_seedbox
}

function delete_dockers() {
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###        CLEANING DOCKER APPS        ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	echo " * Stopping dockers..."
	docker stop $(docker ps) > /dev/null 2>&1
	echo " * Removing dockers..."
	docker rm $(docker ps -a) > /dev/null 2>&1
	read -p " * Do you want to delete all docker's configuration files ? (y/n) " DELETECONF
	if [[ $DELETECONF == "y" ]]; then
		if [[ $SEEDUSER == "" ]]; then
			read -p " * Specify user to delete all his conf files : " SEEDUSER
		fi
		DOCKERFOLDER="/home/$SEEDUSER/dockers/"
		if [[ -d "$DOCKERFOLDER" ]]; then
			echo "	* Deleting files..."
			rm /dockers -R
		fi
	fi
	echo ""
}

function restart_docker_apps() {
	DOCKERS=$(docker ps --format "{{.Names}}")
	declare -i i=1
	declare -a TABAPP
	echo "	* [0] - All dockers (default)"
	while [ $i -le $(echo "$DOCKERS" | wc -w) ]
	do
		APP=$(echo $DOCKERS | cut -d\  -f$i)
		echo "	* [$i] - $APP"
		$TABAPP[$i]=$APP
		i=$i+1
	done
	read -p "Please enter the number you want to restart, let blank to default value (all) : " RESTARTAPP
	case $RESTARTAPP in
	"")
	  docker restart $(docker ps)
	  ;;
	"0")
	  docker restart $(docker ps)
	  ;;
	"1")
	  echo $TABAPP[1]
	  #docker restart TABAPP[1]
	esac
}

function resuming_seedbox() {
	echo ""
	echo ""
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###       RESUMING SEEDBOX INSTALL     ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	echo ""
	echo -e "	${BWHITE}* Access apps from these URL :${NC}"
	echo -e "		--> Your Web server is available on ${YELLOW}$DOMAIN${NC}"
	for line in $(cat $SERVICES);
	do
		echo -e "		--> $line from ${YELLOW}$line.$DOMAIN${NC}"
	done
	echo ""
	echo -e "	${BWHITE}* Here is your IDs :${NC}"
	echo -e "		--> Username : ${YELLOW}$HTUSER${NC}"
	echo -e "		--> Password : ${YELLOW}$HTPASSWORD${NC}"
	echo ""
	read -p "	* Do you want to backup your Dockers conf ? (y/n) : " BACKUPCONF
	case $BACKUPCONF in
	"y")
	  backup_docker_conf
	  ;;
	"n")
	  exit 1
	  ;;
	*)
	  exit 1
	esac
	echo ""
}

function backup_docker_conf() {
	BACKUPDIR="/var/archives/"
	BACKUPNAME="backup-seedboxcompose-"
	CONFDIR="/dockers/"
	echo ""
	BACKUP="$BACKUPDIR$BACKUPNAME$BACKUPDATE.tar.gz"
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###         BACKUP DOCKER CONF         ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	if [[ -d "$CONFDIR" ]]; then
		mkdir -p $BACKUPDIR
		echo -e " * Backing up Dockers conf..."
		tar cvpzf $BACKUP $CONFDIR > /dev/null 2>&1
		echo -e "	--> Your backup was successfully created in ${BWHITE}$BACKUP${NC}"
	else
		echo -e " ${YELLOW}--> Please launch the script to install Seedbox before make a Backup !${NC}"
	fi
	echo ""
}

function already_installed() {
	INSTALLEDFILE="$CONFDIR/seedboxcompose"
	touch $INSTALLEDFILE
}
