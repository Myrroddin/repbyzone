-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local LibStub = LibStub
local C_Map = C_Map
local UnitClassBase = UnitClassBase
local UnitFactionGroup = UnitFactionGroup

------------------- Get addon reference --------------------
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"

function RepByZone:ZoneAndFactionList()
    -- [UImapID] = factionID
    -- If an UImapID is not listed, that zone has no associated factionID
    -- see https://wow.tools/dbc/?dbc=uimap&build=2.5.1.38741#page=1 for the TBC Classic list of UImapIDs
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

        --------- TBC ---------
        [1941]      = 911,      -- Eversong Woods/Silvermoon City
        [1942]      = 922,      -- Ghostlands/Tranquillien
        [1943]      = 930,      -- Azuremyst Isle/Exodar
        [1944]      = A and 946 or H and 947, -- Hellfire Peninsula/Honor Hold or Thrallmar
        [1946]      = 942,      -- Zangarmarsh/Cenarion Expedition
        [1947]      = 930,      -- The Exodar/Exodar
        [1948]      = 1012,     -- Shadowmoon Valley/Ashtongue Deathsworn
        [1950]      = 930,      -- Bloodmyst Isle/Exodar
        [1951]      = A and 978 or H and 941, -- Nagrand/Kurenai or The Mag'har
        [1952]      = 1011,     -- Terokkar Forest/Lower City
        [1953]      = 933,      -- Netherstorm/The Consortium
        [1954]      = 911,      -- Silvermoon City/Silvermoon City
        [1955]      = 935,      -- Shattrath City/The Sha'tar
        [1957]      = 1077,     -- Isle of Quel'Danas/Shattered Sun Offensive

        --------- WotLK ---------
        [114]       = A and 1050 or H and 1085, -- Borean Tundra/Valiance Expedition or Warsong Offensive
        [115]       = 1091,     -- Dragonblight/The Wyrmrest Accord
        [116]       = A and 1050 or H and 1085, -- Grizzly Hills/Valiance Expedition or Warsong Offensive
        [117]       = A and 1050 or H and 1067, -- Howling Fjord/Valiance Expedition or The Hand of Vengeance
        [118]       = 1098,     -- Icecrown/Knights of the Ebon Blade
        [119]       = self.sholazarRepID, -- See Core-Wrath.lua's CheckSholazarBasin()
        [120]       = 1119,     -- The Storm Peaks/The Sons of Hodir
        [121]       = 1106,     -- Zul'Drak/Argent Crusade
        [123]       = A and 1050 or H and 1052, -- Wintergrasp/Valiance Expedition or Horde Expedition
        [124]       = 1098,     -- Plaguelands: The Scarlet Enclave (DK starting zone)/Knights of the Ebon Blade
        [125]       = 1090,     -- Dalaran City/Kirin Tor
        [126]       = 1090,     -- Dalaran City (The Underbelly)/Kirin Tor
        [127]       = 1090,     -- Crystalsong Forest/Kirin Tor
        [170]       = 1106,     -- Hrothgar's Landing/Argent Crusade
        [1360]      = 1098,     -- Icecrown Citadel (The Frozen Throne)/Knights of the Ebon Blade
    }
    return zonesAndFactions
end

