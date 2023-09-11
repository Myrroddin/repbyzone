-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local _G = _G
local LibStub = _G.LibStub
local UnitFactionGroup = _G.UnitFactionGroup

------------------- Get addon reference --------------------
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"

function RepByZone:ZoneAndFactionList()
    -- UImapID = factionID
    -- If an UImapID is not listed, that zone has no associated factionID
    -- see https://wow.gamepedia.com/UiMapID/Classic for the Classic list of UImapIDs
    -- see https://wow.gamepedia.com/FactionID for the list of factionIDs

    local zonesAndFactions = {
        --------- Horde ----------
        [1411]      = 76,       -- Durotar/Orgrimmar
        [1454]      = 76,       -- Orgrimmar/Orgrimmar
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
        [1437]      = 47,       -- Wetlands/Ironforge
        [1419]      = 72,       -- Blasted Lands/Stormwind
        [1426]      = 47,       -- Dun Morogh/Ironforge
        [1432]      = 47,       -- Loch Modan/Ironforge
        [1455]      = 47,       -- Ironforge/Ironforge
        [1457]      = 69,       -- Darnassus/Darnassus
        [1438]      = 69,       -- Teldrassil/Darnassus
        [1439]      = 69,       -- Darkshore/Darnassus
        [1450]      = 609,      -- Moonglade/Cenarion Circle

        --------- Both ---------
        [1422]      = 529,      -- Western Plaguelands/Argent Dawn
        [1423]      = 529,      -- Eastern Plaguelands/Argent Dawn
        [1427]      = 59,       -- Searing Gorge/Thorium Brotherhood
        [1446]      = 369,      -- Tanaris/Gadgetzan
        [1451]      = 609,      -- Silithus/Cenarion Circle
        [1452]      = 577,      -- Winterspring/Everlook
        [1425]      = A and 471 or H and 530, -- The Hinterlands/Wildhammer Clan or Darkspear Trolls
        [1431]      = A and 72 or H and 68, -- Duskwood/Stormwind or Undercity
        [1440]      = A and 69 or H and 76, -- Ashenvale/Darnassus or Orgrimmar
        [1444]      = A and 69 or H and 81, -- Feralas/Darnassus or Thunder Bluff
        [1413]      = A and 470 or H and 81, -- The Barrens/Ratchet or Thunder Bluff
        [1417]      = A and 509 or H and 68, -- Arathi Highlands/The League of Arathor or Undercity
        [1424]      = A and 72 or H and 68, -- Hillsbrad Foothills/Stormwind/Undercity
        [1416]      = A and 72 or H and 76, -- Alterac Mountains/Stormwind or Orgrimmar
        [1418]      = A and 47 or H and 76, -- Badlands/Ironforge or Orgrimmar
        [1428]      = A and 47 or H and 530, -- Burning Steppes/Ironforge or Darkspear Trolls
        [1434]      = A and 72 or H and 76, -- Stranglethorn Vale/Stormwind or Orgrimmar
        [1435]      = A and 72 or H and 76, -- Swamp of Sorrows/Stormwind or Orgrimmar
        [1441]      = A and 69 or H and 81, -- Thousand Needles/Darnassus or Thunder Bluff
        [1442]      = A and 69 or H and 81, -- Stonetalon Mountains/Darnassus or Thunder Bluff
        [1443]      = A and 72 or H and 81, -- Desolace/Stormwind or Thunder Bluff
        [1445]      = A and 72 or H and 76, -- Dustwallow Marsh/Stormwind or Orgrimmar
        [1447]      = A and 69 or H and 76, -- Azshara/Darnassus or Orgrimmar
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
        [33]        = A and 72  or H and 68, -- Shadowfang Keep/Undercity
        [34]        = 72, -- The Stockades/Stormwind
        [36]        = 72, -- The Deadmines/Stormwind
        [43]        = 81, -- Wailing Caverns/Thunder Bluff
        [47]        = A and 69 or H and 81, -- Razorfen Kraul/Darnassus or Thunderbluff
        [48]        = A and 69 or H and 530, -- Blackfathom Deeps/Darnassus or Darkspear Trolls
        [70]        = A and 47 or H and 530, -- Uldaman/Ironforge or Darkspear Trolls
        [90]        = 54, -- Gnomeregan/Gnomeregan Exiles
        [109]       = 270, -- Temple of Atal'Hakkar (Sunken Temple)/Zandalar Tribe
        [129]       = A and 72 or H and 76, -- Razorfen Downs/Stormwind or Orgrimmar
        [209]       = A and 471 or H and 530, -- Zul'Farrak/Wildhammer Clan or Darkspear Trolls
        [229]       = A and 72 or H and 76, -- Blackrock Spire/Stormwind or Orgrimmar
        [230]       = 59, -- Blackrock Depths/Thorium Brotherhood
        [329]       = 529, -- Strathholme/Argent Dawn
        [349]       = 609, -- Maraudon/Cenarion Circle
        [389]       = 76, -- Ragefire Chasm/Orgrimmar
        [429]       = 809, -- Dire Maul/Shen'dralar
        [1001]      = 529, -- Scarlet Halls/Argent Dawn
        [1004]      = 529, -- Scarlet Monastary/Argent Dawn
        [1007]      = 529, -- Scholomance/Argent Dawn

        ----------- Battlegrounds ----------
        [30]        = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [529]       = A and 509 or H and 510, -- Arathi Basin/The Leage of Arathor or The Defilers
        [589]       = A and 890 or H and 889, -- Warsong Gulch/Silverwing Sentinels or Warsong Outriders

        ---------- Raids -----------
        [249]       = A and 72 or H and 76, -- Onyxia's Lair/Stormwind or Orgrimmar
        [309]       = 270, -- Zul'Gurub/Zandalar Tribe
        [409]       = 749, -- Molten Core/Hydraxian Waterlords
        [469]       = A and 72 or H and 76, -- Blackwing Lair/Stormwind or Orgrimmar
        [509]       = 609, -- Ruins of Ahn'Qiraj/Cenarion Circle
        [531]       = 910, -- Temple of Ahn'Qiraj/Brood of Nozdormu
        [533]       = 529, -- Naxxramas/Argent Dawn
    }
    return instancesAndFactions
