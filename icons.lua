-- Custom Icons for Specific Nodes
--
-- This file contains custom icon definitions for specific nodes in the game.
-- Each node has a unique identifier that is used to determine its localized name.
-- Negative values are used to assign icons to game objects. Positive values are
-- used to assign icons to units. To avoid duplicates, it's essential to use only
-- one id per object or unit name.

do -- /db track mines
  pfDatabase:AddCustomIcon(-1731, "img\\tracking\\mines\\Copper") -- Copper Vein
  pfDatabase:AddCustomIcon(-1732, "img\\tracking\\mines\\Tin") -- Tin Vein
  pfDatabase:AddCustomIcon(-1733, "img\\tracking\\mines\\Silver") -- Silver Vein
  pfDatabase:AddCustomIcon(-73940, "img\\tracking\\mines\\Silver") -- Ooze Covered Silver Vein
  pfDatabase:AddCustomIcon(-1735, "img\\tracking\\mines\\Iron") -- Iron Deposit
  pfDatabase:AddCustomIcon(-1734, "img\\tracking\\mines\\Gold") -- Gold Vein
  pfDatabase:AddCustomIcon(-73941, "img\\tracking\\mines\\Gold") -- Ooze Covered Gold Vein
  pfDatabase:AddCustomIcon(-2040, "img\\tracking\\mines\\Mithril") -- Mithril Deposit
  pfDatabase:AddCustomIcon(-123310,"img\\tracking\\mines\\Mithril") -- Ooze Covered Mithril Deposit
  pfDatabase:AddCustomIcon(-2047, "img\\tracking\\mines\\TrueSilver") -- Truesilver Deposit
  pfDatabase:AddCustomIcon(-123309,"img\\tracking\\mines\\TrueSilver") -- Ooze Covered Truesilver Deposit
  pfDatabase:AddCustomIcon(-324, "img\\tracking\\mines\\Thorium") -- Small Thorium Vein
  pfDatabase:AddCustomIcon(-123848, "img\\tracking\\mines\\Thorium") -- Ooze Covered Thorium Vein
  pfDatabase:AddCustomIcon(-180215, "img\\tracking\\mines\\Thorium") -- Hakkari Thorium Vein
  pfDatabase:AddCustomIcon(-175404, "img\\tracking\\mines\\RichThorium") -- Rich Thorium Vein
  pfDatabase:AddCustomIcon(-177388, "img\\tracking\\mines\\RichThorium") -- Ooze Covered Rich Thorium Vein
  pfDatabase:AddCustomIcon(-165658, "img\\tracking\\mines\\DarkIron") -- Dark Iron Deposit
  pfDatabase:AddCustomIcon(-2653, "img\\tracking\\mines\\LesserBloodstone") -- Lesser Bloodstone Deposit
  pfDatabase:AddCustomIcon(-181555, "img\\tracking\\mines\\FelIron") -- Fel Iron Deposit
  pfDatabase:AddCustomIcon(-181556, "img\\tracking\\mines\\Adamantite") -- Adamantite Deposit
  pfDatabase:AddCustomIcon(-181569, "img\\tracking\\mines\\Adamantite") -- Rich Adamantite Deposit
  pfDatabase:AddCustomIcon(-181557, "img\\tracking\\mines\\Khorium") -- Khorium Vein
  pfDatabase:AddCustomIcon(-185877, "img\\tracking\\mines\\Nethercite") -- Nethercite Deposit
end

