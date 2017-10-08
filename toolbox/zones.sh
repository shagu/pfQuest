#!/bin/bash
# dbc exports as csv are required

locales="enUS koKR frFR deDE zhCN zhTW esES esMX ruRU"
index=0

for loc in $locales; do
  if [ $1 ] && [ $1 != $loc ]; then
    index=$(expr $index + 1)
    continue;
  fi

  if [ "$loc" = "ruRU" ]; then index=0; fi

  file="output/${loc}/zones.lua"

  echo "## $loc ##"
  if [ -f "DBC/AreaTable_${loc}.dbc.csv" ]; then
    echo "pfDB[\"zones\"][\"${loc}\"] = {" > $file

    tail -n +2 DBC/AreaTable_${loc}.dbc.csv | while read line; do
      id=$(echo $line | cut -d , -f 1)
      entry=$(echo $line | cut -d , -f $(expr 12 + $index))
      if cat DBC/WorldMapArea_${loc}.dbc.csv| cut -d , -f 3 | grep "^$id$" &> /dev/null; then
        echo "  [$id] = $entry," >> $file
      fi
    done

    echo "}" >> $file
  fi

  index=$(expr $index + 1)
done
