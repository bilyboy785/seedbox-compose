#!/bin/bash
function intro() {
	echo ""
	echo -e "${BLUE}###############################################################"
	echo -e "###                                                         ###"
	echo -e "###                     SEEDBOX-COMPOSE                     ###"
	echo -e "###       Deploy a complete Seedbox with Docker easily      ###"
	echo -e "###                  Author : bilyboy785                    ###"
	echo -e "###                  Version : 1.0                          ###"
	echo -e "###         Publication date : 2017-03-26                   ###"
	echo -e "###            Update date : 2017-03-27                     ###"
	echo -e "###                                                         ###"
	echo -e "###############################################################${NC}"
	echo -e ""
}
function script_option() {
	echo -e "${BLUE}### WELCOME TO SEEDBOX-COMPOSE ###${NC}"
	echo "This script will help you to make a complete seedbox with Rutorrent, Sonarr, Radarr and Jacket, based on Docker !"
	echo "Choose an option to launch the script (1, 2...) : "
	echo ""
	if [[ -d "/etc/seedboxcompose/" ]]; then
		echo -e "	${BWHITE}[1] - ${GREEN}Seedbox already installed <3${NC}"
		echo -e "	${BWHITE}[2] - ${GREEN}New htaccess user${NC}"
		echo -e "	${BWHITE}[3] - ${GREEN}Delete htaccess protection${NC}"
		echo -e "	${BWHITE}[4] - ${GREEN}Add docker application${NC}"
		echo -e "	${BWHITE}[5] - ${GREEN}Add new user (new dockers app)${NC}"
		echo -e "	${BWHITE}[6] - ${GREEN}Restart all dockers application${NC}"
		echo -e "	${BWHITE}[7] - ${GREEN}Backup Dockers conf (/home/username/${NC}"
		echo -e "	${BWHITE}[8] - ${GREEN}Delete and clean all Dockers${NC}"
	else
		echo -e "	${BWHITE}[1] - ${GREEN}Install the Seedbox${NC}"
	fi
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
	  SCRIPT="DELETEHTACCESS"
	  ;;
	"4")
	  echo -e "${BLUE}##########################################${NC}"
	  echo -e "${BLUE}###         ADDING DOCKER APPS         ###${NC}"
	  echo -e "${BLUE}##########################################${NC}"
	  SCRIPT="ADDDOCKAPP"
	  ;;
	"4")
	  echo -e "${BLUE}##########################################${NC}"
	  echo -e "${BLUE}###          ADDING NEW USER           ###${NC}"
	  echo -e "${BLUE}##########################################${NC}"
	  SCRIPT="NEWSEEDBOXUSER"
	  ;;
	"6")
	  SCRIPT="RESTARTDOCKER"
	  echo -e "${BLUE}##########################################${NC}"
	  echo -e "${BLUE}###       RESTARTING DOCKER APPS       ###${NC}"
	  echo -e "${BLUE}##########################################${NC}"
	  ;;
	"7")
	   SCRIPT="BACKUPCONF"
	  ;;
	"8")
	  SCRIPT="DELETEDOCKERS"
	  ;;
	esac
	
}

function conf_dir() {
	echo -e "${BLUE}### CHECKING SEEDBOX-COMPOSE INSTALL ###${NC}"
	if [[ ! -d "$CONFDIR" ]]; then
		echo -e "	${BWHITE}--> Seedbox-Compose not detected : Let's get started !${NC}"
		mkdir $CONFDIR > /dev/null 2>&1
		touch $SERVICESOK
		cat $SERVICES >> $SERVICESOK
	else
		echo -e "	${BWHITE}--> Seedbox-Compose installation detected !${NC}"
		echo ""
	fi
}