do -- /db track herbs
  pfDatabase:AddCustomIcon(-142141, "img\\tracking\\herbs\\ArthasTears") -- Arthas' Tears
  pfDatabase:AddCustomIcon(-176589, "img\\tracking\\herbs\\BlackLotus") -- Black Lotus
  pfDatabase:AddCustomIcon(-142143, "img\\tracking\\herbs\\Blindweed") -- Blindweed
  pfDatabase:AddCustomIcon(-1621, "img\\tracking\\herbs\\Briarthorn") -- Briarthorn
  pfDatabase:AddCustomIcon(-1622, "img\\tracking\\herbs\\Bruiseweed") -- Bruiseweed
  pfDatabase:AddCustomIcon(-176584, "img\\tracking\\herbs\\Dreamfoil") -- Dreamfoil
  pfDatabase:AddCustomIcon(-1619, "img\\tracking\\herbs\\Earthroot") -- Earthroot
  pfDatabase:AddCustomIcon(-2042, "img\\tracking\\herbs\\Fadeleaf") -- Fadeleaf
  pfDatabase:AddCustomIcon(-2866, "img\\tracking\\herbs\\Firebloom") -- Firebloom
  pfDatabase:AddCustomIcon(-142144, "img\\tracking\\herbs\\GhostMushroom") -- Ghost Mushroom
  pfDatabase:AddCustomIcon(-176583, "img\\tracking\\herbs\\GoldenSansam") -- Golden Sansam
  pfDatabase:AddCustomIcon(-2046, "img\\tracking\\herbs\\Goldthorn") -- Goldthorn
  pfDatabase:AddCustomIcon(-1628, "img\\tracking\\herbs\\GraveMoss") -- Grave Moss
  pfDatabase:AddCustomIcon(-142145, "img\\tracking\\herbs\\Gromsblood") -- Gromsblood
  pfDatabase:AddCustomIcon(-176588, "img\\tracking\\herbs\\Icecap") -- Icecap
  pfDatabase:AddCustomIcon(-2043, "img\\tracking\\herbs\\KhadgarsWhisker") -- Khadgar's Whisker
  pfDatabase:AddCustomIcon(-1624, "img\\tracking\\herbs\\Kingsblood") -- Kingsblood
  pfDatabase:AddCustomIcon(-2041, "img\\tracking\\herbs\\Liferoot") -- Liferoot
  pfDatabase:AddCustomIcon(-1620, "img\\tracking\\herbs\\Mageroyal") -- Mageroyal
  pfDatabase:AddCustomIcon(-176586, "img\\tracking\\herbs\\MountainSilversage") -- Mountain Silversage
  pfDatabase:AddCustomIcon(-1618, "img\\tracking\\herbs\\Peacebloom") -- Peacebloom
  pfDatabase:AddCustomIcon(-176587, "img\\tracking\\herbs\\Plaguebloom") -- Plaguebloom
  pfDatabase:AddCustomIcon(-142140, "img\\tracking\\herbs\\PurpleLotus") -- Purple Lotus
  pfDatabase:AddCustomIcon(-1617, "img\\tracking\\herbs\\Silverleaf") -- Silverleaf
  pfDatabase:AddCustomIcon(-2045, "img\\tracking\\herbs\\Stranglekelp") -- Stranglekelp
  pfDatabase:AddCustomIcon(-142142, "img\\tracking\\herbs\\Sungrass") -- Sungrass
  pfDatabase:AddCustomIcon(-1623, "img\\tracking\\herbs\\WildSteelbloom") -- Wild Steelbloom
  pfDatabase:AddCustomIcon(-2044, "img\\tracking\\herbs\\Wintersbite") -- Wintersbite
  pfDatabase:AddCustomIcon(-181270, "img\\tracking\\herbs\\Felweed") -- Felweed
  pfDatabase:AddCustomIcon(-181271, "img\\tracking\\herbs\\DreamingGlory") -- Dreaming Glory
  pfDatabase:AddCustomIcon(-181166, "img\\tracking\\herbs\\Stranglekelp") -- Bloodthistle
  pfDatabase:AddCustomIcon(-181275, "img\\tracking\\herbs\\Ragveil") -- Ragveil
  pfDatabase:AddCustomIcon(-181276, "img\\tracking\\herbs\\FlameCap") -- Flame Cap
  pfDatabase:AddCustomIcon(-181277, "img\\tracking\\herbs\\Terocone") -- Terocone
  pfDatabase:AddCustomIcon(-181278, "img\\tracking\\herbs\\AncientLichen") -- Ancient Lichen
  pfDatabase:AddCustomIcon(-181279, "img\\tracking\\herbs\\Netherbloom") -- Netherbloom
  pfDatabase:AddCustomIcon(-181280, "img\\tracking\\herbs\\NightmareVine") -- Nightmare Vine
  pfDatabase:AddCustomIcon(-181281, "img\\tracking\\herbs\\ManaThistle") -- Mana Thistle
  pfDatabase:AddCustomIcon(-185881, "img\\tracking\\herbs\\Netherdust") -- Netherdust Bush
  pfDatabase:AddCustomIcon(-157936, "img\\tracking\\herbs\\GraveMoss") -- Un'Goro Dirt Pile
end

