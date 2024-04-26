-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local LibStub = LibStub
local UnitFactionGroup = UnitFactionGroup

------------------- Get addon reference --------------------
---@class RepByZone: AceAddon, AceEvent-3.0, AceConsole-3.0
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"

-- Return instance data to Core-Cata.lua
function RepByZone:InstancesAndFactionList()
    local instancesAndFactions = {
        -- [instanceID] = factionID
        -- If an instanceID is not listed, that instance has no associated factionID
        -- See https://wow.gamepedia.com/InstanceID or https://wago.tools/db2/JournalInstance for the list of instanceIDs

        ----------- Battlegrounds ----------
        [30]        = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [489]       = A and 890 or H and 889, -- Warsong Gulch/Silverwing Sentinels or Warsong Outriders
        [529]       = A and 509 or H and 510, -- Arathi Basin (Classic)/The League of Arathor or The Defilers
        [566]       = A and 930 or H and 911, -- Eye of the Storm/Exodar or Silvermoon City
        [607]       = A and 1050 or H and 1085, -- Strand of the Ancients/Valiance Expedition or Warsong Offensive
        [628]       = A and 1050 or H and 1085, -- Isle of Conquest/Valiance Expedition or Warsong Offensive
        [726]       = A and 1174 or H and 1172, -- Twin Peaks/Wildhammer Clan or Dragonmaw Clan
        [727]       = A and 72 or H and 1133, -- Silvershard Mines/Stormwind or Bilgewater Cartel
        [732]       = A and 1177 or H and 1178, -- Tol Barad/Baradin's Warders or Hellscream's Reach
        [761]       = A and 1134 or H and 68, -- The Battle for Gilneas/Gilneas or Undercity
        [968]       = A and 930 or H and 911, -- Eye of the Storm (rated)/Exodar or Silvermoon City
        [1191]      = A and 1682 or H and 1681, -- Ashran/Wrynn's Vanguard or Vol'jin's Spear
        [1681]      = A and 509 or H and 510, -- Arathi Basin (Winter)/The League of Arathor or The Defilers
        [2106]      = A and 890 or H and 889, -- Warsong Gulch/Silverwing Sentinels or Warsong Outriders
        [2107]      = A and 509 or H and 510, -- Arathi Basin/The League of Arathor or The Defilers
        [2118]      = A and 1037 or H and 1052, -- Battle for Wintergrasp/Alliance Vanguard or Horde Expedition
        [2177]      = A and 509 or H and 510, -- Arathi Basin (Comp Stomp)/The League of Arathor or The Defilers

        ---------- Vanilla ----------
        [33]        = A and 1134 or H and 68, -- Shadowfang Keep/Gilneas or Undercity
        [34]        = 72,       -- The Stockades/Stormwind
        [36]        = 72,       -- The Deadmines/Stormwind
        [43]        = 81,       -- Wailing Caverns/Thunder Bluff
        [47]        = A and 69 or H and 81, -- Razorfen Kraul/Darnassus or Thunderbluff
        [48]        = A and 69 or H and 530, -- Blackfathom Depths/Darnassus or Darkspear Trolls
        [70]        = A and 47 or H and 530, -- Uldaman/Ironforge or Darkspear Trolls
        [90]        = 54,       -- Gnomeregan/Gnomeregan
        [129]       = A and 72 or H and 76, -- Razorfen Downs/Stormwind or Orgrimmar
        [209]       = A and 1174 or H and 530, -- Zul'Farrak/Wildhammer Clan or Darkspear Trolls
        [229]       = A and 72 or H and 76, -- Blackrock Spire/Stormwind or Orgrimmar
        [230]       = 59,       -- Blackrock Depths/Thorium Brotherhood
        [329]       = 1106,     -- Strathholme/Argent Crusade
        [349]       = 609,      -- Maraudon/Cenarion Circle
        [389]       = 76,       -- Ragefire Chasm/Orgrimmar
        [409]       = 749,      -- Molten Core/Hydraxian Waterlords
        [429]       = 69,       -- Dire Maul/Darnassus
        [469]       = A and 72 or H and 46, -- Blackwing Lair/Stormwind or Orgrimmar
        [509]       = 609,      -- Ruins of Ahn'Qiraj/Cenarion Circle
        [531]       = 910,      -- Temple of Ahn'Qiraj/Brood of Nozdormu
        [556]       = 1011,     -- Sethekk Halls/Lower City
        [1001]      = 1106,     -- Scarlet Halls/Argent Crusade
        [1004]      = 1106,     -- Scarlet Monastary/Argent Crusade
        [1007]      = 1106,     -- Scholomance/Argent Crusade

        ---------- TBC ----------
        [269]       = 989,      -- The Black Morass/Keepers of Time
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
        [557]       = 933,      -- Mana-Tombs/The Consortium
        [558]       = 1011,     -- Auchenai Crypts/Lower City
        [560]       = 989,      -- Old Hillsbrad Foothills/Keepers of Time
        [564]       = 1012,     -- Black Temple/Ashtongue Deathsworn
        [565]       = 1038,     -- Gruul's Lair/Ogri'la
        [580]       = 1077,     -- Sunwell Plateau/Shattered Sun Offensive
        [585]       = 1077,     -- Magister's Terrace/Shattered Sun Offensive

        ---------- WotLK ----------
        [249]       = A and 72 or H and 76, -- Onyxia's Lair/Stormwind or Orgrimmar
        [533]       = 1106,     -- Naxxramas/Argent Crusade
        [574]       = A and 1050 or H and 1067, -- Utgarde Keep/Valiance Expedition or The Hand of Vengeance
        [575]       = A and 1050 or H and 1067, -- Utgarde Pinnacle/Valiance Expedition or The Hand of Vengeance
        [576]       = 1090,     -- The Nexus/Kirin Tor
        [578]       = 1091,     -- The Oculus/The Wyrmrest Accord
        [595]       = 989,      -- The Culling of Stratholme/Keepers of Time
        [599]       = A and 1050 or H and 1067, -- Halls of Stone/Valiance Expedition or The Hand of Vengeance
        [600]       = A and 1050 or H and 1067, -- Drak'Tharon Keep/Valiance Expedition or The Hand of Vengeance
        [601]       = A and 1050 or H and 1067, -- Azjol-Nerub/Valiance Expedition or The Hand of Vengeance
        [602]       = A and 1050 or H and 1067, -- Halls of Lightning/Valiance Expedition or The Hand of Vengeance
        [603]       = 1119,     -- Ulduar/The Sons of Hodir
        [604]       = A and 1050 or H and 1067, -- Gundrak/Valiance Expedition or The Hand of Vengeance
        [608]       = 1090,     -- The Violet Hold/Kirin Tor
        [615]       = 1091,     -- The Obsidian Sanctum/The Wyrmrest Accord
        [616]       = 1091,     -- The Eye of Eternity/The Wyrmrest Accord
        [618]       = 1374,     -- The Ring of Valor/Brawl'gar Arena
        [619]       = A and 1050 or H and 1067, -- Ahn'kahet: The Old Kingdom/Valiance Expedition or The Hand of Vengeance
        [624]       = A and 1037 or H and 1052, -- Vault of Archavon/Alliance Vanguard or Horde Expedition
        [631]       = 1156,     -- Icecrown Citadel/The Ashen Verdict
        [632]       = 1156,     -- Forge of Souls/The Ashen Verdict
        [649]       = 1106,     -- Trial of the Crusader/Argent Crusade
        [650]       = 1106,     -- Trial of the Champion/Argent Crusade
        [658]       = 1156,     -- Pit of Saron/The Ashen Verdict
        [668]       = 1156,     -- Halls of Reflection/The Ashen Verdict
        [724]       = 1091,     -- The Ruby Sanctum/The Wyrmrest Accord
        [1043]      = 1374,     -- Brawl'gar Arena/Brawl'gar Arena

        ---------- Cataclysm ----------
        [369]       = 72,       -- Deeprun Tram/Stormwind
        [568]       = A and 72 or H and 911, -- Zul'Aman/Stormwind or Silvermoon City
        [643]       = 1135,     -- Throne of the Tides/The Earthen Ring
        [644]       = 2164,     -- Halls of Origination/Champions of Azeroth
        [645]       = 1158,     -- Blackrock Caverns/Guardians of Hyjal
        [657]       = 1173,     -- The Vortex Pinnacle/Ramkahen
        [669]       = 1158,     -- Blackwing Descent/Guardians of Hyjal
        [670]       = A and 1174 or H and 1172, -- Grim Batol/Wildhammer Clan or Dragonmaw Clan
        [671]       = A and 1174 or H and 1172, -- The Bastion of Twilight/Wildhammer Clan or Dragonmaw Clan
        [720]       = 1204,     -- Firelands/Avengers of Hyjal
        [725]       = 1135,     -- The Stonecore/The Earthen Ring
        [754]       = 1173,     -- Throne of the Four Winds/Ramkahen
        [755]       = 1173,     -- Lost City of the Tol'vir/Ramkahen
        [757]       = A and 1177 or H and 1178, -- Baradin Hold/Bardin's Warders or Hellscream's Reach
        [859]       = A and 72 or H and 76, -- Zul'Gurub/Stormwind or Orgrimmar
        [938]       = 910,      -- End Time/Brood of Nozdormu
        [939]       = 989,      -- Well of Eternity/Keepers of Time
        [940]       = 1091,     -- Hour of Twilight/The Wyrmrest Accord
        [967]       = 1091,     -- Dragon Soul/The Wyrmrest Accord
        [974]       = 909,      -- Darkmoon Island/Darkmoon Faire
        [1113]      = 909,      -- Transport: Darkmoon Carousel/Darkmoon Faire
    }
    return instancesAndFactions
end