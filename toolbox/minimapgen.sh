#!/bin/bash
# maps.txt taken from aowow.sql

function calc { bc -l <<< ${@//[xX]/*}; };

echo "local minimap_sizes = {"
cat maps.txt | while read line; do
  id=$(echo $line | cut -d "," -f 1)
  name=$(echo $line | cut -d "," -f 2)
  xone=$(echo $line | cut -d "," -f 4)
  xtwo=$(echo $line | cut -d "," -f 6)
  yone=$(echo $line | cut -d "," -f 3)
  ytwo=$(echo $line | cut -d "," -f 5)

  X=$(calc "-1*$xone + $xtwo")
  Y=$(calc "-1*$yone + $ytwo")
  echo "  [$id] = { $X, $Y }, -- $name"
done
echo "}"
