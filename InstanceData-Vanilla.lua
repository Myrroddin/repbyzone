---@diagnostic disable: duplicate-set-field
-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local LibStub = LibStub
local UnitFactionGroup = UnitFactionGroup

------------------- Get addon reference --------------------
---@class RepByZone: AceAddon, AceEvent-3.0, AceConsole-3.0
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"
local instancesAndFactions

-- Return instance data to Core-Vanilla.lua
function RepByZone:InstancesAndFactionList()
	if instancesAndFactions then return instancesAndFactions end
	instancesAndFactions = {
		-- [instanceID] = factionID
		-- If an instanceID is not listed, that instance has no associated factionID
		-- See https://warcraft.wiki.gg/wiki/InstanceID#Classic for the list of instanceIDs

		--------- Dungeons ----------
		[33]		= A and 72 or H and 68,		-- Shadowfang Keep/Stormwind or Undercity
		[34]		= 72,						-- The Stockades/Stormwind
		[36]		= 72,						-- The Deadmines/Stormwind
		[43]		= 81,						-- Wailing Caverns/Thunder Bluff
		[47]		= A and 69 or H and 81,		-- Razorfen Kraul/Darnassus or Thunderbluff
		[48]		= A and 69 or H and 530,	-- Blackfathom Depths/Darnassus or Darkspear Trolls
		[70]		= A and 47 or H and 530,	-- Uldaman/Ironforge or Darkspear Trolls
		[90]		= 54,						-- Gnomeregan/Gnomeregan
		[129]		= A and 72 or H and 76,		-- Razorfen Downs/Stormwind or Orgrimmar
		[189]		= 529,						-- Scarlet Monastery/Argent Dawn
		[209]		= A and 471 or H and 530,	-- Zul'Farrak/Wildhammer Clan or Darkspear Trolls
		[229]		= A and 72 or H and 76,		-- Blackrock Spire/Stormwind or Orgrimmar
		[230]		= 59,						-- Blackrock Depths/Thorium Brotherhood
		[289]		= 529,						-- Scholomance/Argent Dawn
		[329]		= 529,						-- Strathholme/Argent Dawn
		[349]		= 609,						-- Maraudon/Cenarion Circle
		[389]		= 76,						-- Ragefire Chasm/Orgrimmar
		[429]		= 809,						-- Dire Maul/Shen'dralar

		----------- Battlegrounds ----------
		[30]		= A and 730 or H and 729,	-- Alterac Valley/Stormpike Guard or Frostwolf Clan
		[489]		= A and 890 or H and 889,	-- Warsong Gulch/Silverwing Sentinels or Warsong Outriders
		[529]		= A and 509 or H and 510,	-- Arathi Basin/The Leage of Arathor or The Defilers

		---------- Raids -----------
		[249]		= A and 72 or H and 76,		-- Onyxia's Lair/Stormwind or Orgrimmar
		[309]		= 270,						-- Zul'Gurub/Zandalar Tribe
		[409]		= 749,						-- Molten Core/Hydraxian Waterlords
		[469]		= A and 72 or H and 76,		-- Blackwing Lair/Stormwind or Orgrimmar
		[509]		= 609,						-- Ruins of Ahn'Qiraj/Cenarion Circle
		[531]		= 910,						-- Temple of Ahn'Qiraj/Brood of Nozdormu
		[533]		= 529,						-- Naxxramas/Argent Dawn
	}
	return instancesAndFactions
end