function install_base_packages() {
	echo ""
	echo -e "${BLUE}### INSTALL BASE PACKAGES ###${NC}"
	echo " * Installing apache2-utils, unzip, git, curl ..."
	apt-get install -y gawk apache2-utils htop unzip git apt-transport-https ca-certificates curl gnupg2 software-properties-common > /dev/null 2>&1
	if [[ $? = 0 ]]; then
		echo -e "	${BWHITE}--> Packages installation done !${NC}"
	else
		echo -e "	${RED}--> Error while installing packages, please see logs${NC}"
	fi
}

function delete_htaccess() {
	SITEENABLEDFOLDER="/etc/nginx/sites-enabled/"
}

function upgrade_system() {
	DEBIANSOURCES="includes/sources.list/sources.list.debian"
	UBUNTUSOURCES="includes/sources.list/sources.list.ubuntu"
	DOCKERLIST="/etc/apt/sources.list.d/docker.list"
	SOURCESFOLDER="/etc/apt/sources.list"
	DEBIANVERSION=$(cat /etc/debian_version | cut -d \. -f1)
	SYSTEM=$(gawk -F= '/^NAME/{print $2}' /etc/os-release)
	echo ""
	echo -e "${BLUE}### UPGRADING ###${NC}"
	echo " * Checking system OS release"
	echo -e "	${BWHITE}--> System detected : $SYSTEM${NC}"
	if [[ $(echo $SYSTEM | grep "Debian") != "" ]]; then
		echo -e "	${BWHITE}--> $SYSTEM version : $DEBIANVERSION${NC}"
		if [[ "$DEBIANVERSION" -lt "8" ]]; then
			sed -ri 's/deb\ cdrom/#deb\ cdrom/g' /etc/apt/sources.list
			apt-get update > /dev/null 2>&1
			apt-get install python-software-properties > /dev/null 2>&1
			exit 1
		fi
		echo " * Creating docker.list"
		if [[ ! -f "$DOCKERLIST" ]]; then
			echo "deb https://apt.dockerproject.org/repo debian-jessie main" > $DOCKERLIST
			apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D > /dev/null 2>&1
			if [[ $? = 0 ]]; then
				echo -e "	${BWHITE}--> Docker.list successfully created !${NC}"
			else
				echo -e "	${RED}--> Error adding the Key P80.POOL.SKS for Docker's Repo${NC}" 	
			fi
		else
			echo -e "	${BWHITE}--> Docker.list already exist !${NC}"
		fi
	elif [[ $(echo $SYSTEM | grep "Ubuntu") ]]; then
		echo " * Creating docker.list"
		apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D > /dev/null 2>&1
		apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /dev/null 2>&1
		if [[ "$?" == "0" ]]; then
			echo -e "		* ${GREEN}Docker.list successfully added !${NC}"
		else
			echo -e "		* ${RED}Error adding Key or repository !${NC}"
		fi
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
	echo -e "${BLUE}### ZSH-OHMYZSH ###${NC}"
	ZSHDIR="/usr/share/zsh"
	OHMYZSHDIR="/root/.oh-my-zsh/"
	if [[ ! -d "$OHMYZSHDIR" ]]; then	
		echo -e " * Installing ZSH"
		apt-get install -y zsh > /dev/null 2>&1
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
		curl -L https://github.com/docker/compose/releases/download/1.12.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
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
		git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt > /dev/null 2>&1
		echo ""
	else
		echo " * Let's Encrypt is already installed !"
		echo ""
	fi
}

function choose_services() {
	echo -e "${BLUE}### SERVICES ###${NC}"
	echo -e "${BWHITE}Nginx, Jackett and Docker WebUI will be installed by default !${NC}"
	echo "--> Choose wich services you want to add (default set to no) : "
	for app in $(cat includes/config/services-available);
	do
		read -p "	* $app ? (y/n) : " SERVICEINSTALL
		if [[ $SERVICEINSTALL == "y" ]]; then
			echo -e "		${GREEN}$service will be installed${NC}"
			echo "${app,,}" >> $SERVICESOK
		else
			echo -e "		${RED}$service will not be installed${NC}"
		fi
	done
	echo ""
}