end

function RepByZone:SubZonesAndFactionsList()
    local subZonesAndFactions = {
		-- areaID = factionID
		-- see https://wow.tools/dbc/?dbc=areatable&build=1.13.3.32887#search=&page=1

        [35] = 21, -- Booty Bay/Booty Bay
        [36] = A and 730 or H and 729, -- Alterac Mountains/Stormpike Guard or Frostwolf Clan
        [100] = 47, -- Nesingwary's Expedition/Ironforge
        [122] = 270, -- Zuuldaia Ruins/Zandalar Tribe
        [125] = 270, -- Kal'ai Ruins/Zandalar Tribe
        [128] = 270, -- Ziata'jai Ruins/Zandalar Tribe
        [133] = 54, -- Gnomeregan/Gnomeregan Exiles
		[150] = 72, -- Menethil Harbor/Stormwind
        [193] = A and 72 or H and 68, -- Ruins of Andorhal/Stormwind or Undercity
        [196] = 72, -- Uthor's Tomb/Stormwind
		[197] = 72, -- Sorrow Hill/Stormwind
        [280] = 349, -- Strahnbrad/Ravenholdt
        [288] = 72, -- Azurelode Mine/Stormwind
		[297] = 81, -- Jaguero Isle/Thunder Bluff
		[299] = 72, -- Menethil Bay/Stormwind
        [311] = 270, -- Ruins of Aboraz/Zandalar Tribe
        [313] = 349, -- Northfold Manor/Ravenholdt
        [320] = 72, -- Refuge Pointe/Stormwind
        [327] = 21, -- Faldir's Cove/Booty Bay
        [328] = 21, -- The Drowned Reef/Booty Bay
        [350] = 69, -- Quel'Danil Lodge/Darnassus
		[359] = H and 81 or A and 47, -- Bael Modan/Thunder Bluff or Ironforge
        [367] = 530, -- Sen'jen Village/Darkspear Trolls
        [368] = 530, -- Echo Isles/Darkspear Trolls
        [392] = 470, -- Ratchet/Ratchet
        [393] = 530, -- Darkspear Strand/Darkspear Trolls
        [439] = A and 54 or H and 76, -- The Shimmering Flats/Gnomeregan Exiles or Orgrimmar
        [477] = 270, -- Ruins of Jubuwal/Zandalar Tribe
        [484] = H and 81 or A and 69, -- Freewind Post/Thunder Bluff or Darnassus
		[596] = 470, -- Kodo Graveyard/Ratchet
        [604] = 93, -- Magram Village/Magram Clan Centaur
        [606] = 92, -- Gelkis Village/Gelkis Clan Centaur
        [702] = 69, -- Rut'theran Village/Darnassus
        [813] = 529, -- The Bulwark/Argent Dawn
        [880] = 471, -- Thandol Span (Arathi Highlands)/Wildhammer Clan
        [881] = 47, -- Thandol Span (Wetlands)/Ironforge
        [896] = A and 730 or H and 729, -- Purgation Isle/Stormpike Guard or Frostwolf Clan
        [1016] = 69, -- Direforge Hill/Darnassus
        [1025] = 69, -- The Green Belt/Darnassus
        [1057] = A and 47 or H and 68, -- Thoradin's Wall (Hillsbrad Foothills)/Ironforge or Undercity
        [1216] = 579, -- Timbermaw Hold/Timbermaw Hold
        [1446] = 59, -- Thorium Point/Thorium Brotherhood
        [1677] = A and 730 or H and 729, -- Gavin's Naze/Stormpike Guard or Frostwolf Clan
        [1679] = A and 730 or H and 729, -- Corrahn's Dagger/Stormpike Guard or Frostwolf Clan
        [1680] = A and 730 or H and 729, -- The Headland/Stormpike Guard or Frostwolf Clan
		[1658] = A and 609, -- Cenarion Enclave/Cenarion Circle
        [1678] = 72, -- Sofera's Naze/Stormwind
		[1739] = 87, -- Bloodsail Compound/Bloodsail Buccaneers
        [1741] = 87, -- Gurubashi Arena/Bloodsail Buccaneers
        [1761] = 579, -- Deadwood Village/Timbermaw Hold
        [1762] = 579, -- Felpaw Village/Timbermaw Hold
        [1857] = A and 47 or H and 68, -- Thoradin's Wall (Arathi Highlands)/Ironforge or Undercity
		[1977] = 309, -- Zul'Gurub/Zandalar Tribe
		[2097] = H and 81 or A and 69, -- Darkcloud Pinnacle/Thunder Bluff or Darnassus
		[2157] = H and 81 or A and 47, -- Bael'dun Keep/Thunder Bluff or Ironforge
		[2240] = A and 54 or H and 76, -- Mirage Raceway/Gnomeregan Exiles or Orgrimmar
        [2241] = A and 589, -- Frostsaber Rock/Wintersaber Trainers
        [2243] = 579, -- Timbermaw Post/Timbermaw Hold
        [2244] = 579, -- Winterfall Village/Timbermaw Hold
        [2246] = 579, -- Frostfire Hot Springs/Timbermaw Hold
        [2257] = 72, -- Deeprun Tram/Stormwind
        [2405] = 529, -- Ethel Rethor/Argent Dawn
        [2406] = 69, -- Ranazjar Isle/Darnassus
        [2407] = 470, -- Kormek's Hut/Ratchet
        [2408] = 530, -- Shadowprey Village/Darkspear Trolls
        [2597] = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [2617] = 470, -- Scrabblescrew's Camp/Ratchet
        [2897] = 530, -- Zoram'gar Outpost/Darkspear Trolls
		[3197] = 72, -- Chillwind Camp/Stormwind
        [3357] = 270, -- Yojamba Isle/Zandalar Tribe
        [3456] = 529, -- Naxxramas/Argent Dawn
        [3486] = 349, -- Ravenholdt Manor/Ravenholdt
    }
    return subZonesAndFactions
end