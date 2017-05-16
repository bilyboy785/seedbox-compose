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
		ACTION=$(whiptail --title "Seedbox-Compose" --menu "Welcome to Seedbox-Compose Script. Please choose an action below :" 20 75 11 \
			"1" "Seedbox-Compose already installed !" \
			"2" "New seedbox user" \
			"3" "New htaccess user" \
			"4" "Add docker Apps for user X" \
			"5" "Restart all dockers" \
			"6" "Backup dockers configuration" \
			"7" "Enable scheduled backup" \
			"8" "Install FTP Server" \
			"9" "Generate SSL certificate" \
			"10" "Disable htaccess protection" \
			"11" "Uninstall Seedbox-Compose"  3>&1 1>&2 2>&3)
		echo ""
		case $ACTION in
		"1")
		  clear
		  echo ""
		  echo -e "${YELLOW}### Seedbox-Compose already installed !###${NC}"
		  if (whiptail --title "Seedbox already installed" --yesno "You're in trouble with Seedbox-compose ? Uninstall and try again ?" 7 90) then
				uninstall_seedbox
			else
				echo "NOTHING"
			fi
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
		  SCRIPT="RESTARTDOCKERS"
		;;
		"6")
		  SCRIPT="BACKUPCONF"
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
		  SCRIPT="UNINSTALL"
		;;
		esac
	else
		ACTION=$(whiptail --title "Seedbox-Compose" --menu "Welcome to Seedbox-Compose installation !" 10 75 2 \
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
	echo ""
}

function delete_htaccess() {
	SITEENABLEDFOLDER="/etc/nginx/conf.d/"
	sed -ri 's///g' /etc/
}

function checking_system() {
	echo -e "${BLUE}### CHECKING SYSTEM ###${NC}"
	echo " * Checking system OS"
	TMPSOURCESDIR="includes/sources.list"
	TMPSYSTEM=$(gawk -F= '/^NAME/{print $2}' /etc/os-release)
	TMPCODENAME=$(lsb_release -sc)
	TMPRELEASE=$(cat /etc/debian_version)
	if [[ $(echo $TMPSYSTEM | sed 's/\"//g') == "Debian GNU/Linux" ]]; then
		SYSTEMOS="Debian"
		if [[ $(echo $TMPRELEASE | grep "8") != "" ]]; then
			SYSTEMRELEASE="8"
			SYSTEMCODENAME="jessie"
		elif [[ $(echo $TMPRELEASE | grep "7") != "" ]]; then
			SYSTEMRELEASE="7"
			SYSTEMCODENAME="wheezy"
		fi
	elif [[ $(echo $TMPSYSTEM | sed 's/\"//g') == "Ubuntu" ]]; then
		SYSTEMOS="Ubuntu"
		if [[ $(echo $TMPCODENAME | grep "xenial") != "" ]]; then
			SYSTEMRELEASE="16.04"
			SYSTEMCODENAME="xenial"
		elif [[ $(echo $TMPCODENAME | grep "yakkety") != "" ]]; then
			SYSTEMRELEASE="16.10"
			SYSTEMCODENAME="yakkety"
		elif [[ $(echo $TMPCODENAME | grep "zesty") != "" ]]; then
			SYSTEMRELEASE="17.14"
			SYSTEMCODENAME="zesty"
		fi
	fi
	echo -e "	${YELLOW}--> System OS : $SYSTEMOS${NC}"
	echo -e "	${YELLOW}--> Release : $SYSTEMRELEASE${NC}"
	echo -e "	${YELLOW}--> Codename : $SYSTEMCODENAME${NC}"
	case $SYSTEMCODENAME in
		"jessie" )
			echo -e " ${BWHITE}* Creating sources.list${NC}"
			rm /etc/apt/sources.list -R
			cp "$TMPSOURCESDIR/debian.jessie" "$SOURCESLIST"
			checking_errors $?
			;;
		"wheezy" )
			echo -e "	${YELLOW}--> Please upgrade to Debian Jessie !${NC}"
			;;
	esac
	if [[ "$SYSTEMOS" == "Ubuntu" ]]; then
		echo -e " ${BWHITE}* Creating repositories${NC}"
		echo "deb http://nginx.org/packages/ubuntu/ $SYSTEMCODENAME nginx" >> $SOURCESLIST
		echo "deb-src http://nginx.org/packages/ubuntu/ $SYSTEMCODENAME nginx" >> $SOURCESLIST
		apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /dev/null 2>&1
		add-apt-repository ppa:certbot/certbot -y > /dev/null 2>&1
		checking_errors $?
	fi
	echo -e " ${BWHITE}* Adding Nginx key${NC}"
	wget -q http://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key > /dev/null 2>&1
	checking_errors $?
	echo -e " ${BWHITE}* Adding Docker key${NC}"
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D > /dev/null 2>&1
	checking_errors $?
	echo -e " ${BWHITE}* Updating & upgrading system${NC}"
	apt-get update > /dev/null 2>&1
	apt-get upgrade -y > /dev/null 2>&1
	checking_errors $?
	echo -e " ${BWHITE}* Installing certbot${NC}"
	if [[ "$SYSTEMOS" == "Ubuntu" ]]; then
		apt-get install certbot -y  > /dev/null 2>&1
	elif [[ "$SYSTEMOS" == "Debian" ]]; then
		apt-get install certbot -t jessie-backports -y > /dev/null 2>&1
	fi
	checking_errors $?
	echo ""
}

