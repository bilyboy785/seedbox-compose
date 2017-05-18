#!/bin/bash
function under_developpment() {
	clear
	echo ""
	echo -e "${RED}####################################"
	echo -e "###       UNDERDEVELOPPEMENT     ###"
	echo -e "####################################${NC}"
	echo ""
}

function check_dir() {
	if [[ $1 != $BASEDIR ]]; then
		cd $BASEDIR
	fi
}

function script_option() {
	if [[ -d "$CONFDIR" ]]; then
		ACTION=$(whiptail --title "Seedbox-Compose" --menu "Welcome to Seedbox-Compose Script. Please choose an action below :" 18 80 10 \
			"1" "Seedbox-Compose already installed !" \
			"2" "Manage Users" \
			"3" "Manage Apps" \
			"4" "Manage Backups" \
			"5" "Manage Docker" \
			"6" "Install FTP Server" \
			"7" "Manage SSL Certificates" \
			"8" "Disable htaccess protection" \
			"9" "Uninstall Seedbox-Compose"  3>&1 1>&2 2>&3)
		echo ""
		case $ACTION in
		"1")
		  clear
		  echo ""
		  echo -e "${YELLOW}### Seedbox-Compose already installed !###${NC}"
		  if (whiptail --title "Seedbox already installed" --yesno "You're in trouble with Seedbox-compose ? Uninstall and try again ?" 7 90) then
				uninstall_seedbox
			else
				script_option
			fi
		  ;;
		"2")
			SCRIPT="MANAGEUSERS"
			;;
		"3")
			SCRIPT="MANAGEAPPS"
			;;
		"4")
			ACTIONBACKUP=$(whiptail --title "Manage Backup" --menu "Choose an action for backups !" 10 75 2 \
				"1" "Create a backup now of my Home !" \
				"2" "Schedule a backup for my data !" 3>&1 1>&2 2>&3)
			echo ""
			case $ACTIONBACKUP in
			"1")
			  backup_docker_conf
			  ;;
			"2")
			  schedule_backup_seedbox
			  ;;
			 esac
			;;
		"5")
			# manage_docker
			under_developpment
			;;
		"6")
			SCRIPT="INSTALLFTPSERVER"
			;;
		"7")
			ACTIONSSL=$(whiptail --title "Manage SSL" --menu "Choose an action for SSL Certificates" 10 75 2 \
				"1" "Generate Let's Encrypt Certificates" \
				"2" "Renew Let's Encrypt Certificates" 3>&1 1>&2 2>&3)
			echo ""
			case $ACTIONSSL in
			"1")
				under_developpment
				#generate_ssl_cert
				;;
			"2")
				under_developpment
				#renew_ssl_cert
				;;
			 esac
			;;
		"8")
			SCRIPT="DELETEHTACCESS"
			;;
		"9")
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
	if [[ ! -d "$CONFDIR" ]]; then
		mkdir $CONFDIR > /dev/null 2>&1
	fi
}

function install_base_packages() {
	echo ""
	echo -e "${BLUE}### INSTALL BASE PACKAGES ###${NC}"
	sed -ri 's/deb\ cdrom/#deb\ cdrom/g' /etc/apt/sources.list
	whiptail --title "Base Package" --msgbox "Seedbox-Compose installer will now install base packages and update system" 10 60
	echo -e " ${BWHITE}* Installing apache2-utils, unzip, git, curl ...${NC}"
	{
	NUMPACKAGES=$(cat $PACKAGESFILE | wc -l)
	for package in $(cat $PACKAGESFILE);
	do
		apt-get install -y $package
		echo $NUMPACKAGES
		NUMPACKAGES=$(($NUMPACKAGES+(100/$NUMPACKAGES)))
	done
	} | whiptail --gauge "Please wait during packages installation !" 6 70 0
	checking_errors $?
	echo ""
}

function delete_htaccess() {
	SITEENABLEDFOLDER="/etc/nginx/conf.d/"
	sed -ri 's///g' /etc/
}

function checking_system() {
	echo -e "${BLUE}### CHECKING SYSTEM ###${NC}"
	echo -e " ${BWHITE}* Checking system OS${NC}"
	TMPSOURCESDIR="/opt/seedbox-compose/includes/sources.list"
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
		echo -e " ${YELLOW}* Nginx is already installed !${NC}"
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
		echo -e " ${YELLOW}* ZSH is already installed !${NC}"
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
		echo -e " ${YELLOW}* Docker is already installed !${NC}"
		echo ""
	fi
}

function install_letsencrypt() {
	echo -e "${BLUE}### LETS ENCRYPT ###${NC}"
	LEDIR="/opt/letsencrypt"
	if [[ ! -d "$LEDIR" ]]; then
		echo " * Installing Lets'Encrypt"
		git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt > /dev/null 2>&1
		checking_errors $?
		echo ""
		cd /opt/letsencrypt && ./letsencrypt-auto --help > /dev/null 2>&1
		cd $BASEDIR
	else
		echo -e " ${YELLOW}* Let's Encrypt is already installed !${NC}"
		echo ""
	fi
}

