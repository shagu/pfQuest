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

echo "===== compressing DB (Vanilla) ====="
echo "-> database"
compress db/items.lua ws
compress db/refloot.lua ws
compress db/objects.lua ws
compress db/units.lua ws
compress db/quests.lua ws
compress db/meta.lua ws
compress db/minimap.lua ws

echo "-> locales"
for loc in db/*/; do
  compress $loc/items.lua
  compress $loc/objects.lua
  compress $loc/professions.lua
  compress $loc/quests.lua nc
  compress $loc/units.lua
  compress $loc/zones.lua
done

echo "===== compressing DB (TBC) ====="
echo "-> database"
compress db/items-tbc.lua ws
compress db/refloot-tbc.lua ws
compress db/objects-tbc.lua ws
compress db/units-tbc.lua ws
compress db/quests-tbc.lua ws
compress db/meta-tbc.lua ws
compress db/minimap-tbc.lua ws

echo "-> locales"
for loc in db/*/; do
  compress $loc/items-tbc.lua
  compress $loc/objects-tbc.lua
  compress $loc/professions-tbc.lua
  compress $loc/quests-tbc.lua nc
  compress $loc/units-tbc.lua
  compress $loc/zones-tbc.lua
done