function define_parameters() {
	echo -e "${BLUE}### USER INFORMATIONS ###${NC}"
	USEDOMAIN="y"
	CURRTIMEZONE=$(cat /etc/timezone)
	create_user
	read -p " * Please specify your Timezone (default $CURRTIMEZONE) : " TIMEZONEDEF
	if [[ $TIMEZONEDEF == "" ]]; then
		TIMEZONE=$CURRTIMEZONE
	else
		TIMEZONE=$TIMEZONEDEF
	fi
	read -p " * Please enter an email address : " CONTACTEMAIL
	read -p " * Do you want to use a domain to access services ? (default yes) [y/n] : " USEDOMAIN
	if [[ "$USEDOMAIN" == "y" ]]; then
		read -p "	--> Enter your domain name : " DOMAIN
	else
		DOMAIN="localhost"
	fi
}

function create_user() {
	read -p " * Create new user : " SEEDUSER
	egrep "^$SEEDUSER" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		read -s -p " * Enter password : " PASSWORD
		USERID=$(id -u $SEEDUSER)
		GRPID=$(id -g $SEEDUSER)
	else
		read -s -p " * Enter password : " PASSWORD
		PASS=$(perl -e 'print crypt($ARGV[0], "password")' $PASSWORD)
		useradd -m -p $PASS $SEEDUSER > /dev/null 2>&1
		if [[ $? -eq 0 ]]; then 
			echo "User has been added to system !"
		else
			echo "Failed to add a user !"
		fi
		USERID=$(id -u $SEEDUSER)
		GRPID=$(id -g $SEEDUSER)
	fi
	add_user_htpasswd $SEEDUSER $PASSWORD
}

function add_user_htpasswd() {
	HTFOLDER="/etc/nginx/conf/passwd/"
	HTTEMPFOLDER="/tmp/"
	HTFILE=".htpasswd"
	if [[ $1 == "" ]]; then
		echo ""
		echo -e "${BLUE}## HTPASSWD MANAGER ##${NC}"
		read -p "	* Enter username for HTACCESS : " HTUSER
		read -s -p "	* Enter password : " HTPASSWORD
	else
		HTUSER=$1
		HTPASSWORD=$2
	fi
	if [[ ! -f $HTFOLDER$HTFILE ]]; then
		htpasswd -c -b $HTTEMPFOLDER$HTFILE $HTUSER $HTPASSWORD > /dev/null 2>&1
	else
		htpasswd -b $HTFOLDER$HTFILE $HTUSER $HTPASSWORD > /dev/null 2>&1
	fi
}

function install_services() {
	touch $INSTALLEDFILE > /dev/null 2>&1
	if [[ -f "$FILEPORTPATH" ]]; then
		declare -i PORT=$(cat $FILEPORTPATH | tail -1)
	else
		declare -i PORT=$FIRSTPORT
	fi
	if [[ "$DOMAIN" != "localhost" ]]; then
		read -p " * Do you want to use SSL with Let's Encrypt support ? (default yes) [y/n] : " LESSL
	fi
	for line in $(cat $SERVICESOK);
	do
		REVERSEPROXYNGINX="/etc/nginx/sites-enabled/$line.$SEEDUSER.conf"
		cat "includes/dockerapps/$line.yml" >> $DOCKERCOMPOSEFILE
		sed -i "s|%TIMEZONE%|$TIMEZONE|g" $DOCKERCOMPOSEFILE
		sed -i "s|%UID%|$USERID|g" $DOCKERCOMPOSEFILE
		sed -i "s|%GID%|$GRPID|g" $DOCKERCOMPOSEFILE
		sed -i "s|%PORT%|$PORT|g" $DOCKERCOMPOSEFILE
		sed -i "s|%USER%|$SEEDUSER|g" $DOCKERCOMPOSEFILE
		sed -i "s|%EMAIL%|$CONTACTEMAIL|g" $DOCKERCOMPOSEFILE
		if [[ "$DOMAIN" != "localhost" ]] && [[ "$line" != "teamspeak" ]]; then
			if [[ "$LESSL" != "n" ]]; then
				NGINXPROXYFILE="includes/nginxproxyssl/$line.conf"
				cat $NGINXPROXYFILE >> $REVERSEPROXYNGINX
			else
				NGINXPROXYFILE="includes/nginxproxy/$line.conf"
				cat $NGINXPROXYFILE >> $REVERSEPROXYNGINX
			fi
			sed -i "s|%DOMAIN%|$line.$DOMAIN|g" $REVERSEPROXYNGINX
			sed -i "s|%PORT%|$PORT|g" $REVERSEPROXYNGINX
		fi
		echo "$line-$PORT" >> $INSTALLEDFILE
		PORT=$PORT+1
	done
	echo $PORT >> $FILEPORTPATH
	echo ""
}