function define_parameters() {
	echo -e "${BLUE}### USER INFORMATIONS ###${NC}"
	USEDOMAIN="y"
	CURRTIMEZONE=$(cat /etc/timezone)
	create_user
	CONTACTEMAIL=$(whiptail --title "Email address" --inputbox \
	"Please enter your email address :" 7 50 3>&1 1>&2 2>&3)
	TIMEZONEDEF=$(whiptail --title "Timezone" --inputbox \
	"Please enter your timezone" 7 66 "$CURRTIMEZONE" \
	3>&1 1>&2 2>&3)
	if [[ $TIMEZONEDEF == "" ]]; then
		TIMEZONE=$CURRTIMEZONE
	else
		TIMEZONE=$TIMEZONEDEF
	fi
	if (whiptail --title "Use domain name" --yesno "Do you want to use a domain to join your apps ?" 7 50) then
		DOMAIN=$(whiptail --title "Your domain name" --inputbox \
		"Please enter your domain :" 7 50 \
		3>&1 1>&2 2>&3)
	else
		DOMAIN="localhost"
	fi
	echo ""
}

function create_user() {
	echo -e " ${BWHITE}* Checking group for Seedbox${NC}"
	if [[ ! -f "$GROUPFILE" ]]; then
		touch $GROUPFILE
		SEEDGROUP=$(whiptail --title "Group" --inputbox \
        	"Create a group for your Seedbox" 7 50 3>&1 1>&2 2>&3)	
		echo "$SEEDGROUP" > "$GROUPFILE"
	else
		TMPGROUP=$(cat $GROUPFILE)
		if [[ "$TMPGROUP" == "" ]]; then
			SEEDGROUP=$(whiptail --title "Group" --inputbox \
        		"Create a group for your Seedbox" 7 50 3>&1 1>&2 2>&3)
        fi
	fi
    egrep "^$SEEDGROUP" /etc/group >/dev/null
	if [[ "$?" != "0" ]]; then
		echo -e " ${BWHITE}* Creating group $SEEDGROUP"
	    groupadd $SEEDGROUP
	    checking_errors $?
	else
		SEEDGROUP=$TMPGROUP
	    echo -e " ${YELLOW}* No need to create group $SEEDGROUP, already exist.${NC}"
	fi
	echo -e " ${BWHITE}* Checking user for Seedbox${NC}"
	if [[ ! -f "$USERSFILE" ]]; then
		touch $USERSFILE
	fi
	SEEDUSER=$(whiptail --title "Username" --inputbox \
		"Please enter a username :" 7 50 3>&1 1>&2 2>&3)
	PASSWORD=$(whiptail --title "Password" --passwordbox \
		"Please enter a password :" 7 50 3>&1 1>&2 2>&3)
	egrep "^$SEEDUSER" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo -e " ${YELLOW}* User already exist !${NC}"
		USERID=$(id -u $SEEDUSER)
		GRPID=$(id -g $SEEDUSER)
		echo -e " ${BWHITE}* Adding $SEEDUSER in $SEEDGROUP"
		usermod -a -G $SEEDGROUP $SEEDUSER
		checking_errors $?
	else
		PASS=$(perl -e 'print crypt($ARGV[0], "password")' $PASSWORD)
		echo -e " ${BWHITE}* Adding $SEEDUSER to the system"
		useradd -m -G $SEEDGROUP -p $PASS $SEEDUSER > /dev/null 2>&1
		checking_errors $?
		USERID=$(id -u $SEEDUSER)
		GRPID=$(id -g $SEEDUSER)
	fi
	add_user_htpasswd $SEEDUSER $PASSWORD
	echo $SEEDUSER >> $USERSFILE
}

