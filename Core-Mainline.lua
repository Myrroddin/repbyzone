---@diagnostic disable: duplicate-set-field, undefined-global, undefined-field
-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local After = C_Timer.After
local ALLIANCE = FACTION_ALLIANCE
local CollapseFactionHeader = C_Reputation.CollapseFactionHeader
local enum = Enum.CovenantType
local ExpandFactionHeader = C_Reputation.ExpandFactionHeader
local FACTION_INACTIVE = FACTION_INACTIVE
local GetActiveCovenantID = C_Covenants.GetActiveCovenantID
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetFactionDataByIndex = C_Reputation.GetFactionDataByIndex
local GetFactionDataByID = C_Reputation.GetFactionDataByID
local GetInstanceInfo = GetInstanceInfo
local GetInventoryItemID = GetInventoryItemID
local GetMapInfo = C_Map.GetMapInfo
local GetMinimapZoneText = GetMinimapZoneText
local GetNumFactions = C_Reputation.GetNumFactions
local HORDE = FACTION_HORDE
local INVSLOT_TABARD = INVSLOT_TABARD
local IsInInstance = IsInInstance
local IsPlayerNeutral = IsPlayerNeutral
local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local LibStub = LibStub
local NONE = NONE
local pairs = pairs
local select = select
local SetWatchedFactionByID = C_Reputation.SetWatchedFactionByID
local type = type
local UnitFactionGroup = UnitFactionGroup
local UnitOnTaxi = UnitOnTaxi
local UnitRace = UnitRace
local wipe = wipe
local MAX_REPUTATION_REACTION = MAX_REPUTATION_REACTION

------------------- Create the addon --------------------
---@class RepByZone: AceAddon, AceEvent-3.0, AceConsole-3.0
local RepByZone = LibStub("AceAddon-3.0"):NewAddon("RepByZone", "AceEvent-3.0", "AceConsole-3.0", "LibAboutPanel-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")

-- Local variables
local db, isOnTaxi, instancesAndFactions, zonesAndFactions, subZonesAndFactions
local A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
local H = UnitFactionGroup("player") == "Horde" and HORDE
local CURRENT_DB_VERSION = 1

-- Table to localize subzones that Blizzard does not provide areaIDs
local citySubZonesAndFactions = {
	-- [L["Subzone"]]				= factionID, subzone names are localized so we can compare to the localized minimap text from Blizzard
	[L["A Hero's Welcome"]]			= A and 1094 or H and 1124,		-- The Silver Covenant or The Sunreavers
	[L["Shrine of Unending Light"]]	= 932,							-- The Aldor
	[L["The Beer Garden"]]			= A and 1094 or H and 1124,		-- The Silver Covenant or The Sunreavers
	[L["The Crimson Dawn"]]			= 1124,							-- The Sunreavers
	[L["The Filthy Animal"]]		= A and 1094 or H and 1124,		-- The Silver Covenant or The Sunreavers
	[L["The Salty Sailor Tavern"]]	= 21,							-- Booty Bay
	[L["The Seer's Library"]]		= 934,							-- The Scryers
	[L["The Silver Blade"]]			= 1094,							-- The Silver Covenant
	[L["Tinker Town"]]				= 54,							-- Gnomeregan
}

-- Faction tabard code
local tabardID, tabardStandingStatus = nil, false
local tabard_itemIDs_to_factionIDs = {
	-- [itemID]		= factionID
	-- Alliance
	[45574]		= 72,		-- Stormwind City
	[45577]		= 47,		-- Ironforge
	[45578]		= 54,		-- Gnomeregan
	[45579]		= 69,		-- Darnassus
	[45580]		= 930,		-- Exodar
	[64882]		= 1134,		-- Gilneas
	[83079]		= 1353,		-- Tushui Pandaren

	-- Horde
	[45581]		= 76,		-- Orgrimmar
	[45582]		= 530,		-- Darkspear Trolls
	[45583]		= 68,		-- Undercity
	[45584]		= 81,		-- Thunder Bluff
	[45585]		= 911,		-- Silvermoon City
	[64884]		= 1133,		-- Bilgewater Cartel
	[83080]		= 1352,		-- Huojin Pandaren
}

