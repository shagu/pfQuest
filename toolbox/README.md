# Fetch Databases

## Setup Dependencies

### Archlinux

    pacman -S lxc php php-gd lua lua-sql-mysql mariadb-clients libmariadbclient


### Ubuntu

    sudo apt-get install mariadb-client php php-gd php-mysqli lua5.2 lua-sql-mysql

## Setup Database LXC Container

    lxc-create -n pfQuest -t ubuntu
    lxc-start  -n pfQuest
    lxc-attach -n pfQuest

    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    apt-get update && apt-get upgrade
    apt-get install phpmyadmin mariadb-server wget p7zip
    exit

## Light's Hope / Elysium: Core entries + Translations

Grab the latest [Light's Hope](https://github.com/LightsHope/server/releases) or [Elysium](https://github.com/elysium-project/database) database

# Create Database Structure

    CREATE USER 'mangos'@'localhost' IDENTIFIED BY 'mangos';
    CREATE DATABASE `elysium` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    CREATE DATABASE `aowow` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `elysium`.* TO 'mangos'@'localhost';
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `aowow`.* TO 'mangos'@'localhost';

# Import Databases

    mysql -u mangos -p elysium -h 127.0.0.1 < elysiumdb/world_*.sql
    mysql -u mangos -p aowow -h 127.0.0.1 < aowow.sql

# Copy CSVs to DBC/

    $ ls -1 DBC/
    deDE  enUS  esES  frFR  koKR  ruRU  zhCN

    $ ls -1 DBC/deDE
    AreaTable.dbc.csv
    SkillLine.dbc.csv
    WorldMapArea.dbc.csv

# Extract Data

## Extract Specific Localizations (e.g german)

    make deDE

## Build Every Database

    make