function choose_services() {
	echo -e "${BLUE}### SERVICES ###${NC}"
	echo -e " ${BWHITE}--> Services will be installed : ${NC}"
	for app in $(cat $SERVICESAVAILABLE);
	do
		service=$(echo $app | cut -d\- -f1)
		desc=$(echo $app | cut -d\- -f2)
		echo "$service $desc off" >> /tmp/menuservices.txt
	done
	SERVICESTOINSTALL=$(whiptail --title "Services manager" --checklist \
	"Please select services you want to add for $SEEDUSER (Use space to select)" 28 60 17 \
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
	touch $INSTALLEDFILE > /dev/null 2>&1
	if [[ -f "$FILEPORTPATH" ]]; then
		declare -i PORT=$(cat $FILEPORTPATH | tail -1)
	else
		declare -i PORT=$FIRSTPORT
	fi
	if [[ "$DOMAIN" != "localhost" ]]; then
		if (whiptail --title "Use SSL" --yesno "Do you want to use SSL with Let's Encrypt support ?" 10 60) then
			LESSL="y"
		else
			LESSL="n"
		fi
	fi
	DOCKERCOMPOSEFILE="/home/$SEEDUSER/docker-compose.yml"
	touch $DOCKERCOMPOSEFILE
	for line in $(cat $SERVICESPERUSER);
	do
		cat "/opt/seedbox-compose/includes/dockerapps/$line.yml" >> $DOCKERCOMPOSEFILE
		sed -i "s|%TIMEZONE%|$TIMEZONE|g" $DOCKERCOMPOSEFILE
		sed -i "s|%UID%|$USERID|g" $DOCKERCOMPOSEFILE
		sed -i "s|%GID%|$GRPID|g" $DOCKERCOMPOSEFILE
		sed -i "s|%PORT%|$PORT|g" $DOCKERCOMPOSEFILE
		sed -i "s|%USER%|$SEEDUSER|g" $DOCKERCOMPOSEFILE
		sed -i "s|%EMAIL%|$CONTACTEMAIL|g" $DOCKERCOMPOSEFILE
		sed -i "s|%IPADDRESS%|$IPADDRESS|g" $DOCKERCOMPOSEFILE
		SUBURI=$(whiptail --title "Access Type" --menu \
	            "Please choose how do you want access your Apps :" 10 45 2 \
	            "1" "Subdomains" \
	            "2" "URI" 3>&1 1>&2 2>&3)
	    case $SUBURI in
	        "1" )
				PROXYACCESS="SUBDOMAIN"
				FQDNTMP="$line.$DOMAIN"
				FQDN=$(whiptail --title "SSL Subdomain" --inputbox \
				"Do you want to use a different subdomain for $line ? default :" 7 75 "$FQDNTMP" 3>&1 1>&2 2>&3)
				ACCESSURL=$FQDN
				URI="/"
				NGINXSITE="/etc/nginx/conf.d/$FQDN.conf"
	        	;;
	        "2" )
				PROXYACCESS="URI"
				FQDN=$DOMAIN
				FQDNTMP="/$line"
				ACCESSURL=$(whiptail --title "SSL Subdomain" --inputbox \
				"Do you want to use a different URI for $line ? default :" 7 75 "$FQDNTMP" 3>&1 1>&2 2>&3)
				URI=$ACCESSURL
	        	NGINXSITE="/etc/nginx/conf.d/$line.$DOMAIN.conf"
				;;
	    esac
		if [[ "$DOMAIN" != "localhost" ]]; then
	        if [[ "$LESSL" == "y" ]]; then
				NGINXPROXYFILE="/opt/seedbox-compose/includes/nginxproxyssl/$line.conf"
			else
				NGINXPROXYFILE="/opt/seedbox-compose/includes/nginxproxy/$line.conf"
			fi
			touch $NGINXSITE
			cat $NGINXPROXYFILE >> $NGINXSITE
			echo "$line-$PORT-$FQDN" >> $INSTALLEDFILE
			sed -i "s|%DOMAIN%|$FQDN|g" $NGINXSITE
			sed -i "s|%PORT%|$PORT|g" $NGINXSITE
			sed -i "s|%USER%|$SEEDUSER|g" $NGINXSITE
			sed -i "s|%URI%|$URI|g" $NGINXSITE
			sed -i "s|%URIS%|$URI\/|g" $NGINXSITE
		elif [[ "$DOMAIN" == "localhost" ]]; then
			NGINXPROXYFILE="/opt/seedbox-compose/includes/nginxproxy/$line.conf"
			touch $NGINXSITE
			cat $NGINXPROXYFILE >> $NGINXSITE
			sed -i "s|%DOMAIN%|localhost|g" $NGINXSITE
			sed -i "s|%PORT%|$PORT|g" $NGINXSITE
			sed -i "s|%USER%|$SEEDUSER|g" $NGINXSITE
			sed -i "s|%URI%|$URI|g" $NGINXSITE
			sed -i "s|%URIS%|$URI/|g" $NGINXSITE
			echo "$line-$PORT-$SEEDUSER" >> $INSTALLEDFILE
		fi
		PORT=$PORT+1
		FQDN=""
		FQDNTMP=""
	done
	if (whiptail --title "Docker Watcher" --yesno "Do you want to install a Watcher to auto-update your Apps ?" 7 75) then
		cat "/opt/seedbox-compose/includes/dockerapps/watchtower.yml" >> $DOCKERCOMPOSEFILE
		sed -i "s|%USER%|$SEEDUSER|g" $DOCKERCOMPOSEFILE
	fi
	echo $PORT >> $FILEPORTPATH
	echo ""
}

function docker_compose() {
	echo -e "${BLUE}### DOCKERCOMPOSE ###${NC}"
	ACTDIR="$PWD"
	cd /home/$SEEDUSER/
	echo -e " ${BWHITE}* Starting docker...${NC}"
	service docker restart
	checking_errors $?
	echo -e " ${BWHITE}* Docker-composing, it may takes a long...${NC}"
	docker-compose up -d > /dev/null 2>&1
	checking_errors $?
	echo ""
	cd $ACTDIR
}

function valid_htpasswd() {
	if [[ -d "/etc/nginx/" ]]; then
		HTFOLDER="/etc/nginx/passwd/"
		mkdir -p $HTFOLDER
		HTTEMPFOLDER="/tmp/"
		HTFILE=".htpasswd-$SEEDUSER"
		cat "$HTTEMPFOLDER$HTFILE" >> "$HTFOLDER$HTFILE"
		rm "$HTTEMPFOLDER$HTFILE"
	fi
}