-- WoD garrison bodyguard code
local bodyguardRepID

RepByZone.WoDFollowerZones = {
	[525]		= true,		-- Frostfire Ridge
	[534]		= true,		-- Tanaan Jungle
	[535]		= true,		-- Talador
	[539]		= true,		-- Shadowmoon Valley
	[542]		= true,		-- Spires of Arak
	[543]		= true,		-- Gorgrond
	[550]		= true,		-- Nagrand
	[582]		= true,		-- Lunarfall
	[590]		= true,		-- Frostwall
}

local bodyguard_quests = {
	-- [questID]	= factionID
	[36877]		= 1736,		-- Tormmok
	[36898]		= 1733,		-- Delvar Ironfist
	[36899]		= 1738,		-- Defender Illona
	[36900]		= 1737,		-- Talonpriest Ishaal
	[36901]		= 1739,		-- Vivianne
	[36902]		= 1740,		-- Aeda Brightdawn
	[36936]		= 1741,		-- Leorajh
}

-- Covenant code
local covenantReps = {
	[enum.Kyrian]		= 2407,		-- The Ascended
	[enum.Venthyr]		= 2413,		-- Court of Harvesters
	[enum.NightFae]		= 2422,		-- Night Fae
	[enum.Necrolord]	= 2410,		-- The Undying Army
}

-- Get the character's racial factionID for the defaults table
-- See https://wago.tools/db2/ChrRaces for the list of raceIDs
-- Note: allied races must use factionIDs under "Alliance" or "Horde" in the reputation panel, as their true factionIDs may not be discovered until the player quests in the appropriate zones
local player_raceIDs_to_factionIDs = {
	-- [playerRaceID]   = factionID
	[1]		= 72,		-- Human/Stormwind
	[2]		= 76,		-- Orc/Orgrimmar
	[3]		= 47,		-- Dwarf/Ironforge
	[4]		= 69,		-- Night Elf/Darnassus
	[5]		= 68,		-- Undead (Scourge)/Undercity
	[6]		= 81,		-- Tauren/Thunder Bluff
	[7]		= 54,		-- Gnome/Gnomeregan
	[8]		= 530,		-- Troll/Darkspear Trolls
	[9]		= 1133,		-- Goblin/Bilgewater Cartel
	[10]	= 911,		-- Blood Elf/Silvermoon City
	[11]	= 930,		-- Draenei/Exodar
	[22]	= 1134,		-- Worgen/Gilneas
	[23]	= 1134,		-- Gilnean/Gilneas
	[24]	= 1216,		-- Pandaren (Neutral)/Shang Xi's Academy
	[25]	= 1353,		-- Pandaren (Alliance)/Tushui Pandaren
	[26]	= 1352,		-- Pandaren (Horde)/Huojin Pandaren
	[27]	= 911,		-- Nightborne/Silvermoon City
	[28]	= 81,		-- Highmountain Tauren/Thunder Bluff
	[29]	= 69,		-- Void Elf/Darnassus
	[30]	= 930,		-- Lightforged Draenei/Exodar
	[31]	= 530,		-- Zandalari Troll/Darkspear Trolls
	[32]	= 72,		-- Kul Tiran/Stormwind
	[33]	= 72,		-- Thin Human/Stormwind
	[34]	= 47,		-- Dark Iron Dwarf/Ironforge
	[35]	= 76,		-- Vulpera/Orgrimmar
	[36]	= 76,		-- Maghar Orc/Orgrimmar
	[37]	= 54,		-- Mechagnome/Gnomeregan
	[52]	= 2524,		-- Dracthyr (Alliance)/Obsidian Warders
	[70]	= 2523,		-- Dracthyr (Horde)/Dark Talons
	[84]	= 76,		-- Earthen (Horde)/Orgrimmar
	[85]	= 47,		-- Earthen (Alliance)/Ironforge
	[86]	= 930,		-- Haranir (Alliance)/Exodar
	[91]	= 530,		-- Haranir (Horde)/Darkspear Trolls
}
local function GetRacialRep()
	local _, _, playerRaceID = UnitRace("player")
	local racialRepID
	racialRepID = player_raceIDs_to_factionIDs[playerRaceID]
	if not racialRepID then
		racialRepID = A and 72 or H and 76 -- Known factionIDs in case Blizzard adds new races and the addon hasn't been updated
	end
	return racialRepID