function RepByZone:InstancesAndFactionList()
    local instancesAndFactions = {
        -- [instanceID] = factionID
        -- If an instanceID is not listed, that instance has no associated factionID
        -- See https://wow.gamepedia.com/InstanceID for the list of instanceIDs

        --------- Dungeons ----------
        [33]        = A and 72 or H and 68, -- Shadowfang Keep/Undercity
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
        [269]       = 989,  -- The Black Morass/Keepers of Time
        [329]       = 529, -- Strathholme/Argent Dawn
        [349]       = 609, -- Maraudon/Cenarion Circle
        [389]       = 76, -- Ragefire Chasm/Orgrimmar
        [429]       = 809, -- Dire Maul/Shen'dralar
        [540]       = A and 946 or H and 947, -- The Shattered Halls/Honor Hold or Thrallmar
        [542]       = A and 946 or H and 947, -- The Blood Furnace/Honor Hold or Thrallmar
        [543]       = A and 946 or H and 947, -- Hellfire Ramparts/Honor Hold or Thrallmar
        [545]       = 942,      -- The Steamvault/Cenarion Expedition
        [546]       = 942,      -- The Underbog/Cenarion Expedition
        [547]       = 942,      -- The Slave Pens/Cenarion Expedition
        [552]       = 935,      -- The Arcatraz/The Sha'tar
        [553]       = 935,      -- The Botanica/The Sha'tar
        [554]       = 935,      -- The Mechanar/The Sha'tar
        [555]       = 1011,     -- Shadow Labyrinth/Lower City
        [556]       = 1011,     -- Sethekk Halls/Lower City
        [557]       = 933,      -- Mana-Tombs/The Consortium
        [558]       = 1011,     -- Auchenai Crypts/Lower City
        [560]       = 989,      -- Old Hillsbrad Foothills/Keepers of Time
        [574]       = A and 1050 or H and 1067, -- Utgarde Keep/Valiance Expedition or The Hand of Vengeance
        [575]       = A and 1050 or H and 1067, -- Utgarde Pinnacle/Valiance Expedition or The Hand of Vengeance
        [576]       = 1090,     -- The Nexus/Kirin Tor
        [578]       = 1091,     -- The Oculus/The Wyrmrest Accord
        [585]       = 1077,     -- Magister's Terrace/Shattered Sun Offensive
        [595]       = 989,      -- The Culling of Stratholme/Keepers of Time
        [599]       = A and 1050 or H and 1067, -- Halls of Stone/Valiance Expedition or The Hand of Vengeance
        [600]       = A and 1050 or H and 1067, -- Drak'Tharon Keep/Valiance Expedition or The Hand of Vengeance
        [601]       = A and 1050 or H and 1067, -- Azjol-Nerub/Valiance Expedition or The Hand of Vengeance
        [602]       = A and 1050 or H and 1067, -- Halls of Lightning/Valiance Expedition or The Hand of Vengeance
        [604]       = A and 1050 or H and 1067, -- Gundrak/Valiance Expedition or The Hand of Vengeance
        [608]       = 1090,     -- The Violet Hold/Kirin Tor
        [619]       = A and 1050 or H and 1067, -- Ahn'kahet: The Old Kingdom/Valiance Expedition or The Hand of Vengeance
        [632]       = 1156,     -- Forge of Souls/The Ashen Verdict
        [650]       = 1106,     -- Trial of the Champion/Argent Crusade
        [658]       = 1156,     -- Pit of Saron/The Ashen Verdict
        [668]       = 1156,     -- Halls of Reflection/The Ashen Verdict
        [1001]      = 529, -- Scarlet Halls/Argent Dawn
        [1004]      = 529, -- Scarlet Monastary/Argent Dawn
        [1007]      = 529, -- Scholomance/Argent Dawn

        ----------- Battlegrounds ----------
        [30]        = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [529]       = A and 509 or H and 510, -- Arathi Basin/The Leage of Arathor or The Defilers
        [566]       = A and 930 or H and 911, -- Eye of the Storm/Exodar or Silvermoon City
        [589]       = A and 890 or H and 889, -- Warsong Gulch/Silverwing Sentinels or Warsong Outriders
        [607]       = A and 1050 or H and 1085, -- Strand of the Ancients/Valiance Expedition or Warsong Offensive
        [628]       = A and 1050 or H and 1085, -- Isle of Conquest/Valiance Expedition or Warsong Offensive

        ---------- Raids -----------
        [249]       = A and 72 or H and 76, -- Onyxia's Lair/Stormwind or Orgrimmar
        [309]       = 270, -- Zul'Gurub/Zandalar Tribe
        [409]       = 749, -- Molten Core/Hydraxian Waterlords
        [469]       = A and 72 or H and 76, -- Blackwing Lair/Stormwind or Orgrimmar
        [509]       = 609, -- Ruins of Ahn'Qiraj/Cenarion Circle
        [531]       = 910, -- Temple of Ahn'Qiraj/Brood of Nozdormu
        [532]       = 967,      -- Karazhan/The Violet Eye
        [533]       = 529, -- Naxxramas/Argent Dawn
        [544]       = A and 946 or H and 947, -- Magtheridon's Lair/Honor Hold or Thrallmar
        [548]       = 942,      -- Serpentshrine Cavern/Cenarion Expedition
        [550]       = 935,      -- Tempest Keep/The Sha'tar
        [564]       = 1012,     -- Black Temple/Ashtongue Deathsworn
        [565]       = 1038,     -- Gruul's Lair/Ogri'la
        [580]       = 1077,     -- Sunwell Plateau/Shattered Sun Offensive
        [603]       = 1119,     -- Ulduar/The Sons of Hodir
        [615]       = 1091,     -- The Obsidian Sanctum/The Wyrmrest Accord
        [616]       = 1091,     -- The Eye of Eternity/The Wyrmrest Accord
        [624]       = A and 1037 or H and 1052, -- Vault of Archavon/Alliance Vanguard or Horde Expedition
        [631]       = 1156,     -- Icecrown Citadel/The Ashen Verdict
        [649]       = 1106,     -- Trial of the Crusader/Argent Crusade
        [724]       = 1091,     -- The Ruby Sanctum/The Wyrmrest Accord
    }
    return instancesAndFactions
end

