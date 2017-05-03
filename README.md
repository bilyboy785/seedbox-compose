# Seedbox-Compose
A docker-compose file to deploy complete Seedbox based only Docker. Install a fresh Debian / Ubuntu Server, install git git-core and docker and use this **Docker-compose.yml** to deploy your Seedbox.

### Tested on ###
 * [x] Debian 8
 * [ ] Debian 7
 * [x] Ubuntu 16
 * [ ] Ubuntu 15
 * [ ] CentOS
 
## Services availables in this docker-compose

Service                | Status      |   Access
---------------------- | ----------- | ----------------------
Nginx                  | Installed   |  /                                              
Rtorrent/RuTorrent     | Installed   |  rtorrent.domain.tld                  
Jackett                | Installed   |  jackett.domain.tld                 
Radarr                 | Installed   |  radarr.domain.tld                  
Sonarr                 | Installed   |  sonarr.domain.tld                 
UI for Docker          | Installed   |  docker.domain.tld                  
PlexMediaServer        | Optional    |  plex.domain.tld                 
PlexPy                 | Optional    |  plexpy.domain.tld                 
Zerobin                | Optional    |  zerobin.domain.tld                 
Lufi                   | Optional    |  lufi.domain.tld                 
Lutim                  | Optional    |  lutim.domain.tld
MariaDB                | Optional    |  ---                 
Nextcloud              | Optional    |  cloud.domain.tld                   

## Installation
 * First, you need to create DNS entry type A for each service you want to install : **service.domain.tld** (look at the services table)
 * Second, clone this repo into a fresh Debian/Ubuntu server :
```shell
git clone https://github.com/bilyboy785/seedbox-compose.git /root/seedbox-compose
```
 * Launch the script :
```shell
cd /root/seedbox-compose
./build.sh
```

## Services configuration

## Sources