end

-- Return a table of default SV values
local defaults = {
	profile = {
		enabled					= true,
		ignoreExaltedTabards	= true,
		useFactionTabards		= true,
		verbose					= true,
		watchOnTaxi				= true,
		watchSubZones			= true,
		watchWoDBodyGuards		= {
			["**"] = true
		}
	},
	char = {
		watchedRepID			= GetRacialRep()
	},
	global = {
		delayGetFactionDataByID	= 0.25,
	}
}

-- Ace3 code
function RepByZone:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("RepByZoneDB", defaults, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	-- if the current_db_version is less than the CURRENT_DB_VERSION, reset the database to defaults and show a popup message to the user
	local oldVersion = self.db.global.current_db_version
	if (not oldVersion) or (oldVersion < CURRENT_DB_VERSION) then
		StaticPopupDialogs["REPBYZONE_RESET"] = {
			text = L["RepByZone has been updated. The settings have been reset to defaults."],
			button1 = ACCEPT,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true
		}
		StaticPopup_Show("REPBYZONE_RESET")
		self.db:ResetDB(DEFAULT)
	end

	self.db.global.current_db_version = CURRENT_DB_VERSION
	db = self.db.profile
	self:SetEnabledState(db and db.enabled)

	local options = self:GetOptions() -- Options.lua
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

	-- Support for LibAboutPanel-2.0
	options.args.aboutTab = self:AboutOptionsTable("RepByZone")
	options.args.aboutTab.order = -1 -- -1 means "put it last"

	-- Register your options with AceConfigRegistry
	LibStub("AceConfig-3.0"):RegisterOptionsTable("RepByZone", options)

	-- Add options to Interface/AddOns
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RepByZone", "RepByZone")

	-- Create slash commands
	self:RegisterChatCommand("repbyzone", "SlashHandler")
	self:RegisterChatCommand("rbz", "SlashHandler")
end

function RepByZone:OnEnable()
	-- All events that deal with entering a new zone or subzone are handled with the same function
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "SwitchedZones")
	if db.watchSubZones then
		self:RegisterEvent("ZONE_CHANGED", "SwitchedZones")
		self:RegisterEvent("ZONE_CHANGED_INDOORS", "SwitchedZones")
	end

	-- If the player loses or gains control of the character, it is one of the signs of taxi use
	self:RegisterEvent("PLAYER_CONTROL_LOST", "CheckTaxi")
	self:RegisterEvent("PLAYER_CONTROL_GAINED", "CheckTaxi")

	-- We are zoning into an instance
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- Pandaren do not start Alliance or Horde
	if IsPlayerNeutral() then
		self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT", "GetPandarenRep")
	else
		-- We missed Pandaren joining either the Alliance or Horde and the char db is outdated
		if self.db.char.watchedRepID == 1216 then
			self:GetPandarenRep(nil, true)
		end
	end

	-- See if the player belongs to a Covenant, picks one, or changes Covenants
	self:RegisterEvent("COVENANT_CHOSEN", "GetCovenantRep")

	-- Check if a WoD garrison bodyguard is assigned
	self:RegisterEvent("CHAT_MSG_MONSTER_SAY", "UpdateActiveBodyguardRepID")
	self:RegisterEvent("GOSSIP_CLOSED", "UpdateActiveBodyguardRepID")

	-- Check if a faction tabard is equipped or changed
	if db.useFactionTabards then
		self:RegisterEvent("UNIT_INVENTORY_CHANGED", "GetEquippedTabard")
		self:RegisterEvent("UPDATE_FACTION", "UpdateTabardStanding")
		self:GetEquippedTabard(nil, "player")
	end

	-- Is the player on a taxi?
	self:CheckTaxi()

	-- Calculate the fallback reputation
	self.fallbackRepID = (type(self.db.char.watchedRepID) == "number" and self.db.char.watchedRepID) or 0

	-- For certain content
	self.racialRepID = GetRacialRep()

	-- Get the player's Covenant, if any
	self:GetCovenantRep()

	-- Get the player's WoD garrison bodyguard, if any
	bodyguardRepID = self:GetActiveBodyguardRepID()
	wipe(self.WoDFollowerZones)
	for index, value in pairs(db.watchWoDBodyGuards) do
		self.WoDFollowerZones[index] = value
	end

	self:SwitchedZones()
