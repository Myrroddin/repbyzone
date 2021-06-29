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
        [489]       = A and 890 or H and 889, -- Warsong Gulch/Silverwing Sentinels or Warsong Outriders
        [529]       = A and 509 or H and 510, -- Arathi Basin (Classic)/The League of Arathor or The Defilers
        [566]       = A and 930 or H and 911, -- Eye of the Storm/Exodar or Silvermoon City
        [607]       = A and 1050 or H and 1085, -- Strand of the Ancients/Valiance Expedition or Warsong Offensive
        [628]       = A and 1050 or H and 1085, -- Isle of Conquest/Valiance Expedition or Warsong Offensive
        [726]       = A and 1174 or H and 1172, -- Twin Peaks/Wildhammer Clan or Dragonmaw Clan
        [727]       = A and 72 or H and 1133, -- Silvershard Mines/Stormwind or Bilgewater Cartel
        [761]       = A and 1134 or H and 68, -- The Battle for Gilneas/Gilneas or Undercity
        [968]       = A and 930 or H and 911, -- Eye of the Storm (rated)/Exodar or Silvermoon City
        [998]       = A and 1353 or H and 1352, -- Temple of Kotmogu/Tushui Pandaren or Huojin Pandaren
        [1105]      = A and 1353 or H and 1352, -- Deepwind Gorge/Tushui Pandaren or Huojin Pandaren
        [1681]      = A and 509 or H and 510, -- Arathi Basin (Winter)/The League of Arathor or The Defilers
        [1803]      = A and 72 or H and 68, -- Seething Shore/Stormwind or Undercity
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
        [615]       = 1091,     -- The Eye of Eternity/The Wyrmrest Accord
        [619]       = A and 1050 or H and 1067, -- Ahn'kahet: The Old Kingdom/Valiance Expedition or The Hand of Vengeance
        [624]       = A and 1037 or H and 1052, -- Vault of Archavon/Alliance Vanguard or Horde Expedition
        [631]       = 1156,     -- Icecrown Citadel/The Ashen Verdict
        [632]       = 1156,     -- Forge of Souls/The Ashen Verdict
        [649]       = 1106,     -- Trial of the Crusader/Argent Crusade
        [650]       = 1106,     -- Trial of the Champion/Argent Crusade
        [658]       = 1156,     -- Pit of Saron/The Ashen Verdict
        [668]       = 1156,     -- Halls of Reflection/The Ashen Verdict
        [724]       = 1091,     -- The Ruby Sanctum/The Wyrmrest Accord

        ---------- Cataclysm ----------
        [369]       = 72,       -- Deeprun Tram/Stormwind
        [974]       = 909,      -- Darkmoon Island/Darkmoon Faire
        [1113]      = 909,      -- Transport: Darkmoon Carousel/Darkmoon Faire

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
        [1136]      = A and 72 or H and 76, -- Siege of Orgrimmar/Stormwind or Orgrimmar
        [1148]      = self.racialRepID, -- Proving Grounds/racial rep
        
        ---------- BfA ----------
        [1594]      = 1133,     -- The Motherloade!!/Bilgewater Cartel
        [1754]      = 2160,     -- Freehold/Proudmoore Admiralty
        [1762]      = 2103,     -- King's Rest/Zandalari Empire
        [1763]      = 2103,     -- Atal'Dazar/Zandalari Empire
        [1771]      = 2160,     -- Tol Dagor/Proudmoore Admiralty
        [1804]      = A and 509 or H and 510, -- Warfront: The Battle for Stromgarde/The League of Arathor or The Defilers
        [1813]      = A and 69 or H and 76, -- Un'gol Ruins/Darnassus or Orgrimmar
        [1814]      = A and 1134 or H and 68, -- Havenswood/Gilneas or Undercity
        [1822]      = A and 2160 or H and 2103, -- Siege of Boralus/Proudmoore Admiralty or Zandalari Empire
        [1841]      = 2103,     -- The Underrot/Zandalari Empire
        [1861]      = 2164,     -- Uldir/Champions of Azeroth
        [1862]      = 2161,     -- Waycrest Manor/Order of Embers
        [1864]      = 2162,     -- Shrine of the Storm/Storm's Wake
        [1877]      = 2158,     -- Temple of Sethraliss/Voldunai
        [1882]      = 942,      -- Verdant Wilds/Cenarion Expedition
        [1892]      = 87,       -- Rotting Mire/Bloodsail Buccaneers
        [1897]      = A and 1173 or H and 2103, -- Molten Cay/Ramkahen or Zandalari Empire
        [1898]      = A and 1050 or H and 1067, -- Skittering Hollow/Valliance Expedition or The Hand of Vengeance
        [1907]      = A and 1353 or H and 1352, -- Snowblossom Village/Tushui Pandaren or Huojin Pandaren
        [1979]      = A and 1073 or H and 1064, -- Jorundall/The Kalu'ak or The Taunka
        [1883]      = A and 69 or H and 530, -- Whispering Reef/Darnassus or Darkspear Trolls
        [1893]      = 1106,     -- Dread Chain/Argent Crusade
        [1955]      = A and 2160 or H and 2103, -- Uncharted Island/Proudmoore Admiralty or Zandalari Empire
        [2070]      = A and 2160 or H and 2103, -- Battle of Dazara'lor/Proudmoore Admiralty or Zandalari Empire
        [2096]      = 2162,     -- Crucible of Storms/Storm's Wake
        [2097]      = 2391,     -- Operation: Mechagon/Rustbolt Resistance
        [2105]      = 69,       -- Warfront: Darkshore (Alliance)/Darnassus
        [2111]      = 68,     -- Warfront: Darkshore (Horde)/Undercity
        [2124]      = A and 2160 or H and 76, -- Crestfall/Proudmoore Admiralty or Orgrimmar
        [2147]      = 1098,     -- Icecrown Citadel (8.1)/Knights of the Ebon Blade
        [2164]      = A and 2401 or H and 2373, -- The Eternal Palace/Waveblade Ankoan or The Unshackled
        [2212]      = 76,       -- Horrific Vision of Orgrimmar/Orgrimmar
        [2213]      = 72,       -- Horrific Vision of Stormwind/Stormwind
        [2217]      = 2164,     -- Ny'alotha: The Waking City/Champions of Azeroth
        [2268]      = 2391,     -- Mechagon City/Rustbolt Resistance
        [2292]      = A and 509 or H and 510, -- Arathi (Epic Warfront)/The League of Arathor or The Defilers

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