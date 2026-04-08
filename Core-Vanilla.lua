-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local After = C_Timer.After
local CollapseFactionHeader = CollapseFactionHeader
local ExpandFactionHeader = ExpandFactionHeader
local FACTION_INACTIVE = FACTION_INACTIVE
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetFactionInfo = GetFactionInfo
local GetFactionInfoByID = GetFactionInfoByID
local GetMapInfo = C_Map.GetMapInfo
local GetMinimapZoneText = GetMinimapZoneText
local GetNumFactions = GetNumFactions
local IsInInstance = IsInInstance
local LibStub = LibStub
local NONE = NONE
local SetWatchedFactionIndex = SetWatchedFactionIndex
local type = type
local UnitFactionGroup = UnitFactionGroup
local UnitOnTaxi = UnitOnTaxi
local UnitRace = UnitRace
local wipe = wipe

------------------- Create the addon --------------------
local RepByZone = LibStub("AceAddon-3.0"):NewAddon("RepByZone", "AceEvent-3.0", "AceConsole-3.0", "LibAboutPanel-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")

-- Local variables
local db, isOnTaxi, instancesAndFactions, zonesAndFactions, subZonesAndFactions
local A = UnitFactionGroup("player") == "Alliance"
local H = UnitFactionGroup("player") == "Horde"
local _, _, playerRaceID = UnitRace("player")
local CURRENT_DB_VERSION = 1

-- Table to localize subzones for which Blizzard does not provide areaIDs
local citySubZonesAndFactions = {
	-- [L["Subzone"]]               = factionID, subzone names are localized so we can compare to the localized minimap text from Blizzard
	[L["Dwarven District"]]         = 47,       -- Ironforge
	[L["The Salty Sailor Tavern"]]  = 21,       -- Booty Bay
	[L["Tinker Town"]]              = 54,       -- Gnomeregan Exiles
	[L["Valley of Spirits"]]        = 530,      -- Darkspear Trolls
	[L["Valley of Wisdom"]]         = 81,       -- Thunder Bluff
}

-- Get the character's racial factionID for the defaults table
local player_raceIDs_to_factionIDs = {
    -- [playerRaceID]   = factionID
    [1]     = 72,   -- Human/Stormwind
    [2]     = 76,   -- Orc/Orgrimmar
    [3]     = 47,   -- Dwarf/Ironforge
    [4]     = 69,   -- Night Elf/Darnassus
    [5]     = 68,   -- Undead (Scourge)/Undercity
    [6]     = 81,   -- Tauren/Thunder Bluff
    [7]     = 54,   -- Gnome/Gnomeregan
    [8]     = 530,  -- Troll/Darkspear Trolls
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
        enabled                 = true,
        verbose                 = true,
        watchOnTaxi             = true,
        watchSubZones           = true
    },
    char = {
        watchedRepID            = GetRacialRep()
    },
    global = {
        delayGetFactionDataByID = 0.25,
    }
}

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

    -- Add options to Blizzard's Options/AddOns
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

    -- Is the player on a taxi?
    self:CheckTaxi()

    -- Calculate the fallback reputation
    self.fallbackRepID = (type(self.db.char.watchedRepID) == "number" and self.db.char.watchedRepID) or 0

    self:SwitchedZones()
end

function RepByZone:OnDisable()
    -- Stop watching events if RBZ is disabled
    self:UnregisterAllEvents()

    -- Shrink memory footprint by wiping variables
    isOnTaxi = nil
    self.fallbackRepID = nil
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

------------------- Event handlers starts here --------------------
function RepByZone:CheckTaxi()
    isOnTaxi = UnitOnTaxi("player")
end

-- Entering an instance
function RepByZone:PLAYER_ENTERING_WORLD(_, isInitialLogin, isReloadingUi)
    -- If either of these are true, we didn't enter an instance, so exit
    if isInitialLogin or isReloadingUi then
        return
    end

    After(1, function() self:SwitchedZones() end)
end

-------------------- Watched faction code starts here --------------------
-- Player switched zones, subzones, or instances, set watched faction
function RepByZone:SwitchedZones()
    if not db.enabled then return end -- Exit if the addon is disabled

    local uiMapID = GetBestMapForUnit("player")
    if not uiMapID then return end -- Possible zoning issues, exit out unless we have valid map data

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
    local inInstance = IsInInstance()
    local whichInstanceID = inInstance and select(8, GetInstanceInfo())
    local subZone = GetMinimapZoneText()
    local parentMapID = GetMapInfo(uiMapID).parentMapID
    local lookUpSubZones = false

    -- Process subzones
    if db.watchSubZones then
        lookUpSubZones = true
    end

    -- Classic has no subzones which are different in instances
    if inInstance then
        lookUpSubZones = false
    end

    watchedFactionID = watchedFactionID
    or (lookUpSubZones and (citySubZonesAndFactions[subZone] or subZonesAndFactions[subZone]))
    or (inInstance and instancesAndFactions[whichInstanceID])
    or (not inInstance and (zonesAndFactions[uiMapID] or zonesAndFactions[parentMapID]))
    or self.fallbackRepID

    -- WoW has a delay whenever the player changes instance/zone/subzone; factionName and isWatched aren't available immediately, so delay the lookup, then set the watched faction on the bar
    After(self.db.global.delayGetFactionDataByID, function()
        if type(watchedFactionID) == "number" and watchedFactionID > 0 then
            -- We have a factionID for the instance/zone/subzone or we don't have a factionID and self.db.char.watchedRepID is a number
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
            -- There is nothing in the database and self.db.char.watchedRepID is not a number; blank the bar
            SetWatchedFactionIndex(0)
        end
    end)
end