end

function RepByZone:OnDisable()
	-- Stop watching events if RBZ is disabled
	self:UnregisterAllEvents()

	-- Shrink memory footprint by wiping variables
	isOnTaxi = nil
	self.fallbackRepID = nil
	self.racialRepID = nil
	self.covenantRepID = nil
	tabardID = nil
	bodyguardRepID = nil
	tabardStandingStatus = false
end

function RepByZone:SlashHandler()
	LibStub("AceConfigDialog-3.0"):Open("RepByZone")
end

-- The user has reset the profile or created a new profile
function RepByZone:RefreshConfig(callback)
	if callback == "OnProfileReset" then
		self.db:ResetDB(DEFAULT)
	end
	self.db.global.current_db_version = CURRENT_DB_VERSION
	db = self.db.profile
	self.fallbackRepID = (type(self.db.char.watchedRepID) == "number" and self.db.char.watchedRepID) or 0
	self.racialRepID = GetRacialRep()
	zonesAndFactions = self:ZoneAndFactionList()
	subZonesAndFactions = self:SubZonesAndFactionsList()
	instancesAndFactions = self:InstancesAndFactionList()
	self:CheckTaxi()
	self:GetEquippedTabard(nil, "player")
	bodyguardRepID = self:GetActiveBodyguardRepID()
	wipe(self.WoDFollowerZones)
	for index, value in pairs(db and db.watchWoDBodyGuards) do
		self.WoDFollowerZones[index] = value
	end
	self:GetCovenantRep()
	self:SwitchedZones()
end

------------------- Event handlers starts here --------------------
-- Entering an instance
function RepByZone:PLAYER_ENTERING_WORLD(_, isInitialLogin, isReloadingUi)
	-- If either of these are true, we didn't enter an instance, so exit
	if isInitialLogin or isReloadingUi then
		return
	end

	After(1, function() self:SwitchedZones() end)
end

-- Is the player on a taxi
function RepByZone:CheckTaxi()
	isOnTaxi = UnitOnTaxi("player")
end

-- What Covenant does the player belong to, if any
function RepByZone:CovenantToFactionID()
	local id = GetActiveCovenantID()
	return covenantReps[id]
end

function RepByZone:GetCovenantRep()
	local newCovenantRepID = self:CovenantToFactionID()
	if newCovenantRepID ~= self.covenantRepID then
		self.covenantRepID = newCovenantRepID

		-- update both zones and subzones
		instancesAndFactions = self:InstancesAndFactionList()
		zonesAndFactions = self:ZoneAndFactionList()
		subZonesAndFactions = self:SubZonesAndFactionsList()
		self:SwitchedZones()
	end
end

-- Pandaren code
function RepByZone:GetPandarenRep(event, success)
	if success then
		if event then
			self:UnregisterEvent(event)
		end
		A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
		H = UnitFactionGroup("player") == "Horde" and HORDE
		if A or H then
			-- Update data
			self.db.char.watchedRepID = GetRacialRep()
			self.racialRepID = GetRacialRep()
			self.fallbackRepID = (type(self.db.char.watchedRepID) == "number" and self.db.char.watchedRepID) or 0
			local factionName = GetFactionInfoByID(self.db.char.watchedRepID)
			-- Update the faction lists
			zonesAndFactions = self:ZoneAndFactionList()
			subZonesAndFactions = self:SubZonesAndFactionsList()
			instancesAndFactions = self:InstancesAndFactionList()
			self:Print(L["You have joined the %s, switching watched saved variable to %s."]:format(A or H, factionName))
			self:SwitchedZones()
		end
	end
