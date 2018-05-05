#!/bin/bash
# dbc exports as csv are required

locales="enUS koKR frFR deDE zhCN zhTW esES esMX ruRU"
index=0

echo -n "professions: "
for loc in $locales; do
  if [ "$loc" = "ruRU" ]; then index=0; fi

  mkdir -p output/${loc}
  file="output/${loc}/professions.lua"

  echo -n "$loc "
  if [ -f "DBC/${loc}/SkillLine.dbc.csv" ]; then
    echo "pfDB[\"professions\"][\"${loc}\"] = {" > $file

    tail -n +2 DBC/${loc}/SkillLine.dbc.csv | while read line; do
      id=$(echo $line | cut -d , -f 1)
      entry=$(echo $line | cut -d , -f $(expr 4 + $index))
      echo "  [$id] = $entry," >> $file
    done

    echo "}" >> $file
  fi

  index=$(expr $index + 1)
done
echo
