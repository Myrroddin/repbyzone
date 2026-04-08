---@diagnostic disable: duplicate-set-field
-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local LibStub = LibStub
local UnitFactionGroup = UnitFactionGroup
local GetAreaInfo = C_Map.GetAreaInfo

------------------- Get addon reference --------------------
---@class RepByZone: AceAddon, AceEvent-3.0, AceConsole-3.0
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"
local subZonesAndFactions

function RepByZone:SubZonesAndFactionsList()
    if subZonesAndFactions then return subZonesAndFactions end
    subZonesAndFactions = {
		-- [GetAreaInfo(areaID)] = factionID
		-- see https://wago.tools/db2/AreaTable?build=1.15.8.66564

        [GetAreaInfo(19)]       = 270,      -- Zul'Gurub/Zandalar Tribe
        [GetAreaInfo(35)]       = 21,       -- Booty Bay/Booty Bay
        [GetAreaInfo(36)]       = A and 730 or H and 729, -- Alterac Mountains/Stormpike Guard or Frostwolf Clan
        [GetAreaInfo(100)]      = 47,       -- Nesingwary's Expedition/Ironforge
        [GetAreaInfo(122)]      = 270,      -- Zuuldaia Ruins/Zandalar Tribe
        [GetAreaInfo(125)]      = 270,      -- Kal'ai Ruins/Zandalar Tribe
        [GetAreaInfo(128)]      = 270,      -- Ziata'jai Ruins/Zandalar Tribe
        [GetAreaInfo(133)]      = 54,       -- Gnomeregan/Gnomeregan Exiles
		[GetAreaInfo(150)]      = 72,       -- Menethil Harbor/Stormwind
        [GetAreaInfo(193)]      = A and 72 or H and 68, -- Ruins of Andorhal/Stormwind or Undercity
        [GetAreaInfo(196)]      = 72,       -- Uthor's Tomb/Stormwind
		[GetAreaInfo(197)]      = 72,       -- Sorrow Hill/Stormwind
        [GetAreaInfo(280)]      = 349,      -- Strahnbrad/Ravenholdt
        [GetAreaInfo(288)]      = 72,       -- Azurelode Mine/Stormwind
		[GetAreaInfo(297)]      = 81,       -- Jaguero Isle/Thunder Bluff
		[GetAreaInfo(299)]      = 72,       -- Menethil Bay/Stormwind
        [GetAreaInfo(311)]      = 270,      -- Ruins of Aboraz/Zandalar Tribe
        [GetAreaInfo(313)]      = 349,      -- Northfold Manor/Ravenholdt
        [GetAreaInfo(314)]      = A and 72 or H and 68, -- Go'Shek Farm/Stormwind or Undercity
        [GetAreaInfo(315)]      = 72,       -- Dabyrie's Farmstead/Stormwind
        [GetAreaInfo(317)]      = A and 471 or H and 530, -- Witherbark Village/Wildhammer Clan or Darkspear Trolls
        [GetAreaInfo(320)]      = 72,       -- Refuge Pointe/Stormwind
        [GetAreaInfo(321)]      = 68,       -- Hammerfall/Undercity
        [GetAreaInfo(327)]      = 21,       -- Faldir's Cove/Booty Bay
        [GetAreaInfo(328)]      = 21,       -- The Drowned Reef/Booty Bay
        [GetAreaInfo(350)]      = 69,       -- Quel'Danil Lodge/Darnassus
		[GetAreaInfo(359)]      = A and 47 or H and 81, -- Bael Modan/Ironforge or Thunder Bluff
        [GetAreaInfo(367)]      = 530,      -- Sen'jen Village/Darkspear Trolls
        [GetAreaInfo(368)]      = 530,      -- Echo Isles/Darkspear Trolls
        [GetAreaInfo(392)]      = 470,      -- Ratchet/Ratchet
        [GetAreaInfo(393)]      = 530,      -- Darkspear Strand/Darkspear Trolls
        [GetAreaInfo(439)]      = A and 54 or H and 76, -- The Shimmering Flats/Gnomeregan Exiles or Orgrimmar
        [GetAreaInfo(477)]      = 270,      -- Ruins of Jubuwal/Zandalar Tribe
        [GetAreaInfo(484)]      = A and 69 or H and 81, -- Freewind Post/Darnassus or Thunder Bluff
		[GetAreaInfo(596)]      = 470,      -- Kodo Graveyard/Ratchet
        [GetAreaInfo(604)]      = 93,       -- Magram Village/Magram Clan Centaur
        [GetAreaInfo(606)]      = 92,       -- Gelkis Village/Gelkis Clan Centaur
        [GetAreaInfo(702)]      = 69,       -- Rut'theran Village/Darnassus
        [GetAreaInfo(813)]      = 529,      -- The Bulwark/Argent Dawn
        [GetAreaInfo(880)]      = 471,      -- Thandol Span (Arathi Highlands)/Wildhammer Clan
        [GetAreaInfo(881)]      = 47,       -- Thandol Span (Wetlands)/Ironforge
        [GetAreaInfo(896)]      = A and 730 or H and 729, -- Purgation Isle/Stormpike Guard or Frostwolf Clan
        [GetAreaInfo(978)]      = A and 471 or H and 530, -- Zul'Farrak/Wildhammer Clan or Darkspear Trolls
        [GetAreaInfo(1016)]     = 69,       -- Direforge Hill/Darnassus
        [GetAreaInfo(1025)]     = 69,       -- The Green Belt/Darnassus
        [GetAreaInfo(1057)]     = A and 47 or H and 68, -- Thoradin's Wall (Hillsbrad Foothills)/Ironforge or Undercity
        [GetAreaInfo(1216)]     = 579,      -- Timbermaw Hold/Timbermaw Hold
        [GetAreaInfo(1446)]     = 59,       -- Thorium Point/Thorium Brotherhood
		[GetAreaInfo(1658)]     = 609,      -- Cenarion Enclave/Cenarion Circle
        [GetAreaInfo(1677)]     = A and 730 or H and 729, -- Gavin's Naze/Stormpike Guard or Frostwolf Clan
        [GetAreaInfo(1679)]     = A and 730 or H and 729, -- Corrahn's Dagger/Stormpike Guard or Frostwolf Clan
        [GetAreaInfo(1680)]     = A and 730 or H and 729, -- The Headland/Stormpike Guard or Frostwolf Clan
        [GetAreaInfo(1678)]     = 72,       -- Sofera's Naze/Stormwind
		[GetAreaInfo(1739)]     = 87,       -- Bloodsail Compound/Bloodsail Buccaneers
        [GetAreaInfo(1741)]     = 87,       -- Gurubashi Arena/Bloodsail Buccaneers
        [GetAreaInfo(1761)]     = 579,      -- Deadwood Village/Timbermaw Hold
        [GetAreaInfo(1762)]     = 579,      -- Felpaw Village/Timbermaw Hold
        [GetAreaInfo(1837)]     = A and 471 or H and 530, -- Witherbark Caverns/Wildhammer Clan or Darkspear Trolls
        [GetAreaInfo(1857)]     = A and 47 or H and 68, -- Thoradin's Wall (Arathi Highlands)/Ironforge or Undercity
        [GetAreaInfo(1858)]     = A and 471 or H and 530, -- Boulder'gor/Wildhammer Clan or Darkspear Trolls
		[GetAreaInfo(1977)]     = 309,      -- Zul'Gurub/Zandalar Tribe
		[GetAreaInfo(2097)]     = A and 69 or H and 81, -- Darkcloud Pinnacle/Darnassus or Thunder Bluff
		[GetAreaInfo(2157)]     = A and 47 or H and 81, -- Bael'dun Keep/Ironforge or Thunder Bluff
		[GetAreaInfo(2240)]     = 21,       -- Mirage Raceway/Booty Bay
        [GetAreaInfo(2241)]     = 589,      -- Frostsaber Rock/Wintersaber Trainers
        [GetAreaInfo(2243)]     = 579,      -- Timbermaw Post/Timbermaw Hold
        [GetAreaInfo(2244)]     = 579,      -- Winterfall Village/Timbermaw Hold
        [GetAreaInfo(2246)]     = 579,      -- Frostfire Hot Springs/Timbermaw Hold
        [GetAreaInfo(2257)]     = 72,       -- Deeprun Tram/Stormwind
        [GetAreaInfo(2276)]     = 69,       -- Quel'Lithien Lodge/Darnassus
        [GetAreaInfo(2405)]     = 529,      -- Ethel Rethor/Argent Dawn
        [GetAreaInfo(2406)]     = 69,       -- Ranazjar Isle/Darnassus
        [GetAreaInfo(2407)]     = 470,      -- Kormek's Hut/Ratchet
        [GetAreaInfo(2408)]     = 530,      -- Shadowprey Village/Darkspear Trolls
        [GetAreaInfo(2597)]     = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [GetAreaInfo(2617)]     = 470,      -- Scrabblescrew's Camp/Ratchet
        [GetAreaInfo(2897)]     = 530,      -- Zoram'gar Outpost/Darkspear Trolls
		[GetAreaInfo(3197)]     = 72,       -- Chillwind Camp/Stormwind
        [GetAreaInfo(3357)]     = 270,      -- Yojamba Isle/Zandalar Tribe
        [GetAreaInfo(3456)]     = 529,      -- Naxxramas/Argent Dawn
        [GetAreaInfo(3486)]     = 349,      -- Ravenholdt Manor/Ravenholdt
    }
    return subZonesAndFactions
end