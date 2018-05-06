#!/bin/bash
# dbc exports as csv are required

locales="enUS koKR frFR deDE zhCN zhTW esES esMX ruRU"
index=0

echo -n "zones: "
for loc in $locales; do
  if [ "$loc" = "ruRU" ]; then index=0; fi

  mkdir -p output/${loc}
  file="output/${loc}/zones.lua"

  echo -n "$loc "
  if [ -f "DBC/${loc}/AreaTable.dbc.csv" ]; then
    echo "pfDB[\"zones\"][\"${loc}\"] = {" > $file

    tail -n +2 DBC/${loc}/AreaTable.dbc.csv | while read line; do
      id=$(echo $line | cut -d , -f 1)
      entry=$(echo $line | cut -d , -f $(expr 12 + $index) | sed 's/""/\\"/g')
#      if cat DBC/${loc}/WorldMapArea.dbc.csv| cut -d , -f 3 | grep "^$id$" &> /dev/null; then
        echo "  [$id] = $entry," >> $file
#      fi
    done

    echo "}" >> $file
  fi

  index=$(expr $index + 1)
done
echo
