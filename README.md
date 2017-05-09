# Seedbox-Compose [![Build Status](https://travis-ci.org/bilyboy785/seedbox-compose.svg?branch=master)](https://travis-ci.org/bilyboy785/seedbox-compose)
A docker-compose file to deploy complete Seedbox based only Docker. Install a fresh Debian / Ubuntu Server, install git git-core and docker and use this **Docker-compose.yml** to deploy your Seedbox.

### Tested on ###
 * [x] Debian 8.X
 * [x] Ubuntu 16.X
 * [ ] CentOS
 
## Services availables in this docker-compose

Service                | Status      |   Default subdomain
---------------------- | ----------- | ----------------------
Nginx                  | Installed   |  /                                              
Rtorrent/RuTorrent     | Installed   |  rtorrent.domain.tld                  
Jackett                | Installed   |  jackett.domain.tld                
UI for Docker          | Installed   |  docker.domain.tld                  
Radarr                 | Optional    |  radarr.domain.tld                  
Sonarr                 | Optional    |  sonarr.domain.tld    
Sickrage               | Optional    |  sickrage.domain.tld 
Couchpotato            | Optional    |  couchpotato.domain.tld               
PlexMediaServer        | Optional    |  plex.domain.tld
Headphones.            | Optional    |  headphones.domain.tld                  
PlexPy                 | Optional    |  plexpy.domain.tld                 
Zerobin                | Optional    |  zerobin.domain.tld                 
Teamspeak              | Optional    |  ---                                   

## Installation
 * First, you need to create DNS entry type A for each service you want to install : **service.domain.tld** (look at the services table)
 * Second, install git and clone this repo into a fresh Debian/Ubuntu server :
```shell
apt install git
git clone https://github.com/bilyboy785/seedbox-compose.git /root/seedbox-compose
```
 * Launch the script :
```shell
cd /root/seedbox-compose
./build.sh
```

## Services configuration
### Sonarr / Sickrage

### Radarr / Couchpotato

### Jackett

### Teamspeak
To access and configure Teamspeak, you need to have the Token Access and ServerAdmin password. There are stored in logs of TS docker. You can access it with :
```shell
docker logs teamspeak
```

During docker-compose action, i stored your IDs in your **/home/user/dockers/teamspeak/idteamspeak**. Check this file before launching Teamspeak.

## Sources
 * [uifd/ui-for-docker](https://hub.docker.com/r/uifd/ui-for-docker/)
 * [linuxserver/gsm-ts3](https://hub.docker.com/r/linuxserver/gsm-ts3/)
 * [Linuxserver/PlexRequests](https://hub.docker.com/r/linuxserver/plexrequests/)
 * [linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr/)
 * [linuxserver/plexrequests](https://hub.docker.com/r/linuxserver/plexrequests/)
 * [linuxserver/plexpy](https://hub.docker.com/r/linuxserver/plexpy/)
 * [linuxserver/plex](https://hub.docker.com/r/linuxserver/plex/)
 * [linuxserver/jackett](https://hub.docker.com/r/linuxserver/jackett/)
 * [linuxserver/htpcmanager](https://hub.docker.com/r/linuxserver/htpcmanager/)
 * [linuxserver/headphones](https://hub.docker.com/r/linuxserver/headphones/)
 * [linuxserver/nextcloud](https://hub.docker.com/r/linuxserver/nextcloud/)
 * [diameter/rtorrent-rutorrent](https://hub.docker.com/r/diameter/rtorrent-rutorrent/)
 * [hotio/radarr](https://hub.docker.com/r/hotio/radarr/)
 * [wonderfall/boring-nginx](https://hub.docker.com/r/wonderfall/boring-nginx/)
 * [xataz/lutim](https://hub.docker.com/r/xataz/lutim/)
 * [xataz/lufi](https://hub.docker.com/r/xataz/lufi/)
 * [clue/h5ai](https://hub.docker.com/r/clue/h5ai/)
 * [Wonderfall/zerobin](https://hub.docker.com/r/Wonderfall/zerobin/)
