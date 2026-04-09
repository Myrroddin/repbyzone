---@diagnostic disable: duplicate-set-field
-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local LibStub = LibStub
local UnitFactionGroup = UnitFactionGroup

------------------- Get addon reference --------------------
---@class RepByZone: AceAddon, AceEvent-3.0, AceConsole-3.0
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"
local zonesAndFactions

function RepByZone:ZoneAndFactionList()
	-- [UImapID] = factionID
	-- If an UImapID is not listed, that zone has no associated factionID
	-- see https://warcraft.wiki.gg/wiki/UiMapID#Classic for the Classic list of UImapIDs
	-- see https://warcraft.wiki.gg/wiki/FactionID#Classic for the list of factionIDs

	if zonesAndFactions then return zonesAndFactions end
	zonesAndFactions = {
		--------- Horde ----------
		[1411]		= 76,						-- Durotar/Orgrimmar
		[1454]		= 76,						-- Orgrimmar/Orgrimmar
		[1412]		= 81,						-- Mulgore/Thunder Bluff
		[1456]		= 81,						-- Thunder Bluff/Thunder Bluff
		[1421]		= 68,						-- Silverpine Forest/Undercity
		[1458]		= 68,						-- Undercity/Undercity
		[1420]		= 68,						-- Tirisfal Glades/Undercity

		--------- Alliance ----------
		[1453]		= 72,						-- Stormwind City/Stormwind
		[1429]		= 72,						-- Elwynn Forest/Stormwind
		[1436]		= 72,						-- Westfall/Stormwind
		[1433]		= 72,						-- Redridge Mountains/Stormwind
		[1437]		= 47,						-- Wetlands/Ironforge
		[1419]		= 72,						-- Blasted Lands/Stormwind
		[1426]		= 47,						-- Dun Morogh/Ironforge
		[1432]		= 47,						-- Loch Modan/Ironforge
		[1455]		= 47,						-- Ironforge/Ironforge
		[1457]		= 69,						-- Darnassus/Darnassus
		[1438]		= 69,						-- Teldrassil/Darnassus
		[1439]		= 69,						-- Darkshore/Darnassus
		[1450]		= 609,						-- Moonglade/Cenarion Circle

		--------- Both ---------
		[1422]		= 529,						-- Western Plaguelands/Argent Dawn
		[1423]		= 529,						-- Eastern Plaguelands/Argent Dawn
		[1427]		= 59,						-- Searing Gorge/Thorium Brotherhood
		[1446]		= 369,						-- Tanaris/Gadgetzan
		[1451]		= 609,						-- Silithus/Cenarion Circle
		[1452]		= 577,						-- Winterspring/Everlook
		[1425]		= A and 471 or H and 530,	-- The Hinterlands/Wildhammer Clan or Darkspear Trolls
		[1431]		= A and 72 or H and 68,		-- Duskwood/Stormwind or Undercity
		[1440]		= A and 69 or H and 76,		-- Ashenvale/Darnassus or Orgrimmar
		[1444]		= A and 69 or H and 81,		-- Feralas/Darnassus or Thunder Bluff
		[1413]		= A and 470 or H and 81,	-- The Barrens/Ratchet or Thunder Bluff
		[1417]		= A and 509 or H and 68,	-- Arathi Highlands/The League of Arathor or Undercity
		[1424]		= A and 72 or H and 68,		-- Hillsbrad Foothills/Stormwind/Undercity
		[1416]		= A and 72 or H and 76,		-- Alterac Mountains/Stormwind or Orgrimmar
		[1418]		= A and 47 or H and 76,		-- Badlands/Ironforge or Orgrimmar
		[1428]		= A and 47 or H and 530,	-- Burning Steppes/Ironforge or Darkspear Trolls
		[1434]		= A and 72 or H and 76,		-- Stranglethorn Vale/Stormwind or Orgrimmar
		[1435]		= A and 72 or H and 76,		-- Swamp of Sorrows/Stormwind or Orgrimmar
		[1441]		= A and 69 or H and 81,		-- Thousand Needles/Darnassus or Thunder Bluff
		[1442]		= A and 69 or H and 81,		-- Stonetalon Mountains/Darnassus or Thunder Bluff
		[1443]		= A and 72 or H and 81,		-- Desolace/Stormwind or Thunder Bluff
		[1445]		= A and 72 or H and 76,		-- Dustwallow Marsh/Stormwind or Orgrimmar
		[1447]		= A and 69 or H and 76,		-- Azshara/Darnassus or Orgrimmar
		[1448]		= A and 69 or H and 68,		-- Felwood/Darnassus or Undercity
	}
	return zonesAndFactions
end