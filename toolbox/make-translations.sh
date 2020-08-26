#!/bin/bash

USE_TRANSLATIONS_LIST="no"
TMPFILE=".locales.lua"
locales="koKR frFR deDE zhCN esES ruRU"

echo 'local locales = {' > $TMPFILE
for loc in $locales; do
  if [ "$USE_TRANSLATIONS_LIST" != "yes" ]; then
    rm -f translation_$loc.txt
    rm -f translation_reference.txt
  fi

  echo "  [\"$loc\"] = {" >> $TMPFILE
  cat *.lua | sed "s/\(pfQuest_Loc\[\"\)/\n\1/" | grep -oP "pfQuest_Loc\[\".*?\"]" | sed 's/pfQuest_Loc\["\(.*\)"\]/\1/' | sort | uniq | while read -r entry; do
    writable="    [\"$entry\"] = nil,"

    # search previous translation
    rm -f /tmp/.pfquest
    cat locales.lua | awk "/\[\"$loc\"\]/,/},/" | while read -r line; do
      if echo $line | grep -qF "[\"$entry\"]"; then
        match=$(echo $line | grep -F "[\"$entry\"]")
        writable="    $match"
        echo "$writable" > /tmp/.pfquest
      fi
    done

    if [ -f /tmp/.pfquest ]; then
      writable=$(cat /tmp/.pfquest)
      rm /tmp/.pfquest
    fi

    if [ "$USE_TRANSLATIONS_LIST" = "yes" ]; then
      lnr=$(grep -n "^$entry$" translation_reference.txt | cut -d : -f 1)
      orig=$(sed -n "${lnr}p" translation_reference.txt)
      new=$(sed -n "${lnr}p" translation_$loc.txt)

      if [ "$lnr" != "" ] && [ "$new" != "" ] && [ "$new" != "$orig" ]; then
        writable="    [\"$entry\"] = \"$new\","
      fi
    else
      :
      # echo $entry >> translation_reference.txt
      # echo $entry >> translation_$loc.txt
    fi

    # write to new file
    echo "$writable" >> $TMPFILE
  done
  echo "  }," >> $TMPFILE
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
