-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local ALLIANCE = FACTION_ALLIANCE
local After = C_Timer.After
local CollapseFactionHeader = C_Reputation.CollapseFactionHeader
local enum = Enum.CovenantType
local ExpandFactionHeader = C_Reputation.ExpandFactionHeader
local FACTION_INACTIVE = FACTION_INACTIVE
local GetActiveCovenantID = C_Covenants.GetActiveCovenantID
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetDelvesFactionForSeason = C_DelvesUI.GetDelvesFactionForSeason
local GetFactionDataByID = C_Reputation.GetFactionDataByID
local GetFactionDataByIndex = C_Reputation.GetFactionDataByIndex
local GetInstanceInfo = GetInstanceInfo
local GetInventoryItemID = GetInventoryItemID
local GetMapInfo = C_Map.GetMapInfo
local GetMinimapZoneText = GetMinimapZoneText
local GetNumFactions = C_Reputation.GetNumFactions
local HORDE = FACTION_HORDE
local INVSLOT_TABARD = INVSLOT_TABARD
local IsPlayerNeutral = IsPlayerNeutral
local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local LibStub, NONE, pairs, select, type, wipe = LibStub, NONE, pairs, select, type, wipe
local MAX_REPUTATION_REACTION = MAX_REPUTATION_REACTION
local SetWatchedFactionByID = C_Reputation.SetWatchedFactionByID
local StaticPopupDialogs = StaticPopupDialogs
local StaticPopup_Show = StaticPopup_Show
local UnitFactionGroup = UnitFactionGroup
local UnitOnTaxi, UnitRace, UNKNOWN = UnitOnTaxi, UnitRace, UNKNOWN

------------------- Create the addon --------------------
---@class RepByZoneProfile
---@field enabled boolean
---@field ignoreExaltedTabards boolean
---@field useFactionTabards boolean
---@field verbose boolean
---@field watchOnTaxi boolean
---@field watchSubZones boolean
---@field watchWoDBodyGuards table<number|string, boolean>

---@class RepByZoneCharacterDB
---@field watchedRepID number|string?

---@class RepByZoneGlobalDB
---@field delayGetFactionDataByID number
---@field current_db_version number?

---@class RepByZoneDB: AceDBObject-3.0
---@field RegisterCallback fun(target: table, eventName: string, method: string|function, arg?: any)
---@field ResetDB fun(self: RepByZoneDB, defaultProfile?: string)
---@field profile RepByZoneProfile
---@field char RepByZoneCharacterDB
---@field global RepByZoneGlobalDB

---@class RepByZone: AceAddon, AceEvent-3.0, AceConsole-3.0, LibAboutPanel-2.0
---@field db RepByZoneDB
---@field fallbackRepID number?
---@field racialRepID number?
---@field covenantRepID number?
---@field WoDFollowerZones table<number|string, boolean>
---@field tabardExemptDungeons table<number, boolean>
---@field GetOptions fun(self: RepByZone): table
---@field InstancesAndFactionList fun(self: RepByZone): table<number, number>
---@field ZoneAndFactionList fun(self: RepByZone): table<number, number>
---@field SubZonesAndFactionsList fun(self: RepByZone): table<string, number>

local RepByZone = LibStub("AceAddon-3.0"):NewAddon("RepByZone", "AceEvent-3.0", "AceConsole-3.0", "LibAboutPanel-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")

-- Local variables
---@type RepByZoneProfile
local db
local isOnTaxi
---@type table<number, number>?
local instancesAndFactions
---@type table<number, number>?
local zonesAndFactions
---@type table<string, number>?
local subZonesAndFactions

local A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
local H = UnitFactionGroup("player") == "Horde" and HORDE
local CURRENT_DB_VERSION = 1
local TORGHAST_DIFFICULTY_ID = 167
local DELVES_DIFFICULTY_ID = 208

---@param allianceFactionID number
---@param hordeFactionID number
---@return number?
local function GetFactionID(allianceFactionID, hordeFactionID)
	if A then
		return allianceFactionID
	elseif H then
		return hordeFactionID
	end
