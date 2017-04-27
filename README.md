# Seedbox-Compose
A docker-compose file to deploy complete Seedbox based only Docker. Install a fresh Debian / Ubuntu Server, install git git-core and docker and use this **Docker-compose.yml** to deploy your Seedbox.

## Services availables in this docker-compose

Service                | Port               | Status      |   Access
---------------------- | ------------------ | ----------- | --------------
Nginx                  | 80, 443            | Installed   |  /                  
Fail2Ban               | --                 | Installed   |  ---                   
MariaDB                | 3306               | Installed   |  ---                   
Nextcloud              | 8181               | Installed   |  nextcloud.domain.tld          
Rtorrent/RuTorrent     | 8282, 49160, 49161 | Installed   |  rutorrent.domain.tld                  
Jackett                | 8383               | Installed   |  jackett.domain.tld                 
Radarr                 | 8484               | Installed   |  radarr.domain.tld                  
Sonarr                 | 8585               | Installed   |  sonarr.domain.tld                 
UI for Docker          | 8686               | Installed   |  docker.domain.tld                  
PlexMediaServer        | 32400              | Optional    |  plex.domain.tld                 
PlexPy                 | 8787               | Optional    |  plexpy.domain.tld                 
Zerobin                | 8888               | Optional    |  zerobin.domain.tld                 
Lufi                   | 8989               | Optional    |  lufi.domain.tld                 
Lutim                  | 9090               | Optional    |  lutim.domain.tld                 

## Installation
 * First, clone this repo to a fresh Debian/Ubuntu server :
```shell
git clone https://github.com/bilyboy785/seedbox-compose.git
chmod +x seedbox-compose/build.sh && chmod +x seedbox-compose/includes/functions.sh
```

## Sources
