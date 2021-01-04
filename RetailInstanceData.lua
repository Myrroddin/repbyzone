local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"

function RepByZone:InstancesAndFactionList()
    local instancesAndFactions = {
        -- instanceID = factionID
        -- If an instanceID is not listed, that instance has no associated factionID
        -- See https://wow.gamepedia.com/InstanceID for the list of instanceIDs

        --------- Dungeons ----------
        [34]        = 72, -- The Stockades/Stormwind
        [90]        = 54, -- Gnomeregan/Gnomeregan Exiles
        [389]       = 46, -- Ragefire Chasm/Orgrimmar
        [349]       = 609, -- Maraudon/Cenarion Circle
        [1001]      = 529, -- Scarlet Halls/Argent Dawn
        [1004]      = 529, -- Scarlet Monastary/Argent Dawn
        [1007]      = 529, -- Scholomance/Argent Dawn
        [33]        = 68, -- Shadowfang Keep/Undercity
        [329]       = 529, -- Strathholme/Argent Dawn
        [36]        = 72, -- The Deadmines/Stormwind
        [230]       = 59, -- Blackrock Depths/Thorium Brotherhood
        [109]       = 270, -- Temple of Atal'Hakkar (Sunken Temple)/Zandalar Tribe
        [43]        = 81, -- Wailing Caverns/Thunder Bluff
        [429]       = 809, -- Dire Maul/Shen'dralar
        [369]       = 72, -- Deeprun Tram/Stormwind
        [129]       = A and 72 or H and 46, -- Razorfen Downs/Stormwind or Orgrimmar
        [47]        = A and 69 or H and 81, -- Razorfen Kraul/Darnassus or Thunderbluff
        [48]        = A and 69 or H and 530, -- Blackfathom Deeps/Darnassus or Darkspear Trolls
        [229]       = A and 72 or H and 46, -- Blackrock Spire/Stormwind or Orgrimmar
        [70]        = A and 47 or H and 530, -- Uldaman/Ironforge or Darkspear Trolls
        [209]       = A and 1174 or H and 530, -- Zul'Farrak/Wildhammer Clan or Darkspear Trolls

        ----------- Battlegrounds ----------
        [30]        = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [529]       = A and 509 or H and 510, -- Arathi Basin/The Leage of Arathor or The Defilers
        [589]       = A and 890 or H and 889, -- Warsong Gulch/Silverwing Sentinels or Warsong Outriders

        ---------- Raids -----------
        [409]       = 749, -- Molten Core/Hydraxian Waterlords
        [509]       = 609, -- Ruins of Ahn'Qiraj/Cenarion Circle
        [531]       = 910, -- Temple of Ahn'Qiraj/Brood of Nozdormu
        [533]       = 529, -- Naxxramas/Argent Dawn
        [309]       = 270, -- Zul'Gurub/Zandalar Tribe
        [469]       = A and 72 or H and 46, -- Blackwing Lair/Stormwind or Orgrimmar
        [249]       = A and 72 or H and 46, -- Onyxia's Lair/Stormwind or Orgrimmar
    }
    return instancesAndFactions
end