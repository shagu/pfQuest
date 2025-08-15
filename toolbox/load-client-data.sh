#!/bin/bash
root="DBC"
rootsql="client-data.sql"
versions="vanilla turtle tbc wotlk"
locales="enUS koKR frFR deDE zhCN zhTW esES esMX ruRU jaJP ptBR"

# delete old extraction
if [ -f "$rootsql" ]; then
  rm $rootsql
fi

function Run() {
  echo "- $1" &&  $1
}

function WorldMapOverlay() {
  cat >> $rootsql << EOF
DROP TABLE IF EXISTS \`WorldMapOverlay_${v}\`;
CREATE TABLE \`WorldMapOverlay_${v}\` (
\`areaID\` smallint(3) unsigned NOT NULL,
\`zoneID\` smallint(3) unsigned NOT NULL,
\`texture\` varchar(255),
\`textureWidth\` smallint(3) unsigned NOT NULL,
\`textureHeight\` smallint(3) unsigned NOT NULL,
\`offsetX\` smallint(3) unsigned NOT NULL,
\`offsetY\` smallint(3) unsigned NOT NULL,
\`hitRectTop\` smallint(3) unsigned NOT NULL,
\`hitRectLeft\` smallint(3) unsigned NOT NULL,
\`hitRectBottom\` smallint(3) unsigned NOT NULL,
\`hitRectRight\` smallint(3) unsigned NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='WorldMapOverlay';

EOF

  if [ -d $root/$v ] && [ -f $root/$v/WorldMapOverlay.dbc.csv ]; then
    cat $root/$v/WorldMapOverlay.dbc.csv | tail -n +2 | sort -nt ',' -k3,3 | while read line; do
      areaID=$(echo $line | cut -d "," -f 3)
      zoneID=$(echo $line | cut -d "," -f 2)
      texture=$(echo $line | cut -d "," -f 9)
      textureWidth=$(echo $line | cut -d "," -f 10)
      textureHeight=$(echo $line | cut -d "," -f 11)
      offsetX=$(echo $line | cut -d "," -f 12)
      offsetY=$(echo $line | cut -d "," -f 13)
      top=$(echo $line | cut -d "," -f 14)
      left=$(echo $line | cut -d "," -f 15)
      bottom=$(echo $line | cut -d "," -f 16)
      right=$(echo $line | cut -d "," -f 17)

      echo "INSERT INTO \`WorldMapOverlay_${v}\` VALUES ($areaID, $zoneID, $texture, $textureWidth, $textureHeight, $offsetX, $offsetY, $top, $left, $bottom, $right);" >> $rootsql
    done
  fi
}


function AreaTrigger() {
  cat >> $rootsql << EOF
DROP TABLE IF EXISTS \`AreaTrigger_${v}\`;
CREATE TABLE \`AreaTrigger_${v}\` (
\`ID\` smallint(3) unsigned NOT NULL,
\`MapID\` smallint(3) unsigned NOT NULL,
\`X\` float NOT NULL DEFAULT 0.0,
\`Y\` float NOT NULL DEFAULT 0.0,
\`Z\` float NOT NULL DEFAULT 0.0,
\`Size\` float NOT NULL DEFAULT 0.0
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='AreaTrigger';

EOF

  if [ -d $root/$v ] && [ -f $root/$v/AreaTrigger.dbc.csv ]; then
    cat $root/$v/AreaTrigger.dbc.csv | tail -n +2 | sort -nt "," -k1,1 | while read line; do
      id=$(echo $line | cut -d "," -f 1)
      map=$(echo $line | cut -d "," -f 2)
      x=$(echo $line | cut -d "," -f 3)
      y=$(echo $line | cut -d "," -f 4)
      z=$(echo $line | cut -d "," -f 5)
      size=$(echo $line | cut -d "," -f 6)

      echo "INSERT INTO \`AreaTrigger_${v}\` VALUES ($id, $map, $x, $y, $z, $size);" >> $rootsql
    done
  fi
}

function WorldMapArea() {
  cat >> $rootsql << EOF
DROP TABLE IF EXISTS \`WorldMapArea_${v}\`;
CREATE TABLE \`WorldMapArea_${v}\` (
\`zoneID\` smallint(3) unsigned NOT NULL,
\`mapID\` smallint(3) unsigned NOT NULL,
\`areatableID\` smallint(3) unsigned NOT NULL,
\`name\` varchar(255) NOT NULL,
\`x_min\` float NOT NULL DEFAULT 0.0,
\`y_min\` float NOT NULL DEFAULT 0.0,
\`x_max\` float NOT NULL DEFAULT 0.0,
\`y_max\` float NOT NULL DEFAULT 0.0
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='WorldMapArea';

EOF

  if [ -d $root/$v ] && [ -f $root/$v/WorldMapArea.dbc.csv ]; then
    cat $root/$v/WorldMapArea.dbc.csv | tail -n +2 | sort -nt ',' -k3,3 | while read line; do
      zone=$(echo $line | cut -d "," -f 1)
      map=$(echo $line | cut -d "," -f 2)
      area=$(echo $line | cut -d "," -f 3)
      name=$(echo $line | cut -d "," -f 4)
      x_min=$(echo $line | cut -d "," -f 5)
      y_min=$(echo $line | cut -d "," -f 6)
      x_max=$(echo $line | cut -d "," -f 7)
      y_max=$(echo $line | cut -d "," -f 8)

      echo "INSERT INTO \`WorldMapArea_${v}\` VALUES ($zone, $map, $area, $name, $y_max, $y_min, $x_max, $x_min);" >> $rootsql
    done
  fi
}

function FactionTemplate() {
  cat >> $rootsql << EOF
DROP TABLE IF EXISTS \`FactionTemplate_${v}\`;
CREATE TABLE \`FactionTemplate_${v}\` (
\`factiontemplateID\` smallint(3) unsigned NOT NULL,
\`factionID\` smallint(3) unsigned NOT NULL,
\`A\` smallint(1) NOT NULL,
\`H\` smallint(1) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='WorldMapArea';

EOF

  if [ -d $root/$v ] && [ -f $root/$v/FactionTemplate.dbc.csv ]; then
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
}

function Lock() {
  cat >> $rootsql << EOF
DROP TABLE IF EXISTS \`Lock_${v}\`;
CREATE TABLE \`Lock_${v}\` (
\`id\` smallint(3) unsigned NOT NULL,
\`locktype\` smallint(3) NOT NULL,
\`data\` smallint(3) unsigned NOT NULL,
\`skill\` smallint(3) unsigned NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='Lock';

EOF

  if [ -d $root/$v ] && [ -f $root/$v/Lock.dbc.csv ]; then
    cat $root/$v/Lock.dbc.csv | tail -n +2 | while read line; do
      id=$(echo $line | cut -d "," -f 1)
      locktype=$(echo $line | cut -d "," -f 2)
      locktype=$(echo $locktype | cut -d "x" -f 2)
      data=$(echo $line | cut -d "," -f 10)
      skill=$(echo $line | cut -d "," -f 18)

      # hackfix to display chests
      if [ "$id" = "57" ]; then
        echo "INSERT INTO \`Lock_${v}\` VALUES (57, 2, 1, 0);" >> $rootsql
      else
        echo "INSERT INTO \`Lock_${v}\` VALUES ($id, $locktype, $data, $skill);" >> $rootsql
      fi

    done
  fi
}

function SkillLine() {
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
\`name_loc8\` varchar(255) NOT NULL,
\`name_loc10\` varchar(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='SkillLine';

EOF

  index=0
  for loc in $locales; do
    # locale fixes
    if [ "$loc" = "ruRU" ] && [ "$v" == "vanilla" ]; then
      dbcslot=0 # there's no index for ruRU in 1.12, using enUS index
    elif [ "$loc" = "ptBR" ] && [ "$v" == "vanilla" ]; then
      dbcslot=0 # there's no index for ptBR in 1.12, using enUS index
    elif [ "$loc" = "esMX" ] && [ "$v" == "turtle" ]; then
      dbcslot=0 # no turtle client for that language, falling back to enUS
    elif [ "$loc" = "frFR" ] && [ "$v" == "turtle" ]; then
      dbcslot=0 # no turtle client for that language, falling back to enUS
    elif [ "$loc" = "jaJP" ] && [ "$v" == "turtle" ]; then
      dbcslot=0 # no turtle client for that language, falling back to enUS
    elif [ "$loc" = "koKR" ] && [ "$v" == "turtle" ]; then
      dbcslot=0 # no turtle client for that language, falling back to enUS
    elif [ "$loc" = "ruRU" ] && [ "$v" == "turtle" ]; then
      dbcslot=0 # no turtle client for that language, falling back to enUS
    elif [ "$loc" = "zhTW" ] && [ "$v" == "turtle" ]; then
      dbcslot=0 # no turtle client for that language, falling back to enUS
    elif [ "$loc" = "ptBR" ] && [ "$v" == "turtle" ]; then
      dbcslot=7 # turtle uses xxYY (loc7) for ptBR
    else
      dbcslot=$index
    fi

    if [ -d $root/$v ] && [ -f $root/$v/$loc/SkillLine.dbc.csv ]; then
      tail -n +2 $root/$v/$loc/SkillLine.dbc.csv | while read line; do
        id=$(echo $line | cut -d , -f 1)
        entry=$(echo $line | cut -d , -f $(expr 4 + $dbcslot))

        if [ "$loc" = "enUS" ]; then
          echo "INSERT INTO \`SkillLine_${v}\` VALUES ($id, $entry, '', '', '', '', '', '', '', '', '');" >> $rootsql
        elif [ "$loc" = "ptBR" ] && [ "$v" == "turtle" ]; then
          echo "UPDATE \`SkillLine_${v}\` SET name_loc7 = $entry WHERE id = $id;" >> $rootsql
        else
          echo "UPDATE \`SkillLine_${v}\` SET name_loc$index = $entry WHERE id = $id;" >> $rootsql
        fi
      done
    fi
    index=$(expr $index + 1)
  done
}

function AreaTable() {
  cat >> $rootsql << EOF
DROP TABLE IF EXISTS \`AreaTable_${v}\`;
CREATE TABLE \`AreaTable_${v}\` (
\`id\` int(3) unsigned NOT NULL,
\`zoneID\` smallint(3) unsigned NOT NULL,
\`name_loc0\` varchar(255) NOT NULL,
\`name_loc1\` varchar(255) NOT NULL,
\`name_loc2\` varchar(255) NOT NULL,
\`name_loc3\` varchar(255) NOT NULL,
\`name_loc4\` varchar(255) NOT NULL,
\`name_loc5\` varchar(255) NOT NULL,
\`name_loc6\` varchar(255) NOT NULL,
\`name_loc7\` varchar(255) NOT NULL,
\`name_loc8\` varchar(255) NOT NULL,
\`name_loc10\` varchar(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='AreaTable';

EOF


  index=0
  for loc in $locales; do
    # locale fixes
    if [ "$loc" = "ruRU" ] && [ "$v" == "vanilla" ]; then
      dbcslot=0 # there's no index for ruRU in 1.12, using enUS index
    elif [ "$loc" = "ptBR" ] && [ "$v" == "vanilla" ]; then
      dbcslot=0 # there's no index for ptBR in 1.12, using enUS index
    elif [ "$loc" = "esMX" ] && [ "$v" == "turtle" ]; then
      dbcslot=0 # no turtle client for that language, falling back to enUS
    elif [ "$loc" = "frFR" ] && [ "$v" == "turtle" ]; then
      dbcslot=0 # no turtle client for that language, falling back to enUS
    elif [ "$loc" = "jaJP" ] && [ "$v" == "turtle" ]; then
      dbcslot=0 # no turtle client for that language, falling back to enUS
    elif [ "$loc" = "koKR" ] && [ "$v" == "turtle" ]; then
      dbcslot=0 # no turtle client for that language, falling back to enUS
    elif [ "$loc" = "ruRU" ] && [ "$v" == "turtle" ]; then
      dbcslot=0 # no turtle client for that language, falling back to enUS
    elif [ "$loc" = "zhTW" ] && [ "$v" == "turtle" ]; then
      dbcslot=0 # no turtle client for that language, falling back to enUS
    elif [ "$loc" = "ptBR" ] && [ "$v" == "turtle" ]; then
      dbcslot=7 # turtle uses xxYY (loc7) for ptBR
    else
      dbcslot=$index
    fi

    if [ -d $root/$v ] && [ -f $root/$v/$loc/AreaTable.dbc.csv ]; then
      tail -n +2 $root/$v/$loc/AreaTable.dbc.csv | while read line; do
        id=$(echo $line | cut -d , -f 1)
        zoneID=$(echo $line | cut -d , -f 3)
        entry=$(echo $line | cut -d , -f $(expr 12 + $dbcslot))
        if ! [ -z "$entry" ] && [ "$entry" != "\"\"" ]; then
          entry=$(echo $entry | sed 's/""/\\"/g')
        fi

        # some zones must be flagged with UNUSED for some locales
        unused_zones="55 276 394 407 470 474 476 696 697 698 699 1196"
        if [ "$loc" = "zhCN" ]; then
          for unused in $unused_zones; do
            if [ "$unused" == "$id" ]; then
              entry="\"$(echo ${entry} | sed 's/"//g')UNUSED\""
            fi
          done
        fi

        if [ "$loc" = "enUS" ]; then
          echo "INSERT INTO \`AreaTable_${v}\` VALUES ($id, $zoneID, $entry, '', '', '', '', '', '', '', '', '');" >> $rootsql
        elif [ "$loc" = "ptBR" ] && [ "$v" == "turtle" ]; then
          echo "UPDATE \`AreaTable_${v}\` SET name_loc7 = $entry WHERE id = $id;" >> $rootsql
        else
          echo "UPDATE \`AreaTable_${v}\` SET name_loc$index = $entry WHERE id = $id;" >> $rootsql
        fi
      done
    fi
    index=$(expr $index + 1)
  done
}

# build sql tables
for v in $versions; do
  echo "Expansion: $v"

  Run WorldMapOverlay
  Run AreaTrigger
  Run WorldMapArea
  Run FactionTemplate
  Run Lock
  Run SkillLine
  Run AreaTable
done