end

-- WoD bodyguard code
function RepByZone:GetActiveBodyguardRepID()
	local newBodyguardRepID
	for questID in pairs(bodyguard_quests) do
		if IsQuestFlaggedCompleted(questID) then
			newBodyguardRepID = bodyguard_quests[questID]
			break
		end
	end
	return newBodyguardRepID
end

function RepByZone:UpdateActiveBodyguardRepID()
	-- Send a custom event to the handler
	self:SwitchedZones("BODYGUARD_UPDATED")
end

-- Tabard code
function RepByZone:UpdateTabardStanding()
	if not tabardID then
		if tabardStandingStatus then
			tabardStandingStatus = false
			self:SwitchedZones()
		end
		return
	end

	local factionData = GetFactionDataByID(tabardID)
	local isExalted = (factionData and factionData.reaction == MAX_REPUTATION_REACTION) or false

	if isExalted ~= tabardStandingStatus then
		tabardStandingStatus = isExalted
		self:SwitchedZones()
	end
end

function RepByZone:GetEquippedTabard(_, unit)
	if unit ~= "player" then return end

	local newItemID = GetInventoryItemID(unit, INVSLOT_TABARD)
	local newFactionID = newItemID and tabard_itemIDs_to_factionIDs[newItemID]
	local factionData = GetFactionDataByID(newFactionID)

	local newStanding = factionData and (factionData.reaction == MAX_REPUTATION_REACTION) or false

	local changed = false

	if newFactionID ~= tabardID then
		tabardID = newFactionID
		changed = true
	end

	if newStanding ~= tabardStandingStatus then
		tabardStandingStatus = newStanding
		changed = true
	end

	if changed then
		self:SwitchedZones()
	end
end

-------------------- Reputation code starts here --------------------
local repsCollapsed = {} -- Obey user's settings about headers opened or closed
-- Open all faction headers
function RepByZone:OpenAllFactionHeaders()
	local numFactions = GetNumFactions()
	local factionData, factionIndex = nil, 1

	while factionIndex <= numFactions do
		factionData = GetFactionDataByIndex(factionIndex)
		if factionData then
			if factionData.isHeader and factionData.isCollapsed then
				if factionData.name then
					repsCollapsed[factionData.name] = repsCollapsed[factionData.name] or factionData.isCollapsed
					ExpandFactionHeader(factionIndex)
					numFactions = GetNumFactions()
				end
			end
			factionIndex = factionIndex + 1
		end
	end
end

-- Close all faction headers
function RepByZone:CloseAllFactionHeaders()
	local numFactions = GetNumFactions()
	local factionData, factionIndex = nil, 1

	while factionIndex <= numFactions do
		factionData = GetFactionDataByIndex(factionIndex)
		if factionData then
			if factionData.isHeader then
				if factionData.isCollapsed and not repsCollapsed[factionData.name] then
					ExpandFactionHeader(factionIndex)
					numFactions = GetNumFactions()
				elseif repsCollapsed[factionData.name] and not factionData.isCollapsed then
					CollapseFactionHeader(factionIndex)
					numFactions = GetNumFactions()
				end
			end
			factionIndex = factionIndex + 1
		end
	end
	wipe(repsCollapsed)
end

function RepByZone:GetAllFactions()
	-- Will not return factions the user has marked as inactive
	self:OpenAllFactionHeaders()
	local factionData, factionList = nil, {}

	for factionIndex = 1, GetNumFactions() do
		factionData = GetFactionDataByIndex(factionIndex)
		if factionData then
			if factionData.name then
				if not factionData.isHeader and factionData.name ~= FACTION_INACTIVE then
					if factionData.factionID then
						factionList[factionData.factionID] = factionData.name
					end
				end
			end
		end
	end
	factionList["0-none"] = NONE

	self:CloseAllFactionHeaders()
	return factionList
