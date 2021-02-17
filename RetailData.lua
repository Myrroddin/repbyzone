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
        [3]         = 72,       -- Tiragarde Keep/Stormwind
        [4]         = 72,       -- Tiragarde Keep (Great Hall)/Stormwind
        [7]         = 81,       -- Mulgore/Thunder Bluff
        [10]        = A and 470 or H and 46, -- Northern Barrens/Ratchet or Orgrimmar
        [14]        = A and 72 or H and 46, -- Arathi Highlands/Stormwind or Orgrimmar
        [15]        = A and 47 or H and 46, -- Badlands/Ironforge or Orgrimmar
        [17]        = A and 72 or H and 46, -- Blasted Lands/Stormwind or Orgrimmar
        [18]        = 68,       -- Tirisfal Glades/Undercity
        [21]        = A and 1134 or H and 68, -- Silverpine Forest/Gilneas or Undercity
        [22]        = 1106,      -- Western Plaguelands/Argent Crusade
        [23]        = 529,      -- Eastern Plaguelands/Argent Dawn
        [25]        = 68,       -- Hillsbrad Foothills/Undercity
        [26]        = A and 1174 or H and 530, -- Hinterlands/Wildhammer Clan or Darkspear Trolls
        [27]        = 47,       -- Dun Morogh/Ironforge
        [30]        = 54,       -- New Tinkertown/Gnomeregan
        [32]        = 59,       -- Searing Gorge/Thorium Brotherhood
        [37]        = 72,       -- Elwynn Forest/Stormwind
        [41]        = 1090,     -- Dalaran/Kirin Tor
        [42]        = 967,      -- Deadwind Pass/The Violet Eye
        [47]        = A and 72 or H and 68, -- Duskwood/Stormwind or Undercity
        [48]        = 47,       -- Loch Modan/Ironforge
        [52]        = 72,       -- Westfall/Stormwind
        [57]        = 69,       -- Teldrassil/Darnassus
        [62]        = 69,       -- Darkshore/Darnassus
        [71]        = 369,      -- Tanaris/Gadgetzan
        [74]        = 989,      -- Timeless Tunnel/Keepers of Time
        [75]        = 989,      -- Caverns of Time/Keepers of Time
        [76]        = 1133,     -- Azshara/Bilgewater Cartel
        [80]        = 609,      -- Moonglade/Cenarion Circle
        [81]        = 609,      -- Silithus/Cenarion Circle
        [83]        = 577,      -- Winterspring/Everlook
        [84]        = 72,       -- Stormwind City/Stormwind
        [85]        = 46,       -- Orgrimmar/Orgrimmar
        [87]        = 47,       -- Ironforge/Ironforge
        [88]        = 81,       -- Thunder Bluff/Thunder Bluff
        [89]        = 69,       -- Darnassus/Darnassus
        [90]        = 68,       -- Undercity/Undercity

        --------- Cataclysm ---------
        [5861]      = 909,      -- Darkmoon Island/Darkmoon Faire

        --------- MoP ---------
        [371]       = A and 1242 or H and 1228, -- Jade Forest/Pearlfin Jinyu or Forest Hozen
        [376]       = 1272,     -- Valley of the Four Winds/The Tillers
        [379]       = 1270,     -- Kun-Lai Summit/Shado-Pan
        [388]       = 1270,     -- Towlong Steppes/Shado-Pan
        [390]       = 1269,     -- Vale of Eternal Blossoms/Golden Lotus
        [418]       = 1302,     -- Krasarang Wilds/The Anglers
        [422]       = 1337,     -- Dread Wastes/The Klaxxi
        [433]       = 1359,     -- The Veiled Stair/The Black Prince
        [507]       = A and 72 or H and 46, -- Isle of Giants/Stormwind or Orgrimmar
        [516]       = A and 1387 or H and 1388, -- Isle of Thunder/Kirin Tor Offensive or Sunreaver Onslaught
        [554]       = 1492,     -- Timeless Isle/Emperor Shaohao

        --------- WoD ---------

        --------- Legion ---------
        [787]       = 609,      -- Moonglade/Cenarion Circle

        --------- BfA ---------
        [863]       = A and 2159 or H and 2380, -- Nazmir/7th Legion or Talanji's Expedition
        [864]       = A and 2159 or H and 2382, -- Vol'dun/7th Legion or Voldunai
        [895]       = A and 2160 or H and 2157, -- Tiragarde Sound/Proudmore Admiralty or The Honorbound
        [896]       = A and 2383 or H and 2157, -- Drustvar/Order of Embers or The Honorbound
        [942]       = A and 2381 or H and 2157, -- Stormsong Valley/Storm's Wake or The Honorbound
        [1193]      = A and 2159 or H and 2378, -- Zuldazar/7th Legion or Zandalari Empire
        [1355]      = A and 2401 or H and 2373, -- Nazjatar/Waveblade Ankoan or The Unshackled
        [1462]      = 2391,      -- Mechagon Island/Rustbolt Resistance

        --------- Shadowlands ---------
        [1525]      = 2413,     -- Revendreth/Court of Harvesters
        [1536]      = 2410,     -- Maldraxxus/The Undying Army
        [1543]      = 2432,     -- The Maw/Ve'nari
        [1569]      = 2407,     -- Bastion/The Ascended
        -- Oribos has 4 UiMapIDs depending on where in the city you are
        [1670]      = covenantRepID, -- Ring of Fates/Covenant
        [1671]      = covenantRepID, -- Ring of Transference/Covenant
        [1672]      = covenantRepID, -- The Broker's Den/Covenant
        [1673]      = covenantRepID, -- The Crucible/Covenant
        [1740]      = 2465,     -- Ardenweald/The Wild Hunt
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
        [35]        = 21,       -- Booty Bay/Booty Bay
        [36]        = A and 730 or H and 729, -- Alterac Mountains/Stormpike Guard or Frostwolf Clan
        [100]       = 47,       -- Nesingwary's Expedition/Ironforge
        [122]       = 270,      -- Zuuldaia Ruins/Zandalar Tribe
        [125]       = 270,      -- Kal'ai Ruins/Zandalar Tribe
        [128]       = 270,      -- Ziata'jai Ruins/Zandalar Tribe
        [133]       = 54,       -- New Tinkertown/Gnomeregan
		[150]       = 72,       -- Menethil Harbor/Stormwind
        [152]       = 529,      -- The Bulwark/Argent Dawn
        [193]       = A and 72 or H and 68, -- Ruins of Andorhal/Stormwind or Undercity
        [196]       = 72,       -- Uthor's Tomb/Stormwind
        [197]       = 72,       -- Sorrow Hill/Stormwind
        [199]       = 72,       -- Felstone Field/Stormwind
        [201]       = 68,       -- Gahrron's Withering/Undercity
        [202]       = 68,       -- Writhing Haunt/Undercity
        [204]       = 1134,     -- Pyrewood Village/Gilneas
        [233]       = 1134,     -- Ambermill/Gilneas
        [279]       = 1090,     -- Dalaran Crater/Kirin Tor
        [280]       = 349,      -- Strahnbrad/Ravenholdt
        [288]       = 72,       -- Azurelode Mine/Stormwind
		[297]       = 81,       -- Jaguero Isle/Thunder Bluff
		[299]       = 72,       -- Menethil Bay/Stormwind
        [311]       = 270,      -- Ruins of Aboraz/Zandalar Tribe
        [313]       = 349,      -- Northfold Manor/Ravenholdt
        [321]       = 68,       -- Hammerfall/Undercity
        [324]       = 349,      -- Stromgarde Keep/Ravenholdt
        [327]       = 21,       -- Faldir's Cove/Booty Bay
        [328]       = 21,       -- The Drowned Reef/Booty Bay
        [330]       = 47,       -- Thandol Span/Ironforge
        [350]       = 69,       -- Quel'Danil Lodge/Darnassus
		[359]       = H and 81 or A and 47, -- Bael Modan/Thunder Bluff or Ironforge
        [367]       = 530,      -- Sen'jen Village/Darkspear Trolls
        [368]       = 530,      -- Echo Isles/Darkspear Trolls
        [392]       = 470,      -- Ratchet/Ratchet
        [393]       = 530,      -- Darkspear Strand/Darkspear Trolls
        [439]       = A and 54 or H and 76, -- The Shimmering Flats/Gnomeregan or Orgrimmar
        [477]       = 270,      -- Ruins of Jubuwal/Zandalar Tribe
        [484]       = H and 81 or A and 69, -- Freewind Post/Thunder Bluff or Darnassus
        [530]       = 69,       -- Quel'Danil Lodge/Darnassus
		[596]       = 470,      -- Kodo Graveyard/Ratchet
        [604]       = 93,       -- Magram Village/Magram Clan Centaur
        [606]       = 92,       -- Gelkis Village/Gelkis Clan Centaur
        [702]       = 69,       -- Rut'theran Village/Darnassus
        [721]       = 54,       -- Gnomeregan/Gnomeregan
        [813]       = 529,      -- The Bulwark/Argent Dawn
        [880]       = 57,       -- Thandol Span/Ironforge
        [896]       = A and 730 or H and 729, -- Purgation Isle/Stormpike Guard or Frostwolf Clan
        [1016]      = 69,       -- Direforge Hill/Darnassus
        [1019]      = 69,       -- The Green Belt/Darnassus
        [1216]      = 579,      -- Timbermaw Hold/Timbermaw Hold
        [1336]      = A and 54 or H and 1133, -- Lost Rigger Cove/Gnomeregan or Bilgewater Cartel
        [1446]      = 59,       -- Thorium Point/Thorium Brotherhood
		[1658]      = 609,      -- Cenarion Enclave/Cenarion Circle
        [1677]      = A and 730 or H and 729, -- Gavin's Naze/Stormpike Guard or Frostwolf Clan
        [1678]      = 72,       -- Sofera's Naze/Stormwind
        [1679]      = A and 730 or H and 729, -- Corrahn's Dagger/Stormpike Guard or Frostwolf Clan
        [1680]      = A and 730 or H and 729, -- The Headland/Stormpike Guard or Frostwolf Clan
		[1739]      = 87,       -- Bloodsail Compound/Bloodsail Buccaneers
        [1741]      = 87,       -- Gurubashi Arena/Bloodsail Buccaneers
        [1761]      = 579,      -- Deadwood Village/Timbermaw Hold
        [1762]      = 579,      -- Felpaw Village/Timbermaw Hold
		[1858]      = 1174,     -- Boulder'gor/Wildhammer Clan
		[1977]      = 309,      -- Zul'Gurub/Zandalar Tribe
		[2097]      = H and 81 or A and 69, -- Darkcloud Pinnacle/Thunder Bluff or Darnassus
		[2157]      = H and 81 or A and 47, -- Bael'dun Keep/Thunder Bluff or Ironforge
		[2240]      = A and 54 or H and 76, -- Mirage Raceway/Gnomeregan or Orgrimmar
        [2241]      = 589,      -- Frostsaber Rock/Wintersaber Trainers
        [2243]      = 579,      -- Timbermaw Post/Timbermaw Hold
        [2244]      = 579,      -- Winterfall Village/Timbermaw Hold
        [2246]      = 579,      -- Frostfire Hot Springs/Timbermaw Hold
        [2257]      = 72,       -- Deeprun Tram/Stormwind
        [2379]      = 72,       -- Azurelode Mine/Stormwind
        [2405]      = 529,      -- Ethel Rethor/Argent Dawn
        [2406]      = 69,       -- Ranazjar Isle/Darnassus
        [2407]      = 470,      -- Kormek's Hut/Ratchet
        [2408]      = 530,      -- Shadowprey Village/Darkspear Trolls
        [2597]      = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [2617]      = 470,      -- Scrabblescrew's Camp/Ratchet
        [2839]      = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [2897]      = 530,      -- Zoram'gar Outpost/Darkspear Trolls
		[3197]      = 72,       -- Chillwind Camp/Stormwind
        [3357]      = 270,      -- Yojamba Isle/Zandalar Tribe
        [3486]      = 349,      -- Ravenholdt Manor/Ravenholdt
        [4241]      = 1098,     -- Archerus: The Ebon Hold/Knights of the Ebon Blade
        [4342]      = 1098,     -- Archerus: The Ebon Hold/Knights of the Ebon Blade
        [4745]      = 76,       -- Orgrimmar Rear Gate/Orgrimmar
        [5044]      = 609,      -- The Tainted Forest/Cenarion Circle
        [5083]      = 911,      -- Sunveil Excursion/Silvermoon City
        [5117]      = 1133,     -- Nozzlepot's Outpost/Bilgewater Cartel
        [5121]      = 68,       -- Galen's Fall/Undercity
        [5367]      = 942,      -- The Mender's Stead/Cenarion Circle
        [5476]      = 1134,     -- Pyrewood Chapel/Gilneas
        [5477]      = 1134,     -- Pyrewood Inn/Gilneas
        [5478]      = 1134,     -- Pyrewood Town Hall/Gilneas
        [5480]      = 1134,     -- Gilneas Liberation Base Camp/Gilneas
        [5481]      = 47,       -- 7th Legion Base Camp/Ironforge
        [5495]      = 54,       -- Gnomeregan/Gnomeregan
        [5496]      = 369,      -- Fuselight/Gadgetzan
        [5524]      = 911,      -- Bloodwatcher Point/Silvermoon City
        [5497]      = 369,      -- Fuselight-by-the-Sea/Gadgetzan
        [5564]      = 72,       -- Dragon's Mouth/Stormwind
        [5687]      = 1134,     -- The Howling Oak/Gilneas
        [9750]      = 68,       -- Hammerfall (BfA)/Undercity
        [9755]      = 47,       -- Thandol Span (BfA)/Ironforge

        --------- WotLK ---------
        [7679]      = 1098,     -- Archerus: The Ebon Hold/Knights of the Ebon Blade
        [7743]      = 1098,     -- Archerus: The Ebon Hold/Knights of the Ebon Blade

        --------- MoP ---------
        [5876]      = 1271,     -- Serpent's Heart/Order of the Cloud Serpent
        [5931]      = 1271,     -- The Arboretum/Order of the Cloud Serpent
        [5974]      = 1341,     -- Jade Temple Grounds/The August Celestials
        [5975]      = 1341,     -- Temple of the Jade Serpent/The August Celestials
        [5976]      = 1270,     -- Gate of the Setting Sun/Shado-Pan
        [6012]      = 1271,     -- Windward Isle/Order of the Cloud Serpent
        [6013]      = 81,       -- Dawnchaser/Thunder Bluff
        [6016]      = 69,       -- Sentinel Basecamp/Darnassus
        [6022]      = 1271,     -- Mistveil Sea/Order of the Cloud Serpent
        [6048]      = 1341,     -- Temple of the Red Crane/The August Celestials
        [6080]      = 1271,     -- Serpent's Overlook/Order of the Cloud Serpent
        [6117]      = 1341,     -- Fountain of the Everseeing/The August Celestials
        [6118]      = 1341,     -- The Scrollkeeper's Sanctum/The August Celestials
        [6119]      = 1341,     -- Terrace of the Twin Dragons/The August Celestials
        [6120]      = 1341,     -- The Heart of Jade/The August Celestials
        [6155]      = 1341,     -- Cradle of Chi-Ji/The August Celestials
        [6160]      = 1341,     -- Angkhal Pavilion/The August Celestials
        [6161]      = 1341,     -- Pedestal of Hope/The August Celestials
        [6162]      = 1341,     -- Dome Balrissa/The August Celestials
        [6174]      = 1341,     -- Temple of the White Tiger/The August Celestials
        [6182]      = 1341,     -- Mogu'shan Palace2/The August Celestials
        [6213]      = 1341,     -- Niuzao Temple/The August Celestials
        [6143]      = 1341,     -- Mogu'shan Palace1/The August Celestials
        [6295]      = 1345,     -- Seat of Knowledge/The Lorewalkers
        [6371]      = A and 1376 or H and 1375, -- The Southern Isles/Operation: Shieldwall or Dominance Offensive
        [6393]      = 1270,     -- Serpent's Spine1/Shado-Pan
        [6394]      = 1270,     -- Serpent's Spine2/Shado-Pan
        [6395]      = 1270,     -- Serpent's Spine3/Shado-Pan
        [6482]      = A and 1341, -- The Summer Terrace/The August Celestials
        [6498]      = 1341,     -- Gate of the August Celestials/The August Celestials
        [6512]      = 1271,     -- The Widow's Wail/Order of the Cloud Serpent
        [6513]      = 1271,     -- Oona Kagu/Order of the Cloud Serpent
        [6560]      = H and 1341, -- The Golden Terrace/The August Celestials
        [6566]      = A and 1376 or H and 1375, -- Domination Point/Operation: Shieldwall or Dominance Offensive
        [6595]      = A and 1376 or H and 1375, -- The Skyfire/Operation: Shieldwall or Dominance Offensive
        [6596]      = A and 1376 or H and 1375, -- Lion's Landing1/Operation: Shieldwall or Dominance Offensive
        [6597]      = A and 1376 or H and 1375, -- Sparkrocket Outpost/Operation: Shieldwall or Dominance Offensive
        [6600]      = A and 1376 or H and 1375, -- Blacksand Spillway/Operation: Shieldwall or Dominance Offensive
        [6601]      = A and 1376 or H and 1375, -- Bilgewater Beach/Operation: Shieldwall or Dominance Offensive
        [6602]      = A and 1376 or H and 1375, -- The Boiling Crustacean/Operation: Shieldwall or Dominance Offensive
        [6604]      = A and 1376 or H and 1375, -- Quickchop's Lumber Farm/Operation: Shieldwall or Dominance Offensive
        [6609]      = A and 1376 or H and 1375, -- Ruins of Ogudei/Operation: Shieldwall or Dominance Offensive
        [6643]      = A and 1376 or H and 1375, -- Lion's Landing/Operation: Shieldwall or Dominance Offensive
        [6644]      = A and 1376 or H and 1375, -- Domination Point (Horde)/Operation: Shieldwall or Dominance Offensive
        [6701]      = 54,       -- Beeble's Wreck/Gnomeregan
        [6702]      = 1133,     -- Bozzle's Wreck/Bilgewater Cartel
        [6771]      = 1341,     -- Celestial Tournament/The August Celestials


        --------- BfA ---------
        [9310]      = 2386,     -- The Wound/Champions of Azeroth
        [9329]      = 2387,     -- Seeker's Outpost/Tortollan Seekers
        [9494]      = 1133,     -- Warfront: The Battle for Stromgarde (Ar'gorok)/Bilgewater Cartel
        [9556]      = 2387,     -- Tortaka Refuge/Tortollan Seekers
        [9667]      = 2386,     -- Chamber of Heart/Champions of Azeroth
        [9693]      = 2387,     -- Seeker's Vista/Tortollan Seekers
        [9714]      = 2387,     -- Seeker's Expedition/Tortollan Seekers
        [9735]      = 1133,     -- Ar'gorok/Bilgewater Cartel
        [10006]     = 2387,     -- House of Jol/Tortollan Seekers
        [10504]     = 2386,     -- Chamber of Heart (rebuilt)/Champions of Azeroth
        [15539]     = 1098,     -- Archerus: The Ebon Hold (Class Hall)/Knights of the Ebon Blade

        --------- Shadowlands ---------
        [11533]     = covenantRepID == 3 and 2422 or 2465, -- Tirna Noch/Night Fae or The Wild Hunt
        [12876]     = covenantRepID == 4 and 2410 or 2410, -- Seat of the Primus/The Undying Army
        [13367]     = covenantRepID == 3 and 2422 or 2465, -- Queen's Conservatory/Night Fae or The Wild Hunt
    }
    return subZonesAndFactions
end