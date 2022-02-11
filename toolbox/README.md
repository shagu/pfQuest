# pfQuest-toolbox

## Setup Dependencies
### Archlinux

    # pacman -S mariadb mariadb-clients luarocks
    # mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    # systemctl start mariadb
    # luarocks install luasql-mysql MYSQL_INCDIR=/usr/include/mysql

## Prepare Databases
The pfQuest extractor supports VMaNGOS and CMaNGOS databases. By default, VMaNGOS is used vanilla and CMaNGOS is used for TBC. For CMaNGOS translations, the Mangos-Extras project is used.

### Create Users And Permissions

    # mysql
    DROP DATABASE IF EXISTS `pfquest`;
    DROP DATABASE IF EXISTS `vmangos`;
    DROP DATABASE IF EXISTS `cmangos-tbc`;

    CREATE USER 'mangos'@'localhost' IDENTIFIED BY 'mangos';

    CREATE DATABASE `pfquest` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `pfquest`.* TO 'mangos'@'localhost';

    CREATE DATABASE `vmangos` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `vmangos`.* TO 'mangos'@'localhost';

    CREATE DATABASE `cmangos-tbc` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `cmangos-tbc`.* TO 'mangos'@'localhost';

### Import Client Data

Import the game client data SQL files:

    mysql -u mangos -p"mangos" pfquest < ../client-data.sql


### Vanilla (VMaNGOS)

Manually download the latest [VMaNGOS Database](https://github.com/brotalnia/database) and unzip it.

    mysql -u mangos -p"mangos" vmangos < world_*.sql

Clone the VMaNGOS core repository to obtain all SQL updates.

    git clone https://github.com/vmangos/core.git
    cd core/sql/migrations
    for file in *_world.sql; do mysql -u mangos -p"mangos" vmangos < $file; done
    cd -

### The Burning Crusade (CMaNGOS)

Clone the latest CMaNGOS TBC database and the translations of the Mangos-Extras project:

    git clone https://github.com/cmangos/mangos-tbc.git
    git clone https://github.com/cmangos/tbc-db.git
    git clone https://github.com/MangosExtras/MangosOne_Localised.git

    mysql -u mangos -p"mangos" cmangos-tbc < mangos-tbc/sql/base/mangos.sql
    mysql -u mangos -p"mangos" cmangos-tbc < tbc-db/Full_DB/*.sql
    for file in tbc-db/Updates/*.sql; do mysql -u mangos -p"mangos" cmangos-tbc < "$file"; done
    for file in mangos-tbc/sql/updates/mangos/*.sql; do mysql -u mangos -p"mangos" cmangos-tbc < "$file"; done
    mysql -u mangos -p"mangos" cmangos-tbc < mangos-tbc/sql/base/dbc/original_data/Spell.sql
    mysql -u mangos -p"mangos" cmangos-tbc < mangos-tbc/sql/base/dbc/cmangos_fixes/Spell.sql
    mysql -u mangos -p"mangos" cmangos-tbc < tbc-db/ACID/acid_tbc.sql

    sed -i "/locales_command/d" MangosOne_Localised/1_LocaleTablePrepare.sql
    mysql -u mangos -p"mangos" cmangos-tbc < MangosOne_Localised/1_LocaleTablePrepare.sql
    for file in MangosOne_Localised/1_LocaleTablePrepare.sql MangosOne_Localised/Translations/*/*.sql; do echo "$file"; mysql -u mangos -p"mangos" cmangos-tbc < "$file"; done

## Run the Extractor

Start the database extractor

    $ make

## Optional: Build Client-Data
### Copy CSVs to DBC/
You additionally need to extract the `dbc` files from your gameclients.
Those can be obtained via the `ad` tool within the CMaNGOS tools.
The DBC files then need to be converted into `.csv` and placed as followed:

    $ ls -1 DBC/
    deDE  enUS  esES  frFR  koKR  ruRU  zhCN

    $ ls -1 DBC/deDE
    AreaTable.dbc.csv
    SkillLine.dbc.csv
    WorldMapArea.dbc.csv

### Required DBCs
#### WorldMapArea.dbc [enUS]
Required to obtain the map-sizes which are used for
  1. calculating the minimap offset
  2. calculating the objects possible maps during extraction

#### Lock.dbc [enUS]
Used to get a list of all skill requirements which are used during the
meta-list extraction

#### AreaTable.dbc [all]
The `AreaTable.dbc` is used to build the zones table. The zone table is required
to tell the gameclient which map should be shown when searching for an object.
It's basically a map-id to mape-name translation table.

#### SkillLine.dbc [all]
The `SkillLine.db` is used to build the professions table. The profession table is
required to check the players professions against quest requirements. It's
basically a profession-id to profession-name translation table.
