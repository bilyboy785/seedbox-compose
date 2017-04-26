# Seedbox-Compose
A docker-compose file to deploy complete Seedbox based only Docker. Install a fresh Debian / Ubuntu Server, install git git-core and docker and use this **Docker-compose.yml** to deploy your Seedbox.

## Services availables in this docker-compose

Service | Port | Access | Link
---------------------- | ------------------ | ------------------------- | ------------- |
Nginx                  | 80, 443            | --                        | https://nginx.org
Fail2Ban               | --                 | --                        | https://www.fail2ban.org/
MariaDB                | 3306               | --                        | https://mariadb.org/
Nextcloud              | 8181               | /nextcloud                | https://nextcloud.com
Rtorrent/RuTorrent     | 8282, 49160, 49161 | ...                       | https://wiki.archlinux.org/index.php/RTorrent
Jackett                | 8383               | ...                       | https://github.com/Jackett/Jackett
Radarr                 | 8484               | ...                       | https://github.com/Radarr/Radarr
Sonarr                 | 8585               | ...                       | https://sonarr.tv/
UI for Docker          | 8686               | ...                       | https://github.com/kevana/ui-for-docker
PlexMediaServer        | 32400              | ...                       | https://www.plex.tv/fr/
PlexPy                 | 8787               | ...                       | https://github.com/JonnyWong16/plexpy
Zerobin                | 8888               | ...                       | https://github.com/sebsauvage/ZeroBin
Lufi                   | 8989               | ...                       | ...
Lutim                  | 9090               | ...                       | ...
