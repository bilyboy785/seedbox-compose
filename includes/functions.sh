#!/bin/bash
function under_developpment() {
	clear
	echo ""
	echo -e "${RED}####################################"
	echo -e "###       UNDERDEVELOPPEMENT     ###"
	echo -e "####################################${NC}"
	echo ""
}

function script_option() {
	#echo -e "${BLUE}### WELCOME TO SEEDBOX-COMPOSE ###${NC}"
	#echo "This script will help you to make a complete seedbox based on Docker !"
	#echo "Choose an option to launch the script (1, 2...) : "
	#echo ""
	if [[ -d "$CONFDIR" ]]; then
		ACTION=$(whiptail --title "Seedbox-Compose" --menu "Welcome to Seedbox-Compose Script. Please choose an action below :" 20 65 10 \
			"1" "Install Seedbox-Compose" \
			"2" "New seedbox user" \
			"3" "New htaccess user" \
			"4" "Add docker Apps for user X" \
			"5" "Restart all dockers" \
			"6" "Backup dockers configuration" \
			"7" "Enable scheduled backup" \
			"8" "Install FTP Server" \
			"9" "Generate SSL certificate" \
			"10" "Disable htaccess protection" \
			"11" "Delete and clean dockers"  3>&1 1>&2 2>&3)
		echo ""
		case $ACTION in
		"1")
		  SCRIPT="INSTALL"
		  ;;
		"2")
		  SCRIPT="NEWSEEDBOXUSER"
		  ;;
		"3")
		  SCRIPT="ADDUSER"
		  ;;
		"4")
		  SCRIPT="ADDDOCKAPP"
		  ;;
		"5")
		  echo -e "${BLUE}##########################################${NC}"
		  echo -e "${BLUE}###        RESTART ALL DOCKERS         ###${NC}"
		  echo -e "${BLUE}##########################################${NC}"
		  SCRIPT="RESTARTDOCKERS"
		;;
		"6")
		  SCRIPT="BACKUPCONF"
		  echo -e "${BLUE}##########################################${NC}"
		  echo -e "${BLUE}###        BACKUP DOCKERS CONF         ###${NC}"
		  echo -e "${BLUE}##########################################${NC}"
		;;
		"7")
		   SCRIPT="SCHEDULEBACKUP"
		   echo -e "${BLUE}##########################################${NC}"
		  echo -e "${BLUE}###           SCHEDULE BACKUP          ###${NC}"
		  echo -e "${BLUE}##########################################${NC}"
		;;
		"8")
		   SCRIPT="INSTALLFTPSERVER"
		;;
		"9")
		   SCRIPT="GENERATECERT"
		;;
		"10")
		   SCRIPT="DELETEHTACCESS"
		;;
		"11")
		  SCRIPT="DELETEDOCKERS"
		;;
		esac
	else
		ACTION=$(whiptail --title "Seedbox-Compose" --menu "Welcome to Seedbox-Compose Script. Please install it first !" 16 60 8 \
			"1" "Install Seedbox-Compose" 3>&1 1>&2 2>&3)
		echo ""
		case $ACTION in
		"1")
		  SCRIPT="INSTALL"
		  ;;
		 esac
	fi
	
}

function conf_dir() {
	#echo -e "${BLUE}### CHECKING SEEDBOX-COMPOSE INSTALL ###${NC}"
	if [[ ! -d "$CONFDIR" ]]; then
		#echo -e "	${BWHITE}--> Seedbox-Compose not detected : Let's get started !${NC}"
		mkdir $CONFDIR > /dev/null 2>&1
	fi
}

function install_base_packages() {
	echo ""
	echo -e "${BLUE}### INSTALL BASE PACKAGES ###${NC}"
	sed -ri 's/deb\ cdrom/#deb\ cdrom/g' /etc/apt/sources.list
	whiptail --title "Base Package" --msgbox "Seedbox-Compose installer will now install base packages and update system" 10 60
	echo " * Installing apache2-utils, unzip, git, curl ..."
	{
	NUMPACKAGES=$(cat $PACKAGESFILE | wc -l)
	for package in $(cat $PACKAGESFILE);
	do
		apt-get install -y $package
		echo $NUMPACKAGES
		echo $package
		NUMPACKAGES=$(($NUMPACKAGES+(100/$NUMPACKAGES)))
	done
	} | whiptail --gauge "Please wait during packages installation !" 6 60 0
	if [[ $? = 0 ]]; then
		echo -e "	${GREEN}--> Packages installation done !${NC}"
	else
		echo -e "	${RED}--> Error while installing packages, please see logs${NC}"
	fi
}

