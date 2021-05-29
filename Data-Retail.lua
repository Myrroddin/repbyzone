local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"

function RepByZone:ZoneAndFactionList()
    -- UImapID = factionID
    -- If an UImapID is not listed, that zone has no associated factionID
    -- see https://wow.gamepedia.com/UiMapID for the list of UImapIDs
    -- see https://wow.gamepedia.com/FactionID for the list of factionIDs

    if self.covenantRepID == nil then
        self.covenantRepID = self:CovenantToFactionID()
    end
    local covenantRepID = self.covenantRepID
    local db = self.db.char

    local zonesAndFactions = {
        --------- Vanilla ----------
        [1]         = 46,       -- Durotar/Orgrimmar
        [3]         = 72,       -- Tiragarde Keep/Stormwind
        [4]         = 72,       -- Tiragarde Keep (Great Hall)/Stormwind
        [7]         = 81,       -- Mulgore/Thunder Bluff
        [10]        = A and 470 or H and 76, -- Northern Barrens/Ratchet or Orgrimmar
        [14]        = A and 509 or H and 510, -- Arathi Highlands/The League of Arathor or The Defilers
        [15]        = A and 47 or H and 76, -- Badlands/Ironforge or Orgrimmar
        [17]        = A and 72 or H and 76, -- Blasted Lands/Stormwind or Orgrimmar
        [18]        = 68,       -- Tirisfal Glades/Undercity
        [21]        = A and 1134 or H and 68, -- Silverpine Forest/Gilneas or Undercity
        [22]        = 1106,      -- Western Plaguelands/Argent Crusade
        [23]        = 1106,      -- Eastern Plaguelands/Argent Crusade
        [25]        = 68,       -- Hillsbrad Foothills/Undercity
        [26]        = A and 1174 or H and 530, -- Hinterlands/Wildhammer Clan or Darkspear Trolls
        [27]        = 47,       -- Dun Morogh/Ironforge
        [30]        = 54,       -- New Tinkertown/Gnomeregan
        [32]        = 59,       -- Searing Gorge/Thorium Brotherhood
        [36]        = A and 72 or H and 76, -- Burning Steppes/Stormwind or Orgrimmar
        [37]        = 72,       -- Elwynn Forest/Stormwind
        [41]        = 1090,     -- Dalaran/Kirin Tor
        [42]        = 967,      -- Deadwind Pass/The Violet Eye
        [47]        = A and 72 or H and 68, -- Duskwood/Stormwind or Undercity
        [48]        = 47,       -- Loch Modan/Ironforge
        [49]        = 72,       -- Redridge Mountains/Stormwind
        [50]        = A and 72 or H and 76, -- Northern Stranglethorn/Stormwind or Orgrimmar
        [51]        = 76,       -- Swamp of Sorrows/Orgimmar
        [52]        = 72,       -- Westfall/Stormwind
        [56]        = 47,       -- Wetlands/Ironforge
        [57]        = 69,       -- Teldrassil/Darnassus
        [62]        = 69,       -- Darkshore/Darnassus
        [63]        = A and 69 or H and 1085, -- Ashenvale/Darnassus or Warsong Offensive
        [64]        = A and 54 or H and 1133, -- Thousand Needles/Gnomeregan or Bilgewater Cartel
        [65]        = A and 69 or H and 81, -- Stonetalon Mountains/Darnassus or Thunder Bluff
        [66]        = 609,      -- Desolace/Cenarion Circle
        [69]        = A and 69 or H and 81, -- Feralas/Darnassus or Thunder Bluff
        [70]        = A and 72 or H and 76, -- Dustwallow Marsh/Stormwind or Orgrimmar
        [71]        = 369,      -- Tanaris/Gadgetzan
        [74]        = 989,      -- Timeless Tunnel/Keepers of Time
        [75]        = 989,      -- Caverns of Time/Keepers of Time
        [76]        = 1133,     -- Azshara/Bilgewater Cartel
        [77]        = A and 69 or H and 1133, -- Felwood/Darnassus or Bilgewater Cartel
        [80]        = 609,      -- Moonglade/Cenarion Circle
        [81]        = 609,      -- Silithus/Cenarion Circle
        [83]        = 577,      -- Winterspring/Everlook
        [84]        = 72,       -- Stormwind City/Stormwind
        [85]        = 76,       -- Orgrimmar/Orgrimmar
        [87]        = 47,       -- Ironforge/Ironforge
        [88]        = 81,       -- Thunder Bluff/Thunder Bluff
        [89]        = 69,       -- Darnassus/Darnassus
        [90]        = 68,       -- Undercity/Undercity

        --------- TBC ---------
        [94]        = 911,      -- Eversong Woods/Silvermoon City
        [95]        = 922,      -- Ghostlands/Tranquillien
        [97]        = 930,      -- Azuremyst Isle/Exodar
        [100]       = A and 946 or H and 947, -- Hellfire Peninsula/Honor Hold or Thrallmar
        [102]       = 942,      -- Zangarmarsh/Cenarion Expedition
        [103]       = 930,      -- The Exodar/Exodar
        [104]       = 1012,     -- Shadowmoon Valley/Ashtongue Deathsworn
        [106]       = 930,      -- Bloodmyst Isle/Exodar
        [107]       = A and 978 or H and 941, -- Nagrand/Kurenai or The Mag'har
        [108]       = 1011,     -- Terokkar Forest/Lower City
        [109]       = 933,      -- Netherstorm/The Consortium
        [110]       = 911,      -- Silvermoon City/Silvermoon City
        [111]       = 935,      -- Shattrath City/The Sha'tar
        [122]       = 1077,     -- Isle of Quel'Danas/Shattered Sun Offensive

        --------- WotLK ---------
        [114]       = A and 1050 or H and 1085, -- Borean Tundra/Valiance Expedition or Warsong Offensive
        [115]       = 1091,     -- Dragonblight/The Wyrmrest Accord
        [1360]      = 1098,     -- Icecrown Citadel (The Frozen Throne)/Knights of the Ebon Blade

        --------- Cataclysm ---------

        --------- MoP ---------
        [371]       = A and 1242 or H and 1228, -- Jade Forest/Pearlfin Jinyu or Forest Hozen
        [376]       = 1272,     -- Valley of the Four Winds/The Tillers
        [379]       = 1270,     -- Kun-Lai Summit/Shado-Pan
        [388]       = 1270,     -- Towlong Steppes/Shado-Pan
        [390]       = 1269,     -- Vale of Eternal Blossoms/Golden Lotus
        [407]       = 909,      -- Darkmoon Island (orphan)/Darkmoon Faire
        [408]       = 909,      -- Darkmoon Island (dungeon)/Darkoon Faire
        [418]       = 1302,     -- Krasarang Wilds/The Anglers
        [422]       = 1337,     -- Dread Wastes/The Klaxxi
        [425]       = 72,       -- Northshire/Stormwind
        [433]       = 1359,     -- The Veiled Stair/The Black Prince
        [507]       = A and 72 or H and 76, -- Isle of Giants/Stormwind or Orgrimmar
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
        [133]       = 54,       -- New Tinkertown/Gnomeregan
		[150]       = 72,       -- Menethil Harbor/Stormwind
        [152]       = 1106,     -- The Bulwark/Argent Crusade
        [193]       = A and 72 or H and 68, -- Ruins of Andorhal/Stormwind or Undercity
        [196]       = 72,       -- Uthor's Tomb/Stormwind
        [197]       = 72,       -- Sorrow Hill/Stormwind
        [199]       = 72,       -- Felstone Field/Stormwind
        [201]       = 68,       -- Gahrron's Withering/Undercity
        [202]       = 68,       -- Writhing Haunt/Undercity
        [204]       = 1134,     -- Pyrewood Village/Gilneas
        [233]       = 1134,     -- Ambermill/Gilneas
        [250]       = 59,       -- Ruins of Thaurissan
        [279]       = 1090,     -- Dalaran Crater/Kirin Tor
        [280]       = 349,      -- Strahnbrad/Ravenholdt
        [288]       = 72,       -- Azurelode Mine/Stormwind
		[297]       = 81,       -- Jaguero Isle/Thunder Bluff
		[299]       = 72,       -- Menethil Bay/Stormwind
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
        [484]       = H and 81 or A and 69, -- Freewind Post/Thunder Bluff or Darnassus
        [501]       = 369,     -- Beezil's Wreck/Gadgetzan
        [517]       = 1358,     -- Tidefury Cove/Nat Pagle
        [530]       = 69,       -- Quel'Danil Lodge/Darnassus
		[596]       = 470,      -- Kodo Graveyard/Ratchet
        [603]       = 69,       -- Sargeron/Darnassus
        [604]       = 93,       -- Magram Village (Shok'Thokar)/Magram Clan Centaur
        [606]       = 92,       -- Gelkis Village/Gelkis Clan Centaur
        [608]       = 69,       -- Nijel's Point/Darnassus
        [609]       = 93,       -- Kolkar Village/Magram Clan Centaur
        [702]       = 69,       -- Rut'theran Village/Darnassus
        [721]       = 54,       -- Gnomeregan/Gnomeregan
        [813]       = 1106,     -- The Bulwark/Argent Crusade
        [880]       = 1174,     -- Thandol Span (Arathi Highlands)/Wildhammer Clan
        [881]       = 47,       -- Thandol Span (Wetlands)/Ironforge
        [896]       = A and 730 or H and 729, -- Purgation Isle/Stormpike Guard or Frostwolf Clan
        [987]       = 1133,     -- Land's End Beach/Bilgewater Cartel
        [989]       = 1173,     -- Ruins of Uldum/Ramkahen
        [990]       = 1173,     -- Valley of the Watchers/Ramkahen
        [1016]      = 69,       -- Direforge Hill/Darnassus
        [1025]      = 69,       -- The Green Belt/Darnassus
        [1057]      = A and 47 or H and 68, -- Thoradin's Wall (Hillsbrad Foothills)/Ironforge or Undercity
        [1216]      = 579,      -- Timbermaw Hold/Timbermaw Hold
        [1220]      = 69,       -- Darnassian Base Camp/Darnassus
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
        [1769]      = 579,      -- Timbermaw Hold/Timbermaw Hold
        [1778]      = 369,      -- Sorrowmurk/Gadgetzan
        [1797]      = 1133,     -- Stagalbog/Bilgewater Cartel
        [1857]      = A and 47 or H and 68, -- Thoradin's Wall (Arathi Highlands)/Ironforge or Undercity
		[1858]      = 1174,     -- Boulder'gor/Wildhammer Clan
        [1941]      = 989,      -- Caverns of Time/Keepers of Time
        [1998]      = 1134,     -- Talonbranch Glade/Gilneas
        [2079]      = A and 54 or H and 68, -- Alcaz Island/Gnomeregan or Undercity
		[2097]      = H and 81 or A and 69, -- Darkcloud Pinnacle/Thunder Bluff or Darnassus
		[2157]      = H and 81 or A and 47, -- Bael'dun Keep/Thunder Bluff or Ironforge
		[2240]      = A and 54 or H and 1133, -- Mirage Raceway/Gnomeregan or Bilgewater Cartel
        [2241]      = 589,      -- Frostsaber Rock/Wintersaber Trainers
        [2242]      = 69,       -- The Hidden Grove/Darnassus
        [2243]      = 579,      -- Timbermaw Post/Timbermaw Hold
        [2244]      = 579,      -- Winterfall Village/Timbermaw Hold
        [2246]      = 579,      -- Frostfire Hot Springs/Timbermaw Hold
        [2248]      = 47,       -- Dun Mandarr/Ironforge
        [2253]      = 69,       -- Starfall Village/Darnassus
        [2257]      = 72,       -- Deeprun Tram/Stormwind
        [2300]      = 989,      -- Caverns of Time/Keepers of Time
        [2379]      = 72,       -- Azurelode Mine/Stormwind
        [2404]      = 69,       -- Tethris Aran/Darnassus
        [2406]      = 69,       -- Ranazjar Isle/Darnassus
        [2407]      = 470,      -- Kormek's Hut/Ratchet
        [2408]      = 530,      -- Shadowprey Village/Darkspear Trolls
        [2539]      = 530,      -- Malaka'jin/Darkspear Trolls
        [2597]      = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [2617]      = 470,      -- Scrabblescrew's Camp/Ratchet
        [2738]      = 69,       -- Southwind Village/Darnassus
        [2839]      = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [2897]      = 530,      -- Zoram'gar Outpost/Darkspear Trolls
        [3137]      = 69,       -- Talrendis Point/Darnassus
		[3197]      = 72,       -- Chillwind Camp/Stormwind
        [3319]      = 890,      -- Silverwing Grove/Silverwing Sentinels
        [3426]      = 69,       -- Staghelm Point/Darnassus
        [3427]      = 47,       -- Bronzebeard Encampment/Ironforge
        [3486]      = 349,      -- Ravenholdt Manor/Ravenholdt
        [4010]      = 369,      -- Mudsprocket/Gadgetzan
        [4690]      = 1135,     -- Thunder Peak/The Earthen Ring
        [4715]      = 1133,     -- The Skunkworks/Bilgewater Cartel
        [4745]      = 76,       -- Orgrimmar Rear Gate/Orgrimmar
        [4798]      = 1068,     -- Thoargad's Camp/Explorer's League
        [4803]      = 911,      -- Furien's Post/Silvermoon City
        [4882]      = 369,      -- Marshal's Stand/Gadgetzan
        [4883]      = 369,      -- Mossy Pile/Gadgetzan
        [4925]      = 609,      -- Thunk's Abode/Cenarion Circle
        [4927]      = 76,       -- The Fold/Orgimmar
        [4933]      = 76,       -- Krom'gar Fortress/Orgimmar
        [4934]      = 1133,     -- The Sludgewerks/Bilgewater Cartel
        [4940]      = 1068,     -- Northwatch Expedition Base Camp/Explorer's League
        [5011]      = 81,       -- Westreach Summit/Thunder Bluff
        [5028]      = 87,       -- Southsea Holdfast/Bloodsail Buccaneers
        [5041]      = A and 54 or H and 1133, -- Fizzle & Pozzik's Speedbarge/Gnomeregan or Bilgewater Cartel
        [5044]      = 609,      -- The Tainted Forest/Cenarion Circle
        [5048]      = A and 54 or H and 1133, -- Raceway Ruins/Gnomeregan or Bilgewater Cartel
        [5083]      = 911,      -- Sunveil Excursion/Silvermoon City
        [5117]      = 1133,     -- Nozzlepot's Outpost/Bilgewater Cartel
        [5121]      = 68,       -- Galen's Fall/Undercity
        [5305]      = 69,       -- Greenwarden's Grove/Darnassus
        [5317]      = 530,      -- Bambala/Darkspear Trolls
        [5367]      = 942,      -- The Mender's Stead/Cenarion Circle
        [5388]      = 911,      -- Dawnrise Expedition/Silvermoon City
        [5458]      = 369,      -- Bogpaddle/Gadgetzan
        [5476]      = 1134,     -- Pyrewood Chapel/Gilneas
        [5477]      = 1134,     -- Pyrewood Inn/Gilneas
        [5478]      = 1134,     -- Pyrewood Town Hall/Gilneas
        [5480]      = 1134,     -- Gilneas Liberation Base Camp/Gilneas
        [5481]      = 47,       -- 7th Legion Base Camp/Ironforge
        [5495]      = 54,       -- Gnomeregan/Gnomeregan
        [5496]      = 369,      -- Fuselight/Gadgetzan
        [5497]      = 369,      -- Fuselight-by-the-Sea/Gadgetzan
        [5524]      = 911,      -- Bloodwatcher Point/Silvermoon City
        [5564]      = 72,       -- Dragon's Mouth/Stormwind
        [5645]      = 609,      -- Whisperwind Grove/Cenarion Circle
        [5649]      = 609,      -- Wildheart Point/Cenarion Circle
        [5654]      = 59,       -- Chiselgrip/Thorium Brotherhood
        [5675]      = A and 69 or H and 81, -- Arikara's Needle/Darnassus or Thunder Bluff
        [5687]      = 1134,     -- The Howling Oak/Gilneas
        [5705]      = A and 47 or H and 530, -- Snowden Chalet/Ironforge or Darkspear Trolls
        [5706]      = 369,      -- The Steam Pools/Gadgetzan

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
        [3596]      = A and 1135, -- The Hidden Reef/The Earthen Ring
        [3598]      = 69,       -- Wyrmscar Island/Darnassus
        [3615]      = 1135,     -- Throne of the Elements/The Earthen Ring
        [3623]      = 933,      -- Aeris Landing/The Consortium
        [3636]      = 1135,     -- Elemental Plateau/The Earthen Ring
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
        [3745]      = 1174,     -- Wildhammer Stronghold/Wildhammer Clan
        [3754]      = 932,      -- Altar of Sha'tar/The Aldor
        [3758]      = 1015,     -- Netherwing Fields/Netherwing
        [3759]      = 1015,     -- Netherwing Ledge/Netherwing
        [3766]      = 978,      -- Orebor Harborage/Kurenai
        [3778]      = 1068,     -- Draenethyst Mine/Explorer's League
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
        [3936]      = 1174,     -- Deathforge Tower/Wildhammer Clan
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

        --------- WotLK ---------
        [4023]      = 1090,     -- Amber Ledge/Kirin Tor
        [4024]      = 1090,     -- Coldarra/Kirin Tor
        [4033]      = 942,      -- Winterfin Village/Cenarion Expedition
        [4037]      = 1064,     -- Taunka'le Village/The Taunka
        [4040]      = 1073,     -- Njord's Breath Bay/The Kalu'ak
        [4041]      = 1073,     -- Kaskala/The Kalu'ak
        [4097]      = 942,      -- Winterfin Caverns/Cenarion Expedition
        [4099]      = 942,      -- Winterfin Retreat/Cenarion Expedition
        [4113]      = 1073,     -- Unu'pe/The Kalu'ak
        [4120]      = 1090,     -- The Nexus/Kirin Tor
        [4121]      = 1090,     -- Transitus Shield/Kirin Tor
        [4151]      = 1064,     -- Westwind Refuge Camp/The Taunka
        [4152]      = 1073,     -- Moa'ki Harbor/The Kalu'ak
        [4155]      = 1073,     -- The Half Shell/The Kalu'ak
        [4158]      = 1037,     -- Stars' Rest/Alliance Vanguard
        [4165]      = 1052,     -- Agmar's Hammer/Horde Expedition
        [4169]      = 1037,     -- Fordragon Hold/Alliance Vanguard
        [4170]      = 1052,     -- Kor'kron Vanguard/Horde Expedition
        [4171]      = A and 1037 or H and 1052, -- The Court of Skulls/Alliance Vanguard or Horde Expedition
        [4172]      = A and 1037 or H and 1052, -- Angrathar the Wrathgate/Alliance Vanguard or Horde Expedition
        [4177]      = 1037,     -- Wintergarde Keep/Alliance Vanguard
        [4178]      = 1037,     -- Wintergarde Mine/Alliance Vanguarde
        [4186]      = 1067,     -- Venomspite/The Hand of Vengeance
        [4188]      = 1037,     -- The Carrion Fields/Alliance Vanguard
        [4189]      = 942,      -- D.E.H.T.A Encampment/Cenarion Expedition
        [4190]      = 1037,     -- Thorson's Post/Alliance Vanguard
        [4191]      = 1106,     -- Light's Trust/Argent Crusade
        [4224]      = 1073,     -- The Briny Pinnacle/The Kalu'ak
        [4227]      = 530,      -- Dragon's Fall/Darkspear Trolls
        [4233]      = 1106,     -- Dawn's Reach/Argent Crusade
        [4234]      = 1106,     -- Naxxramas/Argent Crusade
        [4243]      = 1037,     -- Wintergarde Crypt/Alliance Vanguard
        [4246]      = 1037,     -- Wintergarde Mausoleum/Alliance Vanguard
        [4253]      = 2159,     -- 7th Legion Front/7th Legion
        [4256]      = A and 1094 or H and 1124, -- Drak'mar Lake/The Silver Covenant or The Sunreavers
        [4281]      = 1098,     -- Archerus: The Ebon Hold (Eastern Kingdoms)/Knights of the Ebon Blade
        [4342]      = 1098,     -- Archerus: The Ebon Hold(Death Knight start)/Knights of the Ebon Blade
        [5561]      = 1090,     -- The Nexus Entrance/Kirin Tor

        --------- MoP ---------
        [4081]      = 81,       -- The Dawnchaser/Thunder Bluff
        [5876]      = 1271,     -- Serpent's Heart/Order of the Cloud Serpent
        [5931]      = 1271,     -- The Arboretum/Order of the Cloud Serpent
        [5974]      = 1341,     -- Jade Temple Grounds/The August Celestials
        [5975]      = 1341,     -- Temple of the Jade Serpent/The August Celestials
        [5976]      = 1270,     -- Gate of the Setting Sun/Shado-Pan
        [6012]      = 1271,     -- Windward Isle/Order of the Cloud Serpent
        [6013]      = A and 1376 or H and 1375, -- The Dawnchaser (Retreat)/Operation: Shieldwall or Dominance Offensive
        [6016]      = 69,       -- Sentinel Basecamp/Darnassus
        [6022]      = 1271,     -- Mistveil Sea/Order of the Cloud Serpent
        [6025]      = 47,       -- Nesingwary's Safari/Ironforge
        [6048]      = 1341,     -- Temple of the Red Crane/The August Celestials
        [6059]      = A and 1353 or H and 1352, -- Binan Village/Tushui Pandaren or Huojin Pandaren
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
        [6174]      = 1341,     -- Temple of the White Tiger/The August Celestials
        [6295]      = 1345,     -- Seat of Knowledge/The Lorewalkers
        [6368]      = 1302,     -- Soggy's Gamble/The Anglers
        [6371]      = A and 1376 or H and 1375, -- The Southern Isles/Operation: Shieldwall or Dominance Offensive
        [6393]      = 1270,     -- Serpent's Spine (Valley of the Four Winds)/Shado-Pan
        [6394]      = 1270,     -- Serpent's Spine (Vale of Eternal Blossoms)/Shado-Pan
        [6395]      = 1270,     -- Serpent's Spine (Kun-Lai Summit)/Shado-Pan
        [6401]      = 1302,     -- Shelf of Mazu/The Anglers
        [6402]      = 1302,     -- Wreck of the Mist-Hopper/The Anglers
        [6433]      = 1302,     -- Lonesome Cove/The Anglers
        [6482]      = A and 1341, -- The Summer Terrace/The August Celestials
        [6498]      = 1341,     -- Gate of the August Celestials/The August Celestials
        [6512]      = 1271,     -- The Widow's Wail/Order of the Cloud Serpent
        [6513]      = 1271,     -- Oona Kagu/Order of the Cloud Serpent
        [6533]      = 72,       -- The Skyfire (Jade Forest)/Stormwind
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

        --------- Legion ---------
        [7679]      = 1098,     -- Archerus: The Ebon Hold (Broken Isles)/Knights of the Ebon Blade
        [7743]      = 1098,     -- Archerus: The Ebon Hold (Icecrown)/Knights of the Ebon Blade

        --------- BfA ---------
        [8925]      = 47,       -- Nesingwary's Trek/Ironforge
        [9310]      = 2386,     -- The Wound/Champions of Azeroth
        [9329]      = 2387,     -- Seeker's Outpost/Tortollan Seekers
        [9470]      = 2395,     -- Mildenhall Brewery/Honeyback Hive
        [9473]      = 69,       -- Staghelm Point/Darnassus
        [9474]      = 1133,     -- Southwind Village/Bilgewater Cartel
        [9494]      = 1133,     -- Warfront: The Battle for Stromgarde (Ar'gorok)/Bilgewater Cartel
        [9556]      = 2387,     -- Tortaka Refuge/Tortollan Seekers
        [9667]      = 2386,     -- Chamber of Heart (Destroyed)/Champions of Azeroth
        [9693]      = 2387,     -- Seeker's Vista/Tortollan Seekers
        [9714]      = 2387,     -- Seeker's Expedition/Tortollan Seekers
        [9735]      = 1133,     -- Ar'gorok/Bilgewater Cartel
        [9750]      = 68,       -- Hammerfall/Undercity
        [9755]      = 47,       -- Thandol Span/Ironforge
        [9756]      = 68,       -- Thoradin's Wall (Horde Warfront)/Undercity
        [9758]      = 47,       -- Thoradin's Wall (Alliance Warfront)/Ironforge
        [6759]      = A and 47 or H and 68, -- Thoradin's Wall/Ironforge or Undercity
        [10006]     = 2387,     -- House of Jol/Tortollan Seekers
        [10504]     = 2386,     -- Chamber of Heart (rebuilt)/Champions of Azeroth
        [12905]     = 2386,     -- Chamber of Heart (scenario)/Champions of Azeroth
        [13539]     = 1098,     -- Archerus: The Ebon Hold (Class Hall)/Knights of the Ebon Blade

        --------- Shadowlands ---------
        [10565]     = covenantRepID, -- Oribos/Covenant
        [10979]     = 2413,     -- Darkhaven/Court of Harvesters
        [11533]     = covenantRepID == 3 and 2422 or 2465, -- Tirna Noch/Night Fae or The Wild Hunt
        [12876]     = covenantRepID == 4 and 2410 or 2410, -- Seat of the Primus/The Undying Army
        [13209]     = covenantRepID, -- Netherhollow (Oribos)/Covenant
        [13367]     = covenantRepID == 3 and 2422 or 2465, -- Queen's Conservatory/Night Fae or The Wild Hunt
        [13414]     = 2413,     -- The Sinposium/Court of Harvesters
        [13498]     = covenantRepID, -- Ring of Transference (Oribos)/Covenant
        [13499]     = covenantRepID, -- Ring of Fates (Oribos)/Covenant
    }
    return subZonesAndFactions
end