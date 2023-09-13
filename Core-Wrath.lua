-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local _G = _G
local C_Map = _G.C_Map
local C_Reputation = _G.C_Reputation
local CollapseFactionHeader = _G.CollapseFactionHeader
local ExpandFactionHeader = _G.ExpandFactionHeader
local FACTION_INACTIVE = _G.FACTION_INACTIVE
local GetFactionInfo = _G.GetFactionInfo
local GetFactionInfoByID = _G.GetFactionInfoByID
local GetInstanceInfo = _G.GetInstanceInfo
local GetInventoryItemID = _G.GetInventoryItemID
local GetMinimapZoneText = _G.GetMinimapZoneText
local GetNumFactions = _G.GetNumFactions
local INVSLOT_TABARD = _G.INVSLOT_TABARD
local IsInInstance = _G.IsInInstance
local LibStub = _G.LibStub
local NONE = _G.NONE
local pairs = _G.pairs
local select = _G.select
local type = _G.type
local UnitAffectingCombat =_G.UnitAffectingCombat
local UnitClass = _G.UnitClass
local UnitOnTaxi = _G.UnitOnTaxi
local UnitRace = _G.UnitRace
local wipe = _G.table.wipe

------------------- Create the addon --------------------
local RepByZone = LibStub("AceAddon-3.0"):NewAddon("RepByZone", "AceEvent-3.0", "LibAboutPanel-2.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")
local Dialog = LibStub("AceConfigDialog-3.0")

-- Local variables
local db
local isOnTaxi
local instancesAndFactions
local zonesAndFactions
local subZonesAndFactions

-- Table to localize subzones that Blizzard does not provide areaIDs
local CitySubZonesAndFactions = {
	-- ["Subzone"] = factionID
	["Aldor Rise"] = 932, -- The Aldor
    ["Deeprun Tram"] = 72, -- Stormwind
	["Dwarven District"] = 47, -- Ironforge
    ["Scryer's Tier"] = 934, -- The Scryers
    ["Shrine of Unending Light"] = 932, -- The Aldor
	["The Salty Sailor Tavern"] = 21, -- Booty Bay
    ["The Seer's Library"] = 934, -- The Scryers
	["Tinker Town"] = 54, -- Gnomeregan Exiles
	["Valley of Spirits"] = 530, -- Darkspear Trolls
	["Valley of Wisdom"] = 81, -- Thunder Bluff
}

-- Faction tabard code
local tabardID
local tabard_itemIDs_to_factionIDs = {
    -- [itemID] = factionID
    -- Alliance
    [45574]     = 72,       -- Stormwind City
    [45577]     = 47,       -- Ironforge
    [45578]     = 54,       -- Gnomeregan
    [45579]     = 69,       -- Darnassus
    [45580]     = 930,      -- Exodar

    -- Horde
    [45581]     = 76,       -- Orgrimmar
    [45582]     = 530,      -- Darkspear Trolls
    [45583]     = 68,       -- Undercity
    [45584]     = 81,       -- Thunder Bluff
    [45585]     = 911,      -- Silvermoon City
}

