#!/bin/bash
function compress() {
  if ! [ -f $1 ]; then return; fi

  if ! [ "$2" = "nc" ]; then
    sed 's/ --.*//g' -i $1
  fi

  sed 's/  //g' -i $1

  if [ "$2" = "ws" ]; then
    # even remove single whitespaces
    sed 's/ //g' -i $1
  fi

  sed 's/ = /=/g' -i $1
  tr -d '\n' < $1 > /tmp/$(basename $1)
  mv /tmp/$(basename $1) $1
}

echo "===== compressing DB ====="
echo "-> database"
compress db/items.lua ws
compress db/objects.lua ws
compress db/units.lua ws
compress db/quests.lua ws

echo "-> locales"
for loc in db/*/; do
  compress $loc/items.lua
  compress $loc/objects.lua
  compress $loc/professions.lua
  compress $loc/quests.lua nc
  compress $loc/units.lua
  compress $loc/zones.lua
done