function checking_errors() {
	if [[ "$1" == "0" ]]; then
		echo -e "	${GREEN}--> Operation success !${NC}"
	else
		echo -e "	${RED}--> Operation failed !${NC}"
	fi
}

function install_nginx() {
	echo -e "${BLUE}### NGINX ###${NC}"
	NGINXDIR="/etc/nginx/"
	if [[ ! -d "$NGINXDIR" ]]; then	
		echo -e " * Installing Nginx"
		apt-get install -y nginx > /dev/null 2>&1
		checking_errors $?
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
		checking_errors $?
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
	echo " --> Services will be installed : "
	for app in $(cat includes/config/services-available);
	do
		service=$(echo $app | cut -d\- -f1)
		desc=$(echo $app | cut -d\- -f2)
		echo "$service $desc off" >> /tmp/menuservices.txt
	done
	SERVICESTOINSTALL=$(whiptail --title "Services manager" --checklist \
	"Please select services you want to add for $SEEDUSER (Use space to select)" 28 65 17 \
	$(cat /tmp/menuservices.txt) 3>&1 1>&2 2>&3)
	SERVICESPERUSER="$SERVICESUSER$SEEDUSER"
	touch $SERVICESPERUSER
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
	HTFILE=".htpasswd-$SEEDUSER"
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
	INSTALLEDFILE="/home/$SEEDUSER/resume"
	touch "$INSTALLEDFILE" > /dev/null 2>&1
	if [[ -f "$FILEPORTPATH" ]]; then
		declare -i PORT=$(cat $FILEPORTPATH | tail -1)
	else
		declare -i PORT=$FIRSTPORT
	fi
	if [[ "$DOMAIN" != "localhost" ]]; then
		if (whiptail --title "Use SSL" --yesno "Do you want to use SSL with Let's Encrypt support ?" 10 60) then
			RSASSLKEY=$(whiptail --title "RSA Key Size" --inputbox \
			"Secify RSA key size for your certificate" 7 50 "4096" 3>&1 1>&2 2>&3)
			LESSL="y"
		else
			LESSL="n"
		fi
	fi
	DOCKERCOMPOSEFILE="/home/$SEEDUSER/docker-compose.yml"
	for line in $(cat $SERVICESPERUSER);
	do
		#REVERSEPROXYNGINX="/etc/nginx/conf.d/$line-$SEEDUSER.conf"
		cat "includes/dockerapps/$line.yml" >> $DOCKERCOMPOSEFILE
		sed -i "s|%TIMEZONE%|$TIMEZONE|g" $DOCKERCOMPOSEFILE
		sed -i "s|%UID%|$USERID|g" $DOCKERCOMPOSEFILE
		sed -i "s|%GID%|$GRPID|g" $DOCKERCOMPOSEFILE
		sed -i "s|%PORT%|$PORT|g" $DOCKERCOMPOSEFILE
		sed -i "s|%USER%|$SEEDUSER|g" $DOCKERCOMPOSEFILE
		sed -i "s|%EMAIL%|$CONTACTEMAIL|g" $DOCKERCOMPOSEFILE
		sed -i "s|%IPADDRESS%|$IPADDRESS|g" $DOCKERCOMPOSEFILE
		if [[ "$DOMAIN" != "localhost" ]]; then
			FQDNTMP="$line.$DOMAIN"
			FQDN=$(whiptail --title "SSL Subdomain" --inputbox \
			"Do you want to use a different subdomain for $line ? default :" 7 75 "$FQDNTMP" 3>&1 1>&2 2>&3)
			if [[ "$LESSL" = "y" ]]; then
				NGINXSITE="/etc/nginx/conf.d/$FQDN.conf"
				NGINXPROXYFILE="$PWD/includes/nginxproxyssl/$line.conf"
				touch $NGINXSITE
				cat $NGINXPROXYFILE >> $NGINXSITE
				echo "$line-$PORT-$FQDN" >> $INSTALLEDFILE
			else
				NGINXPROXYFILE="$PWD/includes/nginxproxy/$line.conf"
				touch $NGINXSITE
				cat $NGINXPROXYFILE >> $NGINXSITE
			fi
			sed -i "s|%DOMAIN%|$FQDN|g" $NGINXSITE
			sed -i "s|%PORT%|$PORT|g" $NGINXSITE
			sed -i "s|%USER%|$SEEDUSER|g" $NGINXSITE
		elif [[ "$DOMAIN" == "localhost" ]]; then
			echo "$line-$PORT-$SEEDUSER" >> $INSTALLEDFILE
		fi
		PORT=$PORT+1
		FQDN=""
		FQDNTMP=""
	done
	echo $PORT >> $FILEPORTPATH
	echo ""
}

