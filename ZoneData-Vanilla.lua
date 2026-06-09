-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local LibStub = LibStub
local UnitFactionGroup = UnitFactionGroup

------------------- Get addon reference --------------------
---@type RepByZone
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local A = UnitFactionGroup("player") == "Alliance"

---@type table<number, number>?
local zonesAndFactions

---@param allianceFactionID number
---@param hordeFactionID number
---@return number
local function GetFactionID(allianceFactionID, hordeFactionID)
	if A then
		return allianceFactionID
	end
	return hordeFactionID
end

---@return table<number, number>
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
		[1425]		= GetFactionID(471, 530),	-- The Hinterlands/Wildhammer Clan or Darkspear Trolls
		[1431]		= GetFactionID(72, 68),		-- Duskwood/Stormwind or Undercity
		[1440]		= GetFactionID(69, 76),		-- Ashenvale/Darnassus or Orgrimmar
		[1444]		= GetFactionID(69, 81),		-- Feralas/Darnassus or Thunder Bluff
		[1413]		= GetFactionID(470, 81),	-- The Barrens/Ratchet or Thunder Bluff
		[1417]		= GetFactionID(509, 68),	-- Arathi Highlands/The League of Arathor or Undercity
		[1424]		= GetFactionID(72, 68),		-- Hillsbrad Foothills/Stormwind/Undercity
		[1416]		= GetFactionID(72, 76),		-- Alterac Mountains/Stormwind or Orgrimmar
		[1418]		= GetFactionID(47, 76),		-- Badlands/Ironforge or Orgrimmar
		[1428]		= GetFactionID(47, 530),	-- Burning Steppes/Ironforge or Darkspear Trolls
		[1434]		= GetFactionID(72, 76),		-- Stranglethorn Vale/Stormwind or Orgrimmar
		[1435]		= GetFactionID(72, 76),		-- Swamp of Sorrows/Stormwind or Orgrimmar
		[1441]		= GetFactionID(69, 81),		-- Thousand Needles/Darnassus or Thunder Bluff
		[1442]		= GetFactionID(69, 81),		-- Stonetalon Mountains/Darnassus or Thunder Bluff
		[1443]		= GetFactionID(72, 81),		-- Desolace/Stormwind or Thunder Bluff
		[1445]		= GetFactionID(72, 76),		-- Dustwallow Marsh/Stormwind or Orgrimmar
		[1447]		= GetFactionID(69, 76),		-- Azshara/Darnassus or Orgrimmar
		[1448]		= GetFactionID(69, 68),		-- Felwood/Darnassus or Undercity
	}
	return zonesAndFactions
end