function create_reverse() {
	if [[ "$DOMAIN" != "localhost" ]]; then
		echo -e "${BLUE}### REVERSE PROXY ###${NC}"
		SITEFOLDER="/etc/nginx/conf.d/"
		echo -e " ${BWHITE}* Stopping nginx${NC}"
		service nginx stop > /dev/null 2>&1
		checking_errors $?
		if [[ "$PROXYACCESS" == "URI" ]]; then
			echo -e " ${BWHITE}--> [$DOMAIN] - Creating reverse${NC}"
			generate_ssl_cert $CONTACTEMAIL $DOMAIN
		else	
			for line in $(cat $INSTALLEDFILE);
			do
				SERVICE=$(echo $line | cut -d\- -f1)
				PORT=$(echo $line | cut -d\- -f2)
				FQDN=$(echo $line | cut -d\- -f3)
				echo -e " ${BWHITE}--> [$SERVICE] - Creating reverse${NC}"
				if [[ "$DOMAIN" != "localhost" ]] && [[ "$line" != "teamspeak" ]] && [[ "$LESSL" == "y" ]]; then
					generate_ssl_cert $CONTACTEMAIL $FQDN
					checking_errors $?
				fi
			done
		fi
		echo ""
		echo -e " --> ${BWHITE}Restarting Nginx...${NC}"
		service nginx restart > /dev/null 2>&1
		if [[ "$?" == "0" ]]; then
			echo -e "	${GREEN}* Service nginx restarted !${NC}"
		else
			echo -e "	${RED}* Failed to restart Nginx !${NC}"
		fi
		valid_htpasswd
	fi
	USERDIR="/home/$SEEDUSER/downloads/{medias,movies,tv}"
	if [[ -d "$USERDIR" ]]; then
		chown $SEEDUSER: $USERDIR -R > /dev/null 2>&1
		chmod 777 $USERDIR -R > /dev/null 2>&1
	fi
	echo ""
}

function generate_ssl_cert() {
	EMAILADDRESS=$1
	DOMAINSSL=$2
	echo -e "	${BWHITE}--> Generating LE certificate for $DOMAINSSL, please wait...${NC}"
	bash /opt/letsencrypt/letsencrypt-auto certonly --standalone --preferred-challenges http-01 --agree-tos --rsa-key-size 4096 --non-interactive --quiet --email $EMAILADDRESS -d $DOMAINSSL
}

function manage_users() {
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###             MANAGE USERS           ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	MANAGEUSER=$(whiptail --title "Management" --menu \
	                "Choose an action to manage users" 10 45 2 \
	                "1" "New Seedbox User" \
	                "2" "Delete Seedbox User" 3>&1 1>&2 2>&3)
	case $MANAGEUSER in
		"1" )
			echo -e "${BLUE}#### NEW SEEDBOX USER ####${NC}"
			echo -e "${BLUE}--------------------------${NC}"
			define_parameters
			choose_services
			install_services
			docker_compose
			create_reverse
			resume_seedbox
			backup_docker_conf
			schedule_backup_seedbox
			;;
		"2" )
			echo -e "${BLUE}### DELETE SEEDBOX USER ###${NC}"
			echo -e "${BLUE}---------------------------${NC}"
			echo -e "${RED}--> UNDER DEVELOPPMENT ! ${NC}"
			;;
	esac
}