function docker_compose() {
	echo -e "${BLUE}### DOCKERCOMPOSE ###${NC}"
	ACTDIR="$PWD"
	cd /home/$SEEDUSER/
	echo " * Starting docker..."
	service docker restart
	echo " * Docker-composing, it may takes a long..."
	docker-compose up -d > /dev/null 2>&1
	echo -e "	${BWHITE}--> Docker-compose ok !${NC}"
	echo ""
	cd $ACTDIR
}

function valid_htpasswd() {
	HTFOLDER="/etc/nginx/passwd/"
	mkdir -p $HTFOLDER
	HTTEMPFOLDER="/tmp/"
	HTFILE=".htpasswd-$SEEDUSER"
	cat "$HTTEMPFOLDER$HTFILE" >> "$HTFOLDER$HTFILE"
	rm "$HTTEMPFOLDER$HTFILE"
}

function create_reverse() {
	if [[ "$DOMAIN" != "localhost" ]]; then
		echo -e "${BLUE}### REVERSE PROXY ###${NC}"
		SITEFOLDER="/etc/nginx/conf.d/"
		service nginx stop > /dev/null 2>&1
		for line in $(cat $INSTALLEDFILE);
		do
			SERVICE=$(echo $line | cut -d\- -f1)
			PORT=$(echo $line | cut -d\- -f2)
			FQDN=$(echo $line | cut -d\- -f3)
			echo -e " ${BWHITE}--> [$SERVICE] - Creating reverse${NC}"
			if [[ "$DOMAIN" != "localhost" ]] && [[ "$line" != "teamspeak" ]]; then
				generate_ssl_cert $CONTACTEMAIL $FQDN
				if [[ "$?" == "0" ]]; then
					echo -e "		${GREEN}* Certificate generation OK !${NC}"
				else
					echo -e "		${RED}* Certificate generation failed !${NC}"
				fi
			fi
		done
		echo ""
		echo -e " --> ${BWHITE}Restarting Nginx...${NC}"
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
	echo -e "	${BWHITE}--> Generating LE certificate files for $DOMAINSSL, please wait... and wait again !${NC}"
	bash /opt/letsencrypt/letsencrypt-auto certonly --standalone --preferred-challenges http-01 --agree-tos --rsa-key-size $RSASSLKEY --non-interactive --quiet --email $EMAILADDRESS -d $DOMAINSSL
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

function install_ftp_server() {
	echo -e "${BLUE}### INSTALL FTP SERVER ###${NC}"
	if [[ ! -f "$PROFTPDCONF" ]]; then
		if (whiptail --title "Use FTP Server" --yesno "Do you want to install FTP server ?" 7 50) then
			FTPSERVERNAME=$(whiptail --title "FTPServer Name" --inputbox \
			"Please enter a name for your FTP Server :" 7 50 "SeedBox" 3>&1 1>&2 2>&3)
			echo -e "	${BWHITE}* Installing proftpd...${NC}"
			apt-get install proftpd -y > /dev/null 2>&1
			checking_errors $?
			BASEPROFTPDFILE="includes/config/proftpd.conf"
			echo -e "	${BWHITE}* Creating configuration file...${NC}"
			mv "$PROFTPDCONF" "$PROFTPDCONF.bak"
	 		cat "$BASEPROFTPDFILE" >> "$PROFTPDCONF"
	 		sed -i -e "s/ServerName\ \"Debian\"/$FTPSERVERNAME/g" "$PROFTPDCONF"
	 		checking_errors $?
	 		echo -e "	${BWHITE}* Restarting service...${NC}"
	 		service proftpd restart
	 		checking_errors $?
		fi
	else
		echo -e "	${RED}* Proftpd is already installed !${NC}"
	fi
}

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
	if [[ "$DOMAIN" != "localhost" ]]; then
		echo -e " ${BWHITE}* Access apps from these URL :${NC}"
		echo -e "	--> Your Web server is available on ${YELLOW}$DOMAIN${NC}"
		for line in $(cat $INSTALLEDFILE);
		do
			ACCESSDOMAIN=$(echo $line | cut -d\- -f3)
			echo -e "	--> $line from ${YELLOW}$ACCESSDOMAIN${NC}"
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
	# echo -e " ${BWHITE}* Found logs here :${NC}"
	# echo -e "	--> Info Logs : ${YELLOW}$INFOLOGS${NC}"
	# echo -e "	--> Error Logs : ${YELLOW}$ERRORLOGS${NC}"
	if [[ -f "/home/$SEEDUSER/downloads/medias/supervisord.log" ]]; then
		mv /home/$SEEDUSER/downloads/medias/supervisord.log /home/$SEEDUSER/downloads/medias/.supervisord.log > /dev/null 2>&1
		mv /home/$SEEDUSER/downloads/medias/supervisord.pid /home/$SEEDUSER/downloads/medias/.supervisord.pid > /dev/null 2>&1
	fi
	chown $SEEDUSER: -R /home/$SEEDUSER/downloads/{tv;movies;medias}
	chmod 775: -R /home/$SEEDUSER/downloads/{tv;movies;medias}
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
	echo ""
	schedule_backup_seedbox
	echo ""
}

