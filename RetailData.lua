local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"

function RepByZone:ZoneAndFactionList()
    -- UImapID = factionID
    -- If an UImapID is not listed, that zone has no associated factionID
    -- see https://wow.gamepedia.com/UiMapID for the list of UImapIDs
    -- see https://wow.gamepedia.com/FactionID for the list of factionIDs

    local covenantRepID = self.covenantRepID
    local db = self.db.char

    local zonesAndFactions = {
        --------- Vanilla ----------
        [1]         = 46,       -- Durotar/Orgrimmar
        [85]        = 46,       -- Orgrimmar/Orgrimmar
        [88]        = 81,       -- Thunder Bluff/Thunder Bluff
        [7]         = 81,       -- Mulgore/Thunder Bluff
        [84]        = 72,       -- Stormwind City/Stormwind
        [37]        = 72,       -- Elwynn Forest/Stormwind
        [52]        = 72,       -- Westfall/Stormwind
        [87]        = 47,       -- Ironforge/Ironforge
        [27]        = 47,       -- Dun Morogh/Ironforge
        [32]        = 47,       -- Searing Gorge/Ironforge
        [48]        = 47,       -- Loch Modan/Ironforge
        [89]        = 69,       -- Darnassus/Darnassus
        [57]        = 69,       -- Teldrassil/Darnassus
        [62]        = 69,       -- Darkshore/Darnassus
        [90]        = 68,       -- Undercity/Undercity
        [18]        = 68,       -- Tirisfal Glades/Undercity
        [21]        = 68,       -- Silverpine Forest/Undercity
        [30]        = 54,       -- New Tinkertown/Gnomeregan
        [41]        = 1090,     -- Dalaran/Kirin Tor
        [80]        = 609,      -- Moonglade/Cenarion Circle
        [81]        = 609,      -- Silithus/Cenarion Circle
        [74]        = 989,      -- Timeless Tunnel/Keepers of Time
        [75]        = 989,      -- Caverns of Time/Keepers of Time
        [22]        = 529,      -- Western Plaguelands/Argent Dawn
        [23]        = 529,      -- Eastern Plaguelands/Argent Dawn
        [71]        = 369,      -- Tanaris/Gadgetzan
        [83]        = 577,      -- Winterspring/Everlook
        [15]        = A and 47 or H and 46,     -- Badlands/Ironforge or Orgrimmar
        [47]        = A and 72 or H and 68,     -- Duskwood/Stormwind or Undercity
        [76]        = A and 69 or H and 1133,   -- Azshara/Darnassus or Bilgewater Cartel
        --[[
        [1411]      = 46,       -- Durotar/Orgrimmar
        [1454]      = 46,       -- Orgrimmar/Orgrimmar
        [1412]      = 81,       -- Mulgore/Thunder Bluff
        [1456]      = 81,       -- Thunder Bluff/Thunder Bluff
        [1421]      = 68,       -- Silverpine Forest/Undercity
        [1458]      = 68,       -- Undercity/Undercity
        [1420]      = 68,       -- Tirisfal Glades/Undercity
        [1453]      = 72,       -- Stormwind City/Stormwind
        [1429]      = 72,       -- Elwynn Forest/Stormwind
        [1436]      = 72,       -- Westfall/Stormwind
        [1433]      = 72,       -- Redridge Mountains/Stormwind
        [1437]      = 47,       -- Wetlands/Ironforge
        [1419]      = 72,       -- Blasted Lands/Stormwind
        [1426]      = 47,       -- Dun Morogh/Ironforge
        [1432]      = 47,       -- Loch Modan/Ironforge
        [1455]      = 47,       -- Ironforge/Ironforge
        [1427]      = 47,       -- Searing Gorge/Ironforge
        [1457]      = 69,       -- Darnassus/Darnassus
        [1438]      = 69,       -- Teldrassil/Darnassus
        [1439]      = 69,       -- Darkshore/Darnassus
        [1450]      = 609,      -- Moonglade/Cenarion Circle
        [1422]      = 529,      -- Western Plaguelands/Argent Dawn
        [1423]      = 529,      -- Eastern Plaguelands/Argent Dawn
        [1446]      = 369,      -- Tanaris/Gadgetzan
        [1451]      = 609,      -- Silithus/Cenarion Circle
        [1452]      = 577,      -- Winterspring/Everlook
        [1425]      = A and 1174 or H and 530, -- The Hinterlands/Wildhammer Clan or Darkspear Trolls
        [1431]      = A and 72 or H and 68, -- Duskwood/Stormwind or Undercity
        [1440]      = A and 69 or H and 46, -- Ashenvale/Darnassus or Orgrimmar
        [1444]      = A and 69 or H and 81, -- Feralas/Darnassus or Thunder Bluff
        [1413]      = A and 470 or H and 81, -- The Barrens/Ratchet or Thunder Bluff
        [1417]      = A and 72 or H and 530, -- Arathi Highlands/Stormwind or Darkspear Trolls
        [1424]      = A and 72 or H and 68, -- Hillsbrad Foothills/Stormwind/Undercity
        [1416]      = A and 72 or H and 46, -- Alterac Mountains/Stormwind or Orgrimmar
        [1418]      = A and 47 or H and 46, -- Badlands/Ironforge or Orgrimmar
        [1428]      = A and 47 or H and 530, -- Burning Steppes/Ironforge or Darkspear Trolls
        [1438]      = A and 72 or H and 76, -- Stranglethorn Vale/Stormwind or Orgrimmar
        [1435]      = A and 72 or H and 46, -- Swamp of Sorrows/Stormwind or Orgrimmar
        [1441]      = A and 69 or H and 81, -- Thousand Needles/Darnassus or Thunder Bluff
        [1442]      = A and 69 or H and 81, -- Stonetalon Mountains/Darnassus or Thunder Bluff
        [1443]      = A and 72 or H and 81, -- Desolace/Stormwind or Thunder Bluff
        [1445]      = A and 72 or H and 46, -- Dustwallow Marsh/Stormwind or Orgrimmar
        [1447]      = A and 69 or H and 46, -- Azshara/Darnassus or Orgrimmar
        [1448]      = A and 69 or H and 68, -- Felwood/Darnassus or Undercity
        ]]--

        --------- Cataclysm ---------
        [5861]      = 909,      -- Darkmoon Island/Darkmoon Faire

        --------- Legion ---------
        [787]       = 609,      -- Moonglade/Cenarion Circle

        --------- BfA ---------
        [1264]      = 72,       -- Stormwind City/Stormwind
        [1535]      = 46,       -- Durotar/Orgrimmar
        [1462]      = 2391      -- Mechagon Island/Rustbolt Resistance
        [1330]      = 2417,     -- Uldum/Uldum Accord
        [1570]      = 2415,     -- Vale of Eternal Blossoms/Rajani
        [864]       = A and 2159 or H and 2382, -- Vol'dun/7th Legion or Voldunai
        [1193]      = A and 2159 or H and 2378, -- Zuldazar/7th Legion or Zandalari Empire
        [863]       = A and 2159 or H and 2380, -- Nazmir/7th Legion or Talanji's Expedition
        [895]       = A and 2160 or H and 2157, -- Tiragarde Sound/Proudmore Admiralty or The Honorbound
        [896]       = A and 2383 or H and 2157, -- Drustvar/Order of Embers or The Honorbound
        [942]       = A and 2381 or H and 2157, -- Stormsong Valley/Storm's Wake or The Honorbound
        [1355]      = A and 2401 or H and 2373, -- Nazjatar/Waveblade Ankoan or The Unshackled

        --------- Shadowlands ---------
        [1740]      = 2422,     -- Ardenweald/Night Fae
        [1525]      = 2413,     -- Revendreth/Court of Harvesters
        [1569]      = 2407,     -- Bastion/The Ascended
        [1536]      = 2410,     -- Maldraxxus/The Undying Army
        [1543]      = 2432,     -- The Maw/Ve'nari
        -- Oribos has 4 UiMapIDs depending on where in the city you are
        [1670]      = covenantRepID, -- Ring of Fates/Covenant
        [1671]      = covenantRepID, -- Ring of Transference/Covenant
        [1672]      = covenantRepID, -- The Broker's Den/Covenant
        [1673]      = covenantRepID, -- The Crucible/Covenant
    }
    return zonesAndFactions