function delete_htaccess() {
	SITEENABLEDFOLDER="/etc/nginx/conf.d/"
	sed -ri 's///g' /etc/
}

function upgrade_system() {
	DEBIANSOURCES="includes/sources.list/sources.list.debian"
	UBUNTUSOURCES="includes/sources.list/sources.list.ubuntu"
	DOCKERLIST="/etc/apt/sources.list.d/docker.list"
	NGINXLIST="/etc/apt/sources.list.d/nginx.list"
	SOURCESFOLDER="/etc/apt/sources.list"
	DEBIANVERSION=$(cat /etc/debian_version | cut -d \. -f1)
	SYSTEM=$(gawk -F= '/^NAME/{print $2}' /etc/os-release)
	echo ""
	echo -e "${BLUE}### UPGRADING ###${NC}"
	echo " * Checking system OS release"
	echo -e "	${YELLOW}--> System detected : $SYSTEM${NC}"
	if [[ $(echo $SYSTEM | grep "Debian") != "" ]]; then
		echo -e "	${YELLOW}--> $SYSTEM version : $DEBIANVERSION${NC}"
		echo "deb http://ftp.debian.org/debian jessie-backports main" >> $SOURCESFOLDER
		apt-get update > /dev/null 2>&1
		if [[ "$DEBIANVERSION" -lt "8" ]]; then
			sed -ri 's/deb\ cdrom/#deb\ cdrom/g' /etc/apt/sources.list
			echo "deb http://ftp.debian.org/debian wheezy-backports main" >> $SOURCESFOLDER
			apt-get update > /dev/null 2>&1
			apt-get install python-software-properties > /dev/null 2>&1
		fi
		echo " * Creating docker.list"
		if [[ ! -f "$DOCKERLIST" ]]; then
			echo "deb https://apt.dockerproject.org/repo debian-jessie main" > $DOCKERLIST
			apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D > /dev/null 2>&1
			if [[ $? = 0 ]]; then
				echo -e "	${GREEN}--> Docker.list successfully created !${NC}"
			else
				echo -e "	${RED}--> Error adding the Key P80.POOL.SKS for Docker's Repo${NC}" 	
			fi
		else
			echo -e "	${YELLOW}--> Docker.list already exist !${NC}"
		fi
		echo " * Creating nginx.list"
		if [[ ! -f "$NGINXLIST" ]]; then
			echo "deb http://nginx.org/packages/debian/ $(lsb_release -sc) nginx" > $NGINXLIST
			wget -q -O - https://nginx.org/keys/nginx_signing.key | apt-key add - > /dev/null 2>&1
			if [[ $? = 0 ]]; then
				echo -e "	${GREEN}--> Nginx.list successfully created !${NC}"
			else
				echo -e "	${RED}--> Error adding the Key nginx_signing.key for Nginx Repo${NC}" 	
			fi
		else
			echo -e "	${YELLOW}--> Nginx.list already exist !${NC}"
		fi
		echo -e " ${BWHITE}* Installing Certbot${NC}"
		apt-get install certbot -t jessie-backports -y > /dev/null 2>&1
		if [[ "$?" == "0" ]]; then
			echo -e "	${GREEN}--> Certbot successfully installed !${NC}"
		else
			echo -e "	${RED}--> Failed installing Certbot${NC}"
		fi
	elif [[ $(echo $SYSTEM | grep "Ubuntu") ]]; then
		echo " * Creating docker.list"
		apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D > /dev/null 2>&1
		apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /dev/null 2>&1
		if [[ "$?" == "0" ]]; then
			echo -e "	--> ${GREEN}Docker.list successfully added !${NC}"
		else
			echo -e "	--> ${RED}Error adding Key or repository !${NC}"
		fi
		echo " * Adding certbot repository"
		apt-get install -y software-properties-common > /dev/null 2>&1
		add-apt-repository ppa:certbot/certbot -y > /dev/null 2>&1
		if [[ $? = 0 ]]; then
			echo -e "	${GREEN}--> Certbot repository successfully added !${NC}"
		else
			echo -e "	${RED}--> Failed to add Certbot repository !${NC}"
		fi
		apt-get update > /dev/null 2>&1
		echo " * Installing certbot"
		apt-get install certbot -y  > /dev/null 2>&1
		if [[ $? = 0 ]]; then
			echo -e "	${GREEN}--> Certbot successfully installed !${NC}"
		else
			echo -e "	${RED}--> Failed to install Certbot !${NC}"
		fi
	fi
	echo " * Updating sources and upgrading system"
	apt-get update > /dev/null 2>&1
	apt-get upgrade -y > /dev/null 2>&1
	if [[ $? = 0 ]]; then
		echo -e "	${GREEN}--> System upgraded successfully !${NC}"
	fi
	echo ""
}