-- Return a table of defaul SV values
local defaults = {
    profile = {
        enabled = true,
        watchSubZones = true,
        verbose = true,
        watchOnTaxi = true,
        useClassRep = true,
        useFactionTabards = true,
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

     -- Check Sholazar Basin factions
     self:RegisterEvent("UPDATE_FACTION", "GetSholazarBasinRep")

    -- Check if a faction tabard is equipped or changed
    self:RegisterEvent("UNIT_INVENTORY_CHANGED", "GetEquippedTabard")

    -- We are zoning into an instance
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "EnteringInstance")

    -- Set up variables
    self:SetUpVariables(false) -- false == this is not a new or reset profile
end

function RepByZone:OnDisable()
    -- Stop watching most events if RBZ is disabled
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("ZONE_CHANGED")
    self:UnregisterEvent("ZONE_CHANGED_INDOORS")
    self:UnregisterEvent("PLAYER_CONTROL_LOST")
    self:UnregisterEvent("PLAYER_CONTROL_GAINED")
    self:UnregisterEvent("UPDATE_FACTION")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
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
    db.watchedRepID, db.watchedRepName = nil, nil

    self:SetUpVariables(true) -- true == new or reset profile
end

-- Initialize tables and variables, or reset them if the user resets the profile
function RepByZone:SetUpVariables(newOrResetProfile)
    local defaultRepID, defaultRepName

    -- Populate variables
    isOnTaxi = UnitOnTaxi("player")
    self:GetSholazarBasinRep()
    if db.useFactionTabards then
        self:GetEquippedTabard()
    end

    -- Initialize or verify part of the database
    defaultRepID, defaultRepName = self:GetRacialRep()
    db.watchedRepID = db.watchedRepID or defaultRepID
    db.watchedRepName = db.watchedRepName or defaultRepName

    -- Populate tables
    if newOrResetProfile then
        instancesAndFactions = self:InstancesAndFactionList()
        zonesAndFactions = self:ZoneAndFactionList()
        subZonesAndFactions = self:SubZonesAndFactionsList()
    else
        instancesAndFactions = instancesAndFactions or self:InstancesAndFactionList()
        zonesAndFactions = zonesAndFactions or self:ZoneAndFactionList()
        subZonesAndFactions = subZonesAndFactions or self:SubZonesAndFactionsList()
    end

    -- Setup or reset is done, update watched reputation
    self:SwitchedZones()
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
-- Sholazar Basin has three possible zone factions, retun factionID based on player's quest progress
function RepByZone:GetSholazarBasinRep()
    local uiMapID = C_Map.GetBestMapForUnit("player")
    if not uiMapID then return end -- Possible zoning issues, exit out unless we have valid map data
    local parentMapID = C_Map.GetMapInfo(uiMapID).parentMapID

    -- If the player is not in Sholazar Basin then exit out
    if uiMapID ~= 119 or parentMapID ~= 119 then return end

    local newSholazarRepID
    local frenzyHeartStanding = select(3, GetFactionInfoByID(1104))
    local oraclesStanding = select(3, GetFactionInfoByID(1105))

    if frenzyHeartStanding <= 3 then
        newSholazarRepID = 1105 -- Frenzyheart hated, return Oracles
    elseif oraclesStanding <= 3 then
        newSholazarRepID = 1104 -- Oracles hated, return Frenzyheart
    elseif frenzyHeartStanding == 0 or oraclesStanding == 0 then
        newSholazarRepID = db.watchedRepID or self.racialRepID
    end

    if newSholazarRepID ~= self.sholazarRepID then
        self.sholazarRepID = newSholazarRepID

        -- update both zones and subzones
        zonesAndFactions = self:ZoneAndFactionList()
        subZonesAndFactions = self:SubZonesAndFactionsList()
        self:SwitchedZones()
    end
end

-- Tabard code
function RepByZone:GetEquippedTabard(_, unit)
    if unit ~= "player" then return end
    local newTabardID, newTabardRep
    newTabardID = GetInventoryItemID(unit, INVSLOT_TABARD)

    if newTabardID then
        for tabard, factionID in pairs(tabard_itemIDs_to_factionIDs) do
            if tabard == newTabardID then
                newTabardRep = factionID
                break
            end
        end
    end

    if newTabardRep ~= tabardID then
        tabardID = newTabardRep
        self:SwitchedZones()
    end
end

local repsCollapsed = {} -- Obey user's settings about headers opened or closed
-- Open all faction headers
function RepByZone:OpenAllFactionHeaders()
    local numFactions = GetNumFactions()
    local factionIndex = 1

	while factionIndex <= numFactions do
		local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(factionIndex)
		if isHeader and isCollapsed then
            repsCollapsed[name] = repsCollapsed[name] or isCollapsed
            ExpandFactionHeader(factionIndex)
            numFactions = GetNumFactions()
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
                factionList[factionID] = name
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
    -- Catch possible errors during initialization
    local useClassRep
    if self.db == nil then
        useClassRep = true
    elseif self.db.profile.useClassRep == nil then
        useClassRep = true
    else
        useClassRep = self.db.profile.useClassRep
    end
    local whichID, whichName

    local _, playerRace = UnitRace("player")
    local racialRepID = playerRace == "Dwarf" and 47 -- Ironforge
    or playerRace == "Gnome" and 54 -- Gnomeregan
    or playerRace == "Human" and 72 -- Stormwind
    or playerRace == "NightElf" and 69 -- Darnassus
    or playerRace == "Orc" and 76 -- Orgrimmar
    or playerRace == "Tauren" and 81 -- Thunder Bluff
    or playerRace == "Troll" and 530 -- Darkspear Trolls
    or playerRace == "Scourge" and 68 -- Undercity
    or playerRace == "Draenei" and 930 -- Exodar
    or playerRace == "BloodElf" and 911 -- Silvermoon City

    -- Classes have factions
    local _, classFileName = UnitClass("player")
    local classRepID = classFileName == "ROGUE" and 349 -- Ravenholdt
    or classFileName == "DRUID" and 609 -- Cenarion Circle
    or classFileName == "DEATHKNIGHT" and 1098 -- Knights of the Ebon Blade
    or classFileName == "MAGE" and 1090 -- Kirin Tor

    self:OpenAllFactionHeaders()

    -- Check if the player has discovered the race faction
    local function CheckRace()
        for i = 1, GetNumFactions() do
            local name, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionID = GetFactionInfo(i)
            if name and not isHeader then
                if factionID == racialRepID then
                    return factionID, name
                end
            end
        end
    end
    whichID, whichName = CheckRace()

    -- Check if the player has discoverd the class faction
    local function CheckClassRep()
        for i = 1, GetNumFactions() do
            local name, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionID = GetFactionInfo(i)
            if name and not isHeader then
                if factionID == classRepID then
                    return factionID, name
                end
            end
        end
    end
    if useClassRep then
        whichID, whichName = CheckClassRep()
    end

    if not whichID then
        whichID, whichName = CheckRace()
    end

    self:CloseAllFactionHeaders()

    self.racialRepID = useClassRep and classRepID or racialRepID
    self.racialRepName = type(self.racialRepID) == "number" and GetFactionInfoByID(self.racialRepID)
    if self.racialRepID == nil and whichID == nil then
        self.racialRepID, self.racialRepName = "0-none", NONE
        whichID, whichName = self.racialRepID, self.racialRepName
    end

    return whichID, whichName
end

-- Entering an instance
function RepByZone:EnteringInstance(_, ...)
    local isInitialLogin, isReloadingUI = ...

    if not isInitialLogin and not isReloadingUI then
        self:SwitchedZones()
    end
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

    -- Set up variables
    local _, watchedFactionID, factionName, isWatched
    local hasDungeonTabard = false
    local inInstance, instanceType = IsInInstance()
    local whichInstanceID = inInstance and select(8, GetInstanceInfo())
    local subZone = GetMinimapZoneText()
    local backupRepID = (db.watchedRepID == nil and self.racialRepID ~= nil) or (self.racialRepID == nil and db.watchedRepID ~= nil)

    -- Apply instance reputations
    if inInstance and instanceType == "party" then
        hasDungeonTabard = false
        if db.useFactionTabards then
            if tabardID then
                watchedFactionID = tabardID
                hasDungeonTabard = true
                -- I'm not sure why setting the watched faction here is necessary, but it doesn't work without this code
                factionName, _, _, _, _, _, _, _, _, _, _, isWatched = GetFactionInfoByID(tabardID)
                if factionName and not isWatched then
                    C_Reputation.SetWatchedFaction(tabardID)
                    if db.verbose then
                        self:Print(L["Now watching %s"]:format(factionName))
                    end
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

    -- We aren't in an instance that supports tabards or we aren't watching tabards in the dungeon
    if inInstance and not hasDungeonTabard then
        for instanceID, factionID in pairs(instancesAndFactions) do
            if instanceID == whichInstanceID then
                watchedFactionID = factionID
                -- I'm not sure why setting the watched faction here is necessary, but it doesn't work without this code
                factionName, _, _, _, _, _, _, _, _, _, _, isWatched = GetFactionInfoByID(factionID)
                if factionName and not isWatched then
                    C_Reputation.SetWatchedFaction(factionID)
                    if db.verbose then
                        self:Print(L["Now watching %s"]:format(factionName))
                    end
                end
                break
            end
        end
    end

    -- Apply world zone data
    if inInstance or watchedFactionID then
        return
    else
        for zoneID, factionID in pairs(zonesAndFactions) do
            if zoneID == uiMapID then
                watchedFactionID = factionID
                -- I'm not sure why setting the watched faction here is necessary, but it doesn't work without this code
                factionName, _, _, _, _, _, _, _, _, _, _, isWatched = GetFactionInfoByID(factionID)
                if factionName and not isWatched then
                    C_Reputation.SetWatchedFaction(factionID)
                    if db.verbose then
                        self:Print(L["Now watching %s"]:format(factionName))
                    end
                end
                break
            end
        end
    end

    if db.watchSubZones then
        -- Wrath instances do not have subzones
        if inInstance then return end

        -- Blizzard provided areaIDs
        for areaID, factionID in pairs(subZonesAndFactions) do
            if C_Map.GetAreaInfo(areaID) == subZone then
                watchedFactionID = factionID
                -- I'm not sure why setting the watched faction here is necessary, but it doesn't work without this code
                factionName, _, _, _, _, _, _, _, _, _, _, isWatched = GetFactionInfoByID(factionID)
                if factionName and not isWatched then
                    C_Reputation.SetWatchedFaction(factionID)
                    if db.verbose then
                        self:Print(L["Now watching %s"]:format(factionName))
                    end
                end
                break
            end
        end
        -- Our localized missing Blizzard areaIDs
        for areaName, factionID in pairs(CitySubZonesAndFactions) do
            if L[areaName] == subZone then
                watchedFactionID = factionID
                -- I'm not sure why setting the watched faction here is necessary, but it doesn't work without this code
                factionName, _, _, _, _, _, _, _, _, _, _, isWatched = GetFactionInfoByID(factionID)
                if factionName and not isWatched then
                    C_Reputation.SetWatchedFaction(factionID)
                    if db.verbose then
                        self:Print(L["Now watching %s"]:format(factionName))
                    end
                end
                break
            end
        end
    end

    -- Set the watched reputation to backupRepID
    if type(watchedFactionID) ~= "number" then
        if type(backupRepID) == "number" then
            factionName, _, _, _, _, _, _, _, _, _, _, isWatched = GetFactionInfoByID(backupRepID)
            if factionName and not isWatched then
                C_Reputation.SetWatchedFaction(backupRepID)
                if db.verbose then
                    self:Print(L["Now watching %s"]:format(factionName))
                end
            end
        else
            -- There is no faction to watch, clear the reputation bar
            C_Reputation.SetWatchedFaction(0)
        end
    end
end