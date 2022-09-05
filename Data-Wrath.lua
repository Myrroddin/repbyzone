local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"

function RepByZone:ZoneAndFactionList()
    -- UImapID = factionID
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
        -- instanceID = factionID
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

function RepByZone:SubZonesAndFactions()
    local subZonesAndFactions = {
		-- areaID = factionID
		-- see https://wow.tools/dbc/?dbc=areatable&build=1.13.3.32887#search=&page=1
		
        --------- Vanilla ---------
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

        --------- TBC ---------
        [3482]      = 922,      -- The Dead Scar (Eversong Woods)/Tranquillien
        [3514]      = 922,      -- The Dead Scar (Ghostlands)/Tranquillien
        [3530]      = A and 930 or H and 911, -- Shadow Ridge/Exodar or Silvermoon City
        [3547]      = 1077,     -- Throne of Kil'jaeden/Shattered Sun Offensive
        [3552]      = 978,      -- Temple of Telhamat/Kurenai
        [3554]      = 911,      -- Falcon Watch/Silvermoon City
        [3555]      = 941,      -- Mag'har Post/The Mag'har
        [3569]      = 69,       -- Tides' Hollow/Darnassus
        [3573]      = 72,       -- Odesyus' Landing/Stormwind
        [3590]      = 69,       -- Wrathscale Lair/Darnassus
        [3591]      = 69,       -- Ruins of Loreth'Aran/Darnassus
        [3598]      = 69,       -- Wyrmscar Island/Darnassus
        [3623]      = 933,      -- Aeris Landing/The Consortium
        [3673]      = 47,       -- Nesingwary Safari/Ironforge
        [3828]      = A and 930 or H and 911, -- Halaa/Exodar or Silvermoon City
        [3630]      = 933,      -- Oshu'gun/The Consortium
        [3631]      = 933,      -- Spirit Fields/The Consortium
        [3644]      = 930,      -- Telredor/Exodar
        [3645]      = 530,      -- Zabra'jin/Darkspear Trolls
        [3646]      = 970,      -- Quagg Ridge/Sporeggar
        [3647]      = 970,      -- The Spawning Glen/Sporeggar
        [3649]      = 970,      -- Sporeggar/Sporeggar
        [3652]      = 970,      -- Funggor Cavern/Sporeggar
        [3674]      = 942,      -- Cenarion Thicket/Cenarion Expedition
        [3679]      = 1031,     -- Skettis/Sha'tari Skyguard
        [3680]      = 1031,     -- Blackwind Valley/Sha'tari Skyguard
        [3681]      = 934,      -- Firewing Point/The Scryers
        [3683]      = 941,      -- Stonebreaker Hold/The Mag'har
        [3684]      = 69,       -- Allerian Stronghold/Darnassus
        [3690]      = 1031,     -- Blackwind Lake/Sha'tari Skyguard
        [3691]      = 1031,     -- Lake Ere'Noru/Sha'tari Skyguard
        [3718]      = 530,      -- Swamprat Post/Darkspear Trolls
        [3719]      = 941,      -- Bleeding Hollow Ruins/The Mag'har
        [3744]      = 76,       -- Shadowmoon Village/Orgrimmar
        [3754]      = 932,      -- Altar of Sha'tar/The Aldor
        [3758]      = 1015,     -- Netherwing Fields/Netherwing
        [3759]      = 1015,     -- Netherwing Ledge/Netherwing
        [3766]      = 978,      -- Orebor Harborage/Kurenai
        [3769]      = 941,      -- Thunderlord Stronghold/The Mag'har
        [3771]      = 69,       -- The Living Grove/Darnassus
        [3772]      = 69,       -- Sylvanaar/Darnassus
        [3784]      = 1031,     -- Forge Camp: Terror/Sha'tari Skyguard
        [3785]      = 1031,     -- Forge Camp: Wrath/Sha'tari Skyguard
        [3786]      = 1038,     -- Ogri'la/Ogri'la
        [3792]      = 933,      -- Mana-Tombs/The Consortium
        [3801]      = 941,      -- Mag'har Grounds/The Mag'har
        [3806]      = 911,      -- Supply Caravan/Silvermoon City
        [3808]      = 942,      -- Cenarion Post/Cenarion Expedition
        [3816]      = 21,       -- Zeppelin Crash/Booty Bay
        [3828]      = 942,      -- Ruuan Weald/Cenarion Expedition
        [3832]      = 1038,     -- Vortex Summit/Ogri'la
        [3839]      = 1011,     -- Abandoned Armory/Lower City
        [3842]      = 935,      -- Tempest Keep (Netherstorm)/The Sha'tar
        [3864]      = 1031,     -- Bash'ir Landing/Sha'tari Skyguard
        [3896]      = 932,      -- Aldor Rise/The Aldor
        [3898]      = 934,      -- Scryer's Tier/The Scryers
        [3899]      = 1011,     -- Lower City/Lower City
        [3901]      = 69,       -- Allerian Post/Darnassus
        [3902]      = 941,      -- Stonebreaker Camp/The Mag'har
        [3918]      = 54,       -- Toshley's Station/Gnomeregan
        [3937]      = 76,       -- Slag Watch/Orgrimmar
        [3938]      = 934,      -- Sanctum of the Stars/The Scryers
        [3951]      = 942,      -- Evergrove/Cenarion Expedition
        [3952]      = 942,      -- Wyrmskull Bridge/Cenarion Expedition
        [3958]      = 1031,     -- Sha'tari Base Camp/Sha'tari Skyguard
        [3965]      = 1015,     -- Netherwing Mines/Netherwing
        [3966]      = 1015,     -- Dragonmaw Base Camp/Netherwing
        [3964]      = 1031,     -- Skyguard Outpost/Sha'tari Skyguard
        [3973]      = 1031,     -- Blackwind Landing/Sha'tari Skyguard
        [3974]      = 1031,     -- Veil Harr'ik/Sha'tari Skyguard
        [3975]      = 1031,     -- Terokk's Rest/Sha'tari Skyguard
        [3976]      = 1031,     -- Veil Ala'rak/Sha'tari Skyguard
        [3977]      = 1031,     -- Upper Veil Shil'ak/Sha'tari Skyguard
        [3978]      = 1031,     -- Lower Veil Shil'ak/Sha'tari Skyguard
        [5554]      = 935,      -- The Mechanar Entrance/The Sha'tar
        [5555]      = 935,      -- The Botanica Entrance/The Sha'tar
        [5556]      = 935,      -- The Arcatraz Entrance/The Sha'tar
    }
    return subZonesAndFactions
end