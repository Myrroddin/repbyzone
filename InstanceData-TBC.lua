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

        ---------- Vanilla ----------
        [33]        = A and 72 or H and 68, -- Shadowfang Keep/Stormwind or Undercity
        [34]        = 72,       -- The Stockades/Stormwind
        [36]        = 72,       -- The Deadmines/Stormwind
        [43]        = 81,       -- Wailing Caverns/Thunder Bluff
        [47]        = A and 69 or H and 81, -- Razorfen Kraul/Darnassus or Thunderbluff
        [48]        = A and 69 or H and 530, -- Blackfathom Depths/Darnassus or Darkspear Trolls
        [70]        = A and 47 or H and 530, -- Uldaman/Ironforge or Darkspear Trolls
        [90]        = 54,       -- Gnomeregan/Gnomeregan
        [129]       = A and 72 or H and 76, -- Razorfen Downs/Stormwind or Orgrimmar
        [189]       = 529,      -- Scarlet Monastery/Argent Dawn
        [209]       = A and 471 or H and 530, -- Zul'Farrak/Wildhammer Clan or Darkspear Trolls
        [229]       = A and 72 or H and 76, -- Blackrock Spire/Stormwind or Orgrimmar
        [230]       = 59,       -- Blackrock Depths/Thorium Brotherhood
        [249]       = A and 72 or H and 76, -- Onyxia's Lair/Stormwind or Orgrimmar
        [289]       = 529,      -- Scholomance/Argent Dawn
        [329]       = 529,      -- Strathholme/Argent Dawn
        [349]       = 609,      -- Maraudon/Cenarion Circle
        [389]       = 76,       -- Ragefire Chasm/Orgrimmar
        [409]       = 749,      -- Molten Core/Hydraxian Waterlords
        [429]       = 809,       -- Dire Maul/Shen'dralar
        [469]       = A and 72 or H and 76, -- Blackwing Lair/Stormwind or Orgrimmar
        [509]       = 609,      -- Ruins of Ahn'Qiraj/Cenarion Circle
        [531]       = 910,      -- Temple of Ahn'Qiraj/Brood of Nozdormu

        ----------- Battlegrounds ----------
        [30]        = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan        
        [489]       = A and 890 or H and 889, -- Warsong Gulch/Silverwing Sentinels or Warsong Outriders
        [529]       = A and 509 or H and 510, -- Arathi Basin/The Leage of Arathor or The Defilers
        -- Eye of the Storm (566) has no associated factionID, use the player's default

        ---------- TBC ----------
        [269]       = 989,      -- The Black Morass/Keepers of Time
        [309]       = 270,      -- Zul'Gurub/Zandalar Tribe
        [532]       = 967,      -- Karazhan/The Violet Eye
        [534]       = 990,      -- Hyjal Summit/The Scale of the Sands
        [540]       = A and 946 or H and 947, -- The Shattered Halls/Honor Hold or Thrallmar
        [542]       = A and 946 or H and 947, -- The Blood Furnace/Honor Hold or Thrallmar
        [543]       = A and 946 or H and 947, -- Hellfire Ramparts/Honor Hold or Thrallmar
        [544]       = A and 946 or H and 947, -- Magtheridon's Lair/Honor Hold or Thrallmar
        [545]       = 942,      -- The Steamvault/Cenarion Expedition
        [546]       = 942,      -- The Underbog/Cenarion Expedition
        [547]       = 942,      -- The Slave Pens/Cenarion Expedition
        [548]       = 942,      -- Serpentshrine Cavern/Cenarion Expedition
        [550]       = 935,      -- Tempest Keep/The Sha'tar
        [552]       = 935,      -- The Arcatraz/The Sha'tar
        [553]       = 935,      -- The Botanica/The Sha'tar
        [554]       = 935,      -- The Mechanar/The Sha'tar
        [555]       = 1011,     -- Shadow Labyrinth/Lower City
        [556]       = 1011,     -- Sethekk Halls/Lower City
        [557]       = 933,      -- Mana-Tombs/The Consortium
        [558]       = 1011,     -- Auchenai Crypts/Lower City
        [560]       = 989,      -- Old Hillsbrad Foothills/Keepers of Time
        [564]       = 1012,     -- Black Temple/Ashtongue Deathsworn
        [565]       = 1038,     -- Gruul's Lair/Ogri'la
        [580]       = 1077,     -- Sunwell Plateau/Shattered Sun Offensive
        [585]       = 1077,     -- Magister's Terrace/Shattered Sun Offensive
    }
    return instancesAndFactions
end