# Seedbox-Compose [![Build Status](https://travis-ci.org/bilyboy785/seedbox-compose.svg?branch=master)](https://travis-ci.org/bilyboy785/seedbox-compose)
A docker-compose file to deploy complete Seedbox based only Docker. Install a fresh Debian / Ubuntu Server, install git git-core and docker and use this **Docker-compose.yml** to deploy your Seedbox.

### Tested on ###
 * [x] Debian 8.X
 * [x] Ubuntu 16.X
 * [ ] CentOS
 
## Services availables in this docker-compose
 * **Movies automation**
   * Couchpotato
   * Radarr

 * **TVShows automation**
   * Sickrage
   * Sonarr

 * **Music automation**
   * Headphones 

 * **Seedbox manager**
   * HTPCManager
   * **SOON** : Maximux

 * **Media Server**
   * Plex Media Server

 * **WebUID Manager**
   * Portainer - Manager for Dockers
   * PlexPy - Manager for Plex Media Server
   * H5ai - WebUI to access files

 * **Torrent Client**
   * Rtorrent/Rutorrent
   * Transmission
 
 * **Utilities**
   * Zerobin - Code paste
   * Jackett - Torrent Providers finder


## Installation & Configuration
For all instructions and configuration tips, follow the (Wiki)[https://github.com/bilyboy785/seedbox-compose/wiki]

## Sources
 * [portainer/portainer](https://hub.docker.com/r/portainer/portainer/)
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
 * [wonderfall/zerobin](https://hub.docker.com/r/Wonderfall/zerobin/)
 * [xataz/lutim](https://hub.docker.com/r/xataz/lutim/)
 * [xataz/lufi](https://hub.docker.com/r/xataz/lufi/)
 * [clue/h5ai](https://hub.docker.com/r/clue/h5ai/)
