local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")

local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"

function RepByZone:InstancesAndFactionList()
    local instancesAndFactions = {
        -- instanceID = factionID
        -- If an instanceID is not listed, that instance has no associated factionID
        -- See https://wow.gamepedia.com/InstanceID for the list of instanceIDs

        ----------- Battlegrounds ----------
        [30]        = A and 730 or H and 729, -- Alterac Valley/Stormpike Guard or Frostwolf Clan
        [2107]      = A and 509 or H and 510, -- Arathi Basin/The League of Arathor or The Defilers
        [1681]      = A and 509 or H and 510, -- Arathi Basin (Winter)/The League of Arathor or The Defilers
        [2177]      = A and 509 or H and 510, -- Arathi Basin (Comp Stomp)/The League of Arathor or The Defilers
        [529]       = A and 509 or H and 510, -- Arathi Basin (Classic)/The League of Arathor or The Defilers
        [489]       = A and 890 or H and 889, -- Warsong Gulch/Silverwing Sentinels or Warsong Outriders
        [761]       = A and 1134 or H and 68, -- The Battle for Gilneas/Gilneas or Undercity
        [998]       = 1341,     -- Temple of Kotmogu/The August Celestials

        ---------- Vanilla ----------
        [33]        = A and 1134 or H and 68, -- Shadowfang Keep/Gilneas or Undercity
        [34]        = 72,       -- The Stockades/Stormwind
        [36]        = 72,       -- The Deadmines/Stormwind
        [43]        = 81,       -- Wailing Caverns/Thunder Bluff
        [47]        = A and 69 or H and 81, -- Razorfen Kraul/Darnassus or Thunderbluff
        [48]        = A and 69 or H and 530, -- Blackfathom Depths/Darnassus or Darkspear Trolls
        [70]        = A and 47 or H and 530, -- Uldaman/Ironforge or Darkspear Trolls
        [90]        = 54,       -- Gnomeregan/Gnomeregan
        [109]       = 270,      -- Temple of Atal'Hakkar (Sunken Temple)/Zandalar Tribe
        [129]       = A and 72 or H and 46, -- Razorfen Downs/Stormwind or Orgrimmar
        [209]       = A and 1174 or H and 530, -- Zul'Farrak/Wildhammer Clan or Darkspear Trolls
        [229]       = A and 72 or H and 46, -- Blackrock Spire/Stormwind or Orgrimmar
        [230]       = 59,       -- Blackrock Depths/Thorium Brotherhood
        [309]       = 270,      -- Zul'Gurub/Zandalar Tribe
        [329]       = 529,      -- Strathholme/Argent Dawn
        [349]       = 609,      -- Maraudon/Cenarion Circle
        [389]       = 46,       -- Ragefire Chasm/Orgrimmar
        [409]       = 749,      -- Molten Core/Hydraxian Waterlords
        [429]       = 809,      -- Dire Maul/Shen'dralar
        [469]       = A and 72 or H and 46, -- Blackwing Lair/Stormwind or Orgrimmar
        [509]       = 609,      -- Ruins of Ahn'Qiraj/Cenarion Circle
        [531]       = 910,      -- Temple of Ahn'Qiraj/Brood of Nozdormu
        [1001]      = 529,      -- Scarlet Halls/Argent Dawn
        [1004]      = 529,      -- Scarlet Monastary/Argent Dawn
        [1007]      = 529,      -- Scholomance/Argent Dawn

        ---------- WotLK ----------
        [249]       = A and 72 or H and 46, -- Onyxia's Lair/Stormwind or Orgrimmar
        [533]       = 1106,     -- Naxxramas/Argent Crusade
        [631]       = 1106,     -- Icecrown Citadel/Argent Crusade
        [649]       = 1106,     -- Trial of the Crusader/Argent Crusade

        ---------- Cataclysm ----------
        [369]       = 72, -- Deeprun Tram/Stormwind

        ---------- MoP ----------
        [959]       = 1270,     -- Shado-pan Monestary/Shado-Pan
        [960]       = 1341,     -- Temple of the Jade Serpent/The August Celestials
        [961]       = 1272,     -- Stormstout Brewery/The Tillers
        [962]       = 1270,     -- Gate of the Setting Sun/Shado-Pan
        [994]       = 1341,     -- Mogu'shan Palace/The August Celestials
        [996]       = 1492,     -- Terrace of Endless Spring/Emperor Shaohao
        [1005]      = A and 1353 or H and 1352, -- A Brewing Storm/Tushi Pandaren or Huojin Pandaren
        [1008]      = 1341,     -- Mogu'shan Vault/The August Celestials
        [1009]      = 1337,     -- Heart of Fear/The Klaxxi
        [1011]      = 1341,     -- Siege of Niuzao Temple/The August Celestials
        [1024]      = A and 1353 or H and 1352, -- Greenstone Village/Tushi Pandaren or Huojin Pandaren
        [1030]      = 1270,     -- Crypt of Forgotten Kings/Shado-Pan
        [1031]      = 1341,     -- Arena of Annihilation/The August Celestials
        [1048]      = 1302,     -- Unga Ingoo/The Anglers
        [1050]      = 1337,     -- Assault on Zan'vess/The Klaxxi
        [1051]      = A and 1353 or H and 1352, -- Brewmoon Festival/Tushi Pandaren or Huojin Pandaren
        [1095]      = 1395,     -- Dagger in the Dark (Alliance)/The Lorewalkers
        [1098]      = 1270,     -- Throne of Thunder/Shado-Pan
        [1102]      = 1375,     -- Domination Point (Horde)/Dominance Offensive
        [1103]      = 1376,     -- Lion's Landing/Operation: Shieldwall
        [1104]      = 1395,     -- A Little Patience (Horde)/The Lorewalkers
        [1112]      = 1012,     -- Pursuing the Black Harvest (Warlock)/Ashtongue Deathsworn
        [1130]      = A and 47 or H and 2103, -- Blood in the Snow/Ironforge or Zandalari Empire
        [1131]      = A and self.racialRepID or H and 46, -- The Secrets of Ragefire/racial rep or Orgrimmar
        [1136]      = A and 72 or H and 46, -- Siege of Orgrimmar/Stormwind or Orgrimmar
        [1148]      = self.racialRepID -- Proving Grounds/racial rep
        
        ---------- BfA ----------
        [1594]      = 1133,     -- The Motherloade!!/Bilgewater Cartel
        [1754]      = 2160,     -- Freehold/Proudmoore Admiralty
        [1762]      = 2103,     -- King's Rest/Zandalari Empire
        [1763]      = 2103,     -- Atal'Dazar/Zandalari Empire
        [1771]      = 2160,     -- Tol Dagor/Proudmoore Admiralty
        [1804]      = A and 509 or H and 530, -- Warfront: The Battle for Stromgarde/The League of Arathor or Darkspear Trolls
        [1822]      = A and 2160 or H and 2103, -- Siege of Boralus/Proudmoore Admiralty or Zandalari Empire
        [1841]      = 2103,     -- The Underrot/Zandalari Empire
        [1861]      = 2164,     -- Uldir/Champions of Azeroth
        [1862]      = 2161,     -- Waycrest Manor/Order of Embers
        [1864]      = 2162,     -- Shrine of the Storm/Storm's Wake
        [1877]      = 2158,     -- Temple of Sethraliss/Voldunai
        [2070]      = A and 2160 or H and 2103, -- Battle of Dazara'lor/Proudmoore Admiralty or Zandalari Empire
        [2096]      = 2162,     -- Crucible of Storms/Storm's Wake
        [2097]      = 2391,     -- Operation: Mechagon/Rustbolt Resistance
        [2105]      = 69,       -- Warfront: Darkshore (Alliance)/Darnassus
        [2111]      = 1133,     -- Warfront: Darkshore (Horde)/Bilgewater Cartel
        [2164]      = A and 2401 or H and 2373, -- The Eternal Palace/Waveblade Ankoan or The Unshackled
        [2212]      = 46,       -- Horrific Vision of Orgrimmar/Orgrimmar
        [2213]      = 72,       -- Horrific Vision of Stormwind/Stormwind
        [2217]      = 2164,     -- Ny'alotha: The Waking City/Champions of Azeroth
        [2268]      = 2391,     -- Mechagon City/Rustbolt Resistance

        ---------- Shadowlands ----------
        [2284]      = 2413,     -- Sanguine Depths/Court of Harvesters
        [2285]      = 2407,     -- Spires of Ascension/The Ascended
        [2286]      = 2407,     -- The Necrotic Wake/The Ascended
        [2287]      = 2439,     -- Halls of Atonement/The Avowed
        [2289]      = 2410,     -- Plaguefall/The Undying Army
        [2290]      = 2465,     -- Mists of Tirna Scithe/The Wild Hunt
        [2291]      = 2465,     -- De Other Side/The Wild Hunt
        [2293]      = 2410,     -- Theater of Pain/The Undying Army
        [2296]      = 2413,     -- Castle Nathria/Court of Harvesters
        [2453]      = 2432,     -- Torgast/Ve'nari
    }
    return instancesAndFactions
end