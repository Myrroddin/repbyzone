-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local C_Map = C_Map
local C_Reputation = C_Reputation
local CollapseFactionHeader = CollapseFactionHeader
local ExpandFactionHeader = ExpandFactionHeader
local FACTION_INACTIVE = FACTION_INACTIVE
local GetFactionInfo = GetFactionInfo
local GetFactionInfoByID = GetFactionInfoByID
local GetMinimapZoneText = GetMinimapZoneText
local GetNumFactions = GetNumFactions
local IsInInstance = IsInInstance
local LibStub = LibStub
local NONE = NONE
local type = type
local UnitAffectingCombat = UnitAffectingCombat
local UnitFactionGroup = UnitFactionGroup
local UnitOnTaxi = UnitOnTaxi
local UnitRace = UnitRace
local wipe = wipe

------------------- Create the addon --------------------
local RepByZone = LibStub("AceAddon-3.0"):NewAddon("RepByZone", "AceEvent-3.0", "LibAboutPanel-2.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")
local Dialog = LibStub("AceConfigDialog-3.0")

-- Local variables
local db, isOnTaxi, instancesAndFactions, zonesAndFactions, subZonesAndFactions
local A = UnitFactionGroup("player") == "Alliance"
local H = UnitFactionGroup("player") == "Horde"
local _, playerRace = UnitRace("player")

-- Table to localize subzones that Blizzard does not provide areaIDs
local citySubZonesAndFactions = {
	-- [L["Subzone"]]               = factionID, subzone names are localized so we can compare to the localized minimap text from Blizzard
	[L["Dwarven District"]]         = 47,       -- Ironforge
	[L["The Salty Sailor Tavern"]]  = 21,       -- Booty Bay
	[L["Tinker Town"]]              = 54,       -- Gnomeregan Exiles
	[L["Valley of Spirits"]]        = 530,      -- Darkspear Trolls
	[L["Valley of Wisdom"]]         = 81,       -- Thunder Bluff
}

-- Blizzard adds new player races, assign factionIDs on the "basic" factions that are available for new characters
local player_races_to_factionIDs = {
    --["playerRaceFile"]    = factionID
    ["Dwarf"]               = 47,       -- Ironforge
    ["Gnome"]               = 54,       -- Gnomeregan
    ["Human"]               = 72,       -- Stormwind
    ["NightElf"]            = 69,       -- Darnassus
    ["Orc"]                 = 76,       -- Orgrimmar
    ["Scourge"]             = 68,       -- Undercity
    ["Tauren"]              = 81,       -- Thunder Bluff
    ["Troll"]               = 530,      -- Darkspear Trolls
}

-- Return a table of defaul SV values
local defaults = {
    profile = {
        delayGetFactionInfoByID = 0.25,
        enabled                 = true,
        verbose                 = true,
        watchOnTaxi             = true,
        watchSubZones           = true,
        watchedRepID            = nil,
        watchedRepName          = nil
    }
}

function RepByZone:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("RepByZoneDB", defaults)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
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
    self.optionsFrame = Dialog:AddToBlizOptions("RepByZone", "RepByZone")

    -- Create slash commands
    self:RegisterChatCommand("repbyzone", "SlashHandler")
    self:RegisterChatCommand("rbz", "SlashHandler")

    -- These events never get unregistered
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat")

    -- Set up variables
    self:SetUpVariables(false) -- false == this is not a new or reset profile
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
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "EnteringInstance")
end

function RepByZone:OnDisable()
    -- Stop watching most events if RBZ is disabled
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("ZONE_CHANGED")
    self:UnregisterEvent("ZONE_CHANGED_INDOORS")
    self:UnregisterEvent("PLAYER_CONTROL_LOST")
    self:UnregisterEvent("PLAYER_CONTROL_GAINED")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function RepByZone:SlashHandler()
    -- Check if player is in combat, exit out and close options panels if that's the case
    local isInCombat = self:InCombat()
    if isInCombat then return end

    -- Close option panel if opened, otherwise open option panel
    if Dialog.OpenFrames["RepByZone"] then
        Dialog:Close("RepByZone")
    else
        Dialog:Open("RepByZone")
    end
end

-- The user has reset the DB or created a new profile
function RepByZone:RefreshConfig()
    db = self.db.profile
    self:SetUpVariables(true) -- true == new or reset profile
end

