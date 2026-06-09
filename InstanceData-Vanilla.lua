-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local LibStub = LibStub
local UnitFactionGroup = UnitFactionGroup

------------------- Get addon reference --------------------
---@type RepByZone
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local A = UnitFactionGroup("player") == "Alliance"

---@type table<number, number>?
local instancesAndFactions

---@param allianceFactionID number
---@param hordeFactionID number
---@return number
local function GetFactionID(allianceFactionID, hordeFactionID)
	if A then
		return allianceFactionID
	end
	return hordeFactionID
end

-- Return instance data to Core-Vanilla.lua
---@return table<number, number>
function RepByZone:InstancesAndFactionList()
	if instancesAndFactions then return instancesAndFactions end
	instancesAndFactions = {
		-- [instanceID] = factionID
		-- If an instanceID is not listed, that instance has no associated factionID
		-- See https://warcraft.wiki.gg/wiki/InstanceID#Classic for the list of instanceIDs

		--------- Dungeons ----------
		[33]		= GetFactionID(72, 68),		-- Shadowfang Keep/Stormwind or Undercity
		[34]		= 72,						-- The Stockades/Stormwind
		[36]		= 72,						-- The Deadmines/Stormwind
		[43]		= 81,						-- Wailing Caverns/Thunder Bluff
		[47]		= GetFactionID(69, 81),		-- Razorfen Kraul/Darnassus or Thunderbluff
		[48]		= GetFactionID(69, 530),	-- Blackfathom Depths/Darnassus or Darkspear Trolls
		[70]		= GetFactionID(47, 530),	-- Uldaman/Ironforge or Darkspear Trolls
		[90]		= 54,						-- Gnomeregan/Gnomeregan
		[129]		= GetFactionID(72, 76),		-- Razorfen Downs/Stormwind or Orgrimmar
		[189]		= 529,						-- Scarlet Monastery/Argent Dawn
		[209]		= GetFactionID(471, 530),	-- Zul'Farrak/Wildhammer Clan or Darkspear Trolls
		[229]		= GetFactionID(72, 76),		-- Blackrock Spire/Stormwind or Orgrimmar
		[230]		= 59,						-- Blackrock Depths/Thorium Brotherhood
		[289]		= 529,						-- Scholomance/Argent Dawn
		[329]		= 529,						-- Strathholme/Argent Dawn
		[349]		= 609,						-- Maraudon/Cenarion Circle
		[389]		= 76,						-- Ragefire Chasm/Orgrimmar
		[429]		= 809,						-- Dire Maul/Shen'dralar

		----------- Battlegrounds ----------
		[30]		= GetFactionID(730, 729),	-- Alterac Valley/Stormpike Guard or Frostwolf Clan
		[489]		= GetFactionID(890, 889),	-- Warsong Gulch/Silverwing Sentinels or Warsong Outriders
		[529]		= GetFactionID(509, 510),	-- Arathi Basin/The Leage of Arathor or The Defilers

		---------- Raids -----------
		[249]		= GetFactionID(72, 76),		-- Onyxia's Lair/Stormwind or Orgrimmar
		[309]		= 270,						-- Zul'Gurub/Zandalar Tribe
		[409]		= 749,						-- Molten Core/Hydraxian Waterlords
		[469]		= GetFactionID(72, 76),		-- Blackwing Lair/Stormwind or Orgrimmar
		[509]		= 609,						-- Ruins of Ahn'Qiraj/Cenarion Circle
		[531]		= 910,						-- Temple of Ahn'Qiraj/Brood of Nozdormu
		[533]		= 529,						-- Naxxramas/Argent Dawn
	}
	return instancesAndFactions
end