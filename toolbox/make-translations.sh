#!/bin/bash
TMPFILE=".locales.lua"
locales="koKR frFR deDE zhCN esES ruRU"

echo 'local locales = {' > $TMPFILE
for loc in $locales; do
  echo -n "Language: $loc "

  echo "  [\"$loc\"] = {" >> $TMPFILE
  cat *.lua | sed "s/\(pfQuest_Loc\[\"\)/\n\1/" | grep -oP "pfQuest_Loc\[\".*?\"]" | sed 's/pfQuest_Loc\["\(.*\)"\]/\1/' | sort | uniq | while read -r entry; do
    writable="    [\"$entry\"] = nil,"

    echo -n "."

    # search previous translation
    cat locales.lua | awk "/\[\"$loc\"\]/,/},/" | while read -r line; do
      if echo $line | grep -qF "[\"$entry\"]"; then
        match=$(echo $line | grep -F "[\"$entry\"]")
        writable="    $match"
        echo "$writable" >> $TMPFILE
        exit 1
      fi
    done && echo "$writable" >> $TMPFILE
  done
  echo "  }," >> $TMPFILE
  echo
done
echo '}' >> $TMPFILE

cat >> $TMPFILE << "EOF"

pfQuest_Loc = setmetatable(locales[GetLocale()] or {}, { __index = function(tab,key)
 local value = tostring(key)
 rawset(tab,key,value)
 return value
end})
EOF

mv $TMPFILE locales.lua