function docker_compose() {
	echo -e "${BLUE}### DOCKERCOMPOSE ###${NC}"
	echo " * Starting docker..."
	service docker restart
	echo " * Docker-composing, it may take a long..."
	docker-compose up -d -f $DOCKERCOMPOSEFILE > /dev/null 2>&1
	echo -e "	${BWHITE}--> Docker-compose ok !${NC}"
	echo ""
}

function valid_htpasswd() {
	HTFOLDER="/etc/nginx/conf/passwd/"
	mkdir -p $HTFOLDER
	HTTEMPFOLDER="/tmp/"
	HTFILE=".htpasswd"
	cat $HTTEMPFOLDER$HTFILE >> $HTFOLDER$HTFILE
}

function add_user() {
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
		exit 1
	fi
}

function create_reverse() {
	if [[ "$DOMAIN" != "localhost" ]]; then
		echo -e "${BLUE}### REVERSE PROXY ###${NC}"
		SITEFOLDER="/etc/nginx/sites-enabled/"
		CERTBOT="includes/certbot/certbot-auto"
		echo " * Installing Nginx"
		apt-get install nginx -y > /dev/null 2>&1
		service nginx stop > /dev/null 2>&1
		for line in $(cat $SERVICESOK);
		do
			if [[ "$line" != "teamspeak" ]]; then
				FILE=$line.conf
				SITEENABLED="$SITEFOLDER$line.conf"
				echo " --> [$line] - Creating reverse"
				if [[ "$LESSL" != "n" ]]; then
					REVERSEFOLDER="includes/nginxproxyssl/"
				else
					REVERSEFOLDER="includes/nginxproxy/"
				fi
				cat $REVERSEFOLDER$FILE >> $SITEFOLDER$FILE
				read -p "	* Specify a different subdomain for $line ? (default $line.$DOMAIN) : " SUBDOMAINVAR
				case $LESSL in
				"y")
					if [[ "$SUBDOMAINVAR" == "" ]]; then
						echo -e "		${BWHITE}--> Generating LE certificate files for $line.$DOMAIN, please wait...${NC}"
						./$CERTBOT certonly --quiet --standalone --preferred-challenges http-01 --agree-tos --rsa-key-size 4096 --email $CONTACTEMAIL -d $line.$DOMAIN
						if [[ "$?" == "0" ]]; then
							echo -e "		${GREEN}* Certificate generation OK !${NC}"
						else
							echo -e "		${RED}* Certificate generation failed !${NC}"
						fi
					else
						echo -e "		${BWHITE}--> Generating LE certificate files for $SUBDOMAINVAR.$DOMAIN, please wait...${NC}"
						./$CERTBOT certonly --quiet --standalone --preferred-challenges http-01 --agree-tos --rsa-key-size 4096 --email $CONTACTEMAIL -d $SUBDOMAINVAR.$DOMAIN
						echo -e "		${BWHITE}--> Replacing domain name in sites-enabled...${NC}"
						sed -i "s|$line.$DOMAIN|$SUBDOMAINVAR.$DOMAIN|g" $SITEENABLED
						if [[ "$?" == "0" ]]; then
							echo -e "		${GREEN}* Certificate generation OK !${NC}"
						else
							echo -e "		${RED}* Certificate generation failed !${NC}"
						fi
					fi
				;;
				"")
					if [[ "$SUBDOMAINVAR" == "" ]]; then
						echo -e "		${BWHITE}--> Generating LE certificate files for $line.$DOMAIN, please wait...${NC}"
						./$CERTBOT certonly --quiet --standalone --preferred-challenges http-01 --agree-tos --rsa-key-size 4096 --email $CONTACTEMAIL -d $line.$DOMAIN
						if [[ "$?" == "0" ]]; then
							echo -e "		${GREEN}* Certificate generation OK !${NC}"
						else
							echo -e "		${RED}* Certificate generation failed !${NC}"
						fi
					else
						echo -e "		${BWHITE}--> Generating LE certificate files for $SUBDOMAINVAR.$DOMAIN, please wait...${NC}"
						./$CERTBOT certonly --quiet --standalone --preferred-challenges http-01 --agree-tos --rsa-key-size 4096 --email $CONTACTEMAIL -d $SUBDOMAINVAR.$DOMAIN
						echo -e "		${BWHITE}--> Replacing domain name in sites-enabled...${NC}"
						sed -i "s|$line.$DOMAIN|$SUBDOMAINVAR.$DOMAIN|g" $SITEENABLED
						if [[ "$?" == "0" ]]; then
							echo -e "		${GREEN}* Certificate generation OK !${NC}"
						else
							echo -e "		${RED}* Certificate generation failed !${NC}"
						fi
					fi
				;;
				esac
			fi
		done
		echo -e "	--> ${BWHITE}Starting Nginx...${NC}"
		service nginx restart > /dev/null 2>&1
	fi
	USERDIR="/home/$SEEDUSER"
	chown $SEEDUSER: $USERDIR/downloads/{medias,movies,tv} -R
	chmod 777 $USERDIR/downloads/{medias,movies,tv} -R
}

