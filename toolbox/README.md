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

    mariadb <<< '
        DROP DATABASE IF EXISTS `pfquest`;
        DROP DATABASE IF EXISTS `vmangos`;
        DROP DATABASE IF EXISTS `cmangos-tbc`;
        DROP DATABASE IF EXISTS `turtle`;

        CREATE USER 'mangos'@'localhost' IDENTIFIED BY 'mangos';

        CREATE DATABASE `pfquest` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
        GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `pfquest`.* TO 'mangos'@'localhost';

        CREATE DATABASE `vmangos` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
        GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `vmangos`.* TO 'mangos'@'localhost';

        CREATE DATABASE `cmangos-tbc` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
        GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `cmangos-tbc`.* TO 'mangos'@'localhost';

        CREATE DATABASE `turtle` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
        GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES, EXECUTE, ALTER ROUTINE, CREATE ROUTINE ON `turtle`.* TO 'mangos'@'localhost';
    '

### Import Client Data

Import the game client data SQL files:

    mariadb -u mangos -p"mangos" pfquest < ../client-data.sql

### Vanilla (VMaNGOS)

Manually download the latest [VMaNGOS Database](https://github.com/vmangos/core/releases/tag/db_latest) and unzip it.

    mariadb -u mangos -p"mangos" vmangos < mangos.sql

Clone the VMaNGOS core repository to obtain all SQL updates.

    git clone https://github.com/vmangos/core.git

    cd core/sql/migrations
    for file in *_world.sql; do mariadb -u mangos -p"mangos" vmangos < $file; done
    cd -

Create `_loc10` entries to VMaNGOS translation tables for `ptBR`:

    mariadb -u mangos -p"mangos" vmangos <<< '
        # select database
        USE vmangos;

        # locales_creature
        ALTER TABLE locales_creature ADD name_loc10 varchar(100);
        ALTER TABLE locales_creature ADD subname_loc10 varchar(100);

        # locales_gameobject
        ALTER TABLE locales_gameobject ADD name_loc10 varchar(100);

        # locales_item
        ALTER TABLE locales_item ADD name_loc10 varchar(100);
        ALTER TABLE locales_item ADD description_loc10 varchar(255);

        # locales_quest
        ALTER TABLE locales_quest ADD Title_loc10 TEXT;
        ALTER TABLE locales_quest ADD Details_loc10 TEXT;
        ALTER TABLE locales_quest ADD Objectives_loc10 TEXT;
        ALTER TABLE locales_quest ADD ObjectiveText1_loc10 TEXT;
        ALTER TABLE locales_quest ADD ObjectiveText2_loc10 TEXT;
        ALTER TABLE locales_quest ADD ObjectiveText3_loc10 TEXT;
        ALTER TABLE locales_quest ADD ObjectiveText4_loc10 TEXT;
        ALTER TABLE locales_quest ADD OfferRewardText_loc10 TEXT;
        ALTER TABLE locales_quest ADD RequestItemsText_loc10 TEXT;
        ALTER TABLE locales_quest ADD EndText_loc10 TEXT;
    '

Use the current `ptBR` localizations from the vmangos core repo and patch them into `_loc10` entries.

    cd core/sql/translations/ptBR
    git checkout .
    sed -i 's/`name`/`name_loc10`/g' *.sql
    sed -i 's/`subname`/`subname_loc10`/g' *.sql
    sed -i 's/`description`/`description_loc10`/g' *.sql
    sed -i 's/`Title`/`Title_loc10`/g' *.sql
    sed -i 's/`Details`/`Details_loc10`/g' *.sql
    sed -i 's/`Objectives`/`Objectives_loc10`/g' *.sql
    sed -i 's/`ObjectiveText1`/`ObjectiveText1_loc10`/g' *.sql
    sed -i 's/`ObjectiveText2`/`ObjectiveText2_loc10`/g' *.sql
    sed -i 's/`ObjectiveText3`/`ObjectiveText3_loc10`/g' *.sql
    sed -i 's/`ObjectiveText4`/`ObjectiveText4_loc10`/g' *.sql
    sed -i 's/`OfferRewardText`/`OfferRewardText_loc10`/g' *.sql
    sed -i 's/`RequestItemsText`/`RequestItemsText_loc10`/g' *.sql
    sed -i 's/`EndText`/`EndText_loc10`/g' *.sql

    sed -i 's/`creature_template`/`locales_creature`/' *.sql
    sed -i 's/`gameobject_template`/`locales_gameobject`/' *.sql
    sed -i 's/`item_template`/`locales_item`/' *.sql
    sed -i 's/`quest_template`/`locales_quest`/' *.sql

    mariadb -u mangos -p"mangos" vmangos < creature_template.sql
    mariadb -u mangos -p"mangos" vmangos < gameobject_template.sql
    mariadb -u mangos -p"mangos" vmangos < item_template.sql
    mariadb -u mangos -p"mangos" vmangos < quest_template.sql
    cd -

### TurtleWoW (Optional)

Obtain and download the latest TurtleWoW database and unzip it.

    mariadb -u mangos -p"mangos" turtle < turtle/*.sql

### The Burning Crusade (CMaNGOS)

Clone the latest CMaNGOS TBC database and the translations of the Mangos-Extras project:

    git clone https://github.com/cmangos/mangos-tbc.git
    git clone https://github.com/cmangos/tbc-db.git
    git clone https://github.com/mangosone/database.git

    mariadb -u mangos -p"mangos" cmangos-tbc < mangos-tbc/sql/base/mangos.sql
    mariadb -u mangos -p"mangos" cmangos-tbc < tbc-db/Full_DB/TBCDB_1.10.0_ReturnOfTheVengeance.sql
    for file in tbc-db/Updates/*.sql; do mariadb -u mangos -p"mangos" cmangos-tbc < "$file"; done
    for file in mangos-tbc/sql/updates/mangos/*.sql; do mariadb -u mangos -p"mangos" cmangos-tbc < "$file"; done
    mariadb -u mangos -p"mangos" cmangos-tbc < mangos-tbc/sql/base/dbc/original_data/Spell.sql
    mariadb -u mangos -p"mangos" cmangos-tbc < mangos-tbc/sql/base/dbc/cmangos_fixes/Spell.sql
    mariadb -u mangos -p"mangos" cmangos-tbc < tbc-db/ACID/acid_tbc.sql

    sed -i "/locales_command/d" database/Translations/1_LocaleTablePrepare.sql
    mariadb -u mangos -p"mangos" cmangos-tbc < database/Translations/1_LocaleTablePrepare.sql
    for file in database/Translations/1_LocaleTablePrepare.sql database/Translations/Translations/*/*.sql; do echo "$file"; mariadb -u mangos -p"mangos" cmangos-tbc < "$file"; done


## Optimize Database Performance

Run the following commands to improve extractor performance by indexing the sql entries:

    mariadb <<< '
        use 'vmangos';
        # creatures
        CREATE INDEX idx_cse_guid ON creature_spawn_entry(guid);
        CREATE INDEX idx_cse_entry ON creature_spawn_entry(entry);
        CREATE INDEX idx_guid_map_position ON creature(guid, map, position_x, position_y);
        # gameobjects
        CREATE INDEX idx_gse_guid ON gameobject_spawn_entry(guid);
        CREATE INDEX idx_gse_entry ON gameobject_spawn_entry(entry);
        # items
        CREATE INDEX idx_got_data1 ON gameobject_template(data1);
        CREATE INDEX idx_golt_entry ON gameobject_loot_template(entry);
        CREATE INDEX idx_npcvt_entry ON npc_vendor_template(entry);
        CREATE INDEX idx_ct_entry ON creature_template(Entry);

        use 'turtle';
        # creatures
        CREATE INDEX idx_cse_guid ON creature_spawn_entry(guid);
        CREATE INDEX idx_cse_entry ON creature_spawn_entry(entry);
        CREATE INDEX idx_guid_map_position ON creature(guid, map, position_x, position_y);
        # gameobjects
        CREATE INDEX idx_gse_guid ON gameobject_spawn_entry(guid);
        CREATE INDEX idx_gse_entry ON gameobject_spawn_entry(entry);
        # items
        CREATE INDEX idx_got_data1 ON gameobject_template(data1);
        CREATE INDEX idx_golt_entry ON gameobject_loot_template(entry);
        CREATE INDEX idx_npcvt_entry ON npc_vendor_template(entry);
        CREATE INDEX idx_ct_entry ON creature_template(Entry);

        use 'cmangos-tbc';
        # creatures
        CREATE INDEX idx_cse_guid ON creature_spawn_entry(guid);
        CREATE INDEX idx_cse_entry ON creature_spawn_entry(entry);
        CREATE INDEX idx_guid_map_position ON creature(guid, map, position_x, position_y);
        # gameobjects
        CREATE INDEX idx_gse_guid ON gameobject_spawn_entry(guid);
        CREATE INDEX idx_gse_entry ON gameobject_spawn_entry(entry);
        # items
        CREATE INDEX idx_got_data1 ON gameobject_template(data1);
        CREATE INDEX idx_golt_entry ON gameobject_loot_template(entry);
        CREATE INDEX idx_npcvt_entry ON npc_vendor_template(entry);
        CREATE INDEX idx_ct_entry ON creature_template(Entry);

        use 'pfquest';
        # worldmap
        CREATE INDEX idx_wma_vanilla_sizes ON pfquest.WorldMapArea_vanilla(x_min, x_max, y_min, y_max);
        CREATE INDEX idx_wma_vanilla_mapid ON pfquest.WorldMapArea_vanilla(mapID);
        CREATE INDEX idx_wma_vanilla_area ON pfquest.WorldMapArea_vanilla(areatableID);
        CREATE INDEX idx_wma_tbc_sizes ON pfquest.WorldMapArea_tbc(x_min, x_max, y_min, y_max);
        CREATE INDEX idx_wma_tbc_mapid ON pfquest.WorldMapArea_tbc(mapID);
        CREATE INDEX idx_wma_tbc_area ON pfquest.WorldMapArea_tbc(areatableID);
    '

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