function RepByZone:SubZonesAndFactionsList()
    local subZonesAndFactions = {
		-- [C_Map.GetAreaInfo(areaID)] = factionID
		-- see https://wow.tools/dbc/?dbc=areatable&build=1.13.3.32887#search=&page=1 or https://wago.tools/db2/AreaTable?page=1&build=3.4.3.51278

        --------- Vanilla ---------
        [C_Map.GetAreaInfo(19)]     = 270,      -- Zul'Gurub/Zandalar Tribe
        [C_Map.GetAreaInfo(35)]     = 21,       -- Booty Bay/Booty Bay
        [C_Map.GetAreaInfo(36)]     = A and 730 or H and 729, -- Alterac Mountains/Stormpike Guard or Frostwolf Clan
        [C_Map.GetAreaInfo(100)]    = 47,       -- Nesingwary's Expedition/Ironforge
        [C_Map.GetAreaInfo(122)]    = 270,      -- Zuuldaia Ruins/Zandalar Tribe
        [C_Map.GetAreaInfo(125)]    = 270,      -- Kal'ai Ruins/Zandalar Tribe
        [C_Map.GetAreaInfo(128)]    = 270,      -- Ziata'jai Ruins/Zandalar Tribe
        [C_Map.GetAreaInfo(133)]    = 54,       -- Gnomeregan/Gnomeregan Exiles
		[C_Map.GetAreaInfo(150)]    = 72,       -- Menethil Harbor/Stormwind
        [C_Map.GetAreaInfo(193)]    = A and 72 or H and 68, -- Ruins of Andorhal/Stormwind or Undercity
        [C_Map.GetAreaInfo(196)]    = 72,       -- Uthor's Tomb/Stormwind
		[C_Map.GetAreaInfo(197)]    = 72,       -- Sorrow Hill/Stormwind
        [C_Map.GetAreaInfo(280)]    = 349,      -- Strahnbrad/Ravenholdt
        [C_Map.GetAreaInfo(288)]    = 72,       -- Azurelode Mine/Stormwind
		[C_Map.GetAreaInfo(297)]    = 81,       -- Jaguero Isle/Thunder Bluff
		[C_Map.GetAreaInfo(299)]    = 72,       -- Menethil Bay/Stormwind
        [C_Map.GetAreaInfo(311)]    = 270,      -- Ruins of Aboraz/Zandalar Tribe
        [C_Map.GetAreaInfo(313)]    = 349,      -- Northfold Manor/Ravenholdt
        [C_Map.GetAreaInfo(314)]    = A and 72 or H and 68, -- Go'Shek Farm/Stormwind or Undercity
        [C_Map.GetAreaInfo(315)]    = 72,       -- Dabyrie's Farmstead/Stormwind
        [C_Map.GetAreaInfo(317)]    = A and 471 or H and 530, -- Witherbark Village/Wildhammer Clan or Darkspear Trolls
        [C_Map.GetAreaInfo(320)]    = 72,       -- Refuge Pointe/Stormwind
        [C_Map.GetAreaInfo(321)]    = 68,       -- Hammerfall/Undercity
        [C_Map.GetAreaInfo(327)]    = 21,       -- Faldir's Cove/Booty Bay
        [C_Map.GetAreaInfo(328)]    = 21,       -- The Drowned Reef/Booty Bay
        [C_Map.GetAreaInfo(350)]    = 69,       -- Quel'Danil Lodge/Darnassus
		[C_Map.GetAreaInfo(359)]    = A and 47 or H and 81, -- Bael Modan/Ironforge or Thunder Bluff
        [C_Map.GetAreaInfo(367)]    = 530,      -- Sen'jen Village/Darkspear Trolls
        [C_Map.GetAreaInfo(368)]    = 530,      -- Echo Isles/Darkspear Trolls
        [C_Map.GetAreaInfo(392)]    = 470,      -- Ratchet/Ratchet
        [C_Map.GetAreaInfo(393)]    = 530,      -- Darkspear Strand/Darkspear Trolls
        [C_Map.GetAreaInfo(439)]    = A and 54 or H and 76, -- The Shimmering Flats/Gnomeregan Exiles or Orgrimmar
        [C_Map.GetAreaInfo(477)]    = 270,      -- Ruins of Jubuwal/Zandalar Tribe
        [C_Map.GetAreaInfo(484)]    = A and 69 or H and 81, -- Freewind Post/Darnassus or Thunder Bluff
		[C_Map.GetAreaInfo(596)]    = 470,      -- Kodo Graveyard/Ratchet
        [C_Map.GetAreaInfo(604)]    = 93,       -- Magram Village/Magram Clan Centaur
        [C_Map.GetAreaInfo(606)]    = 92,       -- Gelkis Village/Gelkis Clan Centaur
        [C_Map.GetAreaInfo(702)]    = 69,       -- Rut'theran Village/Darnassus
        [C_Map.GetAreaInfo(813)]    = 529,      -- The Bulwark/Argent Dawn
        [C_Map.GetAreaInfo(881)]    = 47,       -- Thandol Span (Wetlands)/Ironforge
        [C_Map.GetAreaInfo(896)]    = A and 730 or H and 729, -- Purgation Isle/Stormpike Guard or Frostwolf Clan
        [C_Map.GetAreaInfo(978)]    = A and 1174 or H and 530, -- Zul'Farrak/Wildhammer Clan or Darkspear Trolls
        [C_Map.GetAreaInfo(1016)]   = 69,       -- Direforge Hill/Darnassus
        [C_Map.GetAreaInfo(1025)]   = 69,       -- The Green Belt/Darnassus
        [C_Map.GetAreaInfo(1057)]   = A and 47 or H and 68, -- Thoradin's Wall (Hillsbrad Foothills)/Ironforge or Undercity
        [C_Map.GetAreaInfo(1216)]   = 579,      -- Timbermaw Hold/Timbermaw Hold
        [C_Map.GetAreaInfo(1446)]   = 59,       -- Thorium Point/Thorium Brotherhood
		[C_Map.GetAreaInfo(1658)]   = 609,      -- Cenarion Enclave/Cenarion Circle
        [C_Map.GetAreaInfo(1677)]   = A and 730 or H and 729, -- Gavin's Naze/Stormpike Guard or Frostwolf Clan
        [C_Map.GetAreaInfo(1679)]   = A and 730 or H and 729, -- Corrahn's Dagger/Stormpike Guard or Frostwolf Clan
        [C_Map.GetAreaInfo(1680)]   = A and 730 or H and 729, -- The Headland/Stormpike Guard or Frostwolf Clan
        [C_Map.GetAreaInfo(1678)]   = 72,       -- Sofera's Naze/Stormwind
		[C_Map.GetAreaInfo(1739)]   = 87,       -- Bloodsail Compound/Bloodsail Buccaneers
        [C_Map.GetAreaInfo(1741)]   = 87,       -- Gurubashi Arena/Bloodsail Buccaneers
        [C_Map.GetAreaInfo(1761)]   = 579,      -- Deadwood Village/Timbermaw Hold
        [C_Map.GetAreaInfo(1762)]   = 579,      -- Felpaw Village/Timbermaw Hold
        [C_Map.GetAreaInfo(1837)]   = A and 471 or H and 530, -- Witherbark Caverns/Wildhammer Clan or Darkspear Trolls
        [C_Map.GetAreaInfo(1857)]   = A and 47 or H and 68, -- Thoradin's Wall (Arathi Highlands)/Ironforge or Undercity
        [C_Map.GetAreaInfo(1858)]   = A and 471 or H and 530, -- Boulder'gor/Wildhammer Clan or Darkspear Trolls
		[C_Map.GetAreaInfo(1977)]   = 309,      -- Zul'Gurub/Zandalar Tribe
		[C_Map.GetAreaInfo(2097)]   = A and 69 or H and 81, -- Darkcloud Pinnacle/Darnassus or Thunder Bluff
		[C_Map.GetAreaInfo(2157)]   = A and 47 or H and 81, -- Bael'dun Keep/Ironforge or Thunder Bluff
		[C_Map.GetAreaInfo(2240)]   = 21,       -- Mirage Raceway/Booty Bay
        [C_Map.GetAreaInfo(2241)]   = 589,      -- Frostsaber Rock/Wintersaber Trainers
        [C_Map.GetAreaInfo(2243)]   = 579,      -- Timbermaw Post/Timbermaw Hold
        [C_Map.GetAreaInfo(2244)]   = 579,      -- Winterfall Village/Timbermaw Hold
        [C_Map.GetAreaInfo(2246)]   = 579,      -- Frostfire Hot Springs/Timbermaw Hold
        [C_Map.GetAreaInfo(2257)]   = 72,       -- Deeprun Tram/Stormwind
        [C_Map.GetAreaInfo(2276)]   = 69,       -- Quel'Lithien Lodge/Darnassus
        [C_Map.GetAreaInfo(2405)]   = 529,      -- Ethel Rethor/Argent Dawn
        [C_Map.GetAreaInfo(2406)]   = 69,       -- Ranazjar Isle/Darnassus
        [C_Map.GetAreaInfo(2407)]   = 470,      -- Kormek's Hut/Ratchet
        [C_Map.GetAreaInfo(2408)]   = 530,      -- Shadowprey Village/Darkspear Trolls
        [C_Map.GetAreaInfo(2597)]   = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [C_Map.GetAreaInfo(2617)]   = 470,      -- Scrabblescrew's Camp/Ratchet
        [C_Map.GetAreaInfo(2897)]   = 530,      -- Zoram'gar Outpost/Darkspear Trolls
		[C_Map.GetAreaInfo(3197)]   = 72,       -- Chillwind Camp/Stormwind
        [C_Map.GetAreaInfo(3357)]   = 270,      -- Yojamba Isle/Zandalar Tribe
        [C_Map.GetAreaInfo(3456)]   = 529,      -- Naxxramas/Argent Dawn
        [C_Map.GetAreaInfo(3486)]   = 349,      -- Ravenholdt Manor/Ravenholdt

        --------- TBC ---------
        [C_Map.GetAreaInfo(3482)]   = 922,      -- The Dead Scar (Eversong Woods)/Tranquillien
        [C_Map.GetAreaInfo(3514)]   = 922,      -- The Dead Scar (Ghostlands)/Tranquillien
        [C_Map.GetAreaInfo(3530)]   = A and 930 or H and 911, -- Shadow Ridge/Exodar or Silvermoon City
        [C_Map.GetAreaInfo(3547)]   = 1077,     -- Throne of Kil'jaeden/Shattered Sun Offensive
        [C_Map.GetAreaInfo(3552)]   = 978,      -- Temple of Telhamat/Kurenai
        [C_Map.GetAreaInfo(3554)]   = 911,      -- Falcon Watch/Silvermoon City
        [C_Map.GetAreaInfo(3555)]   = 941,      -- Mag'har Post/The Mag'har
        [C_Map.GetAreaInfo(3569)]   = 69,       -- Tides' Hollow/Darnassus
        [C_Map.GetAreaInfo(3573)]   = 72,       -- Odesyus' Landing/Stormwind
        [C_Map.GetAreaInfo(3590)]   = 69,       -- Wrathscale Lair/Darnassus
        [C_Map.GetAreaInfo(3591)]   = 69,       -- Ruins of Loreth'Aran/Darnassus
        [C_Map.GetAreaInfo(3598)]   = 69,       -- Wyrmscar Island/Darnassus
        [C_Map.GetAreaInfo(3623)]   = 933,      -- Aeris Landing/The Consortium
        [C_Map.GetAreaInfo(3673)]   = 47,       -- Nesingwary Safari/Ironforge
        [C_Map.GetAreaInfo(3628)]   = A and 930 or H and 911, -- Halaa/Exodar or Silvermoon City
        [C_Map.GetAreaInfo(3630)]   = 933,      -- Oshu'gun/The Consortium
        [C_Map.GetAreaInfo(3631)]   = 933,      -- Spirit Fields/The Consortium
        [C_Map.GetAreaInfo(3644)]   = 930,      -- Telredor/Exodar
        [C_Map.GetAreaInfo(3645)]   = 530,      -- Zabra'jin/Darkspear Trolls
        [C_Map.GetAreaInfo(3646)]   = 970,      -- Quagg Ridge/Sporeggar
        [C_Map.GetAreaInfo(3647)]   = 970,      -- The Spawning Glen/Sporeggar
        [C_Map.GetAreaInfo(3649)]   = 970,      -- Sporeggar/Sporeggar
        [C_Map.GetAreaInfo(3652)]   = 970,      -- Funggor Cavern/Sporeggar
        [C_Map.GetAreaInfo(3674)]   = 942,      -- Cenarion Thicket/Cenarion Expedition
        [C_Map.GetAreaInfo(3679)]   = 1031,     -- Skettis/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3680)]   = 1031,     -- Blackwind Valley/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3681)]   = 934,      -- Firewing Point/The Scryers
        [C_Map.GetAreaInfo(3683)]   = 941,      -- Stonebreaker Hold/The Mag'har
        [C_Map.GetAreaInfo(3684)]   = 69,       -- Allerian Stronghold/Darnassus
        [C_Map.GetAreaInfo(3690)]   = 1031,     -- Blackwind Lake/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3691)]   = 1031,     -- Lake Ere'Noru/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3718)]   = 530,      -- Swamprat Post/Darkspear Trolls
        [C_Map.GetAreaInfo(3719)]   = 941,      -- Bleeding Hollow Ruins/The Mag'har
        [C_Map.GetAreaInfo(3744)]   = 76,       -- Shadowmoon Village/Orgrimmar
        [C_Map.GetAreaInfo(3754)]   = 932,      -- Altar of Sha'tar/The Aldor
        [C_Map.GetAreaInfo(3758)]   = 1015,     -- Netherwing Fields/Netherwing
        [C_Map.GetAreaInfo(3759)]   = 1015,     -- Netherwing Ledge/Netherwing
        [C_Map.GetAreaInfo(3766)]   = 978,      -- Orebor Harborage/Kurenai
        [C_Map.GetAreaInfo(3769)]   = 941,      -- Thunderlord Stronghold/The Mag'har
        [C_Map.GetAreaInfo(3771)]   = 69,       -- The Living Grove/Darnassus
        [C_Map.GetAreaInfo(3772)]   = 69,       -- Sylvanaar/Darnassus
        [C_Map.GetAreaInfo(3784)]   = 1031,     -- Forge Camp: Terror/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3785)]   = 1031,     -- Forge Camp: Wrath/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3786)]   = 1038,     -- Ogri'la/Ogri'la
        [C_Map.GetAreaInfo(3792)]   = 933,      -- Mana-Tombs/The Consortium
        [C_Map.GetAreaInfo(3801)]   = 941,      -- Mag'har Grounds/The Mag'har
        [C_Map.GetAreaInfo(3806)]   = 911,      -- Supply Caravan/Silvermoon City
        [C_Map.GetAreaInfo(3808)]   = 942,      -- Cenarion Post/Cenarion Expedition
        [C_Map.GetAreaInfo(3816)]   = 21,       -- Zeppelin Crash/Booty Bay
        [C_Map.GetAreaInfo(3828)]   = 942,      -- Ruuan Weald/Cenarion Expedition
        [C_Map.GetAreaInfo(3832)]   = 1038,     -- Vortex Summit/Ogri'la
        [C_Map.GetAreaInfo(3839)]   = 1011,     -- Abandoned Armory/Lower City
        [C_Map.GetAreaInfo(3842)]   = 935,      -- Tempest Keep (Netherstorm)/The Sha'tar
        [C_Map.GetAreaInfo(3864)]   = 1031,     -- Bash'ir Landing/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3896)]   = 932,      -- Aldor Rise/The Aldor
        [C_Map.GetAreaInfo(3898)]   = 934,      -- Scryer's Tier/The Scryers
        [C_Map.GetAreaInfo(3899)]   = 1011,     -- Lower City/Lower City
        [C_Map.GetAreaInfo(3901)]   = 69,       -- Allerian Post/Darnassus
        [C_Map.GetAreaInfo(3902)]   = 941,      -- Stonebreaker Camp/The Mag'har
        [C_Map.GetAreaInfo(3918)]   = 54,       -- Toshley's Station/Gnomeregan
        [C_Map.GetAreaInfo(3937)]   = 76,       -- Slag Watch/Orgrimmar
        [C_Map.GetAreaInfo(3938)]   = 934,      -- Sanctum of the Stars/The Scryers
        [C_Map.GetAreaInfo(3951)]   = 942,      -- Evergrove/Cenarion Expedition
        [C_Map.GetAreaInfo(3952)]   = 942,      -- Wyrmskull Bridge/Cenarion Expedition
        [C_Map.GetAreaInfo(3958)]   = 1031,     -- Sha'tari Base Camp/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3965)]   = 1015,     -- Netherwing Mines/Netherwing
        [C_Map.GetAreaInfo(3966)]   = 1015,     -- Dragonmaw Base Camp/Netherwing
        [C_Map.GetAreaInfo(3964)]   = 1031,     -- Skyguard Outpost/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3973)]   = 1031,     -- Blackwind Landing/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3974)]   = 1031,     -- Veil Harr'ik/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3975)]   = 1031,     -- Terokk's Rest/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3976)]   = 1031,     -- Veil Ala'rak/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3977)]   = 1031,     -- Upper Veil Shil'ak/Sha'tari Skyguard
        [C_Map.GetAreaInfo(3978)]   = 1031,     -- Lower Veil Shil'ak/Sha'tari Skyguard

        --------- WotLK ---------
        [C_Map.GetAreaInfo(3987)]   = 1073,     -- The Isle of Spears/The Kalu'ak
        [C_Map.GetAreaInfo(3988)]   = 1073,     -- Kamagua/The Kalu'ak
        [C_Map.GetAreaInfo(3990)]   = 1073,     -- Scalawag Point/The Kalu'ak
        [C_Map.GetAreaInfo(3996)]   = 1068,     -- Baelgun's Excavation Site/Explorer's League
        [C_Map.GetAreaInfo(3997)]   = 1068,     -- Explorers' League Outpost/Explorers' League
        [C_Map.GetAreaInfo(3999)]   = 1068,     -- Steel Gate/Explorers' League
        [C_Map.GetAreaInfo(4018)]   = 1064,     -- Camp Winterhoof/The Taunka
        [C_Map.GetAreaInfo(4023)]   = 1090,     -- Amber Ledge/Kirin Tor
        [C_Map.GetAreaInfo(4024)]   = 1090,     -- Coldarra/Kirin Tor
        [C_Map.GetAreaInfo(4033)]   = 942,      -- Winterfin Village/Cenarion Expedition
        [C_Map.GetAreaInfo(4037)]   = 1064,     -- Taunka'le Village/The Taunka
        [C_Map.GetAreaInfo(4040)]   = 1073,     -- Njord's Breath Bay/The Kalu'ak
        [C_Map.GetAreaInfo(4041)]   = 1073,     -- Kaskala/The Kalu'ak
        [C_Map.GetAreaInfo(4097)]   = 942,      -- Winterfin Caverns/Cenarion Expedition
        [C_Map.GetAreaInfo(4099)]   = 942,      -- Winterfin Retreat/Cenarion Expedition
        [C_Map.GetAreaInfo(4113)]   = 1073,     -- Unu'pe/The Kalu'ak
        [C_Map.GetAreaInfo(4120)]   = 1090,     -- The Nexus/Kirin Tor
        [C_Map.GetAreaInfo(4121)]   = 1090,     -- Transitus Shield/Kirin Tor
        [C_Map.GetAreaInfo(4151)]   = 1064,     -- Westwind Refuge Camp/The Taunka
        [C_Map.GetAreaInfo(4152)]   = 1073,     -- Moa'ki Harbor/The Kalu'ak
        [C_Map.GetAreaInfo(4155)]   = 1073,     -- The Half Shell/The Kalu'ak
        [C_Map.GetAreaInfo(4158)]   = 1037,     -- Stars' Rest/Alliance Vanguard
        [C_Map.GetAreaInfo(4165)]   = 1052,     -- Agmar's Hammer/Horde Expedition
        [C_Map.GetAreaInfo(4169)]   = 1037,     -- Fordragon Hold/Alliance Vanguard
        [C_Map.GetAreaInfo(4170)]   = 1052,     -- Kor'kron Vanguard/Horde Expedition
        [C_Map.GetAreaInfo(4171)]   = A and 1037 or H and 1052, -- The Court of Skulls/Alliance Vanguard or Horde Expedition
        [C_Map.GetAreaInfo(4172)]   = A and 1037 or H and 1052, -- Angrathar the Wrathgate/Alliance Vanguard or Horde Expedition
        [C_Map.GetAreaInfo(4177)]   = 1037,     -- Wintergarde Keep/Alliance Vanguard
        [C_Map.GetAreaInfo(4178)]   = 1037,     -- Wintergarde Mine/Alliance Vanguarde
        [C_Map.GetAreaInfo(4186)]   = 1067,     -- Venomspite/The Hand of Vengeance
        [C_Map.GetAreaInfo(4188)]   = 1037,     -- The Carrion Fields/Alliance Vanguard
        [C_Map.GetAreaInfo(4189)]   = 942,      -- D.E.H.T.A Encampment/Cenarion Expedition
        [C_Map.GetAreaInfo(4190)]   = 1037,     -- Thorson's Post/Alliance Vanguard
        [C_Map.GetAreaInfo(4191)]   = 1106,     -- Light's Trust/Argent Crusade
        [C_Map.GetAreaInfo(4211)]   = 1064,     -- Camp Oneqwah/The Taunka
        [C_Map.GetAreaInfo(4224)]   = 1073,     -- The Briny Pinnacle/The Kalu'ak
        [C_Map.GetAreaInfo(4226)]   = 1073,     -- Iskaal/The Kalu'ak
        [C_Map.GetAreaInfo(4227)]   = 530,      -- Dragon's Fall/Darkspear Trolls
        [C_Map.GetAreaInfo(4233)]   = 1106,     -- Dawn's Reach/Argent Crusade
        [C_Map.GetAreaInfo(4234)]   = 1106,     -- Naxxramas/Argent Crusade
        [C_Map.GetAreaInfo(4243)]   = 1037,     -- Wintergarde Crypt/Alliance Vanguard
        [C_Map.GetAreaInfo(4246)]   = 1037,     -- Wintergarde Mausoleum/Alliance Vanguard
        [C_Map.GetAreaInfo(4253)]   = 72,       -- 7th Legion Front/Stormwind
        [C_Map.GetAreaInfo(4256)]   = A and 1094 or H and 1124, -- Drak'mar Lake/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4261)]   = 68,       -- Ghostblade Point/Undercity
        [C_Map.GetAreaInfo(4281)]   = 1098,     -- Acherus: The Ebon Hold (Eastern Kingdoms)/Knights of the Ebon Blade
        [C_Map.GetAreaInfo(4284)]   = 47,       -- Nesingwary Base Camp/Ironforge
        [C_Map.GetAreaInfo(4286)]   = 1105,     -- The Bones of Nozronn/The Oracles
        [C_Map.GetAreaInfo(4287)]   = 1104,     -- Kartak's Hold/Frenzyheart Tribe
        [C_Map.GetAreaInfo(4288)]   = 1105,     -- Sparktouched Haven/The Oracles
        [C_Map.GetAreaInfo(4291)]   = 1105,     -- Rainspeaker Canopy/The Oracles
        [C_Map.GetAreaInfo(4292)]   = 1104,     -- Frenzyheart Hill/Frenzyheart Tribe
        [C_Map.GetAreaInfo(4297)]   = 1105,     -- Mosswalker Village/The Oracles
        [C_Map.GetAreaInfo(4303)]   = 1104,     -- Hardknuckle Clearing/Frenzyheart Tribe
        [C_Map.GetAreaInfo(4306)]   = 1105,     -- Mistwhisper Village/The Oracles
        [C_Map.GetAreaInfo(4308)]   = 1104,     -- Spearborn Encampment/Frenzyheart Tribe
        [C_Map.GetAreaInfo(4312)]   = 1098,     -- Ebon Watch/Knights of the Ebon Blade
        [C_Map.GetAreaInfo(4369)]   = 47,       -- Dorian's Outpost/Ironforge
        [C_Map.GetAreaInfo(4342)]   = 1098,     -- Acherus: The Ebon Hold(Death Knight start)/Knights of the Ebon Blade
        [C_Map.GetAreaInfo(4392)]   = 1105,     -- The Stormwright's Shelf/The Oracles
        [C_Map.GetAreaInfo(4429)]   = 1085,     -- Grom'arsh Crash-Site/Warsong Offensive
        [C_Map.GetAreaInfo(4418)]   = 21,       -- K3/Booty Bay
        [C_Map.GetAreaInfo(4428)]   = 1126,     -- Frosthold/The Frostborn
        [C_Map.GetAreaInfo(4441)]   = 1064,     -- Camp Tunka'lo/The Taunka
        [C_Map.GetAreaInfo(4442)]   = 1068,     -- Brann's Base-Camp/Explorers' League
        [C_Map.GetAreaInfo(4458)]   = 21,       -- Sparksocket Minefield/Booty Bay
        [C_Map.GetAreaInfo(4459)]   = 21,       -- Ricket's Folly/Booty Bay
        [C_Map.GetAreaInfo(4479)]   = A and 1094 or H and 1124, -- Winter's Breath Lake/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4485)]   = 1126,     -- The Inventor's Library/The Frostborn
        [C_Map.GetAreaInfo(4487)]   = 1085,     -- Frostfloe Deep/Warsong Offensive
        [C_Map.GetAreaInfo(4501)]   = 1106,     -- The Argent Vanguard/Argent Crusade
        [C_Map.GetAreaInfo(4502)]   = 1126,     -- Mimir's Workshop/The Frostborn
        [C_Map.GetAreaInfo(4503)]   = A and 1094 or H and 1124, -- Ironwall Dam/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4504)]   = 1106,     -- Valley of Echoes/Argent Crusade
        [C_Map.GetAreaInfo(4505)]   = 1106,     -- The Breach/Argent Crusade
        [C_Map.GetAreaInfo(4506)]   = 1106,     -- Scourgeholme/Argent Crusade
        [C_Map.GetAreaInfo(4507)]   = A and 1037 or H and 1052, -- The Broken Front/Alliance Vanguard or Horde Expedition
        [C_Map.GetAreaInfo(4511)]   = A and 1037 or H and 1052, -- The Skybreaker/Alliance Vanguard or Horde Expedition
        [C_Map.GetAreaInfo(4512)]   = A and 1037 or H and 1052, -- Orgrim's Hammer/Alliance Vanguard or Horde Expedition
        [C_Map.GetAreaInfo(4516)]   = 1106,     -- Ironwall Rampart/Argent Crusade
        [C_Map.GetAreaInfo(4522)]   = 1156,     -- Icecrown Citadel/The Ashen Verdict
        [C_Map.GetAreaInfo(4536)]   = A and 1068 or H and 1085, -- Frosthowl Cavern/Explorers' League or Warsong Offensive
        [C_Map.GetAreaInfo(4541)]   = 1106,     -- Vanguard Infirmary/Argent Crusade
        [C_Map.GetAreaInfo(4558)]   = A and 1094 or H and 1124, -- Sunreaver's Command/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4559)]   = A and 1094 or H and 1124, -- Windrunner's Overlook/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4580)]   = 1106,     -- Crusaders' Pinnacle/Argent Crusade
        [C_Map.GetAreaInfo(4593)]   = 1106,     -- The Pit of Fiends/Argent Crusade
        [C_Map.GetAreaInfo(4616)]   = A and 1094 or H and 1124, -- Sunreaver's Sanctuary/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4646)]   = A and 1094 or H and 1124, -- Ashwood Lake/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4658)]   = 1106,     -- Argent Tournament Grounds/Argent Crusade
        [C_Map.GetAreaInfo(4666)]   = A and 1094 or H and 1124, -- Sunreaver Pavilion/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4667)]   = A and 1094 or H and 1124, -- Silver Covenant Pavilion/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4669)]   = 1106,     -- The Ring of Champions/Argent Crusade
        [C_Map.GetAreaInfo(4670)]   = 1106,     -- The Aspirants' Ring/Argent Crusade
        [C_Map.GetAreaInfo(4671)]   = 1106,     -- The Argent Valiants' Ring/Argent Crusade
        [C_Map.GetAreaInfo(4672)]   = A and 1094 or H and 1124, -- The Alliance Valiants' Ring/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4673)]   = A and 1094 or H and 1124, -- The Horde Valiants' Ring/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4674)]   = 1106,     -- Argent Pavilion/Argent Crusade
        [C_Map.GetAreaInfo(4676)]   = A and 1094 or H and 1124, -- Sunreaver Pavilion (Outside)/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4677)]   = A and 1094 or H and 1124, -- Silver Covenant Pavilion (Outside)/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4740)]   = A and 1094 or H and 1124, -- The Silver Enclave/The Silver Covenant or The Sunreavers
        [C_Map.GetAreaInfo(4760)]   = A and 1094 or H and 1124, -- The Sea Reaver's Run/The Silver Covenant or The Sunreavers
    }
    return subZonesAndFactions
end