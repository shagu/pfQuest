#!/bin/bash

locales="ruRU frFR deDE"

echo 'local locales = {' > locales.lua
for loc in $locales; do
  echo "  [\"$loc\"] = {" >> locales.lua
  cat *.lua | sed "s/\(pfQuest_Loc\[\"\)/\n\1/" | grep -oP "pfQuest_Loc\[\".*?\"]" | sed 's/pfQuest_Loc\["\(.*\)"\]/\1/' | sort | uniq | while read -r entry; do
    echo "    [\"$entry\"] = nil," >> locales.lua
  done
  echo "  }," >> locales.lua
done
echo '}' >> locales.lua

cat >> locales.lua << "EOF"

pfQuest_Loc = setmetatable(locales[GetLocale()] or {}, { __index = function(tab,key)
 local value = tostring(key)
 rawset(tab,key,value)
 return value
end})
EOF
