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
local UnitAffectingCombat = UnitAffectingCombat
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
local _, playerRace = UnitRace("player")

-- Table to localize subzones that Blizzard does not provide areaIDs
local citySubZonesAndFactions = {
	-- [L["Subzone"]]               = factionID, subzone names are localized so we can compare to the localized minimap text from Blizzard
    [L["A Hero's Welcome"]]         = A and 1094 or H and 1124, -- The Silver Covenant or The Sunreavers
    [L["Shrine of Unending Light"]] = 932,      -- The Aldor
    [L["The Beer Garden"]]          = A and 1094 or H and 1124, -- The Silver Covenant or The Sunreavers
    [L["The Crimson Dawn"]]         = 1124,     -- The Sunreavers
    [L["The Filthy Animal"]]        = A and 1094 or H and 1124, -- The Silver Covenant or The Sunreavers
    [L["The Roasted Ram"]]          = 2510,     -- Valdrakken Accord
    [L["The Salty Sailor Tavern"]]  = 21,       -- Booty Bay
    [L["The Seer's Library"]]       = 934,      -- The Scryers
    [L["The Silver Blade"]]         = 1094,     -- The Silver Covenant
	[L["Tinker Town"]]              = 54,       -- Gnomeregan
}

-- Faction tabard code
local tabardID, tabardStandingStatus = nil, false
local tabard_itemIDs_to_factionIDs = {
    -- [itemID] = factionID
    -- Alliance
    [45574]     = 72,       -- Stormwind City
    [45577]     = 47,       -- Ironforge
    [45578]     = 54,       -- Gnomeregan
    [45579]     = 69,       -- Darnassus
    [45580]     = 930,      -- Exodar
    [64882]     = 1134,     -- Gilneas
    [83079]     = 1353,     -- Tushui Pandaren

    -- Horde
    [45581]     = 76,       -- Orgrimmar
    [45582]     = 530,      -- Darkspear Trolls
    [45583]     = 68,       -- Undercity
    [45584]     = 81,       -- Thunder Bluff
    [45585]     = 911,      -- Silvermoon City
    [64884]     = 1133,     -- Bilgewater Cartel
    [83080]     = 1352,     -- Huojin Pandaren
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
    ["BloodElf"]            = 911,      -- Silvermoon City
    ["Draenei"]             = 930,      -- Exodar
    ["Goblin"]              = 1133,     -- Bilgewater Cartel
    ["Worgen"]              = 1134,     -- Gilneas
    ["Pandaren"]            = A and 1353 or H and 1352 or 1216, -- Tushui Pandaren or Huojin Pandaren or Shang Xi's Academy
}

-- Return a table of default SV values
local defaults = {
    profile = {
        enabled                 = true,
        ignoreExaltedTabards    = true,
        useFactionTabards       = true,
        verbose                 = true,
        watchOnTaxi             = true,
        watchSubZones           = true,
    },
    char = {
        watchedRepID            = nil,
        watchedRepName          = nil
    },
    global = {
        delayGetFactionDataByID = 0.25,
    }
}

-- Ace3 code
function RepByZone:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("RepByZoneDB", defaults, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    -- reset the AceDB-3.0 DB on the first run, as we migrated from character profiles to the Default profile
    if not self.db.global.initialized then
        self.db:RegisterDefaults(defaults)
        self.db:ResetDB(DEFAULT)
        self.db.global.initialized = true
    end
    db = self.db

    self:SetEnabledState(db.profile.enabled)

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

    -- We are either logging into the game or we are zoning into an instance
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function RepByZone:OnEnable()
    -- All events that deal with entering a new zone or subzone are handled with the same function
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "SwitchedZones")
    if db.profile.watchSubZones then
        self:RegisterEvent("ZONE_CHANGED", "SwitchedZones")
        self:RegisterEvent("ZONE_CHANGED_INDOORS", "SwitchedZones")
    end

    -- If the player loses or gains control of the character, it is one of the signs of taxi use
    self:RegisterEvent("PLAYER_CONTROL_LOST", "CheckTaxi")
    self:RegisterEvent("PLAYER_CONTROL_GAINED", "CheckTaxi")

    -- Pandaren do not start Alliance or Horde
    if IsPlayerNeutral() then
        self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT", "GetPandarenRep")
    end

    -- Check Sholazar Basin and Wrathion/Sabellian factions
    self:RegisterEvent("UPDATE_FACTION", "GetMultiRepIDsForZones")

    -- Check if a faction tabard is equipped or changed
    self:RegisterEvent("UNIT_INVENTORY_CHANGED", "GetEquippedTabard")
end

