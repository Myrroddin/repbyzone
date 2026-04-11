---@diagnostic disable: duplicate-set-field
-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local LibStub = LibStub
local UnitFactionGroup = UnitFactionGroup

------------------- Get addon reference --------------------
---@class RepByZone: AceAddon, AceEvent-3.0, AceConsole-3.0
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

function RepByZone:ZoneAndFactionList()
	local H = UnitFactionGroup("player") == "Horde"
	local A = UnitFactionGroup("player") == "Alliance"
	-- [UImapID] = factionID
	-- If an UImapID is not listed, that zone has no associated factionID
	-- see https://warcraft.wiki.gg/wiki/InstanceID#Retail or https://wago.tools/db2/UiMap for the list of UImapIDs
	-- see https://warcraft.wiki.gg/wiki/FactionID#Retail for the list of factionIDs

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

		--------- WoD ---------
		[525]		= 1445,						-- Frostfire Ridge/Frostwolf Orcs
		[534]		= A and 1847 or H and 1848,	-- Tanaan Jungle/Hand of the Prophet or Vol'jin's Headhunters
		[535]		= A and 1731 or H and 1445,	-- Talador/Council of Exarchs or Frostwolf Orcs
		[539]		= 1731,						-- Shadowmoon Valley/Council of Exarchs
		[542]		= 1515,						-- Spires of Arak/Arakkoa Outcasts
		[543]		= A and 930 or H and 1708,	-- Gorgrond/Exodar or Laughing Skull Orcs
		[550]		= 1711,						-- Nagrand/Steamwheedle Preservation Society
		[579]		= 72,						-- Lunarfall Excavation 1/Stormwind
		[580]		= 72,						-- Lunarfall Excavation 2/Stormwind
		[581]		= 72,						-- Lunarfall Excavation 3/Stormwind
		[582]		= 72,						-- Lunarfall/Stormwind
		[585]		= 76,						-- Frostwall Mine 1/Orgimmar
		[586]		= 76,						-- Frostwall Mine 2/Orgimmar
		[587]		= 76,						-- Frostwall Mine 3/Orgrimmar
		[588]		= A and 1682 or H and 1681, -- Ashran/Wrynn's Vanguard or Vol'jin's Spear
		[590]		= 76,						-- Frostwall/Orgrimmar
		[622]		= A and 1682 or H and 1681, -- Stormshield/Wrynn's Vanguard or Vol'jin's Spear

		--------- Legion ---------
		[626]		= 349,						-- Dalaran: Hall of Shadows (Rogue Class Hall)/Ravenholdt
		[627]		= 1090,						-- Dalaran City/Kirin Tor
		[628]		= 1090,						-- Dalaran: The Underbelly/Kirin Tor
		[629]		= 1090,						-- Dalran: Aegwynn's Gallery/Kirin Tor
		[630]		= 1900,						-- Azsuna/Court of Farondis
		[634]		= 1948,						-- Stormheim/Valarjar
		[641]		= 1883,						-- Val'sharah/Dreamweavers
		[646]		= 2045,						-- Broken Shore/Armies of Legionfall
		[647]		= 1098,						-- Acherus (Death Knight Class Hall)/Knights of the Ebon Blade
		[648]		= 1098,						-- Acherus (Death Knight Class Hall)/Knights of the Ebon Blade
		[650]		= 1828,						-- Highmountain/Highmountain Tribe
		[680]		= 1859,						-- Suramar/The Nightfallen
		[695]		= 1948,						-- Skyhold (Warrior Class Hall)/Valarjar
		[702]		= A and 930 or H and 68,	-- Netherlight Temple (Priest Class Hall)/Exodar or Undercity
		[709]		= 1341,						-- The Wandering Isle (Monk Class Hall)/The August Celestials
		[715]		= 609,						-- Emerald Dreamway/Cenarion Circle
		[717]		= A and 72 or H and 76,		-- Dreadscar Rift (Warlock Class Hall)/Stormwind or Orgrimmar
		[718]		= A and 72 or H and 76,		-- Dreadscar Rift (Warlock Class Hall)/Stormwind or Orgrimmar
		[726]		= 1135,						-- The Maelstrom/The Earthen Ring
		[734]		= 1090,						-- Hall of the Guardian (Mage Class Hall)/Kirin Tor
		[735]		= 1090,						-- The Guardian's Library (Mage Class Hall)/Kirin Tor
		[739]		= A and 69 or H and 1828,	-- Trueshot Lodge (Hunter Class Hall)/Darnassus or Highmountain Tauren
		[747]		= 609,						-- The Dreamgrove/Cenarion Circle
		[750]		= 1828,						-- Thunder Totem/Highmountain Tribe
		[787]		= 609,						-- Moonglade/Cenarion Circle
		[790]		= 1894,						-- Eye of Azshara/The Wardens
		[830]		= 2170,						-- Krokuun/Argussian Reach
		[882]		= 2170,						-- Eredath (formerly Mac'Aree)/Argussian Reach
		[1474]		= 1135,						-- Heart of Azeroth (Shaman Class Hall)/The Earthen Ring

		--------- BfA ---------
		[862]		= A and 2159 or H and 2103,	-- Zuldazar/7th Legion or Zandalari Empire
		[863]		= A and 2159 or H and 2156,	-- Nazmir/7th Legion or Talanji's Expedition
		[864]		= A and 2159 or H and 2158,	-- Vol'dun/7th Legion or Voldunai
		[895]		= A and 2160 or H and 2157,	-- Tiragarde Sound/Proudmore Admiralty or The Honorbound
		[896]		= A and 2167 or H and 2157,	-- Drustvar/Order of Embers or The Honorbound
		[942]		= A and 2162 or H and 2157,	-- Stormsong Valley/Storm's Wake or The Honorbound
		[1161]		= A and 2160 or H and 2157,	-- Borealus/Proudmore Admiralty or The Honorbound
		[1163]		= A and 2159 or H and 2103,	-- Dazar'alor: The Great Seal/7th Legion or Zandalari Empire
		[1164]		= A and 2159 or H and 2103,	-- Dazar'alor: Hall of Chroniclers/7th Legion or Zandalari Empire
		[1165]		= A and 2159 or H and 2103,	-- Dazar'alor/7th Legion or Zandalari Empire
		[1193]		= A and 2159 or H and 2103,	-- Zuldazar/7th Legion or Zandalari Empire
		[1355]		= A and 2400 or H and 2373,	-- Nazjatar/Waveblade Ankoan or The Unshackled
		[1462]		= 2391,						-- Mechagon Island/Rustbolt Resistance
		[1497]		= 2391,						-- Mechagon City/Rustbolt Resistance
		[1527]		= 2417,						-- Uldum/Uldum Accord
		[1530]		= 2415,						-- Vale of Eternal Blossoms/Rajani
		[1570]		= 2415,						-- Vale of Eternal Blossoms/Rajani
		[1571]		= 2417,						-- Uldum/Uldum Accord
		[1573]		= 2391,						-- Mechagon City/Rustbolt Resistance
		[1574]		= 2391,						-- Mechagon City/Rustbolt Resistance

		--------- Shadowlands ---------
		[1525]		= 2413,						-- Revendreth/Court of Harvesters
		[1533]		= 2407,						-- Bastion/The Ascended
		[1536]		= 2410,						-- Maldraxxus/The Undying Army
		[1543]		= 2432,						-- The Maw/Ve'nari
		[1565]		= 2465,						-- Ardenweald/The Wild Hunt
		[1569]		= 2407,						-- Bastion/The Ascended
		[1603]		= 2465,						-- Ardenweald/The Wild Hunt
		[1648]		= 2432,						-- The Maw/Ve'nari
		[1670]		= self.covenantRepID,		-- Oribos: Ring of Fates/Covenant
		[1671]		= self.covenantRepID,		-- Oribos: Ring of Transference/Covenant
		[1672]		= self.covenantRepID,		-- Oribos: The Broker's Den/Covenant
		[1673]		= self.covenantRepID,		-- Oribos: The Crucible/Covenant
		[1688]		= 2413,						-- Revendreth/Court of Havesters
		[1689]		= 2410,						-- Maldraxxus/The Undying Army
		[1701]		= 2465,						-- Heart of the Forest/The Wild Hunt
		[1702]		= 2465,						-- Heart of the Forest/The Wild Hunt
		[1703]		= 2465,						-- Heart of the Forest/The Wild Hunt
		[1707]		= 2407,						-- Elysian Hold/The Ascended
		[1708]		= 2407,						-- Sanctum of Binding/The Ascended
		[1709]		= 2465,						-- Ardenweald/The Wild Hunt
		[1734]		= 2413,						-- Revendreth/Court of Harvesters
		[1738]		= 2413,						-- Revendreth/Court of Harvesters
		[1739]		= 2465,						-- Ardenweald/The Wild Hunt
		[1740]		= 2465,						-- Ardenweald/The Wild Hunt
		[1741]		= 2410,						-- Maldraxxus/The Undying Army
		[1742]		= 2413,						-- Revendreth/Court of Harvesters
		[1813]		= 2407,						-- Bastion/The Ascended
		[1814]		= 2410,						-- Maldraxxus/The Undying Army
		[1911]		= 2432,						-- Torghast: Tower of the Damned/Ve'nari
		[1960]		= 2432,						-- The Maw/Ve'nari
		[1961]		= 2470,						-- Korthia/Death's Advance
		[1970]		= 2478,						-- Zereth Mortis/The Enlightened
		[1971]		= 1948,						-- Skyhold/Valarjar
		[2005]		= 2465,						-- Ardenweald/The Wild Hunt

		--------- Dragonflight ---------
		[1475]		= 2574,						-- The Emerald Dream/Dream Wardens
		[2022]		= 2507,						-- The Waking Shores/Dragonscale Expedition
		[2023]		= 2503,						-- Ohn'ahran Plains/Maruuk Centaur
		[2024]		= 2511,						-- The Azure Span/Iskaara Tuskarr
		[2025]		= 2510,						-- Thaldraszus/Valdrakken Accord
		[2107]		= A and 2524 or H and 2523,	-- The Forbidden Reach/Obsidian Warders or Dark Talons
		[2112]		= 2510,						-- Valdrakken/Valdrakken Accord
		[2118]		= A and 2524 or H and 2523,	-- The Forbidden Reach/Obsidian Warders or Dark Talons
		[2131]		= A and 2524 or H and 2523,	-- The Forbidden Reach/Obsidian Warders or Dark Talons
		[2133]		= 2564,						-- Zaralek Cavern/Loamm Niffen
		[2134]		= 2510,						-- Valdrakken/Valdrakken Accord
		[2151]		= A and 2524 or H and 2523,	-- The Forbidden Reach/Obsidian Warders or Dark Talons
		[2175]		= 2564,						-- Zaralek Cavern/Loamm Niffen
		[2200]		= 2574,						-- Emerald Dream/Dream Wardens
		[2268]		= 2574,						-- Amirdrassil/Dream Wardens
	}
	return zonesAndFactions
end