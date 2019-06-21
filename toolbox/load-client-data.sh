#!/bin/bash
root="DBC"
rootsql="client-data.sql"
versions="vanilla tbc wotlk"
locales="enUS koKR frFR deDE zhCN zhTW esES esMX ruRU"

# delete old extraction
if [ -f "$rootsql" ]; then
  rm $rootsql
fi

# build sql tables
for v in $versions; do
  echo "Expansion: $v"
  # build minimap_sizes
  if [ -d $root/$v ] && [ -f $root/$v/WorldMapArea.dbc.csv ]; then
    function calc { bc -l <<< ${@//[xX]/*}; };

    cat >> $rootsql << EOF

DROP TABLE IF EXISTS \`WorldMapArea_${v}\`;
CREATE TABLE \`WorldMapArea_${v}\` (
  \`mapID\` smallint(3) unsigned NOT NULL,
  \`areatableID\` smallint(3) unsigned NOT NULL,
  \`name\` varchar(255) NOT NULL,
  \`x_min\` float NOT NULL DEFAULT 0.0,
  \`y_min\` float NOT NULL DEFAULT 0.0,
  \`x_max\` float NOT NULL DEFAULT 0.0,
  \`y_max\` float NOT NULL DEFAULT 0.0
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='WorldMapArea';

EOF

    cat $root/$v/WorldMapArea.dbc.csv | tail -n +2 | sort -nt ',' -k3 | while read line; do
      map=$(echo $line | cut -d "," -f 2)
      area=$(echo $line | cut -d "," -f 3)
      name=$(echo $line | cut -d "," -f 4)
      x_min=$(echo $line | cut -d "," -f 5)
      y_min=$(echo $line | cut -d "," -f 6)
      x_max=$(echo $line | cut -d "," -f 7)
      y_max=$(echo $line | cut -d "," -f 8)

      echo "INSERT INTO \`WorldMapArea_${v}\` VALUES ($map, $area, $name, $y_max, $y_min, $x_max, $x_min);" >> $rootsql
    done
  fi

  if [ -d $root/$v ] && [ -f $root/$v/FactionTemplate.dbc.csv ]; then
    function calc { bc -l <<< ${@//[xX]/*}; };

    cat >> $rootsql << EOF

DROP TABLE IF EXISTS \`FactionTemplate_${v}\`;
CREATE TABLE \`FactionTemplate_${v}\` (
  \`factiontemplateID\` smallint(3) unsigned NOT NULL,
  \`factionID\` smallint(3) unsigned NOT NULL,
  \`A\` smallint(1) NOT NULL,
  \`H\` smallint(1) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='WorldMapArea';

EOF

    cat $root/$v/FactionTemplate.dbc.csv | tail -n +2 | sort -nt ',' -k3 | while read line; do
      factiontemplate=$(echo $line | cut -d "," -f 1)
      faction=$(echo $line | cut -d "," -f 2)
      friendly=$(echo $line | cut -d "," -f 5) # field 5
      hostile=$(echo $line | cut -d "," -f 6) # field 6

      if [ $(( 4 & $hostile )) != 0 ] || [ $hostile = 1 ]; then
        horde=-1
      elif [ $(( 4 & $friendly )) != 0 ] || [ $friendly = 1 ]; then
        horde=1
      else
        horde=0
      fi

      if [ $(( 2 & $hostile )) != 0 ] || [ $hostile = 1 ]; then
        alliance=-1
      elif [ $(( 2 & $friendly )) != 0 ] || [ $friendly = 1 ]; then
        alliance=1
      else
        alliance=0
      fi

      echo "INSERT INTO \`FactionTemplate_${v}\` VALUES ($factiontemplate, $faction, $alliance, $horde);" >> $rootsql
    done
  fi

  cat >> $rootsql << EOF
DROP TABLE IF EXISTS \`Lock_${v}\`;
CREATE TABLE \`Lock_${v}\` (
  \`id\` smallint(3) unsigned NOT NULL,
  \`locktype\` varchar(255) NOT NULL,
  \`skill\` smallint(3) unsigned NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='Lock';

EOF

  if [ -d $root/$v ] && [ -f $root/$v/Lock.dbc.csv ]; then
    function add_skills() {
      if [ "$1" = 1 ]; then
        # TODO: chests hackfix
        echo "INSERT INTO \`Lock_${v}\` VALUES (57, 1, 0);" >> $rootsql
      else
        cat $root/$v/Lock.dbc.csv | while read line; do
          if [ "$(echo $line | cut -d "," -f 2)" = "0x2" ]; then
            if [ "$(echo $line | cut -d "," -f 10)" = "$1" ]; then
              id=$(echo $line | cut -d "," -f 1)
              skill=$(echo $line | cut -d "," -f 18)
              echo "INSERT INTO \`Lock_${v}\` VALUES ($id, $1, $skill);" >> $rootsql
            fi
          fi
        done
      fi
    }

    add_skills 1
    add_skills 2
    add_skills 3
  fi

  cat >> $rootsql << EOF
DROP TABLE IF EXISTS \`SkillLine_${v}\`;
CREATE TABLE \`SkillLine_${v}\` (
  \`id\` smallint(3) unsigned NOT NULL,
  \`name_loc0\` varchar(255) NOT NULL,
  \`name_loc1\` varchar(255) NOT NULL,
  \`name_loc2\` varchar(255) NOT NULL,
  \`name_loc3\` varchar(255) NOT NULL,
  \`name_loc4\` varchar(255) NOT NULL,
  \`name_loc5\` varchar(255) NOT NULL,
  \`name_loc6\` varchar(255) NOT NULL,
  \`name_loc7\` varchar(255) NOT NULL,
  \`name_loc8\` varchar(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='SkillLine';

EOF

  index=0
  for loc in $locales; do
    if [ "$loc" = "ruRU" ] && [ "$v" == "vanilla" ]; then index=0; fi
    if [ -d $root/$v ] && [ -f $root/$v/$loc/SkillLine.dbc.csv ]; then
      tail -n +2 $root/$v/$loc/SkillLine.dbc.csv | while read line; do
        id=$(echo $line | cut -d , -f 1)
        entry=$(echo $line | cut -d , -f $(expr 4 + $index))

        if [ "$loc" = "enUS" ]; then
          echo "INSERT INTO \`SkillLine_${v}\` VALUES ($id, $entry, '', '', '', '', '', '', '', '');" >> $rootsql
        else
          nameloc="name_loc$index"
          if [ "$loc" = "ruRU" ]; then nameloc="name_loc8"; fi
          echo "UPDATE \`SkillLine_${v}\` SET $nameloc = $entry WHERE id = $id;" >> $rootsql
        fi
      done
    fi
    index=$(expr $index + 1)
  done

  cat >> $rootsql << EOF
DROP TABLE IF EXISTS \`AreaTable_${v}\`;
CREATE TABLE \`AreaTable_${v}\` (
  \`id\` smallint(3) unsigned NOT NULL,
  \`name_loc0\` varchar(255) NOT NULL,
  \`name_loc1\` varchar(255) NOT NULL,
  \`name_loc2\` varchar(255) NOT NULL,
  \`name_loc3\` varchar(255) NOT NULL,
  \`name_loc4\` varchar(255) NOT NULL,
  \`name_loc5\` varchar(255) NOT NULL,
  \`name_loc6\` varchar(255) NOT NULL,
  \`name_loc7\` varchar(255) NOT NULL,
  \`name_loc8\` varchar(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='AreaTable';

EOF

  index=0
  for loc in $locales; do
    if [ "$loc" = "ruRU" ] && [ "$v" == "vanilla" ]; then index=0; fi
    if [ -d $root/$v ] && [ -f $root/$v/$loc/AreaTable.dbc.csv ]; then
      tail -n +2 $root/$v/$loc/AreaTable.dbc.csv | while read line; do
        id=$(echo $line | cut -d , -f 1)
        entry=$(echo $line | cut -d , -f $(expr 12 + $index) | sed 's/""/\\"/g')

        if [ "$loc" = "enUS" ]; then
          echo "INSERT INTO \`AreaTable_${v}\` VALUES ($id, $entry, '', '', '', '', '', '', '', '');" >> $rootsql
        else
          nameloc="name_loc$index"
          if [ "$loc" = "ruRU" ]; then nameloc="name_loc8"; fi
          echo "UPDATE \`AreaTable_${v}\` SET $nameloc = $entry WHERE id = $id;" >> $rootsql
        fi
      done
    fi
    index=$(expr $index + 1)
  done
done