end

---@param watchedRepID number|string?
---@return number
local function GetFallbackRepID(watchedRepID)
	if type(watchedRepID) == "number" then
		return watchedRepID
	end
	return 0
end

-- Table to localize subzones that Blizzard does not provide areaIDs
---@type table<string, number?>
local citySubZonesAndFactions = {
	-- [L["Subzone"]]				= factionID, subzone names are localized so we can compare to the localized minimap text from Blizzard
	[L["A Hero's Welcome"]]			= GetFactionID(1094, 1124),		-- The Silver Covenant or The Sunreavers
	[L["Shrine of Unending Light"]]	= 932,							-- The Aldor
	[L["The Beer Garden"]]			= GetFactionID(1094, 1124),		-- The Silver Covenant or The Sunreavers
	[L["The Crimson Dawn"]]			= 1124,							-- The Sunreavers
	[L["The Filthy Animal"]]		= GetFactionID(1094, 1124),		-- The Silver Covenant or The Sunreavers
	[L["The Salty Sailor Tavern"]]	= 21,							-- Booty Bay
	[L["The Seer's Library"]]		= 934,							-- The Scryers
	[L["The Silver Blade"]]			= 1094,							-- The Silver Covenant
	[L["Tinker Town"]]				= 54,							-- Gnomeregan
}

-- Faction tabard code
---@type number?
local tabardID
---@type boolean?
local tabardStandingStatus = false

---@type table<number, number>
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
---@type number?
local bodyguardRepID

---@type table<number|string, boolean>
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

---@type table<number, number>
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

-- Get the character's racial factionID for the defaults table
-- See https://wago.tools/db2/ChrRaces for the list of raceIDs
-- Note: allied races must use factionIDs under "Alliance" or "Horde" in the reputation panel, as their true factionIDs may not be discovered until the player quests in the appropriate zones
---@type table<number, number>
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
---@return number
local function GetRacialRep()
	local _, _, playerRaceID = UnitRace("player")
	local racialRepID = player_raceIDs_to_factionIDs[playerRaceID]
	if not racialRepID then
		-- Known factionIDs in case Blizzard adds new races and the addon hasn't been updated.
		if A then
			racialRepID = 72
		elseif H then
			racialRepID = 76
		else
			racialRepID = 0
		end
	end
	return racialRepID
end

-- Covenant code
---@type table<number, number>
local covenantReps = {
	[enum.None]			= GetRacialRep(),	-- No Covenant
	[enum.Kyrian]		= 2407,			-- The Ascended
	[enum.Venthyr]		= 2413,			-- Court of Harvesters
	[enum.NightFae]		= 2422,			-- Night Fae
	[enum.Necrolord]	= 2410,			-- The Undying Army
}

-- Return a table of default SV values
---@type table
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
	---@type RepByZoneDB
	local repDB = LibStub("AceDB-3.0"):New("RepByZoneDB", defaults, true)
	self.db = repDB
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
	self:SetEnabledState(db.enabled)

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
	self.fallbackRepID = GetFallbackRepID(self.db.char.watchedRepID)

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
	tabardStandingStatus = nil
	zonesAndFactions = nil
	subZonesAndFactions = nil
	instancesAndFactions = nil
end

-- The user has reset the profile or created a new profile
function RepByZone:RefreshConfig()
	self.db.global.current_db_version = CURRENT_DB_VERSION
	db = self.db.profile
	self.fallbackRepID = GetFallbackRepID(self.db.char.watchedRepID)
	self.racialRepID = GetRacialRep()
	zonesAndFactions = self:ZoneAndFactionList()
	subZonesAndFactions = self:SubZonesAndFactionsList()
	instancesAndFactions = self:InstancesAndFactionList()
	self:CheckTaxi()
	self:GetEquippedTabard(nil, "player")
	bodyguardRepID = self:GetActiveBodyguardRepID()
	wipe(self.WoDFollowerZones)
	for index, value in pairs(db.watchWoDBodyGuards) do
		self.WoDFollowerZones[index] = value
	end
	self:GetCovenantRep()
	self:SwitchedZones()