do -- /db track chests
  pfDatabase:AddCustomIcon(-2039, "img\\tracking\\chests\\Chest") -- Hidden Strongbox
  pfDatabase:AddCustomIcon(-2744, "img\\tracking\\chests\\Clam") -- Giant Clam
  pfDatabase:AddCustomIcon(-2843, "img\\tracking\\chests\\Chest") -- Battered Chest
  pfDatabase:AddCustomIcon(-2844, "img\\tracking\\chests\\Chest") -- Tattered Chest
  pfDatabase:AddCustomIcon(-2850, "img\\tracking\\chests\\Chest") -- Solid Chest
  pfDatabase:AddCustomIcon(-3658, "img\\tracking\\chests\\Barrel") -- Water Barrel
  pfDatabase:AddCustomIcon(-3659, "img\\tracking\\chests\\Barrel") -- Barrel of Melon Juice
  pfDatabase:AddCustomIcon(-3660, "img\\tracking\\chests\\Crate") -- Armor Crate
  pfDatabase:AddCustomIcon(-3661, "img\\tracking\\chests\\Crate") -- Weapon Crate
  pfDatabase:AddCustomIcon(-3662, "img\\tracking\\chests\\Crate") -- Food Crate
  pfDatabase:AddCustomIcon(-3705, "img\\tracking\\chests\\Barrel") -- Barrel of Milk
  pfDatabase:AddCustomIcon(-3706, "img\\tracking\\chests\\Barrel") -- Barrel of Sweet Nectar
  pfDatabase:AddCustomIcon(-3714, "img\\tracking\\chests\\Chest") -- Alliance Strongbox
  pfDatabase:AddCustomIcon(-19019, "img\\tracking\\chests\\Crate") -- Box of Assorted Parts
  pfDatabase:AddCustomIcon(-142191, "img\\tracking\\chests\\Crate") -- Horde Supply Crate
  pfDatabase:AddCustomIcon(-176582, "img\\tracking\\chests\\ShellfishTrap") -- Shellfish Trap
  pfDatabase:AddCustomIcon(-178244, "img\\tracking\\chests\\Footlocker") -- Practice Lockbox
  pfDatabase:AddCustomIcon(-179486, "img\\tracking\\chests\\Footlocker") -- Battered Footlocker
  pfDatabase:AddCustomIcon(-179487, "img\\tracking\\chests\\Footlocker") -- Waterlogged Footlocker
  pfDatabase:AddCustomIcon(-179492, "img\\tracking\\chests\\Footlocker") -- Dented Footlocker
  pfDatabase:AddCustomIcon(-179493, "img\\tracking\\chests\\Footlocker") -- Mossy Footlocker
  pfDatabase:AddCustomIcon(-179498, "img\\tracking\\chests\\Footlocker") -- Scarlet Footlocker
  pfDatabase:AddCustomIcon(-176213, "img\\tracking\\chests\\BloodHero") -- Blood of Heroes
  pfDatabase:AddCustomIcon(-164881, "img\\tracking\\chests\\NightDragon") -- Cleansed Night Dragon
  pfDatabase:AddCustomIcon(-164882, "img\\tracking\\chests\\Songflower") -- Cleansed Songflower
  pfDatabase:AddCustomIcon(-164883, "img\\tracking\\chests\\WhipperRoot") -- Cleansed Whipper Root
  pfDatabase:AddCustomIcon(-164884, "img\\tracking\\chests\\WindBlossom") -- Cleansed Windblossom
  pfDatabase:AddCustomIcon(-182053, "img\\tracking\\chests\\Glowcap") -- Glowcap
  pfDatabase:AddCustomIcon(-74447, "img\\tracking\\chests\\Chest") -- Large Iron Bound Chest
  pfDatabase:AddCustomIcon(-74448, "img\\tracking\\chests\\Chest") -- Large Solid Chest
  pfDatabase:AddCustomIcon(-75293, "img\\tracking\\chests\\Chest") -- Large Battered Chest
  pfDatabase:AddCustomIcon(-131978, "img\\tracking\\chests\\Chest") -- Large Mithril Bound Chest
  pfDatabase:AddCustomIcon(-131979, "img\\tracking\\chests\\Chest") -- Large Darkwood Chest
  pfDatabase:AddCustomIcon(-184930, "img\\tracking\\chests\\Chest") -- Solid Fel Iron Chest
  pfDatabase:AddCustomIcon(-184931, "img\\tracking\\chests\\Chest") -- Bound Fel Iron Chest
  pfDatabase:AddCustomIcon(-184936, "img\\tracking\\chests\\Chest") -- Bound Adamantite Chest
  pfDatabase:AddCustomIcon(-184939, "img\\tracking\\chests\\Chest") -- Solid Adamantite Chest
  pfDatabase:AddCustomIcon(-28604, "img\\tracking\\chests\\Crate") -- Scattered Crate
  pfDatabase:AddCustomIcon(-185915, "img\\tracking\\chests\\Egg") -- Netherwing Egg
  pfDatabase:AddCustomIcon(-123330, "img\\tracking\\chests\\Footlocker") -- Buccaneer's Strongbox
  pfDatabase:AddCustomIcon(-181665, "img\\tracking\\chests\\Footlocker") -- Burial Chest
  pfDatabase:AddCustomIcon(-184793, "img\\tracking\\chests\\Footlocker") -- Primitive Chest
  pfDatabase:AddCustomIcon(-184740, "img\\tracking\\chests\\Footlocker") -- Wicker Chest
  pfDatabase:AddCustomIcon(-181798, "img\\tracking\\chests\\Chest") -- Fel Iron Chest
  pfDatabase:AddCustomIcon(-181800, "img\\tracking\\chests\\Chest") -- Heavy Fel Iron Chest
  pfDatabase:AddCustomIcon(-181802, "img\\tracking\\chests\\Chest") -- Adamantite Bound Chest
  pfDatabase:AddCustomIcon(-181804, "img\\tracking\\chests\\Chest") -- Felsteel Chest
end