function new_seedbox_user() {
	echo -e "${BLUE}### NEW SEEDBOX USER ###${NC}"
	define_parameters
	choose_services
	install_services
	docker_compose
	create_reverse
	valid_htpasswd
	resume_seedbox
	backup_docker_conf
}

function delete_dockers() {
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###        CLEANING DOCKER APPS        ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	echo " * Stopping dockers..."
	docker stop $(docker ps) > /dev/null 2>&1
	echo " * Removing dockers..."
	docker rm $(docker ps -a) > /dev/null 2>&1
	read -p " * Do you want to delete all docker's configuration files, data and user ? [y/n] " DELETECONF
	if [[ "$DELETECONF" == "y" ]]; then
		if [[ "$SEEDUSER" == "" ]]; then
			read -p "	--> Specify user to delete all his conf files : " SEEDUSER
		fi
		DOCKERFOLDER="/home/$SEEDUSER/dockers/"
		echo "		* Deleting user..."
		userdel $SEEDUSER
		if [[ -d "$DOCKERFOLDER" ]]; then
			echo "		* Deleting files..."
			rm $DOCKERFOLDER -R
			rm $CONFDIR -R
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

function resume_seedbox() {
	echo ""
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###       RESUMING SEEDBOX INSTALL     ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	echo ""
	if [[ "$DOMAIN" != "localhost" ]]; then
		echo -e " ${BWHITE}* Access apps from these URL :${NC}"
		echo -e "	--> Your Web server is available on ${YELLOW}$DOMAIN${NC}"
		for line in $(cat $SERVICESOK);
		do
			echo -e "	--> $line from ${YELLOW}$line.$DOMAIN${NC}"
		done
	else
		echo -e " ${BWHITE}* Access apps from these URL :${NC}"
		for line in $(cat $INSTALLEDFILE);
		do
			SERVICEINSTALLED=$(echo $line | cut -d\- -f1)
			PORTINSTALLED=$(echo $line | cut -d\- -f2 | sed 's! !!g')
			echo -e "	--> $SERVICEINSTALLED from ${YELLOW}$IPADDRESS:$PORTINSTALLED${NC}"
		done
	fi
	echo ""
	echo -e " ${BWHITE}* Here is your IDs :${NC}"
	echo -e "	--> Username : ${YELLOW}$HTUSER${NC}"
	echo -e "	--> Password : ${YELLOW}$HTPASSWORD${NC}"
	echo ""
	echo -e " ${BWHITE}* Found logs here :${NC}"
	echo -e "	--> Info Logs : ${YELLOW}$INFOLOGS${NC}"
	echo -e "	--> Error Logs : ${YELLOW}$ERRORLOGS${NC}"
	mv /home/$SEEDUSER/downloads/medias/supervisord.log /home/$SEEDUSER/downloads/medias/.supervisord.log > /dev/null 2>&1
	mv /home/$SEEDUSER/downloads/medias/supervisord.pid /home/$SEEDUSER/downloads/medias/.supervisord.pid > /dev/null 2>&1
}

function backup_docker_conf() {
	BACKUPDIR="/var/archives/"
	BACKUPNAME="backup-seedboxcompose-"
	echo ""
	BACKUP="$BACKUPDIR$BACKUPNAME$BACKUPDATE.tar.gz"
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###         BACKUP DOCKER CONF         ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	if [[ "$SEEDUSER" != "" ]]; then
		read -p " * Do you want backup configuration for $SEEDUSER [y/n] ? : " BACKUPCONFUSER
		if [[ "$BACKUPCONFUSER" != "y" ]]; then
			exit 1
		fi
		USERBACKUP=$SEEDUSER
	else
		read -p " * Enter username to backup configuration : " USERBACKUP
	fi
	DOCKERCONFDIR="/home/$USERBACKUP/dockers/"
	if [[ -d "$DOCKERCONFDIR" ]]; then
		mkdir -p $BACKUPDIR
		echo -e " * Backing up Dockers conf..."
		tar cvpzf $BACKUP $DOCKERCONFDIR > /dev/null 2>&1
		echo -e "	${BWHITE}--> Backup successfully created in $BACKUP${NC}"
	else
		echo -e "	${YELLOW}--> Please launch the script to install Seedbox before make a Backup !${NC}"
	fi
	echo ""
}

function access_token_ts() {
	grep -R "teamspeak" "$SERVICESOK" > /dev/null
	if [[ "$?" == "0" ]]; then
		read -p " * Do you want create a file with your Teamspeak password and Token ? (default no) [y/n] : " SHOWTSTOKEN
		if [[ "$SHOWTSTOKEN" == "y" ]]; then
			TSIDFILE="/home/$SEEDUSER/dockers/teamspeak/idteamspeak"
			touch $TSIDFILE
			SERVERADMINPASSWORD=$(docker logs teamspeak 2>&1 | grep password | cut -d\= -f 3 | tr --delete '"')
			TOKEN=$(docker logs teamspeak 2>&1 | grep token | cut -d\= -f2)
			echo "Admin Username : serveradmin" >> $TSIDFILE
			echo "Admin password : $SERVERADMINPASSWORD" >> $TSIDFILE
			echo "Token : $TOKEN" >> $TSIDFILE
			echo -e "	--> ${YELLOW}Admin username : serveradmin${NC}"
			echo -e "	--> ${YELLOW}Admin password : $SERVERADMINPASSWORD${NC}"
			echo -e "	--> ${YELLOW}Token : $TOKEN${NC}"
		else
			echo -e "	--> Check teamspeak's Logs with ${BWHITE}docker logs teamspeak${NC}"
		fi
	fi
}
