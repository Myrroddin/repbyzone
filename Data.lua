local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"
local BS = LibStub and LibStub("LibBabble-SubZone-3.0", true) and LibStub("LibBabble-SubZone-3.0"):GetUnstrictLookupTable()

function RepByZone:ZoneAndFactionList()
    -- UImapID = factionID
    -- If an UImapID is not listed, that zone has no associated factionID
    -- see https://wow.gamepedia.com/UiMapID/Classic for the Classic list of UImapIDs
    -- see https://wow.gamepedia.com/FactionID for the list of factionIDs

    local zonesAndFactions = {
        --------- Horde ----------
        [1411]      = 46,       -- Durotar/Orgrimmar
        [1454]      = 46,       -- Orgrimmar/Orgrimmar
        [1412]      = 81,       -- Mulgore/Thunder Bluff
        [1456]      = 81,       -- Thunder Bluff/Thunder Bluff
        [1421]      = 68,       -- Silverpine Forest/Undercity
        [1458]      = 68,       -- Undercity/Undercity
        [1420]      = 68,       -- Tirisfal Glades/Undercity

        --------- Alliance ----------
        [1453]      = 72,       -- Stormwind City/Stormwind
        [1429]      = 72,       -- Elwynn Forest/Stormwind
        [1436]      = 72,       -- Westfall/Stormwind
        [1433]      = 72,       -- Redridge Mountains/Stormwind
        [1437]      = 75,       -- Wetlands/Stormwind
        [1419]      = 72,       -- Blasted Lands/Stormwind
        [1426]      = 47,       -- Dun Morogh/Ironforge
        [1432]      = 47,       -- Loch Modan/Ironforge
        [1455]      = 47,       -- Ironforge/Ironforge
        [1427]      = 47,       -- Searing Gorge/Ironforge
        [1457]      = 69,       -- Darnassus/Darnassus
        [1438]      = 69,       -- Teldrassil/Darnassus
        [1439]      = 69,       -- Darkshore/Darnassus
        [1450]      = 69,       -- Moonglade/Darnassus

        --------- Both ---------
        [1422]      = 529,      -- Western Plaguelands/Argent Dawn
        [1423]      = 529,      -- Eastern Plaguelands/Argent Dawn
        [1446]      = 369,      -- Tanaris/Gadgetzan
        [1451]      = 609,      -- Silithus/Cenarion Circle
        [1452]      = 577,      -- Winterspring/Everlook
        [1425]      = A and 1174 or H and 530, -- The Hinterlands/Wildhammer Clan or Darkspear Trolls
        [1431]      = A and 72 or H and 68, -- Duskwood/Stormwind or Undercity
        [1440]      = A and 69 or H and 68, -- Ashenvale/Darnassus or Undercity
        [1444]      = A and 69 or H and 46, -- Feralas/Darnassus or Orgrimmar
        [1413]      = A and 72 or H and 81, -- The Barrens/Stormwind or Thunder Bluff
        [1417]      = A and 47 or H and 530, -- Arathi Highlands/Ironforge or Darkspear Trolls
        [1424]      = A and 72 or H and 68, -- Hillsbrad Foothills/Stormwind/Undercity
        [1416]      = A and 72 or H and 46, -- Alterac Mountains/Stormwind or Orgrimmar
        [1418]      = A and 47 or H and 46, -- Badlands/Ironforge or Orgrimmar
        [1428]      = A and 47 or H and 530, -- Burning Steppes/Ironforge or Darkspear Trolls
        [1438]      = A and 72 or H and 530, -- Stranglethorn Vale/Stormwind or Darkspear Trolls
        [1435]      = A and 72 or H and 46, -- Swamp of Sorrows/Stormwind or Orgrimmar
        [1441]      = A and 69 or H and 81, -- Thousand Needles/Darnassus or Thunder Bluff
        [1442]      = A and 54 or H and 81, -- Stonetalon Mountains/Gnomeregan Exiles orThunder Bluff
        [1443]      = A and 47 or H and 81, -- Desolace/Ironforge or Thunder Bluff
        [1445]      = A and 72 or H and 46, -- Dustwallow Marsh/Stormwind or Orgrimmar
        [1447]      = A and 47 or H and 46, -- Azshara/Ironforge or Orgrimmar
        [1448]      = A and 69 or H and 68, -- Felwood/Darnassus or Undercity

    }
    return zonesAndFactions
end

function RepByZone:InstancesAndFactionList()
    local instancesAndFactions = {
        -- instanceID = factionID
        -- If an instanceID is not listed, that instance has no associated factionID
        -- See https://wow.gamepedia.com/InstanceID for the list of instanceIDs

        --------- Dungeons ----------
        [34]        = 72, -- The Stockades/Stormwind
        [90]        = 54, -- Gnomeregan/Gnomeregan Exiles
        [389]       = 46, -- Ragefire Chasm/Orgrimmar
        [349]       = 609, -- Maraudon/Cenarion Circle
        [1001]      = 529, -- Scarlet Halls/Argent Dawn
        [1004]      = 529, -- Scarlet Monastary/Argent Dawn
        [1007]      = 529, -- Scholomance/Argent Dawn
        [33]        = 68, -- Shadowfang Keep/Undercity
        [329]       = 529, -- Strathholme/Argent Dawn
        [36]        = 72, -- The Deadmines/Stormwind
        [230]       = 59, -- Blackrock Depths/Thorium Brotherhood
        [109]       = 910, -- Temple of Atal'Hakkar (Sunken Temple)/Brood of Nozdormu
        [43]        = 81, -- Wailing Caverns/Thunder Bluff
        [129]       = A and 72 or H and 46, -- Razorfen Downs/Stormwind or Orgrimmar
        [47]        = A and 69 or H and 81, -- Razorfen Kraul/Darnassus or Thunderbluff
        [48]        = A and 69 or H and 530, -- Blackfathom Deeps/Darnassus or Darkspear Trolls
        [229]       = A and 72 or H and 46, -- Blackrock Spire/Stormwind or Orgrimmar
        [70]        = A and 47 or H and 530, -- Uldaman/Ironforge or Darkspear Trolls
        [209]       = A and 1174 or H and 530, -- Zul'Farrak/Wildhammer Clan or Darkspear Trolls

        ----------- Battlegrounds ----------
        [30]        = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [529]       = A and 509 or H and 510, -- Arathi Basin/The Leage of Arathor or The Defilers
        [589]       = A and 890 or H and 889, -- Warsong Gulch/Silverwing Sentinels or Warsong Outriders

        ---------- Raids -----------
        [409]       = 749, -- Molten Core/Hydraxian Waterlords
        [509]       = 910, -- Ruins of Ahn'Qiraj/Brood of Nozdormu
        [531]       = 910, -- Temple of Ahn'Qiraj/Brood of Nozdormu
        [469]       = A and 72 or H and 46, -- Blackwing Lair/Stormwind or Orgrimmar
    }
    return instancesAndFactions
