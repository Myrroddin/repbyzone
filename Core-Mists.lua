---@diagnostic disable: duplicate-set-field, undefined-global, undefined-field
-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local After = C_Timer.After
local ALLIANCE = FACTION_ALLIANCE
local CollapseFactionHeader = CollapseFactionHeader
local ExpandFactionHeader = ExpandFactionHeader
local FACTION_INACTIVE = FACTION_INACTIVE
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetFactionInfo = GetFactionInfo
local GetFactionInfoByID = GetFactionInfoByID
local GetInstanceInfo = GetInstanceInfo
local GetInventoryItemID = GetInventoryItemID
local GetMapInfo = C_Map.GetMapInfo
local GetMinimapZoneText = GetMinimapZoneText
local GetNumFactions = GetNumFactions
local HORDE = FACTION_HORDE
local INVSLOT_TABARD = INVSLOT_TABARD
local IsInInstance = IsInInstance
local IsPlayerNeutral = IsPlayerNeutral
local LibStub = LibStub
local NONE = NONE
local select = select
local SetWatchedFactionIndex = SetWatchedFactionIndex
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
local _, _, playerRaceID = UnitRace("player")
local CURRENT_DB_VERSION = 1

-- Table to localize subzones that Blizzard does not provide areaIDs
local citySubZonesAndFactions = {
	-- [L["Subzone"]]				= factionID, subzone names are localized so we can compare to the localized minimap text from Blizzard
	[L["A Hero's Welcome"]]			= A and 1094 or H and 1124,	-- The Silver Covenant or The Sunreavers
	[L["Shrine of Unending Light"]]	= 932,						-- The Aldor
	[L["The Beer Garden"]]			= A and 1094 or H and 1124,	-- The Silver Covenant or The Sunreavers
	[L["The Crimson Dawn"]]			= 1124,						-- The Sunreavers
	[L["The Filthy Animal"]]		= A and 1094 or H and 1124,	-- The Silver Covenant or The Sunreavers
	[L["The Salty Sailor Tavern"]]	= 21,						-- Booty Bay
	[L["The Seer's Library"]]		= 934,						-- The Scryers
	[L["The Silver Blade"]]			= 1094,						-- The Silver Covenant
	[L["Tinker Town"]]				= 54,						-- Gnomeregan
}

-- Faction tabard code
local tabardID, tabardStandingStatus = nil, false
local tabard_itemIDs_to_factionIDs = {
	-- [itemID] = factionID
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

-- Get the character's racial factionID for the defaults table
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
	[25]	= 1352,		-- Pandaren (Alliance)/Huojin Pandaren
	[26]	= 1352,		-- Pandaren (Horde)/Huojin Pandaren
}
local function GetRacialRep()
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
	end

	-- Check Sholazar Basin factions
	self:RegisterEvent("UPDATE_FACTION", "GetMultiRepIDsForZones")

	-- Check if a faction tabard is equipped or changed
	self:RegisterEvent("UNIT_INVENTORY_CHANGED", "GetEquippedTabard")

	-- Is the player on a taxi?
	self:CheckTaxi()

	-- Calculate the fallback reputation
	self.fallbackRepID = (type(self.db.char.watchedRepID) == "number" and self.db.char.watchedRepID) or 0

	-- For certain Mists instanced content
	self.racialRepID = GetRacialRep()

	self:SwitchedZones()
end

function RepByZone:OnDisable()
	-- Stop watching events if RBZ is disabled
	self:UnregisterAllEvents()

	-- Shrink memory footprint by wiping variables
	isOnTaxi = nil
	self.fallbackRepID = nil
	self.racialRepID = nil
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
	self.fallbackRepID = (type(self.db.char.watchedRepID) == "number" and self.db.char.watchedRepID) or 0
	self:CheckTaxi()
	db = self.db.profile
end

------------------- Event handlers starts here --------------------
----- Entering an instance
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

-- Pandaren code
function RepByZone:GetPandarenRep(event, success)
	if success then
		A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
		H = UnitFactionGroup("player") == "Horde" and HORDE
		if A or H then
			-- Update data
			self:UnregisterEvent(event)
			self.db.char.watchedRepID = GetRacialRep()
			self.fallbackRepID = (type(self.db.char.watchedRepID) == "number" and self.db.char.watchedRepID) or 0
			local factionName = GetFactionInfoByID(self.db.char.watchedRepID)
			-- Update the faction lists
			zonesAndFactions[378] = A and 1353 or H and 1352 or 1216 -- Update The Wandering Isle data
			self:Print(L["You have joined the %s, switching watched saved variable to %s."]:format(A or H, factionName))
			self:SwitchedZones()
		end
	end
end

function RepByZone:GetMultiRepIDsForZones()
	local uiMapID = GetBestMapForUnit("player")
	if not uiMapID then return end -- possible zoning issues, exit out unless we have valid map data
	local newtabardStandingStatus = false
	local inInstance, instanceType = IsInInstance()

	-- learn if the player is wearing a dungeon faction tabard and update if required
	if inInstance and instanceType == "party" then
		newtabardStandingStatus = tabardID and (select(3, GetFactionInfoByID(tabardID)) == MAX_REPUTATION_REACTION) or false
		if newtabardStandingStatus ~= tabardStandingStatus then
			tabardStandingStatus = newtabardStandingStatus
			self:SwitchedZones()
			return
		end
	end