-- Initialize tables and variables, or reset them if the user resets the profile
function RepByZone:SetUpVariables(newOrResetProfile)
    -- Initialize or verify part of the database
    local defaultRepID, defaultRepName = self:GetRacialRep()
    db.watchedRepID = db.watchedRepID or defaultRepID
    db.watchedRepName = db.watchedRepName or defaultRepName

    -- Populate variables, some of which update the faction lists and call RepByZone:SwitchedZones()
    self:CheckTaxi()

    -- The profile was reset by the user, refresh db.watchedRepID and db.watchedRepName
    if newOrResetProfile then
        db.watchedRepID, db.watchedRepName = defaultRepID, defaultRepName
    end
end

------------------- Event handlers starts here --------------------
function RepByZone:InCombat()
    if UnitAffectingCombat("player") then
        if Dialog.OpenFrames["RepByZone"] then
            Dialog:Close("RepByZone")
        end
        return true
    end
    return false
end

------------------- Event handlers starts here --------------------
function RepByZone:InCombat()
    if UnitAffectingCombat("player") then
        if Dialog.OpenFrames["RepByZone"] then
            Dialog:Close("RepByZone")
        end
        return true
    end
    return false
end

function RepByZone:CheckTaxi()
    isOnTaxi = UnitOnTaxi("player")
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
-- Get the character's racial factionID and factionName
function RepByZone:GetRacialRep()
    local racialRepID, racialRepName
    racialRepID = player_races_to_factionIDs[playerRace]
    if not racialRepID then
        racialRepID = A and 72 or H and 76 -- Known factionIDs in case Blizzard adds new races and the addon hasn't been updated
    end
    racialRepName = GetFactionInfoByID(racialRepID)
    return racialRepID, racialRepName
end

-- Entering an instance
function RepByZone:EnteringInstance()
    self:SwitchedZones()
end

-- Player switched zones, subzones, or instances, set watched faction
function RepByZone:SwitchedZones()
    if not db.enabled then return end -- Exit if the addon is disabled

    local uiMapID = C_Map.GetBestMapForUnit("player")
    if not uiMapID then return end -- Possible zoning issues, exit out unless we have valid map data

    if isOnTaxi then
        if not db.watchOnTaxi then
            -- On taxi but don't switch
            return
        end
    end

    -- Some data may not be available because of the specialty zone functions, get something until a full data update refreshes things
    instancesAndFactions = instancesAndFactions or self:InstancesAndFactionList()
    zonesAndFactions = zonesAndFactions or self:ZoneAndFactionList()
    subZonesAndFactions = subZonesAndFactions or self:SubZonesAndFactionsList()

    -- Set up variables
    local _, watchedFactionID, factionName, isWatched
    local inInstance = IsInInstance()
    local whichInstanceID = inInstance and select(8, GetInstanceInfo())
    local subZone = GetMinimapZoneText()
    local lookUpSubZones = false

    -- Apply instance data
    if inInstance then
        lookUpSubZones = false
    end

    -- Process subzones
    if db.watchSubZones then
        lookUpSubZones = true
        -- Classic has no subzones that are different in instances
        if inInstance then
            lookUpSubZones = false
        end
    end

    watchedFactionID = type(db.watchedRepID) == "number" and db.watchedRepID or 0
    watchedFactionID = not lookUpSubZones and (inInstance and instancesAndFactions[whichInstanceID])
    or (lookUpSubZones and citySubZonesAndFactions[subZone] or subZonesAndFactions[subZone])
    or (not inInstance and zonesAndFactions[uiMapID])

    -- WoW has a delay whenever the player changes instance/zone/subzone/tabard; factionName and isWatched aren't available immediately, so delay the lookup, then set the watched faction on the bar
    C_Timer.After(db.delayGetFactionInfoByID, function()
        if type(watchedFactionID) == "number" and watchedFactionID > 0 then
            -- We have a factionID for the instance/zone/subzone/tabard or we don't have a factionID and db.watchedRepID is a number
            factionName, _, _, _, _, _, _, _, _, _, _, isWatched = GetFactionInfoByID(watchedFactionID)
            if factionName and not isWatched then
                C_Reputation.SetWatchedFaction(watchedFactionID)
                if db.verbose then
                    self:Print(L["Now watching %s"]:format(factionName))
                end
            end
        else
            -- There is nothing in the database and db.watchedRepID == "0-none"; blank the bar
            C_Reputation.SetWatchedFaction(0)
        end
    end)
end