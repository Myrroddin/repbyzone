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
		-- see https://wago.tools/db2/AreaTable?build=2.5.5.66765

		---------- Vanilla ----------
		[GetAreaInfo(19)]		= 270,						-- Zul'Gurub/Zandalar Tribe
		[GetAreaInfo(35)]		= 21,						-- Booty Bay/Booty Bay
		[GetAreaInfo(36)]		= A and 730 or H and 729,	-- Alterac Mountains/Stormpike Guard or Frostwolf Clan
		[GetAreaInfo(100)]		= 47,						-- Nesingwary's Expedition/Ironforge
		[GetAreaInfo(122)]		= 270,						-- Zuuldaia Ruins/Zandalar Tribe
		[GetAreaInfo(125)]		= 270,						-- Kal'ai Ruins/Zandalar Tribe
		[GetAreaInfo(128)]		= 270,						-- Ziata'jai Ruins/Zandalar Tribe
		[GetAreaInfo(133)]		= 54,						-- Gnomeregan/Gnomeregan Exiles
		[GetAreaInfo(150)]		= 72,						-- Menethil Harbor/Stormwind
		[GetAreaInfo(193)]		= A and 72 or H and 68,		-- Ruins of Andorhal/Stormwind or Undercity
		[GetAreaInfo(196)]		= 72,						-- Uthor's Tomb/Stormwind
		[GetAreaInfo(197)]		= 72,						-- Sorrow Hill/Stormwind
		[GetAreaInfo(250)]		= 59,						-- Ruins of Thaurissan/Thorium Brotherhood
		[GetAreaInfo(280)]		= 349,						-- Strahnbrad/Ravenholdt
		[GetAreaInfo(288)]		= 72,						-- Azurelode Mine/Stormwind
		[GetAreaInfo(297)]		= 81,						-- Jaguero Isle/Thunder Bluff
		[GetAreaInfo(299)]		= 72,						-- Menethil Bay/Stormwind
		[GetAreaInfo(311)]		= 270,						-- Ruins of Aboraz/Zandalar Tribe
		[GetAreaInfo(313)]		= 349,						-- Northfold Manor/Ravenholdt
		[GetAreaInfo(314)]		= A and 72 or H and 68,		-- Go'Shek Farm/Stormwind or Undercity
		[GetAreaInfo(315)]		= 72,						-- Dabyrie's Farmstead/Stormwind
		[GetAreaInfo(317)]		= A and 471 or H and 530,	-- Witherbark Village/Wildhammer Clan or Darkspear Trolls
		[GetAreaInfo(320)]		= 72,						-- Refuge Pointe/Stormwind
		[GetAreaInfo(321)]		= 68,						-- Hammerfall/Undercity
		[GetAreaInfo(327)]		= 21,						-- Faldir's Cove/Booty Bay
		[GetAreaInfo(328)]		= 21,						-- The Drowned Reef/Booty Bay
		[GetAreaInfo(350)]		= 69,						-- Quel'Danil Lodge/Darnassus
		[GetAreaInfo(359)]		= A and 47 or H and 81,		-- Bael Modan/Ironforge or Thunder Bluff
		[GetAreaInfo(367)]		= 530,						-- Sen'jen Village/Darkspear Trolls
		[GetAreaInfo(368)]		= 530,						-- Echo Isles/Darkspear Trolls
		[GetAreaInfo(385)]		= 72,						-- Northwatch Hold/Stormwind
		[GetAreaInfo(392)]		= 470,						-- Ratchet/Ratchet
		[GetAreaInfo(393)]		= 530,						-- Darkspear Strand/Darkspear Trolls
		[GetAreaInfo(439)]		= A and 54 or H and 76,		-- The Shimmering Flats/Gnomeregan Exiles or Orgrimmar
		[GetAreaInfo(477)]		= 270,						-- Ruins of Jubuwal/Zandalar Tribe
		[GetAreaInfo(484)]		= A and 69 or H and 81,		-- Freewind Post/Darnassus or Thunder Bluff
		[GetAreaInfo(596)]		= 470,						-- Kodo Graveyard/Ratchet
		[GetAreaInfo(604)]		= 93,						-- Magram Village/Magram Clan Centaur
		[GetAreaInfo(606)]		= 92,						-- Gelkis Village/Gelkis Clan Centaur
		[GetAreaInfo(702)]		= 69,						-- Rut'theran Village/Darnassus
		[GetAreaInfo(813)]		= 529,						-- The Bulwark/Argent Dawn
		[GetAreaInfo(880)]		= 471,						-- Thandol Span (Arathi Highlands)/Wildhammer Clan
		[GetAreaInfo(881)]		= 47,						-- Thandol Span (Wetlands)/Ironforge
		[GetAreaInfo(896)]		= A and 730 or H and 729,	-- Purgation Isle/Stormpike Guard or Frostwolf Clan
		[GetAreaInfo(978)]		= A and 471 or H and 530,	-- Zul'Farrak/Wildhammer Clan or Darkspear Trolls
		[GetAreaInfo(1016)]		= 69,						-- Direforge Hill/Darnassus
		[GetAreaInfo(1025)]		= 69,						-- The Green Belt/Darnassus
		[GetAreaInfo(1057)]		= A and 47 or H and 68,		-- Thoradin's Wall (Hillsbrad Foothills)/Ironforge or Undercity
		[GetAreaInfo(1216)]		= 579,						-- Timbermaw Hold/Timbermaw Hold
		[GetAreaInfo(1446)]		= 59,						-- Thorium Point/Thorium Brotherhood
		[GetAreaInfo(1658)]		= 609,						-- Cenarion Enclave/Cenarion Circle
		[GetAreaInfo(1677)]		= A and 730 or H and 729,	-- Gavin's Naze/Stormpike Guard or Frostwolf Clan
		[GetAreaInfo(1679)]		= A and 730 or H and 729,	-- Corrahn's Dagger/Stormpike Guard or Frostwolf Clan
		[GetAreaInfo(1680)]		= A and 730 or H and 729,	-- The Headland/Stormpike Guard or Frostwolf Clan
		[GetAreaInfo(1678)]		= 72,						-- Sofera's Naze/Stormwind
		[GetAreaInfo(1739)]		= 87,						-- Bloodsail Compound/Bloodsail Buccaneers
		[GetAreaInfo(1741)]		= 87,						-- Gurubashi Arena/Bloodsail Buccaneers
		[GetAreaInfo(1761)]		= 579,						-- Deadwood Village/Timbermaw Hold
		[GetAreaInfo(1762)]		= 579,						-- Felpaw Village/Timbermaw Hold
		[GetAreaInfo(1837)]		= A and 471 or H and 530,	-- Witherbark Caverns/Wildhammer Clan or Darkspear Trolls
		[GetAreaInfo(1857)]		= A and 47 or H and 68,		-- Thoradin's Wall (Arathi Highlands)/Ironforge or Undercity
		[GetAreaInfo(1858)]		= A and 471 or H and 530,	-- Boulder'gor/Wildhammer Clan or Darkspear Trolls
		[GetAreaInfo(1977)]		= 309,						-- Zul'Gurub/Zandalar Tribe
		[GetAreaInfo(2097)]		= A and 69 or H and 81,		-- Darkcloud Pinnacle/Darnassus or Thunder Bluff
		[GetAreaInfo(2157)]		= A and 47 or H and 81,		-- Bael'dun Keep/Ironforge or Thunder Bluff
		[GetAreaInfo(2240)]		= 21,						-- Mirage Raceway/Booty Bay
		[GetAreaInfo(2241)]		= 589,						-- Frostsaber Rock/Wintersaber Trainers
		[GetAreaInfo(2243)]		= 579,						-- Timbermaw Post/Timbermaw Hold
		[GetAreaInfo(2244)]		= 579,						-- Winterfall Village/Timbermaw Hold
		[GetAreaInfo(2246)]		= 579,						-- Frostfire Hot Springs/Timbermaw Hold
		[GetAreaInfo(2257)]		= 72,						-- Deeprun Tram/Stormwind
		[GetAreaInfo(2276)]		= 69,						-- Quel'Lithien Lodge/Darnassus
		[GetAreaInfo(2405)]		= 529,						-- Ethel Rethor/Argent Dawn
		[GetAreaInfo(2406)]		= 69,						-- Ranazjar Isle/Darnassus
		[GetAreaInfo(2407)]		= 470,						-- Kormek's Hut/Ratchet
		[GetAreaInfo(2408)]		= 530,						-- Shadowprey Village/Darkspear Trolls
		[GetAreaInfo(2597)]		= A and 730 or H and 729,	-- Alterac Valley/Stormpike Guard or Frostwolf Clan
		[GetAreaInfo(2617)]		= 470,						-- Scrabblescrew's Camp/Ratchet
		[GetAreaInfo(2897)]		= 530,						-- Zoram'gar Outpost/Darkspear Trolls
		[GetAreaInfo(3197)]		= 72,						-- Chillwind Camp/Stormwind
		[GetAreaInfo(3357)]		= 270,						-- Yojamba Isle/Zandalar Tribe
		[GetAreaInfo(3456)]		= 529,						-- Naxxramas/Argent Dawn
		[GetAreaInfo(3486)]		= 349,						-- Ravenholdt Manor/Ravenholdt

		--------- TBC ---------
		[GetAreaInfo(3482)]		= 922,						-- The Dead Scar (Eversong Woods)/Tranquillien
		[GetAreaInfo(3514)]		= 922,						-- The Dead Scar (Ghostlands)/Tranquillien
		[GetAreaInfo(3530)]		= A and 930 or H and 911,	-- Shadow Ridge/Exodar or Silvermoon City
		[GetAreaInfo(3547)]		= 1077,						-- Throne of Kil'jaeden/Shattered Sun Offensive
		[GetAreaInfo(3552)]		= 978,						-- Temple of Telhamat/Kurenai
		[GetAreaInfo(3554)]		= 911,						-- Falcon Watch/Silvermoon City
		[GetAreaInfo(3555)]		= 941,						-- Mag'har Post/The Mag'har
		[GetAreaInfo(3569)]		= 69,						-- Tides' Hollow/Darnassus
		[GetAreaInfo(3573)]		= 72,						-- Odesyus' Landing/Stormwind
		[GetAreaInfo(3590)]		= 69,						-- Wrathscale Lair/Darnassus
		[GetAreaInfo(3591)]		= 69,						-- Ruins of Loreth'Aran/Darnassus
		[GetAreaInfo(3598)]		= 69,						-- Wyrmscar Island/Darnassus
		[GetAreaInfo(3623)]		= 933,						-- Aeris Landing/The Consortium
		[GetAreaInfo(3673)]		= 47,						-- Nesingwary Safari/Ironforge
		[GetAreaInfo(3628)]		= A and 930 or H and 911,	-- Halaa/Exodar or Silvermoon City
		[GetAreaInfo(3630)]		= 933,						-- Oshu'gun/The Consortium
		[GetAreaInfo(3631)]		= 933,						-- Spirit Fields/The Consortium
		[GetAreaInfo(3644)]		= 930,						-- Telredor/Exodar
		[GetAreaInfo(3645)]		= 530,						-- Zabra'jin/Darkspear Trolls
		[GetAreaInfo(3646)]		= 970,						-- Quagg Ridge/Sporeggar
		[GetAreaInfo(3647)]		= 970,						-- The Spawning Glen/Sporeggar
		[GetAreaInfo(3649)]		= 970,						-- Sporeggar/Sporeggar
		[GetAreaInfo(3652)]		= 970,						-- Funggor Cavern/Sporeggar
		[GetAreaInfo(3674)]		= 942,						-- Cenarion Thicket/Cenarion Expedition
		[GetAreaInfo(3679)]		= 1031,						-- Skettis/Sha'tari Skyguard
		[GetAreaInfo(3680)]		= 1031,						-- Blackwind Valley/Sha'tari Skyguard
		[GetAreaInfo(3681)]		= 934,						-- Firewing Point/The Scryers
		[GetAreaInfo(3683)]		= 941,						-- Stonebreaker Hold/The Mag'har
		[GetAreaInfo(3684)]		= 69,						-- Allerian Stronghold/Darnassus
		[GetAreaInfo(3690)]		= 1031,						-- Blackwind Lake/Sha'tari Skyguard
		[GetAreaInfo(3691)]		= 1031,						-- Lake Ere'Noru/Sha'tari Skyguard
		[GetAreaInfo(3718)]		= 530,						-- Swamprat Post/Darkspear Trolls
		[GetAreaInfo(3719)]		= 941,						-- Bleeding Hollow Ruins/The Mag'har
		[GetAreaInfo(3744)]		= 76,						-- Shadowmoon Village/Orgrimmar
		[GetAreaInfo(3745)]		= 471,						-- Wildhammer Stronghold/Wildhammer Clan
		[GetAreaInfo(3754)]		= 932,						-- Altar of Sha'tar/The Aldor
		[GetAreaInfo(3758)]		= 1015,						-- Netherwing Fields/Netherwing
		[GetAreaInfo(3759)]		= 1015,						-- Netherwing Ledge/Netherwing
		[GetAreaInfo(3766)]		= 978,						-- Orebor Harborage/Kurenai
		[GetAreaInfo(3769)]		= 941,						-- Thunderlord Stronghold/The Mag'har
		[GetAreaInfo(3771)]		= 69,						-- The Living Grove/Darnassus
		[GetAreaInfo(3772)]		= 69,						-- Sylvanaar/Darnassus
		[GetAreaInfo(3784)]		= 1031,						-- Forge Camp: Terror/Sha'tari Skyguard
		[GetAreaInfo(3785)]		= 1031,						-- Forge Camp: Wrath/Sha'tari Skyguard
		[GetAreaInfo(3792)]		= 933,						-- Mana-Tombs/The Consortium
		[GetAreaInfo(3801)]		= 941,						-- Mag'har Grounds/The Mag'har
		[GetAreaInfo(3806)]		= 911,						-- Supply Caravan/Silvermoon City
		[GetAreaInfo(3808)]		= 942,						-- Cenarion Post/Cenarion Expedition
		[GetAreaInfo(3816)]		= 21,						-- Zeppelin Crash/Booty Bay
		[GetAreaInfo(3828)]		= 942,						-- Ruuan Weald/Cenarion Expedition
		[GetAreaInfo(3839)]		= 1011,						-- Abandoned Armory/Lower City
		[GetAreaInfo(3842)]		= 935,						-- Tempest Keep (Netherstorm)/The Sha'tar
		[GetAreaInfo(3864)]		= 1031,						-- Bash'ir Landing/Sha'tari Skyguard
		[GetAreaInfo(3896)]		= 932,						-- Aldor Rise/The Aldor
		[GetAreaInfo(3898)]		= 934,						-- Scryer's Tier/The Scryers
		[GetAreaInfo(3899)]		= 1011,						-- Lower City/Lower City
		[GetAreaInfo(3901)]		= 69,						-- Allerian Post/Darnassus
		[GetAreaInfo(3902)]		= 941,						-- Stonebreaker Camp/The Mag'har
		[GetAreaInfo(3918)]		= 54,						-- Toshley's Station/Gnomeregan
		[GetAreaInfo(3936)]		= 471,						-- Deathforge Tower/Wildhammer Clan
		[GetAreaInfo(3937)]		= 76,						-- Slag Watch/Orgrimmar
		[GetAreaInfo(3938)]		= 934,						-- Sanctum of the Stars/The Scryers
		[GetAreaInfo(3951)]		= 942,						-- Evergrove/Cenarion Expedition
		[GetAreaInfo(3952)]		= 942,						-- Wyrmskull Bridge/Cenarion Expedition
		[GetAreaInfo(3958)]		= 1031,						-- Sha'tari Base Camp/Sha'tari Skyguard
		[GetAreaInfo(3965)]		= 1015,						-- Netherwing Mines/Netherwing
		[GetAreaInfo(3966)]		= 1015,						-- Dragonmaw Base Camp/Netherwing
		[GetAreaInfo(3964)]		= 1031,						-- Skyguard Outpost/Sha'tari Skyguard
		[GetAreaInfo(3973)]		= 1031,						-- Blackwind Landing/Sha'tari Skyguard
		[GetAreaInfo(3974)]		= 1031,						-- Veil Harr'ik/Sha'tari Skyguard
		[GetAreaInfo(3975)]		= 1031,						-- Terokk's Rest/Sha'tari Skyguard
		[GetAreaInfo(3976)]		= 1031,						-- Veil Ala'rak/Sha'tari Skyguard
		[GetAreaInfo(3977)]		= 1031,						-- Upper Veil Shil'ak/Sha'tari Skyguard
		[GetAreaInfo(3978)]		= 1031,						-- Lower Veil Shil'ak/Sha'tari Skyguard
	}
	return subZonesAndFactions
end