function manage_apps() {
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###             APP MANAGER            ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	TMPGROUP=$(cat $GROUPFILE)
	TABUSERS=()
	for USERSEED in $(members $TMPGROUP)
	do
	        IDSEEDUSER=$(id -u $USERSEED)
	        TABUSERS+=( ${USERSEED//\"} ${IDSEEDUSER//\"} )
	done
	## CHOOSE USER
	SEEDUSER=$(whiptail --title "App Manager" --menu \
	                "Please select user to manage Apps" 12 45 8 \
	                "${TABUSERS[@]}"  3>&1 1>&2 2>&3)
	[[ "$?" = 1 ]] && break;
	## RESUME USER INFORMATIONS
	USERDOCKERCOMPOSEFILE="/home/$SEEDUSER/docker-compose.yml"
	USERRESUMEFILE="/home/$SEEDUSER/resume"
	echo -e "${BLUE}### Application manager for $SEEDUSER ###${NC}"
	echo -e " ${BWHITE}* Docker-Compose file : $USERDOCKERCOMPOSEFILE${NC}"
	echo -e " ${BWHITE}* Resume file : $USERRESUMEFILE${NC}"
	## CHOOSE AN ACTION FOR APPS
	ACTIONONAPP=$(whiptail --title "App Manager" --menu \
	                "Select an action :" 12 45 6 \
	                "1" "Add Docker App"  \
	                "2" "Delete an App" 3>&1 1>&2 2>&3)        
	[[ "$?" = 1 ]] && break;
	case $ACTIONONAPP in
		"1" ) ## ADDING APP
			echo -e " ${BWHITE}* Add new apps${NC}"
				choose_services
				install_services
				docker_compose
				create_reverse
				valid_htpasswd
				resume_seedbox
				backup_docker_conf
			;;
		"2" ) ## DELETING APP
			echo -e " ${BWHITE}* Edit my app${NC}"
			TABSERVICES=()
			for SERVICEACTIVATED in $(cat $USERRESUMEFILE)
			do
			        SERVICE=$(echo $SERVICEACTIVATED | cut -d\- -f1)
			        PORT=$(echo $SERVICEACTIVATED | cut -d\- -f2)
			        TABSERVICES+=( ${SERVICE//\"} ${PORT//\"} )
			done
			APPSELECTED=$(whiptail --title "App Manager" --menu \
			              "Choose an App to make an action" 19 45 11 \
			              "${TABSERVICES[@]}"  3>&1 1>&2 2>&3)
			[[ "$?" = 1 ]] && break;
	esac
}

function install_ftp_server() {
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###          INSTALL FTP SERVER        ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	PROFTPDFOLDER="/etc/proftpd/"
	PROFTPDCONFFILE="proftpd.conf"
	PROFTPDTLSCONFFILE="tls.conf"
	BASEPROFTPDFILE="/opt/seedbox-compose/includes/config/proftpd.conf"
	BASEPROFTPDTLSFILELETSENCRYPT="/opt/seedbox-compose/includes/config/proftpd.tls.letsencrypt.conf"
	BASEPROFTPDTLSFILEOPENSSL="/opt/seedbox-compose/includes/config/proftpd.tls.openssl.conf"
	PROFTPDBAKCONF="/etc/proftpd/proftpd.conf.bak"
	PROFTPDTLSBAKCONF="/etc/proftpd/tls.conf.bak"
	if [[ ! -d "$PROFTPDFOLDER" ]]; then
		if (whiptail --title "Use FTP Server" --yesno "Do you want to install FTP server ?" 7 50) then
			FTPSERVERNAME=$(whiptail --title "FTPServer Name" --inputbox \
			"Please enter a name for your FTP Server :" 7 50 "SeedBox" 3>&1 1>&2 2>&3)
			echo -e " ${BWHITE}* Installing proftpd...${NC}"
			apt-get -qq install proftpd -y
			checking_errors $?
			if (whiptail --title "FTP Over SSL" --yesno "Do you want to use FTP with SSL ? (FTPs)" 7 60) then
				if (whiptail --title "FTPs Let's Encrypt" --yesno "Do you want to generate a Let's Encrypt certificate for FTPs ?" 7 70) then
					LEEMAIL=$(whiptail --title "Email address" --inputbox \
					"Please enter your email address :" 7 50 "$CONTACTEMAIL" 3>&1 1>&2 2>&3)
					LEDOMAIN=$(whiptail --title "LE Domain" --inputbox \
					"Please enter your domain for FTP access :" 7 50 "ftp.$DOMAIN" 3>&1 1>&2 2>&3)
					echo -e " ${BWHITE}* Stoping nginx...${NC}"
					service nginx stop
					checking_errors $?
					echo -e " ${BWHITE}* Generating certificate...${NC}"
					generate_ssl_cert $LEEMAIL $LEDOMAIN
					checking_errors $?
					USEFTPSLE="yes"
				else
					FTPSEMAIL=$(whiptail --title "OpenSSL Generation" --inputbox \
					"Email address" 7 50 "$CONTACTEMAIL" 3>&1 1>&2 2>&3)
					FTPSDOMAIN=$(whiptail --title "OpenSSL Generation" --inputbox \
					"Domain or FQDN" 7 50 "ftp.$DOMAIN" 3>&1 1>&2 2>&3)
					FTPSCC=$(whiptail --title "OpenSSL Generation" --inputbox \
					"Coutry code (FR, GB ...)" 7 50 "FR" 3>&1 1>&2 2>&3)
					FTPSSTATE=$(whiptail --title "OpenSSL Generation" --inputbox \
					"State (Ile de France, Bretagne ...)" 7 50 "Nottingham" 3>&1 1>&2 2>&3)
					FTPSLOCALITY=$(whiptail --title "OpenSSL Generation" --inputbox \
					"Locality (Paris, London ...)" 7 50 "Marseille" 3>&1 1>&2 2>&3)
					FTPSORGANIZATION=$(whiptail --title "OpenSSL Generation" --inputbox \
					"Organization (Apple Inc. ...)" 7 50 "Linux" 3>&1 1>&2 2>&3)
					FTPSORGANIZATIONALUNIT=$(whiptail --title "OpenSSL Generation" --inputbox \
					"Organizationnal Unit (Export, Production ...)" 7 50 "Tech" 3>&1 1>&2 2>&3)
					FTPSPASSWORD=$(whiptail --title "OpenSSL Generation" --passwordbox "Password" 7 50 3>&1 1>&2 2>&3)
					echo -e " ${BWHITE}* Generating key request...${NC}"
					openssl genrsa -des3 -passout pass:$FTPSPASSWORD -out /etc/ssl/private/$FTPSDOMAIN.key 2048 -noout > /dev/null 2>&1
					checking_errors $?
					echo -e " ${BWHITE}* Removing passphrase from key...${NC}"
					openssl rsa -in /etc/ssl/private/$FTPSDOMAIN.key -passin pass:$FTPSPASSWORD -out /etc/ssl/private/$FTPSDOMAIN.key > /dev/null 2>&1
					checking_errors $?
					echo -e " ${BWHITE}* Generating Certificate file...${NC}"
					openssl req -new -x509 -key /etc/ssl/private/$FTPSDOMAIN.key -out /etc/ssl/certs/$FTPSDOMAIN.crt -passin pass:$FTPSPASSWORD \
    					-subj "/C=$FTPSCC/ST=$FTPSSTATE/L=$FTPSLOCALITY/O=$FTPSORGANIZATION/OU=$FTPSORGANIZATIONALUNIT/CN=$FTPSDOMAIN/emailAddress=$FTPSEMAIL" > /dev/null 2>&1
    				checking_errors $?
					USEFTPSOPENSSL="yes"
				fi
		 		if (whiptail --title "Force FTPs" --yesno "Do you want to force FTPs ?" 7 60) then
		 			TLSREQUIRED="on"
		 		else
		 			TLSREQUIRED="off"
		 		fi
			fi
			echo -e " ${BWHITE}* Creating base configuration file...${NC}"
			mv "$PROFTPDFOLDER$PROFTPDCONFFILE" "$PROFTPDBAKCONF"
	 	 	cat "$BASEPROFTPDFILE" >> "$PROFTPDFOLDER$PROFTPDCONFFILE"
	 	 	sed -i -e "s/ServerName\ \"Debian\"/ServerName\ \"$FTPSERVERNAME\"/g" "$PROFTPDFOLDER$PROFTPDCONFFILE"
	 		checking_errors $?
	 		if [[ "$USEFTPSLE" == "yes" ]]; then
		 		echo -e " ${BWHITE}* Creating SSL configuration file...${NC}"
		 		sed -i -e "s/#Include\ \/etc\/\proftpd\/tls.conf/Include\ \/etc\/\proftpd\/tls.conf/g" "$PROFTPDFOLDER$PROFTPDCONFFILE"
		 		mv "$PROFTPDFOLDER$PROFTPDTLSCONFFILE" "$PROFTPDTLSBAKCONF"
		 	 	cat "$BASEPROFTPDTLSFILELETSENCRYPT" >> "$PROFTPDFOLDER$PROFTPDTLSCONFFILE"
	 			sed -i "s|%TLSREQUIRED%|$TLSREQUIRED|g" "$PROFTPDFOLDER$PROFTPDTLSCONFFILE"
		 	 	sed -i "s|%DOMAIN%|$LEDOMAIN|g" "$PROFTPDFOLDER$PROFTPDTLSCONFFILE"
		 	 	checking_errors $?
	 		fi
	 		if [[ "$USEFTPSOPENSSL" == "yes" ]]; then
		 		echo -e " ${BWHITE}* Creating SSL configuration file...${NC}"
		 		sed -i -e "s/#Include\ \/etc\/\proftpd\/tls.conf/Include\ \/etc\/\proftpd\/tls.conf/g" "$PROFTPDFOLDER$PROFTPDCONFFILE"
		 		mv "$PROFTPDFOLDER$PROFTPDTLSCONFFILE" "$PROFTPDTLSBAKCONF"
		 	 	cat "$BASEPROFTPDTLSFILEOPENSSL" >> "$PROFTPDFOLDER$PROFTPDTLSCONFFILE"
	 			sed -i "s|%TLSREQUIRED%|$TLSREQUIRED|g" "$PROFTPDFOLDER$PROFTPDTLSCONFFILE"
		 	 	sed -i "s|%DOMAIN%|$FTPSDOMAIN|g" "$PROFTPDFOLDER$PROFTPDTLSCONFFILE"
		 	 	checking_errors $?
	 		fi
	 		echo -e " ${BWHITE}* Restarting service...${NC}"
	 		service proftpd restart
	 		checking_errors $?
	 	else
	 		echo -e " ${BWHITE}* Fine, nothing will be installed !${NC}"
		fi
	else
		echo -e " ${YELLOW}* FTP Server already installed !${NC}"
		echo -e "	${RED}--> Please check manually Proftpd configuration${NC}"
		if (whiptail --title "FTP Server" --yesno "FTP Server already exist ! Do you want to reconfigure service ?" 7 75) then
			FTPSERVERNAME=$(whiptail --title "FTPServer Name" --inputbox \
			"Please enter a name for your FTP Server :" 7 50 "SeedBox" 3>&1 1>&2 2>&3)
			echo -e " ${BWHITE}* Reconfigure... ${NC}"
			echo -e " ${BWHITE}* Cleaning files... ${NC}"
			if [[ -f "$PROFTPDBAKCONF" ]]; then
				rm $PROFTPDBAKCONF -R
				checking_errors $?
			fi
			echo -e " ${BWHITE}* Creating configuration file...${NC}"
			mv "$PROFTPDFOLDER$PROFTPDCONFFILE" "$PROFTPDFOLDER$PROFTPDCONFFILE.bak"
	 	 	cat "$BASEPROFTPDFILE" >> "$PROFTPDFOLDER$PROFTPDCONFFILE"
	 	 	sed -i -e "s/ServerName\ \"Debian\"/ServerName\ \"$FTPSERVERNAME\"/g" "$PROFTPDFOLDER$PROFTPDCONFFILE"
	 	 	checking_errors $?
	 	 	echo -e " ${BWHITE}* Restarting proftpd...${NC}"
	 	 	service proftpd restart
	 		checking_errors $?
	 		echo -e " ${BWHITE}* Restarting nginx...${NC}"
	 	 	service nginx restart
	 		checking_errors $?
	 	fi
	fi
	echo ""
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
		for line in $(cat $INSTALLEDFILE);
		do
			ACCESSDOMAIN=$(echo $line | cut -d\- -f3)
			DOCKERAPP=$(echo $line | cut -d\- -f1)
			echo -e "	--> ${BWHITE}$line${NC} from ${YELLOW}$ACCESSDOMAIN${NC}"
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
	if [[ -d "$PROFTPDFOLDER" ]]; then
		echo ""
		echo -e " ${BWHITE}* Access FTP with your IDs from :${NC}"
		echo -e "	--> IP Address : ${YELLOW}$IPADDRESS${NC}"
		if [[ "$DOMAIN" != "localhost" ]]; then
			echo -e "	--> Domain : ${YELLOW}$FTPSDOMAIN${NC}"
		fi
	fi
	echo ""
	echo -e " ${BWHITE}* Here is your IDs :${NC}"
	echo -e "	--> Username : ${YELLOW}$HTUSER${NC}"
	echo -e "	--> Password : ${YELLOW}$HTPASSWORD${NC}"
	echo ""
	rm -Rf $SERVICESPERUSER > /dev/null 2>&1
	# if [[ -f "/home/$SEEDUSER/downloads/medias/supervisord.log" ]]; then
	# 	mv /home/$SEEDUSER/downloads/medias/supervisord.log /home/$SEEDUSER/downloads/medias/.supervisord.log > /dev/null 2>&1
	# 	mv /home/$SEEDUSER/downloads/medias/supervisord.pid /home/$SEEDUSER/downloads/medias/.supervisord.pid > /dev/null 2>&1
	# fi
	# chown $SEEDUSER: -R /home/$SEEDUSER/downloads/{tv;movies;medias}
	# chmod 775: -R /home/$SEEDUSER/downloads/{tv;movies;medias}
}

function backup_docker_conf() {
	BACKUPDIR="/var/backups/"
	BACKUPNAME="backup-sc-$SEEDUSER-"
	echo ""
	BACKUP="$BACKUPDIR$BACKUPNAME$BACKUPDATE.tar.gz"
	if [[ "$SEEDUSER" != "" ]]; then
		if (whiptail --title "Backup Dockers conf" --yesno "Do you want backup configuration for $SEEDUSER ?" 10 60) then
			echo -e "${BLUE}##########################################${NC}"
			echo -e "${BLUE}###         BACKUP DOCKER CONF         ###${NC}"
			echo -e "${BLUE}##########################################${NC}"
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
		echo -e " ${BWHITE}* Backing up Dockers conf..."
		tar cvpzf $BACKUP $DOCKERCONFDIR > /dev/null 2>&1
		echo -e "	${GREEN}--> Backup successfully created in $BACKUP${NC}"
	else
		echo -e "	${YELLOW}--> Please launch the script to install Seedbox before make a Backup !${NC}"
	fi
}

function schedule_backup_seedbox() {
	CRONTABFILE="/etc/crontab"
	if (whiptail --title "Schedule Backup" --yesno "Do you want to schedule a configuration backup ?" 10 60) then
		if [[ "$SEEDUSER" == "" ]]; then
			SEEDUSER=$(whiptail --title "Username" --inputbox \
			"Please enter your username :" 7 50 \
			3>&1 1>&2 2>&3)
		fi
		MODELSCRIPT="/opt/seedbox-compose/includes/config/model-backup.sh"
		BACKUPSCRIPT="/home/$SEEDUSER/backup-dockers.sh"
		TMPCRONFILE="/tmp/crontab"
		if [[ -d "/home/$SEEDUSER" ]]; then
			grep -R "$SEEDUSER" "$CRONTABFILE" > /dev/null 2>&1
			if [[ "$?" != "0" ]]; then
				BACKUPDIR=$(whiptail --title "Schedule Backup" --inputbox \
					"Please choose backup destination" 7 65 "/var/backups/" \
					3>&1 1>&2 2>&3)
				DAILYRET=$(whiptail --title "Schedule Backup" --inputbox \
					"How many days you want to keep your daily backups ? (Default : 14 backups)" 7 65 "14" \
					3>&1 1>&2 2>&3)
				WEEKLYRET=$(whiptail --title "Schedule Backup" --inputbox \
					"How many days you want to keep your weekly backups ? (Default : 8 backups)" 7 65 "60" \
					3>&1 1>&2 2>&3)
				MONTHLYRET=$(whiptail --title "Schedule Backup" --inputbox \
					"How many days you want to keep your monthly backups ? (Default : 10 backups)" 7 65 "300" \
					3>&1 1>&2 2>&3)
				touch $BACKUPSCRIPT
				cat $MODELSCRIPT >> $BACKUPSCRIPT
				sed -i "s|%USER%|$SEEDUSER|g" "$BACKUPSCRIPT"
				sed -i "s|%BACKUPDIR%|$BACKUPDIR|g" "$BACKUPSCRIPT"
				sed -i "s|%DAILYRET%|$DAILYRET|g" "$BACKUPSCRIPT"
				sed -i "s|%WEEKLYRET%|$WEEKLYRET|g" "$BACKUPSCRIPT"
				sed -i "s|%MONTHLYRET%|$MONTHLYRET|g" "$BACKUPSCRIPT"
				SCHEDULEBACKUP="@daily bash $BACKUPSCRIPT >/dev/null 2>&1"
				echo $SCHEDULEBACKUP >> $TMPCRONFILE
				cat "$TMPCRONFILE" >> "$CRONTABFILE"
				echo -e " ${BWHITE}* Backup successfully scheduled :${NC}"
				echo -e "	${BWHITE}-->${NC} In ${YELLOW}$BACKUPDIR ${NC}"
				echo -e "	${BWHITE}-->${NC} For ${YELLOW}$SEEDUSER ${NC}"
				echo -e "	${BWHITE}-->${NC} Keep ${YELLOW}$DAILYRET days daily backups ${NC}"
				echo -e "	${BWHITE}-->${NC} Keep ${YELLOW}$WEEKLYRET days weekly backups ${NC}"
				echo -e "	${BWHITE}-->${NC} Keep ${YELLOW}$MONTHLYRET days monthly backups ${NC}"
				echo ""
				rm $TMPCRONFILE
			else
				if (whiptail --title "Schedule Backup" --yesno "A cronjob is already configured for $SEEDUSER. Do you want to delete this job ?" 10 80) then
					USERLINE=$(grep -n "$SEEDUSER" $CRONTABFILE | cut -d: -f1)
					sed -i ''$USERLINE'd' $CRONTABFILE
					echo -e " ${BWHITE}* Cronjob for $SEEDUSER has been deleted !${NC}"
					rm -Rf $BACKUPSCRIPT
					schedule_backup_seedbox
				else
					break
				fi
			fi
		else
			echo -e " ${YELLOW}--> Please install Seedbox for $SEEDUSER before backup${NC}"
			echo ""
		fi
	fi
}

# function access_token_ts() {
# 	grep -R "teamspeak" "$SERVICESPERUSER" > /dev/null
# 	if [[ "$?" == "0" ]]; then
# 		read -p " * Do you want create a file with your Teamspeak password and Token ? (default no) [y/n] : " SHOWTSTOKEN
# 		if [[ "$SHOWTSTOKEN" == "y" ]]; then
# 			TSIDFILE="/home/$SEEDUSER/dockers/teamspeak/idteamspeak"
# 			touch $TSIDFILE
# 			SERVERADMINPASSWORD=$(docker logs teamspeak 2>&1 | grep password | cut -d\= -f 3 | tr --delete '"')
# 			TOKEN=$(docker logs teamspeak 2>&1 | grep token | cut -d\= -f2)
# 			echo "Admin Username : serveradmin" >> $TSIDFILE
# 			echo "Admin password : $SERVERADMINPASSWORD" >> $TSIDFILE
# 			echo "Token : $TOKEN" >> $TSIDFILE
# 			echo -e "	--> ${YELLOW}Admin username : serveradmin${NC}"
# 			echo -e "	--> ${YELLOW}Admin password : $SERVERADMINPASSWORD${NC}"
# 			echo -e "	--> ${YELLOW}Token : $TOKEN${NC}"
# 		else
# 			echo -e "	--> Check teamspeak's Logs with ${BWHITE}docker logs teamspeak${NC}"
# 		fi
# 	fi
# }

function uninstall_seedbox() {
	clear
	echo -e "${BLUE}##########################################${NC}"
	echo -e "${BLUE}###          UNINSTALL SEEDBOX         ###${NC}"
	echo -e "${BLUE}##########################################${NC}"
	BACKUPDIR="/var/backups"
	CRONTABFILE="/etc/crontab"
	SEEDGROUP=$(cat $GROUPFILE)
	UNINSTALL=$(whiptail --title "Seedbox-Compose" --menu "Choose what you want uninstall" 10 75 2 \
			"1" "Full uninstall (all files and dockers)" \
			"2" "User uninstall (delete a suer)" 3>&1 1>&2 2>&3)
		case $UNINSTALL in
		"1")
		  	if (whiptail --title "Uninstall Seedbox" --yesno "Do you really want to uninstall Seedbox ?" 7 75) then
		  		echo -e " ${BWHITE}* All files, dockers and configuration will be uninstall${NC}"
				if (whiptail --title "Dockers configuration" --yesno "Do you want to backup your Dockers configuration ?" 7 75) then
					DOBACKUP="yes"
				else
					for seeduser in $(cat $USERSFILE)
					do
						if [[ "$DOBACKUP" == "yes" ]]; then
							BACKUPNAME="$BACKUPDIR/backup-seedbox-$seeduser-$backupdate.tar.gz"
							DOCKERCONFDIR="/home/$seeduser/dockers/"
							echo -e " ${BWHITE}* Backing up dockers configuration for $seeduser...${NC}"
							tar cvpzf $BACKUPNAME $DOCKERCONFDIR > /dev/null 2>&1
							checking_errors $?
						fi
						USERHOMEDIR="/home/$seeduser"
						echo -e " ${BWHITE}* Deleting user...${NC}"
						userdel -r -f $seeduser
						checking_errors $?
						echo -e " ${BWHITE}* Deleting data in your Home directory...${NC}"
						rm -Rf $USERHOMEDIR
						checking_errors $?
						echo -e " ${BWHITE}* Deleting nginx configuration${NC}"
						service nginx stop > /dev/null 2>&1
						rm -Rf /etc/nginx/conf.d/*
						checking_errors $?
						echo -e " ${BWHITE}* Deleting group...${NC}"
						userdel $SEEDGROUP
						checking_errors $?
						echo -e " ${BWHITE}* Stopping Dockers...${NC}"
						docker stop $(docker ps) > /dev/null 2>&1
						checking_errors $?
						echo -e " ${BWHITE}* Removing Dockers...${NC}"
						docker rm $(docker ps -a) > /dev/null 2>&1
						checking_errors $?
						echo -e " ${BWHITE}* Removing Cronjob...${NC}"
						USERLINE=$(grep -n "$seeduser" $CRONTABFILE | cut -d: -f1)
						sed -i ''$USERLINE'd' $CRONTABFILE
						checking_errors $?
					done
					echo -e " ${BWHITE}* Removing Seedbox-compose directory...${NC}"
					rm -Rf /etc/seedboxcompose
					checking_errors $?
					cd /opt && rm -Rf seedbox-compose
					if (whiptail --title "Cloning repo" --yesno "Do you want to redownload Seedbox-compose ?" 7 75) then
						git clone https://github.com/bilyboy785/seedbox-compose.git > /dev/null 2>&1
					fi
					clear
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