end

function RepByZone:SubZonesAndFactions()
    local covenantRepID = self.covenantRepID
    local db = self.db.char

    local subZonesAndFactions = {
		-- areaID = factionID
        -- see https://wow.tools/dbc/?dbc=areatable&build=9.0.2.36949#page=1

        --------- Vanilla ---------
        [35]        = 21, -- Booty Bay/Booty Bay
        [36]        = A and 730 or H and 729, -- Alterac Mountains/Stormpike Guard or Frostwolf Clan
        [100]       = 47, -- Nesingwary's Expedition/Ironforge
        [122]       = 270, -- Zuuldaia Ruins/Zandalar Tribe
        [125]       = 270, -- Kal'ai Ruins/Zandalar Tribe
        [128]       = 270, -- Ziata'jai Ruins/Zandalar Tribe
        [133]       = 54, -- Gnomeregan/Gnomeregan
		[150]       = 72, -- Menethil Harbor/Stormwind
        [193]       = A and 72 or H and 68, -- Ruins of Andorhal/Stormwind or Undercity
        [196]       = 72, -- Uthor's Tomb/Stormwind
        [197]       = 72, -- Sorrow Hill/Stormwind
        [204]       = 1134, -- Pyrewood Village/Gilneas
        [233]       = 1134, -- Ambermill/Gilneas
        [280]       = 349, -- Strahnbrad/Ravenholdt
        [288]       = 72, -- Azurelode Mine/Stormwind
		[297]       = 81, -- Jaguero Isle/Thunder Bluff
		[299]       = 72, -- Menethil Bay/Stormwind
        [311]       = 270, -- Ruins of Aboraz/Zandalar Tribe
        [313]       = 349, -- Northfold Manor/Ravenholdt
        [324]       = 349, -- Stromgarde Keep/Ravenholdt
        [327]       = 21, -- Faldir's Cove/Booty Bay
        [328]       = 21, -- The Drowned Reef/Booty Bay
        [350]       = 69, -- Quel'Danil Lodge/Darnassus
		[359]       = H and 81 or A and 47, -- Bael Modan/Thunder Bluff or Ironforge
        [367]       = 530, -- Sen'jen Village/Darkspear Trolls
        [368]       = 530, -- Echo Isles/Darkspear Trolls
        [392]       = 470, -- Ratchet/Ratchet
        [393]       = 530, -- Darkspear Strand/Darkspear Trolls
        [439]       = A and 54 or H and 76, -- The Shimmering Flats/Gnomeregan or Orgrimmar
        [477]       = 270, -- Ruins of Jubuwal/Zandalar Tribe
        [484]       = H and 81 or A and 69, -- Freewind Post/Thunder Bluff or Darnassus
		[596]       = 470, -- Kodo Graveyard/Ratchet
        [604]       = 93, -- Magram Village/Magram Clan Centaur
        [606]       = 92, -- Gelkis Village/Gelkis Clan Centaur
        [702]       = 69, -- Rut'theran Village/Darnassus
        [813]       = 529, -- The Bulwark/Argent Dawn
        [896]       = A and 730 or H and 729, -- Purgation Isle/Stormpike Guard or Frostwolf Clan
        [1016]      = 69, -- Direforge Hill/Darnassus
        [1019]      = 69, -- The Green Belt/Darnassus
        [1216]      = 579, -- Timbermaw Hold/Timbermaw Hold
        [1336]      = A and 54 or H and 1133, -- Lost Rigger Cove/Gnomeregan or Bilgewater Cartel
        [1446]      = 59, -- Thorium Point/Thorium Brotherhood
		[1658]      = 609, -- Cenarion Enclave/Cenarion Circle
        [1677]      = A and 730 or H and 729, -- Gavin's Naze/Stormpike Guard or Frostwolf Clan
        [1679]      = A and 730 or H and 729, -- Corrahn's Dagger/Stormpike Guard or Frostwolf Clan
        [1680]      = A and 730 or H and 729, -- The Headland/Stormpike Guard or Frostwolf Clan
        [1678]      = 72, -- Sofera's Naze/Stormwind
		[1739]      = 87, -- Bloodsail Compound/Bloodsail Buccaneers
        [1741]      = 87, -- Gurubashi Arena/Bloodsail Buccaneers
        [1761]      = 579, -- Deadwood Village/Timbermaw Hold
        [1762]      = 579, -- Felpaw Village/Timbermaw Hold
		[1858]      = 1174, -- Boulder'gor/Wildhammer Clan
		[1977]      = 309, -- Zul'Gurub/Zandalar Tribe
		[2097]      = H and 81 or A and 69, -- Darkcloud Pinnacle/Thunder Bluff or Darnassus
		[2157]      = H and 81 or A and 47, -- Bael'dun Keep/Thunder Bluff or Ironforge
		[2240]      = A and 54 or H and 76, -- Mirage Raceway/Gnomeregan or Orgrimmar
        [2241]      = 589, -- Frostsaber Rock/Wintersaber Trainers
        [2243]      = 579, -- Timbermaw Post/Timbermaw Hold
        [2244]      = 579, -- Winterfall Village/Timbermaw Hold
        [2246]      = 579, -- Frostfire Hot Springs/Timbermaw Hold
        [2257]      = 72, -- Deeprun Tram/Stormwind
        [2405]      = 529, -- Ethel Rethor/Argent Dawn
        [2406]      = 69, -- Ranazjar Isle/Darnassus
        [2407]      = 470, -- Kormek's Hut/Ratchet
        [2408]      = 530, -- Shadowprey Village/Darkspear Trolls
        [2597]      = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [2617]      = 470, -- Scrabblescrew's Camp/Ratchet
        [2897]      = 530, -- Zoram'gar Outpost/Darkspear Trolls
		[3197]      = 72, -- Chillwind Camp/Stormwind
        [3357]      = 270, -- Yojamba Isle/Zandalar Tribe
        [3486]      = 349, -- Ravenholdt Manor/Ravenholdt
        [4745]      = 76,   -- Orgrimmar Rear Gate/Orgrimmar
        [5476]      = 1134, -- Pyrewood Chapel/Gilneas
        [5477]      = 1134, -- Pyrewood Inn/Gilneas
        [5478]      = 1134, -- Pyrewood Town Hall/Gilneas
        [5480]      = 1134, -- Gilneas Liberation Base Camp/Gilneas
        [5481]      = 47, -- 7th Legion Base Camp/Ironforge
        [5687]      = 1134, -- The Howling Oak/Gilneas

        --------- BfA ---------
        [9310]      = 2386, -- The Wound/Champions of Azeroth
        [9329]      = 2387, -- Seeker's Outpost/Tortollan Seekers
        [9556]      = 2387,  -- Tortaka Refuge/Tortollan Seekers
        [9667]      = 2386, -- Chamber of Heart/Champions of Azeroth
        [9693]      = 2387, -- Seeker's Vista/Tortollan Seekers
        [9714]      = 2387, -- Seeker's Expedition/Tortollan Seekers
        [10006]     = 2387, -- House of Jol/Tortollan Seekers
        [10504]     = 2386, -- Chamber of Heart (rebuilt)/Champions of Azeroth

        --------- Shadowlands ---------
        [11533]     = 2465, -- Tirna Noch/The Wild Hunt
        [12858]     = 2465, -- Heart of the Forest/The Wild Hunt
        [12876]     = 2410,  -- Seat of the Primus/The Undying Army
        [13367]     = 2422, -- Queen's Conservatory/Night Fae
    }
    return subZonesAndFactions
end