end

function RepByZone:SubZonesAndFactions()
    local subZonesAndFactions = {
        [BS["Tinker Town"]] = 54, -- Gnomeregan Exiles
        [BS["Dwarven District"]] = 47, -- Ironforge
        [BS["Booty Bay"]] = 21, -- Booty Bay
        [BS["The Salty Sailor Tavern"]] = 21, -- Booty Bay
        [BS["Faldir's Cove"]] = 21, -- Booty Bay
        [BS["Deadwood Village"]] = 579, -- Timbermaw Hold
        [BS["Felpaw Village"]] = 579, -- Timbermaw Hold
        [BS["Timbermaw Hold"]] = 579, -- Timbermaw Hold
        [BS["Galen's Fall"]] = 68, -- Undercity
        [BS["Northfold Manor"]] = 349, -- Ravenholt
        [BS["Stromgarde Keep"]] = 349, -- Ravenholt
        [BS["The Drowned Reef"]] = 21, -- Booty Bay
        [BS["Ravenholdt Manor"]] = 349, -- Ravenholt
        [BS["Sofera's Naze"]] = A and 72, -- Stormwind
        [BS["Strahnbrad"]] = 349, -- Ravenholt
        [BS["Alterac Mountains"]] = A and 730 or H and 729, -- Stormpike Guard or Frostwolf Clan
        [BS["Alterac Valley"]] = A and 730 or H and 729, -- Stormpike Guard or Frostwolf Clan
        [BS["Azurelode Mine"]] = 72, -- Stormwind
        [BS["Corrahn's Dagger"]] = A and 730 or H and 729, -- Stormpike Guard or Frostwolf Clan
        [BS["Gavin's Naze"]] = A and 730 or H and 729, -- Stormpike Guard or Frostwolf Clan
        [BS["Purgation Isle"]] = A and 730 or H and 729, -- Stormpike Guard or Frostwolf Clan
        [BS["The Headland"]] = A and 730 or H and 729, -- Stormpike Guard or Frostwolf Clan
        [BS["Thorium Point"]] = 59, -- Thorium Brotherhood
        [BS["Ruins of Taurajo"]] = H and 81, -- Thunder Bluff
		[BS["Spearhead"]] = H and 81, -- Thunder Bluff
		[BS["Vendetta Point"]] = H and 81, -- Thunder Bluff
		[BS["Bael Modan"]] = H and 81 or A and 47, -- Thunder Bluff or Ironforge
		[BS["Bael Modan Excavation"]] = H and 81 or A and 47, -- Thunder Bluff or Ironforge
		[BS["Bael'dun Keep"]] = H and 81 or A and 47, -- Thunder Bluff or Ironforge
		[BS["Frazzlecraz Motherlode"]] = A and 47, -- Ironforge
        [BS["Twinbraid's Patrol"]] = A and 47, -- Ironforge
        [BS["Arikara's Needle"]] = H and 81 or A and 69, -- Thunder Bluff or Darnassus
		[BS["Darkcloud Pinnacle"]] = H and 81 or A and 69, -- Thunder Bluff or Darnassus
        [BS["Freewind Post"]] = H and 81 or A and 69, -- Thunder Bluff or Darnassus
        [BS["The Bulwark"]] = 529, -- Argent Dawn
        [BS["Andorhal"]] = A and 72 or H and 68, -- Stormwind or Undercity
		[BS["Chillwind Camp"]] = A and 72, -- Stormwind
		[BS["Sorrow Hill"]] = A and 72, -- Stormwind
        [BS["Uther's Tomb"]] = A and 72, -- Stormwind
        [BS["Direforge Hill"]] = A and 69, -- Darnassus
		[BS["Greenwarden's Grove"]] = A and 69, -- Darnassus
		[BS["Menethil Harbor"]] = A and 72, -- Stormwind
        [BS["The Green Belt"]] = A and 69, -- Darnassus
        [BS["Frostfire Hot Springs"]] = 579, -- Timbermaw Hold
        [BS["Timbermaw Post"]] = 579, -- Timbermaw Hold
        [BS["Winterfall Village"]] = 579, -- Timbermaw Hold
        [BS["Frostsaber Rock"]] = A and 589, -- Wintersaber Trainers
        [BS["Dun Modr"]] = A and 47, -- Ironforge
        [BS["Gelkis Village"]] = 92, -- Gelkis Clan Centaur
        [BS["Magram Village"]] = 93, -- Magram Clan Centaur
    }
    return subZonesAndFactions
end