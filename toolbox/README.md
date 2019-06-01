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
    CREATE DATABASE `aowow` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `aowow`.* TO 'mangos'@'localhost';

    CREATE DATABASE `vmangos` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `elysium`.* TO 'mangos'@'localhost';

#### Import Databases
    $ mysql -u mangos -p"mangos" aowow < aowow.sql
    $ mysql -u mangos -p"mangos" vmangos < world_*.sql

Open the `extractor.lua` and make sure `local C = vmangos` in line 28 is set to `vmangos`.

### Using CMaNGOS
    $ mkdir git && cd git
    $ git clone https://github.com/cmangos/mangos-classic.git
    $ git clone https://github.com/cmangos/classic-db.git
    $ git clone https://github.com/MangosExtras/MangosZero_Localised.git

#### Create Users And Permissions
    # mysql
    CREATE USER 'mangos'@'localhost' IDENTIFIED BY 'mangos';
    CREATE DATABASE `aowow` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `aowow`.* TO 'mangos'@'localhost';

    CREATE DATABASE `cmangos-vanilla` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `cmangos-vanilla`.* TO 'mangos'@'localhost';

#### Import Databases
    $ mysql -u mangos -p"mangos" aowow < aowow.sql
    $ mysql -u mangos -p"mangos" cmangos-vanilla < mangos-classic/sql/base/mangos.sql
    $ mysql -u mangos -p"mangos" cmangos-vanilla < classic-db/Full_DB/ClassicDB_*.sql
    $ for file in MangosZero_Localised/1_LocaleTablePrepare.sql MangosZero_Localised/Translations/*/*.sql; do mysql -u mangos -p"mangos" cmangos-vanilla < $file; done

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
