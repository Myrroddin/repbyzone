---@diagnostic disable: duplicate-set-field
-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local LibStub = LibStub
local UnitFactionGroup = UnitFactionGroup

------------------- Get addon reference --------------------
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")
---@cast RepByZone RepByZoneAddon

function RepByZone:ZoneAndFactionList()
	local H = UnitFactionGroup("player") == "Horde"
	local A = UnitFactionGroup("player") == "Alliance"
	-- [UImapID] = factionID
	-- If an UImapID is not listed, that zone has no associated factionID
	-- see https://warcraft.wiki.gg/wiki/UiMapID or https://wago.tools/db2/UiMap?build=5.5.3.66565 for the list of UImapIDs
	-- see https://warcraft.wiki.gg/wiki/FactionID for the list of factionIDs

	local zonesAndFactions = {
		--------- Vanilla ----------
		[1]			= 46,						-- Durotar/Orgrimmar
		[3]			= 72,						-- Tiragarde Keep/Stormwind
		[4]			= 72,						-- Tiragarde Keep (Great Hall)/Stormwind
		[7]			= 81,						-- Mulgore/Thunder Bluff
		[10]		= A and 470 or H and 76,	-- Northern Barrens/Ratchet or Orgrimmar
		[14]		= A and 509 or H and 510,	-- Arathi Highlands/The League of Arathor or The Defilers
		[15]		= A and 47 or H and 76,		-- Badlands/Ironforge or Orgrimmar
		[17]		= A and 72 or H and 76,		-- Blasted Lands/Stormwind or Orgrimmar
		[18]		= 68,						-- Tirisfal Glades/Undercity
		[21]		= A and 1134 or H and 68,	-- Silverpine Forest/Gilneas or Undercity
		[22]		= 1106,						-- Western Plaguelands/Argent Crusade
		[23]		= 1106,						-- Eastern Plaguelands/Argent Crusade
		[25]		= 68,						-- Hillsbrad Foothills/Undercity
		[26]		= A and 1174 or H and 530,	-- Hinterlands/Wildhammer Clan or Darkspear Trolls
		[27]		= 47,						-- Dun Morogh/Ironforge
		[30]		= 54,						-- New Tinkertown/Gnomeregan
		[32]		= 59,						-- Searing Gorge/Thorium Brotherhood
		[36]		= A and 72 or H and 76,		-- Burning Steppes/Stormwind or Orgrimmar
		[37]		= 72,						-- Elwynn Forest/Stormwind
		[41]		= 1090,						-- Dalaran Crater/Kirin Tor
		[42]		= 967,						-- Deadwind Pass/The Violet Eye
		[47]		= A and 72 or H and 68,		-- Duskwood/Stormwind or Undercity
		[48]		= 47,						-- Loch Modan/Ironforge
		[49]		= 72,						-- Redridge Mountains/Stormwind
		[50]		= A and 72 or H and 76,		-- Northern Stranglethorn/Stormwind or Orgrimmar
		[51]		= 76,						-- Swamp of Sorrows/Orgrimmar
		[52]		= 72,						-- Westfall/Stormwind
		[56]		= 47,						-- Wetlands/Ironforge
		[57]		= 69,						-- Teldrassil/Darnassus
		[62]		= 69,						-- Darkshore/Darnassus
		[63]		= A and 69 or H and 1085,	-- Ashenvale/Darnassus or Warsong Offensive
		[64]		= A and 54 or H and 1133,	-- Thousand Needles/Gnomeregan or Bilgewater Cartel
		[65]		= A and 69 or H and 81,		-- Stonetalon Mountains/Darnassus or Thunder Bluff
		[66]		= 609,						-- Desolace/Cenarion Circle
		[69]		= A and 69 or H and 81,		-- Feralas/Darnassus or Thunder Bluff
		[70]		= A and 72 or H and 76,		-- Dustwallow Marsh/Stormwind or Orgrimmar
		[71]		= 369,						-- Tanaris/Gadgetzan
		[74]		= 989,						-- Timeless Tunnel/Keepers of Time
		[75]		= 989,						-- Caverns of Time/Keepers of Time
		[76]		= 1133,						-- Azshara/Bilgewater Cartel
		[77]		= A and 69 or H and 1133,	-- Felwood/Darnassus or Bilgewater Cartel
		[80]		= 609,						-- Moonglade/Cenarion Circle
		[81]		= 609,						-- Silithus/Cenarion Circle
		[83]		= 577,						-- Winterspring/Everlook
		[84]		= 72,						-- Stormwind City/Stormwind
		[85]		= 76,						-- Orgrimmar/Orgrimmar
		[87]		= 47,						-- Ironforge/Ironforge
		[88]		= 81,						-- Thunder Bluff/Thunder Bluff
		[89]		= 69,						-- Darnassus/Darnassus
		[90]		= 68,						-- Undercity/Undercity

		--------- TBC ---------
		[94]		= 911,						-- Eversong Woods/Silvermoon City
		[95]		= 922,						-- Ghostlands/Tranquillien
		[97]		= 930,						-- Azuremyst Isle/Exodar
		[100]		= A and 946 or H and 947,	-- Hellfire Peninsula/Honor Hold or Thrallmar
		[102]		= 942,						-- Zangarmarsh/Cenarion Expedition
		[103]		= 930,						-- The Exodar/Exodar
		[104]		= 1012,						-- Shadowmoon Valley/Ashtongue Deathsworn
		[105]		= 1038,						-- Blade's Edge Mountains/Ogri'la
		[106]		= 930,						-- Bloodmyst Isle/Exodar
		[107]		= A and 978 or H and 941,	-- Nagrand/Kurenai or The Mag'har
		[108]		= 1011,						-- Terokkar Forest/Lower City
		[109]		= 933,						-- Netherstorm/The Consortium
		[110]		= 911,						-- Silvermoon City/Silvermoon City
		[111]		= 935,						-- Shattrath City/The Sha'tar
		[122]		= 1077,						-- Isle of Quel'Danas/Shattered Sun Offensive

		--------- WotLK ---------
		[114]		= A and 1050 or H and 1085,	-- Borean Tundra/Valiance Expedition or Warsong Offensive
		[115]		= 1091,						-- Dragonblight/The Wyrmrest Accord
		[116]		= A and 1050 or H and 1085,	-- Grizzly Hills/Valiance Expedition or Warsong Offensive
		[117]		= A and 1050 or H and 1067,	-- Howling Fjord/Valiance Expedition or The Hand of Vengeance
		[118]		= 1098,						-- Icecrown/Knights of the Ebon Blade
		[120]		= 1119,						-- The Storm Peaks/The Sons of Hodir
		[121]		= 1106,						-- Zul'Drak/Argent Crusade
		[123]		= A and 1050 or H and 1052,	-- Wintergrasp/Valiance Expedition or Horde Expedition
		[124]		= self.racialRepID,			-- Plaguelands: The Scarlet Enclave (DK starting zone)/racial rep
		[125]		= 1090,						-- Dalaran City/Kirin Tor
		[126]		= 1090,						-- Dalaran City (The Underbelly)/Kirin Tor
		[127]		= 1090,						-- Crystalsong Forest/Kirin Tor
		[170]		= 1106,						-- Hrothgar's Landing/Argent Crusade

		--------- Cataclysm ---------
		[174]		= 1133,						-- The Lost Isles/Bilgewater Cartel
		[179]		= 1134,						-- Gilneas/Gilneas
		[194]		= 1133,						-- Kezan/Bilgewater Cartel
		[198]		= 1158,						-- Mount Hyjal/Guardians of Hyjal
		[199]		= A and 72 or H and 76,		-- Southern Barrens/Stormwind or Orgrimmar
		[201]		= 1135,						-- Kelp'thar Forest/The Earthen Ring
		[202]		= 1134,						-- Gilneas City/Gilneas
		[203]		= 1135,						-- Vashj'ir/The Earthen Ring
		[204]		= 1135,						-- Abyssal Depths/The Earthen Ring
		[205]		= 1135,						-- Shimmering Expanse/The Earthen Ring
		[207]		= 1135,						-- Deephom/The Earthen Ring
		[210]		= A and 72 or H and 76,		-- The Cape of Stranglethorn/Stormwind or Orgrimmar
		[217]		= A and 1134 or H and 68,	-- Ruins of Gilneas/Gilneas or Undercity
		[218]		= 1134,						-- Ruins of Gilneas City/Gilneas
		[224]		= A and 72 or H and 76,		-- Stranglethorn Vale/Stormwind or Orgrimmar
		[241]		= A and 1174 or H and 1172,	-- Twilight Highlands/Wildhammer Clan or Dragonmaw Clan
		[244]		= A and 1177 or H and 1178,	-- Tol Barad/Baradin's Warders or Hellscream's Reach
		[245]		= A and 1177 or H and 1178,	-- Tol Barad Peninsula/Baradin's Warders or Hellscream's Reach
		[249]		= 1173,						-- Uldum/Ramkahen
		[276]		= 1135,						-- The Maelstrom/The Earthen Ring
		[738]		= 1204,						-- Firelands/Avengers of Hyjal

		--------- MoP ---------
		[371]		= A and 1242 or H and 1228,	-- Jade Forest/Pearlfin Jinyu or Forest Hozen
		[376]		= 1272,						-- Valley of the Four Winds/The Tillers
		[378]		= (A and 1353) or (H and 1352) or 1216,	-- The Wandering Isle/Tushui Pandaren or Huojin Pandaren or Shang Xi's Academy
		[379]		= 1270,						-- Kun-Lai Summit/Shado-Pan
		[388]		= 1270,						-- Towlong Steppes/Shado-Pan
		[390]		= 1269,						-- Vale of Eternal Blossoms/Golden Lotus
		[407]		= 909,						-- Darkmoon Island (orphan)/Darkmoon Faire
		[408]		= 909,						-- Darkmoon Island (dungeon)/Darkmoon Faire
		[418]		= 1302,						-- Krasarang Wilds/The Anglers
		[422]		= 1337,						-- Dread Wastes/The Klaxxi
		[425]		= 72,						-- Northshire/Stormwind
		[433]		= 1359,						-- The Veiled Stair/The Black Prince
		[507]		= A and 72 or H and 76,		-- Isle of Giants/Stormwind or Orgrimmar
		[516]		= A and 1387 or H and 1388,	-- Isle of Thunder/Kirin Tor Offensive or Sunreaver Onslaught
		[554]		= 1492,						-- Timeless Isle/Emperor Shaohao
	}
	return zonesAndFactions
end