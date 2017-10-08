#!/usr/bin/php
<?php

ini_set('memory_limit', '-1');

$locales = array("enUS", "koKR", "frFR", "deDE", "zhCN", "zhTW", "esES", "esMX", "ruRU" );

$all_locales = false;

if ( isset($argv[1]) ) {
  $build_locale = $argv[1];
} else {
  $all_locales = true;
}

foreach ($locales as $loc_id => $loc_name) {

  if ( $all_locales == false ) {
    if ( $loc_name != $build_locale ) {
      continue;
    }
  }

  $database = "elysium";

  $max_entry = 0;
  $count = 0;
  $file = "output/$loc_name/vendors.lua";
  $mysql = new mysqli("127.0.0.1", "mangos", "mangos", $database);
  if($mysql->connect_errno != 0){  echo "cant connect to database"; }
  $mysql->set_charset("utf8");

  $locale_query = "";

  if ( $loc_id > 0 ) {
    $locale_query =  ",
     elysium.locales_item.name_loc$loc_id AS item_locale,
     elysium.locales_creature.name_loc$loc_id AS mob_locale
    ";
  }

  $vendors = "
    SELECT
      item_template.name AS item,
      creature_template.name AS mob,
      creature_template.entry AS id,
      npc_vendor.maxcount AS maxcount
      $locale_query

    FROM
      item_template,
      creature_template,
      elysium.locales_item,
      elysium.locales_creature,
      npc_vendor

    WHERE item_template.entry = npc_vendor.item
      AND creature_template.entry = npc_vendor.entry
      AND elysium.locales_item.entry = item_template.entry
      AND elysium.locales_creature.entry = creature_template.Entry

    ORDER BY item, id DESC
  ";


  $query = $mysql->query($vendors);

  file_put_contents($file, "pfDB[\"vendors\"][\"$loc_name\"] = { \n");

  $lastitem = "";
  $first = true;

  while($fetch = $query->fetch_array(MYSQLI_ASSOC)){
    $max_entry = $max_entry + 1;
    $item = $fetch["item"];
    $mob = $fetch["mob"];

    if ($loc_id > 0) {
      $item_locale = $fetch["item_locale"];
      if($item_locale != ""){ $item = $item_locale; }

      $mob_locale = $fetch["mob_locale"];
      if($mob_locale != ""){ $mob = $mob_locale; }
    }


    $item = str_replace("'", "\'", $item);
    $mob = str_replace("'", "\'", $mob);

    $maxcount = $fetch["maxcount"];

    if($item != $lastitem){
      // echo $count - 1 . "x " . $lastitem . "\n";
      $lastitem = $item;
      $count = 1;

      if($first != true){
        file_put_contents($file, "  },\n", FILE_APPEND);
      } else {
        $first = false;
      }

      file_put_contents($file, "  ['" . $item . "'] =\n", FILE_APPEND);
      file_put_contents($file, "  {\n", FILE_APPEND);
      file_put_contents($file, "    [" . $count . "] = '" . $mob . "," . $maxcount . "',\n", FILE_APPEND);
      $count = $count + 1;
    } else {
      file_put_contents($file, "    [" . $count . "] = '" . $mob . "," . $maxcount . "',\n", FILE_APPEND);
      $count = $count + 1;
    }
  }
  file_put_contents($file, "  }\n}\n", FILE_APPEND);
  echo "$max_entry entries.\n";
}

?>
