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
  // elysium = faction_A ;; mangos = creature_template.FactionAlliance
  $faction_table = "faction_A";

  $max_entry = 0;
  $count = 0;
  $file = "output/$loc_name/spawns.lua";
  $mysql = new mysqli("127.0.0.1", "mangos", "mangos", $database);
  $mysql->set_charset("utf8");

  $spawnSection = "";
  $spawnSection1 = "";
  $spawnSection2 = "";
  $spawnSection3 = "";
  $spawnSection4 = "";
  $spawnSection5 = "";

  $lname = null;
  $count = 1;
  $zcount = array();

  $gameobject_loc = "";
  $creature_loc = "";

  // extended query for localized clients
  if ( $loc_id > 0 ) {
    $creature_loc = ",
      elysium.locales_creature.name_loc$loc_id AS name_locale
    ";

    $gameobject_loc = ",
      elysium.locales_gameobject.name_loc$loc_id AS name_locale
    ";
  }

  $qCreature = "
    SELECT
      \"NPC\" AS type,
      creature.id AS id,
      creature.guid AS uid,
      creature_template.Name AS name,
      creature_template.MinLevel AS minlevel,
      creature_template.MaxLevel AS maxlevel,
      creature.position_x AS x,
      creature.position_y AS y,
      creature.map AS map,
      creature.spawntimesecs AS respawn,
      aowow.aowow_zones.mapID AS mapID,
      aowow.aowow_zones.areatableID AS zone,
      aowow.aowow_zones.x_max AS x_max,
      aowow.aowow_zones.x_min AS x_min,
      aowow.aowow_zones.y_max AS y_max,
      aowow.aowow_zones.y_min AS y_min,
      aowow.aowow_factiontemplate.A,
      aowow.aowow_factiontemplate.H
      $creature_loc

    FROM creature_template
      LEFT JOIN creature ON creature_template.Entry = creature.id
      LEFT JOIN elysium.locales_creature ON elysium.locales_creature.entry = creature_template.Entry
      LEFT JOIN aowow.aowow_zones ON (aowow.aowow_zones.mapID = creature.map
        AND aowow.aowow_zones.x_min < creature.position_x
        AND aowow.aowow_zones.x_max > creature.position_x
        AND aowow.aowow_zones.y_min < creature.position_y
        AND aowow.aowow_zones.y_max > creature.position_y
        AND aowow.aowow_zones.areatableID > 0
      )
    LEFT JOIN aowow.aowow_factiontemplate ON aowow.aowow_factiontemplate.factiontemplateID = creature_template.$faction_table

    UNION

    SELECT
      \"Object\" AS type,
      gameobject.id AS id,
      gameobject.guid AS uid,
      gameobject_template.Name AS name,
      \"0\" AS minlevel,
      \"0\" AS maxlevel,
      gameobject.position_x AS x,
      gameobject.position_y AS y,
      gameobject.map AS map,
      gameobject.spawntimesecs AS respawn,
      aowow.aowow_zones.mapID AS mapID,
      aowow.aowow_zones.areatableID AS zone,
      aowow.aowow_zones.x_max AS x_max,
      aowow.aowow_zones.x_min AS x_min,
      aowow.aowow_zones.y_max AS y_max,
      aowow.aowow_zones.y_min AS y_min,
      aowow.aowow_factiontemplate.A,
      aowow.aowow_factiontemplate.H
      $gameobject_loc

    FROM gameobject
      INNER JOIN gameobject_template ON gameobject_template.Entry = gameobject.id
      INNER JOIN elysium.locales_gameobject ON elysium.locales_gameobject.entry = gameobject.id
      LEFT JOIN aowow.aowow_zones ON (aowow.aowow_zones.mapID = gameobject.map
        AND aowow.aowow_zones.x_min < gameobject.position_x
        AND aowow.aowow_zones.x_max > gameobject.position_x
        AND aowow.aowow_zones.y_min < gameobject.position_y
        AND aowow.aowow_zones.y_max > gameobject.position_y
        AND aowow.aowow_zones.areatableID > 0
      )
    LEFT JOIN aowow.aowow_factiontemplate ON aowow.aowow_factiontemplate.factiontemplateID = gameobject_template.faction

    ORDER BY name,id
  ";

  $creature_query = $mysql->query($qCreature);
  file_put_contents($file, "pfDB[\"spawns\"][\"$loc_name\"] = { \n");

  while($creature_fetch = $creature_query->fetch_array(MYSQLI_ASSOC)){
    $max_entry = $max_entry + 1;
    $name = $creature_fetch["name"];

    if ($loc_id > 0) {
      $name_locale = $creature_fetch["name_locale"];
      if($name_locale != "") {
        $name = $name_locale;
      }
    }

    $name = str_replace("'", "\'", $name);

    if($name != null) {
      if($lname != $name && $spawnSection1 != ""){
        arsort($zcount);
        if (key($zcount) != "") {
          $spawnSection3 = "    ['zone'] = '" . key($zcount) . "',\n    ['coords'] =\n    {\n";
        }
        $spawnSection = $spawnSection1 . $spawnSection2 . $spawnSection3 . $spawnSection4 . $spawnSection5;

        // echo $count - 1 . "x " . $lname . "\n";

        file_put_contents($file, $spawnSection, FILE_APPEND);
        unset($zcount);
        $zcount = array();

        $spawnSection = "";
        $spawnSection1 = "";
        $spawnSection2 = "";
        $spawnSection3 = "";
        $spawnSection4 = "";
        $spawnSection5 = "";
        $count = 1;
      }
      $lname = $name;

      $type = $creature_fetch["type"];
      $x = $creature_fetch["x"];
      $y = $creature_fetch["y"];
      $x_max = $creature_fetch["x_max"];
      $x_min = $creature_fetch["x_min"];
      $y_max = $creature_fetch["y_max"];
      $y_min = $creature_fetch["y_min"];
      $zone = $creature_fetch["zone"];
      $H = $creature_fetch["H"];
      $A = $creature_fetch["A"];
      $minlevel = $creature_fetch["minlevel"];
      $maxlevel = $creature_fetch["maxlevel"];
      $respawn = $creature_fetch["respawn"];

      if(isset($y) && isset($y_min)){
        $tx = round(100 - ($y - $y_min) / (($y_max - $y_min)/100),1);
        $ty = round(100 - ($x - $x_min) / (($x_max - $x_min)/100),1);
      }
      $mapname = "./maps/" . $zone . ".png";

      if(!isset($spawnSection4)){
        $spawnSection4 = "";
      }

      $faction = "";
      if($H >= 0) { $faction = $faction . "H"; }
      if($A >= 0) { $faction = $faction . "A"; }

      if($minlevel != "" && $maxlevel != ""){
        if($minlevel != $maxlevel){
          $level = "$minlevel-$maxlevel";
        }else{
          $level = "$minlevel";
        }
      }else{
        $level = "";
      }

      if (file_exists($mapname) && isset($y) && isset($y_min)) {
        $map = @ImageCreateFromPNG($mapname);

        if (@ImageColorAt($map, round($tx * 10), round($ty * 10)) === 0) {
          $spawnSection1 = "  ['$name'] =\n";
          $spawnSection2 = "  {\n    ['type'] = '$type',\n    ['faction'] = '$faction',\n    ['level'] = '$level',\n";
          if (isset($respawn)) {
            $spawnSection2 = $spawnSection2 . "    ['respawn'] = '$respawn',\n";
          }
          $spawnSection3 = "    ['coords'] = \n    {\n";
          $spawnSection4 = $spawnSection4 . "      [$count] = '$tx,$ty,$zone',\n";
          $spawnSection5 = "    },\n  },\n";

          if(!isset($zcount[$zone])) {
            $zcount[$zone] = 0;
          }
          $zcount[$zone]++;

          $count++;
        }
      } else {
        if($spawnSection1 == "") {
          $spawnSection1 = "  ['$name'] =\n";
          $spawnSection2 = "  {\n    ['type'] = '$type',\n    ['faction'] = '$faction',\n    ['level'] = '$level',\n";
          if (isset($respawn)) {
            $spawnSection2 = $spawnSection2 . "    ['respawn'] = '$respawn',\n";
          }
          $spawnSection5 = "  },\n";
        }
      }
    }
  }

  file_put_contents($file, "}\n", FILE_APPEND);
  echo "$max_entry entries.\n";
}

?>