end

function RepByZone:SlashHandler()
	LibStub("AceConfigDialog-3.0"):Open("RepByZone")
end

------------------- Event handlers starts here --------------------
-- Entering an instance
---@param _ string
---@param isInitialLogin boolean
---@param isReloadingUi boolean
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
---@return number
function RepByZone:CovenantToFactionID()
	covenantReps[enum.None] = GetRacialRep()
	local id = GetActiveCovenantID()
	return covenantReps[id] or GetRacialRep()
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
---@param event string?
---@param success boolean
function RepByZone:GetPandarenRep(event, success)
	if success then
		if event then
			self:UnregisterEvent(event)
		end
		A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
		H = UnitFactionGroup("player") == "Horde" and HORDE
		if A or H then
			-- Update data
			local watchedRepID = GetRacialRep()
			self.db.char.watchedRepID = watchedRepID
			self.racialRepID = watchedRepID
			self.fallbackRepID = GetFallbackRepID(watchedRepID)
			self.covenantRepID = self:CovenantToFactionID()
			local factionData = watchedRepID and GetFactionDataByID(watchedRepID)
			local factionName = factionData and factionData.name or UNKNOWN
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
---@return number?
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

---@param _ string?
---@param unit string
function RepByZone:GetEquippedTabard(_, unit)
	if unit ~= "player" then return end

	local newItemID = GetInventoryItemID(unit, INVSLOT_TABARD)
	local newFactionID = newItemID and tabard_itemIDs_to_factionIDs[newItemID]
	local factionData = newFactionID and GetFactionDataByID(newFactionID)

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
---@type table<string, boolean>
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

---@return table<number|string, string>
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
---@param event string?
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
	local _, instanceType, difficultyID, _, _, _, _, whichInstanceID = GetInstanceInfo()
	local inInstance = instanceType ~= "none" and difficultyID ~= 0
	local difficultyFactionID
	local mapInfo = GetMapInfo(uiMapID)
	local parentMapID = mapInfo and mapInfo.parentMapID
	local subZone = GetMinimapZoneText()
	local isWoDZone = self.WoDFollowerZones[uiMapID] or (parentMapID and self.WoDFollowerZones[uiMapID] == nil and self.WoDFollowerZones[parentMapID])

	if difficultyID == TORGHAST_DIFFICULTY_ID then
		difficultyFactionID = self.covenantRepID
	elseif difficultyID == DELVES_DIFFICULTY_ID then
		difficultyFactionID = GetDelvesFactionForSeason()
	end

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
	if whichInstanceID and self.tabardExemptDungeons and self.tabardExemptDungeons[whichInstanceID] then
		-- every 5-person dungeon from Shadowlands+ does not support faction tabards
		hasDungeonTabard = false
	end

	-- Process subzones
	if db.watchSubZones then
		lookUpSubZones = true
		-- Stromgarde Keep and The Battle for Stromgarde are the only instances with subzones which are different than the main instance data
		if inInstance and whichInstanceID ~= 1155 and whichInstanceID ~= 1804 then
			lookUpSubZones = false
		end

		-- Don't loop through subzones if the player is watching a bodyguard rep
		if isWoDZone and bodyguardRepID then
			lookUpSubZones = false
		end
	end

	watchedFactionID = watchedFactionID
	or (inInstance and hasDungeonTabard and tabardID)
	or (inInstance and difficultyFactionID)
	or (lookUpSubZones and (citySubZonesAndFactions[subZone] or subZonesAndFactions[subZone]))
	or (inInstance and instancesAndFactions[whichInstanceID])
	or (not lookUpSubZones and isWoDZone and bodyguardRepID)
	or (not inInstance and (zonesAndFactions[uiMapID] or (parentMapID and zonesAndFactions[parentMapID])))
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