function schedule_backup_seedbox() {
	if (whiptail --title "Backup Dockers conf" --yesno "Do you want to schedule a configuration backup ?" 10 60) then
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
				"Please choose backup destination" 7 65 "/var/backup" \
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
			echo -e " ${YELLOW}--> Please install Seedbox for $SEEDUSER before backup${NC}"
			echo ""
		fi
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

function uninstall_seedbox() {
	clear
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###          UNINSTALL SEEDBOX         ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	ACTION=$(whiptail --title "Seedbox-Compose" --menu "Choose what you want uninstall" 10 75 2 \
			"1" "Full uninstall (all files and dockers)" \
			"2" "User uninstall (delete a suer)" 3>&1 1>&2 2>&3)
		echo ""
		case $ACTION in
		"1")
		  	if (whiptail --title "Uninstall Seedbox" --yesno "Do you really want to uninstall Seedbox ?" 7 75) then
				if (whiptail --title "Dockers configuration" --yesno "Do you want to backup your Dockers configuration ?" 7 75) then
					echo -e " ${BWHITE}* All files, dockers and configuration will be uninstall${NC}"
					echo -e "	${RED}--> Under developpment${NC}"
				else
					echo -e " ${BWHITE}* Everything will be deleted !${NC}"
					echo -e "	${RED}--> Under developpment${NC}"
				fi
			fi
		;;
		"2")
			if (whiptail --title "Uninstall Seedbox" --yesno "Do you really want to uninstall Seedbox ?" 7 75) then
				if (whiptail --title "Dockers configuration" --yesno "Do you want to backup your Dockers configuration ?" 7 75) then
					echo -e " ${BWHITE}* All files, dockers and configuration will be uninstall${NC}"
					echo -e "	${RED}--> Under developpment${NC}"
				else
					echo -e " ${BWHITE}* Everything will be deleted !${NC}"
					echo -e "	${RED}--> Under developpment${NC}"
				fi
			fi
		;;
		esac
	echo ""
}