end

-------------------- Watched faction code starts here --------------------
-- Player switched zones, subzones, or instances, set watched faction
function RepByZone:SwitchedZones(event)
	if not db.enabled then return end -- Exit if the addon is disabled

	-- Possible zoning issues, exit out unless we have valid map data
	local uiMapID = GetBestMapForUnit("player")
	if not uiMapID then return end

	-- Populate tables if they haven't been already
	if not instancesAndFactions then
		instancesAndFactions = self:InstancesAndFactionList()
	end
	if not zonesAndFactions then
		zonesAndFactions = self:ZoneAndFactionList()
	end
	if not subZonesAndFactions then
		subZonesAndFactions = self:SubZonesAndFactionsList()
	end

	if isOnTaxi then
		if not db.watchOnTaxi then
			-- On taxi but don't switch
			return
		end
	end

	-- This is a custom event
	if event == "BODYGUARD_UPDATED" then
		bodyguardRepID = self:GetActiveBodyguardRepID()
	end

	-- Set up variables
	local watchedFactionID, factionData = nil, nil
	local hasDungeonTabard, lookUpSubZones = false, false
	local inInstance, instanceType = IsInInstance()
	local whichInstanceID = inInstance and select(8, GetInstanceInfo())
	local parentMapID = GetMapInfo(uiMapID).parentMapID
	local subZone = GetMinimapZoneText()
	local isWoDZone = self.WoDFollowerZones[uiMapID] or (self.WoDFollowerZones[uiMapID] == nil and self.WoDFollowerZones[parentMapID])

	-- Apply faction tabard instance reputation
	if inInstance and instanceType == "party" then
		hasDungeonTabard =
		db.useFactionTabards
		and tabardID ~= nil
		and (not db.ignoreExaltedTabards or not tabardStandingStatus)
	else
		-- We aren't in a party
		hasDungeonTabard = false
	end
	if self.tabardExemptDungeons[whichInstanceID] then
		-- every 5-person dungeon from Shadowlands+ does not support faction tabards
		hasDungeonTabard = false
	end

	-- Process subzones
	if db.watchSubZones then
		lookUpSubZones = true
		-- Stromgarde Keep and The Battle for Stromgarde are the only instances with subzones which are different than the main instance data
		if (inInstance and whichInstanceID ~= 1155) and (inInstance and whichInstanceID ~= 1804) then
			lookUpSubZones = false
		end

		-- Don't loop through subzones if the player is watching a bodyguard rep
		if isWoDZone and bodyguardRepID then
			lookUpSubZones = false
		end
	end

	watchedFactionID = watchedFactionID
	or (inInstance and hasDungeonTabard and tabardID)
	or (lookUpSubZones and citySubZonesAndFactions[subZone] or subZonesAndFactions[subZone])
	or (inInstance and instancesAndFactions[whichInstanceID])
	or (not lookUpSubZones and isWoDZone and bodyguardRepID)
	or (not inInstance and zonesAndFactions[uiMapID] or zonesAndFactions[parentMapID])
	or self.fallbackRepID

	-- WoW has a delay whenever the player changes instance/zone/subzone/tabard; factionName and isWatched aren't available immediately, so delay the lookup, then set the watched faction on the bar
	After(self.db.global.delayGetFactionDataByID, function()
		if type(watchedFactionID) == "number" and watchedFactionID > 0 then
			-- We have a factionID to watch either from the databases or the default watched factionID is a number greater than 0
			factionData = GetFactionDataByID(watchedFactionID)
			if factionData and not factionData.isWatched then
				SetWatchedFactionByID(watchedFactionID)
				if db.verbose then
					self:Print(L["Now watching %s"]:format(factionData.name))
				end
			end
		else
			-- There is no factionID to watch based on the databases and the user set the default watched factionID to "0-none"
			SetWatchedFactionByID(0)
		end
	end)
end