function install_nginx() {
	echo -e "${BLUE}### NGINX ###${NC}"
	NGINXDIR="/etc/nginx/"
	if [[ ! -d "$NGINXDIR" ]]; then	
		echo -e " * Installing Nginx"
		apt-get install -y nginx > /dev/null 2>&1
	else
		echo -e " * Nginx is already installed !"
	fi
	echo ""
}

function install_zsh() {
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
		echo " * Installing Docker"
		if [[ $(echo $SYSTEM | grep "Ubuntu") ]]; then
			apt-get install -y docker-engine --allow-unauthenticated > /dev/null 2>&1
		else
			apt-get install -y docker-engine > /dev/null 2>&1
		fi
		if [[ "$?" == "0" ]]; then
			echo -e "	${GREEN}* Docker successfully installed${NC}"
		else
			echo -e "	${RED}* Failed installing Docker !${NC}"
		fi
		service docker start > /dev/null 2>&1
		echo " * Installing Docker-compose"
		curl -L https://github.com/docker/compose/releases/download/1.12.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
		chmod +x /usr/local/bin/docker-compose
		if [[ "$?" == "0" ]]; then
			echo -e "	${GREEN}* Docker-Compose successfully installed${NC}"
		else
			echo -e "	${RED}* Failed installing Docker-Compose !${NC}"
		fi
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

function define_parameters() {
	echo -e "${BLUE}### USER INFORMATIONS ###${NC}"
	USEDOMAIN="y"
	CURRTIMEZONE=$(cat /etc/timezone)
	create_user
	TIMEZONEDEF=$(whiptail --title "Timezone" --inputbox \
	"Please enter your timezone" 7 66 "$CURRTIMEZONE" \
	3>&1 1>&2 2>&3)
	if [[ $TIMEZONEDEF == "" ]]; then
		TIMEZONE=$CURRTIMEZONE
	else
		TIMEZONE=$TIMEZONEDEF
	fi
	CONTACTEMAIL=$(whiptail --title "Email address" --inputbox \
	"Please enter your email address :" 7 50 \
	3>&1 1>&2 2>&3)
	if (whiptail --title "Use domain name" --yesno "Do you want to use a domain to join your apps ?" 7 50) then
		DOMAIN=$(whiptail --title "Your domain name" --inputbox \
		"Please enter your domain :" 7 50 \
		3>&1 1>&2 2>&3)
	else
		DOMAIN="localhost"
	fi
	#install_ftp_server
	echo ""
}

function create_user() {
	touch $USERSFILE
	SEEDUSER=$(whiptail --title "Username" --inputbox \
		"Please enter a username :" 7 50 \
		3>&1 1>&2 2>&3)
	PASSWORD=$(whiptail --title "Password" --passwordbox \
		"Please enter a password :" 7 50 \
		3>&1 1>&2 2>&3)
	egrep "^$SEEDUSER" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		USERID=$(id -u $SEEDUSER)
		GRPID=$(id -g $SEEDUSER)
	else
		PASS=$(perl -e 'print crypt($ARGV[0], "password")' $PASSWORD)
		useradd -m -p $PASS $SEEDUSER > /dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			echo -e " ${GREEN}--> User has been added to system !${NC}"
		else
			echo -e " ${RED}--> Failed to add a user !${NC}"
		fi
		USERID=$(id -u $SEEDUSER)
		GRPID=$(id -g $SEEDUSER)
	fi
	add_user_htpasswd $SEEDUSER $PASSWORD
	echo $SEEDUSER >> $USERSFILE
}

function choose_services() {
	echo -e "${BLUE}### SERVICES ###${NC}"
	echo -e "${BWHITE}Nginx, Jackett and Portainer will be installed by default !${NC}"
	echo " --> Services wich will be installed : "
	for app in $(cat includes/config/services-available);
	do
		service=$(echo $app | cut -d\- -f1)
		desc=$(echo $app | cut -d\- -f2)
		echo "$service $desc off" >> /tmp/menuservices.txt
	done
	SERVICESTOINSTALL=$(whiptail --title "Services manager" --checklist \
	"Please select services you want to add for $SEEDUSER. Portainer & Jackett are installed by default !" 25 50 15 \
	$(cat /tmp/menuservices.txt) 3>&1 1>&2 2>&3)
	SERVICESPERUSER="$SERVICESUSER$SEEDUSER"
	touch $SERVICESPERUSER
	cat $SERVICES >> $SERVICESPERUSER
	for APPDOCKER in $SERVICESTOINSTALL
	do
		echo -e "	${GREEN}* $(echo $APPDOCKER | tr -d '"')${NC}"
		echo $(echo ${APPDOCKER,,} | tr -d '"') >> $SERVICESPERUSER
	done
	rm /tmp/menuservices.txt
}

function add_user_htpasswd() {
	HTFOLDER="/etc/nginx/passwd/"
	HTTEMPFOLDER="/tmp/"
	HTFILE=".htpasswd"
	if [[ $1 == "" ]]; then
		echo ""
		echo -e "${BLUE}## HTPASSWD MANAGER ##${NC}"
		HTUSER=$(whiptail --title "HTUser" --inputbox "Enter username for htaccess" 10 60 3>&1 1>&2 2>&3)
		HTPASSWORD=$(whiptail --title "HTPassword" --passwordbox "Enter password" 10 60 3>&1 1>&2 2>&3)
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
	for line in $(cat $SERVICESPERUSER);
	do
		REVERSEPROXYNGINX="/etc/nginx/conf.d/$line-$SEEDUSER.conf"
		cat "includes/dockerapps/$line.yml" >> $DOCKERCOMPOSEFILE
		sed -i "s|%TIMEZONE%|$TIMEZONE|g" $DOCKERCOMPOSEFILE
		sed -i "s|%UID%|$USERID|g" $DOCKERCOMPOSEFILE
		sed -i "s|%GID%|$GRPID|g" $DOCKERCOMPOSEFILE
		sed -i "s|%PORT%|$PORT|g" $DOCKERCOMPOSEFILE
		sed -i "s|%USER%|$SEEDUSER|g" $DOCKERCOMPOSEFILE
		sed -i "s|%EMAIL%|$CONTACTEMAIL|g" $DOCKERCOMPOSEFILE
		# if [[ "$DOMAIN" != "localhost" ]] && [[ "$line" != "teamspeak" ]]; then
		# 	if [[ "$LESSL" != "n" ]]; then
		# 		NGINXPROXYFILE="includes/nginxproxyssl/$line.conf"
		# 		touch $REVERSEPROXYNGINX
		# 		cat $NGINXPROXYFILE >> $REVERSEPROXYNGINX
		# 	else
		# 		NGINXPROXYFILE="includes/nginxproxy/$line.conf"
		# 		touch $REVERSEPROXYNGINX
		# 		cat $NGINXPROXYFILE >> $REVERSEPROXYNGINX
		# 	fi
		# 	sed -i "s|%DOMAIN%|$line.$DOMAIN|g" $REVERSEPROXYNGINX
		# 	sed -i "s|%PORT%|$PORT|g" $REVERSEPROXYNGINX
		# 	sed -i "s|%USER%|$SEEDUSER|g" $REVERSEPROXYNGINX
		# fi
		echo "$line-$PORT" >> $INSTALLEDFILE
		PORT=$PORT+1
	done
	echo $PORT >> $FILEPORTPATH
	echo ""
}

function docker_compose() {
	echo -e "${BLUE}### DOCKERCOMPOSE ###${NC}"
	cd /etc/seedboxcompose/
	echo " * Starting docker..."
	service docker restart
	echo " * Docker-composing, it may takes a long..."
	docker-compose up -d > /dev/null 2>&1
	echo -e "	${BWHITE}--> Docker-compose ok !${NC}"
	echo ""
}

function valid_htpasswd() {
	HTFOLDER="/etc/nginx/passwd/"
	mkdir -p $HTFOLDER
	HTTEMPFOLDER="/tmp/"
	HTFILE=".htpasswd"
	cat "$HTTEMPFOLDER$HTFILE" >> "$HTFOLDER$HTFILE"
}

function create_reverse() {
	if [[ "$DOMAIN" != "localhost" ]]; then
		echo -e "${BLUE}### REVERSE PROXY ###${NC}"
		SITEFOLDER="/etc/nginx/conf.d/"
		service nginx stop > /dev/null 2>&1
		if [[ "$DOMAIN" != "localhost" ]]; then
			if (whiptail --title "Use SSL" --yesno "Do you want to use SSL with Let's Encrypt support ?" 10 60) then
				LESSL="y"
			else
				LESSL="n"
			fi
		fi
		for line in $(cat $SERVICESPERUSER);
		do
			echo $SERVICESPERUSER
			NGINXSITE="/etc/nginx/conf.d/$line-$SEEDUSER.conf"
			FQDNTMP="$line.$DOMAIN"
			echo -e " ${BWHITE}--> [$line] - Creating reverse${NC}"
			if [[ "$DOMAIN" != "localhost" ]] && [[ "$line" != "teamspeak" ]]; then
				if [[ "$LESSL" = "y" ]]; then
					NGINXPROXYFILE="includes/nginxproxyssl/$line.conf"
					touch $NGINXSITE
					cat $NGINXPROXYFILE >> $NGINXSITE
				else
					NGINXPROXYFILE="includes/nginxproxy/$line.conf"
					touch $NGINXSITE
					cat $NGINXPROXYFILE >> $NGINXSITE
				fi
				sed -i "s|%DOMAIN%|$line.$DOMAIN|g" $NGINXSITE
				sed -i "s|%PORT%|$PORT|g" $NGINXSITE
				sed -i "s|%USER%|$SEEDUSER|g" $NGINXSITE
				FQDN=$(whiptail --title "SSL Subdomain" --inputbox \
				"Do you want to use a different subdomain for $line ? default :" 7 50 "$FQDNTMP" 3>&1 1>&2 2>&3)
				generate_ssl_cert $CONTACTEMAIL $FQDN
				if [[ "$?" == "0" ]]; then
					echo -e "		${GREEN}* Certificate generation OK !${NC}"
				else
					echo -e "		${RED}* Certificate generation failed !${NC}"
				fi
			fi
			FQDN=""
			FQDNTMP=""
		done
		echo -e " --> ${YELLOW}Restarting Nginx...${NC}"
		service nginx restart > /dev/null 2>&1
		if [[ "$?" == "0" ]]; then
			echo -e "	${GREEN}* Service nginx restarted !${NC}"
		else
			echo -e "	${RED}* Failed to restart Nginx !${NC}"
		fi
	fi
	USERDIR="/home/$SEEDUSER/downloads/{medias,movies,tv}"
	if [[ -d "$USERDIR" ]]; then
		chown $SEEDUSER: $USERDIR -R > /dev/null 2>&1
		chmod 777 $USERDIR -R > /dev/null 2>&1
	fi
}

function generate_ssl_cert() {
	EMAILADDRESS=$1
	DOMAINSSL=$2
	echo -e "		${BWHITE}--> Generating LE certificate files for $FQDN, please wait...${NC}"
	certbot certonly --quiet --standalone --preferred-challenges http-01 --agree-tos --rsa-key-size 4096 --email $EMAILADDRESS -d $DOMAINSSL
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

# function add_docker_app() {
# 	echo -e "${BLUE}##########################################${NC}"
# 	echo -e "${BLUE}###           ADD DOCKER APPS          ###${NC}"
# 	echo -e "${BLUE}##########################################${NC}"
# 	declare -i NUMUSER=0
# 	declare -a seedboxusers=()
# 	for line in $(cat $USERSFILE);
# 	do
# 		seedboxusers[${#seedboxusers[*]}]=$line
# 		NUMUSER=$NUMUSER+1
# 	done
# 	NBUSERS=$(${#nomtableau[*]})
# 	SEEDUSER=$(whiptail --title "Choose username" --menu \
# 		"Please select user to add dockers app" 15 50 4 \
# 		${seedboxusers[0]} " " 3>&1 1>&2 2>&3)
# 	echo -e " ${BWHITE}* Adding apps for $SEEDUSER"
# }

# function delete_dockers() {
# 	echo -e "${BLUE}##########################################${NC}"
# 	echo -e "${BLUE}###        CLEANING DOCKER APPS        ###${NC}"
# 	echo -e "${BLUE}##########################################${NC}"
# 	echo " * Stopping dockers..."
# 	docker stop $(docker ps) > /dev/null 2>&1
# 	echo " * Removing dockers..."
# 	docker rm $(docker ps -a) > /dev/null 2>&1
# 	if (whiptail --title "Data deleting" --yesno "Do you want to delete all docker's configuration files, data and user ?" 10 60) then
# 		if [[ "$SEEDUSER" == "" ]]; then
# 			SEEDUSER=$(whiptail --title "Username" --inputbox "Specify user to delete all his conf files" 10 60 Morgan 3>&1 1>&2 2>&3)
# 		fi
# 		DOCKERFOLDER="/home/$SEEDUSER/dockers/"
# 		echo "		* Deleting user..."
# 		userdel $SEEDUSER
# 		if [[ -d "$DOCKERFOLDER" ]]; then
# 			echo "		* Deleting files..."
# 			rm $DOCKERFOLDER -R
# 			rm $CONFDIR -R
# 		fi
# 	else
# 		echo -e "	${BWHITE}* Nothing will be deleted !${NC}"
# 	fi
# 	echo ""
# }

# function install_ftp_server() {
# 	if [[ ! -d "$PROFTPDCONF" ]]; then
# 		if (whiptail --title "Use FTP Server" --yesno "Do you want to install FTP server ?" 7 50) then
# 			FTPSERVERNAME=$(whiptail --title "FTPServer Name" --inputbox \
# 			"Please enter a name for your FTP Server :" 7 50 "SeedBox" \
# 			3>&1 1>&2 2>&3)
# 			apt-get install proftpd -y
# 			BASEPROFTPDFILE="includes/config/proftpd.conf"
# 			mv "$PROFTPDCONF" "$PROFTPDCONF.bak"
# 	 		cat "$BASEPROFTPDFILE" >> "$PROFTPDCONF"
# 	 		sed -i -e "s/ServerName\ \"Debian\"/$FTPSERVERNAME/g" "$PROFTPDCONF"
# 	 		service proftpd restart
# 		fi
# 	else
# 		echo -e "${BLUE}### INSTALL FTP SERVER ###${NC}"
# 		echo -e "	${RED}* Proftpd is already installed !${NC}"
# 	fi
# }

#function restart_docker_apps() {
	# DOCKERS=$(docker ps --format "{{.Names}}")
	# declare -i i=1
	# declare -a TABAPP
	# echo "	* [0] - All dockers (default)"
	# while [ $i -le $(echo "$DOCKERS" | wc -w) ]
	# do
	# 	APP=$(echo $DOCKERS | cut -d\  -f$i)
	# 	echo "	* [$i] - $APP"
	# 	$TABAPP[$i]=$APP
	# 	i=$i+1
	# done
	# read -p "Please enter the number you want to restart, let blank to default value (all) : " RESTARTAPP
	# case $RESTARTAPP in
	# "")
	#   docker restart $(docker ps)
	#   ;;
	# "0")
	#   docker restart $(docker ps)
	#   ;;
	# "1")
	#   echo $TABAPP[1]
	#   #docker restart TABAPP[1]
	# esac
#}

function resume_seedbox() {
	echo ""
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###       RESUMING SEEDBOX INSTALL     ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	echo ""
	if [[ "$DOMAIN" != "localhost" ]]; then
		echo -e " ${BWHITE}* Access apps from these URL :${NC}"
		echo -e "	--> Your Web server is available on ${YELLOW}$DOMAIN${NC}"
		for line in $(cat $SERVICESPERUSER);
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
	if [[ -f "/home/$SEEDUSER/downloads/medias/supervisord.log" ]]; then
		mv /home/$SEEDUSER/downloads/medias/supervisord.log /home/$SEEDUSER/downloads/medias/.supervisord.log > /dev/null 2>&1
		mv /home/$SEEDUSER/downloads/medias/supervisord.pid /home/$SEEDUSER/downloads/medias/.supervisord.pid > /dev/null 2>&1
	fi
}

function backup_docker_conf() {
	BACKUPDIR="/var/archives/"
	BACKUPNAME="backup-seedboxcompose-$SEEDUSER-"
	echo ""
	BACKUP="$BACKUPDIR$BACKUPNAME$BACKUPDATE.tar.gz"
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###         BACKUP DOCKER CONF         ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	if [[ "$SEEDUSER" != "" ]]; then
		if (whiptail --title "Backup Dockers conf" --yesno "Do you want backup configuration for $SEEDUSER ?" 10 60) then
			USERBACKUP=$SEEDUSER
		else
			exit 1
		fi
	else
		USERBACKUP=$(whiptail --title "Backup User" --inputbox "Enter username to backup configuration" 10 60 3>&1 1>&2 2>&3)
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
	schedule_backup_seedbox
	echo ""
}

function schedule_backup_seedbox() {
	if [[ "$SEEDUSER" == "" ]]; then
		SEEDUSER=$(whiptail --title "Username" --inputbox \
		"Please enter your username :" 7 50 \
		3>&1 1>&2 2>&3)
	fi
	if [[ -d "/home/$SEEDUSER" ]]; then
		BACKUPTYPE=$(whiptail --title "Backup type" --menu "Choose a scheduling backup type" 12 60 4 \
			"1" "Daily backup" \
			"2" "Weekly backup" \
			"3" "Monthly backup" 3>&1 1>&2 2>&3)
		BACKUPDIR=$(whiptail --title "Backup dir" --inputbox \
			"Please choose backup destination" 7 65 "/var/archives" \
			3>&1 1>&2 2>&3)
		BACKUPNAME="$BACKUPDIR/backup-seedboxcompose-$SEEDUSER.tar.gz"
		DOCKERDIR="/home/$SEEDUSER"
		CRONTABFILE="/etc/crontab"
		TMPCRONFILE="/tmp/crontab"
		case $BACKUPTYPE in
		"1")
			SCHEDULEBACKUP="@daily tar cvpzf $BACKUPNAME $DOCKERDIR >/dev/null 2>&1"
			BACKUPDESC="Backup every day"
		;;
		"2")
			SCHEDULEBACKUP="@weekly tar cvpzf $BACKUPNAME $DOCKERDIR >/dev/null 2>&1"
			BACKUPDESC="Backup every weeks"
		;;
		"3")
			SCHEDULEBACKUP="@monthly tar cvpzf $BACKUPNAME $DOCKERDIR >/dev/null 2>&1"
			BACKUPDESC="Backup every months"
		;;
		esac
		echo $SCHEDULEBACKUP >> $TMPCRONFILE
		cat "$TMPCRONFILE" >> "$CRONTABFILE"
		echo -e " ${GREEN}--> Backup successfully scheduled :${NC}"
		echo -e "	${BWHITE}* $BACKUPDESC ${NC}"
		echo -e "	${BWHITE}* In $BACKUPDIR ${NC}"
		echo -e "	${BWHITE}* For $SEEDUSER ${NC}"
		echo ""
		rm $TMPCRONFILE
	else
		echo -e " ${YELLOW}* Please install Seedbox for $SEEDUSER before backup${NC}"
		echo ""
	fi
}

function access_token_ts() {
	grep -R "teamspeak" "$SERVICESPERUSER" > /dev/null
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