end

-- Tabard code
function RepByZone:GetEquippedTabard(_, unit)
	if unit ~= "player" then return end
	local newTabardID, newTabardRep
	newTabardID = GetInventoryItemID(unit, INVSLOT_TABARD)

	if newTabardID then
		newTabardRep = tabard_itemIDs_to_factionIDs[newTabardID]
	end
	tabardStandingStatus = newTabardRep and (select(3, GetFactionInfoByID(newTabardRep)) == MAX_REPUTATION_REACTION) or false

	if newTabardRep ~= tabardID then
		tabardID = newTabardRep
		self:SwitchedZones()
	end
end

-------------------- Reputation code starts here --------------------
local repsCollapsed = {} -- Obey user's settings about headers opened or closed
-- Open all faction headers
function RepByZone:OpenAllFactionHeaders()
	local numFactions = GetNumFactions()
	local factionIndex = 1

	while factionIndex <= numFactions do
		local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(factionIndex)
		if isHeader and isCollapsed then
			if name then
				repsCollapsed[name] = repsCollapsed[name] or isCollapsed
				ExpandFactionHeader(factionIndex)
				numFactions = GetNumFactions()
			end
		end
		factionIndex = factionIndex + 1
	end
end

-- Close all faction headers
function RepByZone:CloseAllFactionHeaders()
	local numFactions = GetNumFactions()
	local factionIndex = 1

	while factionIndex <= numFactions do
		local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(factionIndex)
		if isHeader then
			if isCollapsed and not repsCollapsed[name] then
				ExpandFactionHeader(factionIndex)
				numFactions = GetNumFactions()
			elseif repsCollapsed[name] and not isCollapsed then
				CollapseFactionHeader(factionIndex)
				numFactions = GetNumFactions()
			end
		end
		factionIndex = factionIndex + 1
	end
	wipe(repsCollapsed)
end

function RepByZone:GetAllFactions()
	-- Will not return factions the user has marked as inactive
	self:OpenAllFactionHeaders()
	local factionList = {}

	for factionIndex = 1, GetNumFactions() do
		local name, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionID = GetFactionInfo(factionIndex)
		if name then
			if not isHeader and name ~= FACTION_INACTIVE then
				if factionID then
					factionList[factionID] = name
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
function RepByZone:SwitchedZones()
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

	-- Set up variables
	local _, watchedFactionID, factionName, isWatched = nil, nil, nil, nil
	local hasDungeonTabard, lookUpSubZones = false, false
	local inInstance, instanceType = IsInInstance()
	local whichInstanceID = inInstance and select(8, GetInstanceInfo())
	local parentMapID = GetMapInfo(uiMapID).parentMapID
	local subZone = GetMinimapZoneText()

	-- Apply instance reputations. Garrisons return false for inInstance and "party" for instanceType, which is good, we can filter them out
	if inInstance and instanceType == "party" then
		hasDungeonTabard	= false
		lookUpSubZones		= false
		-- Process faction tabards
		if db.useFactionTabards then
			if tabardID then
				hasDungeonTabard = true
			end

			if db.ignoreExaltedTabards then
				if tabardStandingStatus then
					hasDungeonTabard = false
				end
			end
		else
			-- We aren't watching faction tabards
			hasDungeonTabard = false
		end
	else
		-- We aren't in a party
		hasDungeonTabard = false
	end

	-- Process subzones
	if db.watchSubZones then
		lookUpSubZones = true
	end

	-- Mists of Pandaria has no subzones which are different in instances
	if inInstance then
		lookUpSubZones = false
	end

	watchedFactionID = watchedFactionID
	or (inInstance and (hasDungeonTabard and tabardID))
	or (lookUpSubZones and (citySubZonesAndFactions[subZone] or subZonesAndFactions[subZone]))
	or (inInstance and instancesAndFactions[whichInstanceID])
	or (not inInstance and (zonesAndFactions[uiMapID] or zonesAndFactions[parentMapID]))
	or self.fallbackRepID

	-- WoW has a delay whenever the player changes instance/zone/subzone/tabard; factionName and isWatched aren't available immediately, so delay the lookup, then set the watched faction on the bar
	After(self.db.global.delayGetFactionDataByID, function()
		if type(watchedFactionID) == "number" and watchedFactionID > 0 then
			-- We have a factionID to watch either from the databases or the default watched factionID is a number greater than or equal to 1
			factionName, _, _, _, _, _, _, _, _, _, _, isWatched = GetFactionInfoByID(watchedFactionID)
			if factionName and not isWatched then
				self:OpenAllFactionHeaders() -- Open all headers to ensure the watched faction is visible
				for factionIndex = 1, GetNumFactions() do
					local name, _, _, _, _, _, _, _, _, _, _, _, _, factionID = GetFactionInfo(factionIndex)
					if name and factionID == watchedFactionID then
						SetWatchedFactionIndex(factionIndex)
						break
					end
				end
				self:CloseAllFactionHeaders() -- Close all headers after setting the watched faction
				if db.verbose then
					self:Print(L["Now watching %s"]:format(factionName))
				end
			end
		else
			-- There is no factionID to watch based on the databases and the user set the default watched factionID to "0-none"
			SetWatchedFactionIndex(0)
		end
	end)
end