function RepByZone:OnDisable()
    -- Stop watching most events if RBZ is disabled
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("ZONE_CHANGED")
    self:UnregisterEvent("ZONE_CHANGED_INDOORS")
    self:UnregisterEvent("PLAYER_CONTROL_LOST")
    self:UnregisterEvent("PLAYER_CONTROL_GAINED")
    self:UnregisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
    self:UnregisterEvent("UPDATE_FACTION")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end

function RepByZone:SlashHandler()
    -- Exit if player is in combat, otherwise, open the settings panel
    if UnitAffectingCombat("player") then return end

    Settings.OpenToCategory("RepByZone")
end

-- The user has reset the profile or created a new profile
function RepByZone:RefreshConfig(callback)
    if callback == "OnProfileReset" then
        self.db:ResetDB(DEFAULT)
        self.db.global.initialized = true
    end
    self:PLAYER_ENTERING_WORLD(_, true) -- Force an update of the saved variables
end

-- Initialize tables and variables, or reset them if the user resets the profile
function RepByZone:SetUpVariables()
    -- Initialize or verify part of the database
    local defaultRepID, defaultRepName = self:GetRacialRep()
    self.db.char.watchedRepID = self.db.char.watchedRepID or defaultRepID
    self.db.char.watchedRepName = self.db.char.watchedRepName or defaultRepName
    self.racialRepID = defaultRepID -- Store the racial factionID for later use

    -- Populate variables, some of which update the faction lists and call RepByZone:SwitchedZones()
    self:CheckTaxi()
    self:GetEquippedTabard(_, "player")

    if not IsPlayerNeutral() then
        -- Alliance or Horde characters cannot use Shang Xi's Academy, and we missed updating them
        if self.db.char.watchedRepID == 1216 then
            self:GetPandarenRep("NEUTRAL_FACTION_SELECT_RESULT", true)
        end
    end

    -- no need to calculate the fallback reputation unless the user changes the setting
    self.fallbackRepID = type(self.db.char.watchedRepID) == "number" and self.db.char.watchedRepID or 0
end

------------------- Event handlers starts here --------------------
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
            self.db.char.watchedRepID, self.db.char.watchedRepName = self:GetRacialRep()
            db = self.db -- Update the local db variable to the current profile
            -- Update the faction lists
            zonesAndFactions = self:ZoneAndFactionList()
            self:Print(L["You have joined the %s, switching watched saved variable to %s."]:format(A or H, db.char.watchedRepName))
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

-- Entering an instance or logging in, set up variables
function RepByZone:PLAYER_ENTERING_WORLD(_, isInitialLogin, isReloadingUi)
    if isInitialLogin then
        self:SetUpVariables()
        db = self.db -- Update the local db variable to the current profile
    end

    if not db.profile.enabled then
        return -- Exit if the addon is disabled
    end

    -- If the player is reloading the UI, we don't want to switch zones
    if isReloadingUi then
        return
    end

    After(1, function() self:SwitchedZones() end)
end

-- Player switched zones, subzones, or instances, set watched faction
function RepByZone:SwitchedZones()
    if not db.profile.enabled then return end -- Exit if the addon is disabled

    -- Possible zoning issues, exit out unless we have valid map data
    local uiMapID = GetBestMapForUnit("player")
    if not uiMapID then return end

    if isOnTaxi then
        if not db.profile.watchOnTaxi then
            -- On taxi but don't switch
            return
        end
    end

    -- Some data may not be available because of the specialty zone functions, get something until a full data update refreshes things
    instancesAndFactions = instancesAndFactions or self:InstancesAndFactionList()
    zonesAndFactions = zonesAndFactions or self:ZoneAndFactionList()
    subZonesAndFactions = subZonesAndFactions or self:SubZonesAndFactionsList()

    -- Set up variables
    local _, watchedFactionID, factionName, isWatched = nil, nil, nil, nil
    local hasDungeonTabard, lookUpSubZones = false, false
    local inInstance, instanceType = IsInInstance()
    local whichInstanceID = inInstance and select(8, GetInstanceInfo())
    local parentMapID = GetMapInfo(uiMapID).parentMapID
    local subZone = GetMinimapZoneText()

    -- Apply instance reputations. Garrisons return false for inInstance and "party" for instanceType, which is good, we can filter them out
    if inInstance and instanceType == "party" then
        hasDungeonTabard = false
        lookUpSubZones = false
        -- Process faction tabards
        if db.profile.useFactionTabards then
            if tabardID then
                hasDungeonTabard = true
            end

            if db.profile.ignoreExaltedTabards then
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
    if db.profile.watchSubZones then
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
    After(db.global.delayGetFactionDataByID, function()
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
                if db.profile.verbose then
                    self:Print(L["Now watching %s"]:format(factionName))
                end
            end
        else
            -- There is no factionID to watch based on the databases and the user set the default watched factionID to "0-none"
            SetWatchedFactionIndex(0)
        end
    end)
end