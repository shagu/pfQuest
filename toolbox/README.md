# pfQuest-toolbox

## Setup Dependencies
### Archlinux

    # pacman -S lua-sql-mysql mariadb mariadb-clients
    # systemctl start mariadb
    # mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

## Server Database
The pfQuest extractor supports VMaNGOS and CMaNGOS databases. You need to pick either one of both.

### Using VMaNGOS (Light's Hope)
Manually download the latest [VMaNGOS Database](https://github.com/brotalnia/database) and unzip it.

#### Create Users And Permissions
    # mysql
    CREATE USER 'mangos'@'localhost' IDENTIFIED BY 'mangos';
    CREATE DATABASE `pfquest` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `pfquest`.* TO 'mangos'@'localhost';

    CREATE DATABASE `vmangos-vanilla` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `vmangos-vanilla`.* TO 'mangos'@'localhost';

#### Import Databases
    $ mysql -u mangos -p"mangos" pfquest < client-data.sql
    $ mysql -u mangos -p"mangos" vmangos-vanilla < world_*.sql

Open the `extractor.lua` and make sure `local C = vmangos` in line 28 is set to `vmangos`.

### Using CMaNGOS
    $ mkdir git && cd git
    $ git clone https://github.com/cmangos/mangos-classic.git
    $ git clone https://github.com/cmangos/classic-db.git
    $ git clone https://github.com/MangosExtras/MangosZero_Localised.git

    $ git clone https://github.com/cmangos/mangos-tbc.git
    $ git clone https://github.com/cmangos/tbc-db.git
    $ git clone https://github.com/MangosExtras/MangosOne_Localised.git

    $ git clone https://github.com/cmangos/mangos-wotlk.git
    $ git clone https://github.com/cmangos/wotlk-db.git
    $ git clone https://github.com/MangosExtras/MangosTwo_Localised.git

#### Create Users And Permissions
    # mysql
    CREATE USER 'mangos'@'localhost' IDENTIFIED BY 'mangos';
    CREATE DATABASE `pfquest` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `pfquest`.* TO 'mangos'@'localhost';

    CREATE DATABASE `cmangos-vanilla` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `cmangos-vanilla`.* TO 'mangos'@'localhost';

    CREATE DATABASE `cmangos-tbc` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `cmangos-tbc`.* TO 'mangos'@'localhost';

    CREATE DATABASE `cmangos-wotlk` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `cmangos-wotlk`.* TO 'mangos'@'localhost';

#### Import Databases
    mysql -u mangos -p"mangos" pfquest < client-data.sql

    mysql -u mangos -p"mangos" cmangos-vanilla < git/mangos-classic/sql/base/mangos.sql
    mysql -u mangos -p"mangos" cmangos-vanilla < git/mangos-classic/sql/base/dbc/original_data/Spell.sql
    mysql -u mangos -p"mangos" cmangos-vanilla < git/mangos-classic/sql/base/dbc/cmangos_fixes/Spell.sql
    mysql -u mangos -p"mangos" cmangos-vanilla < git/classic-db/Full_DB/*.sql
    for file in git/MangosZero_Localised/1_LocaleTablePrepare.sql git/MangosZero_Localised/Translations/*/*.sql; do mysql -u mangos -p"mangos" cmangos-vanilla < $file; done

    mysql -u mangos -p"mangos" cmangos-tbc < git/mangos-tbc/sql/base/mangos.sql
    mysql -u mangos -p"mangos" cmangos-tbc < git/mangos-tbc/sql/base/dbc/original_data/Spell.sql
    mysql -u mangos -p"mangos" cmangos-tbc < git/mangos-tbc/sql/base/dbc/cmangos_fixes/Spell.sql
    mysql -u mangos -p"mangos" cmangos-tbc < git/tbc-db/Full_DB/*.sql
    for file in git/MangosOne_Localised/1_LocaleTablePrepare.sql git/MangosOne_Localised/Translations/*/*.sql; do mysql -u mangos -p"mangos" cmangos-tbc < $file; done

    mysql -u mangos -p"mangos" cmangos-wotlk < git/mangos-wotlk/sql/base/mangos.sql
    mysql -u mangos -p"mangos" cmangos-wotlk < git/mangos-wotlk/dbc/sql/base/original_data/Spell.sql
    mysql -u mangos -p"mangos" cmangos-wotlk < git/mangos-wotlk/dbc/sql/base/cmangos_fixes/Spell.sql
    mysql -u mangos -p"mangos" cmangos-wotlk < git/wotlk-db/Full_DB/*.sql
    for file in git/MangosTwo_Localised/1_LocaleTablePrepare.sql git/MangosTwo_Localised/Translations/*/*.sql; do mysql -u mangos -p"mangos" cmangos-wotlk < $file; done

Open the `extractor.lua` and make sure `local C = cmangos-vanilla` in line 28 is set to `cmangos-vanilla`.

## Copy CSVs to DBC/
You additionally need to extract the `dbc` files from your gameclients.
Those can be obtained via the `ad` tool within the CMaNGOS tools.
The DBC files then need to be converted into `.csv` and placed as followed:

    $ ls -1 DBC/
    deDE  enUS  esES  frFR  koKR  ruRU  zhCN

    $ ls -1 DBC/deDE
    AreaTable.dbc.csv
    SkillLine.dbc.csv
    WorldMapArea.dbc.csv

## Extract Data

    $ make

# Required DBCs
## WorldMapArea.dbc [enUS]
Required to obtain the map-sizes which are used for
  1. calculating the minimap offset
  2. calculating the objects possible maps during extraction

## Lock.dbc [enUS]
Used to get a list of all skill requirements which are used during the
meta-list extraction

## AreaTable.dbc [all]
The `AreaTable.dbc` is used to build the zones table. The zone table is required
to tell the gameclient which map should be shown when searching for an object.
It's basically a map-id to mape-name translation table.

## SkillLine.dbc [all]
The `SkillLine.db` is used to build the professions table. The profession table is
required to check the players professions against quest requirements. It's
basically a profession-id to profession-name translation table.
