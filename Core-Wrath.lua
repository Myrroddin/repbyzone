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
local faction_tabard_auraIDs = {
    -- [auraID] = {factionID}
    -- Alliance
    [93795]     = {72},     -- Stormwind City
    [93805]     = {47},     -- Ironforge
    [93821]     = {54},     -- Gnomeregan
    [93806]     = {69},     -- Darnassus
    [93811]     = {930},    -- Exodar

    -- Horde
    [93825]     = {76},     -- Orgrimmar
    [93827]     = {530},    -- Darkspear
    [94462]     = {68},     -- Undercity
    [94463]     = {81},     -- Thunder Bluff
    [93828]     = {911},    -- Silvermoon City
}

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

    local defaultRepID, defaultRepName = self:GetRacialRep()
    db.watchedRepID = db.watchedRepID or defaultRepID
    db.watchedRepName = db.watchedRepName or defaultRepName

    -- If player is in combat, close options panel and exit out of command line
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat") -- This event should not be unregistered if RBZ is disabled
end

function RepByZone:OnEnable()
    -- Populate variables
    isOnTaxi = UnitOnTaxi("player")
    self:GetRacialRep()
    self:GetSholazarBasinRep()
    self:GetTabardID()

    -- Cache instance, zone, and subzone data; factionIDs may not be available earlier in OnInitialize()?
    instancesAndFactions = instancesAndFactions or self:InstancesAndFactionList()
    zonesAndFactions = zonesAndFactions or self:ZoneAndFactionList()
    subZonesAndFactions = subZonesAndFactions or self:SubZonesAndFactionsList()

    -- All events that deal with entering a new zone or subzone are handled with the same function
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "SwitchedZones")
    self:RegisterEvent("ZONE_CHANGED", "SwitchedZones")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "SwitchedZones")

    -- If player is in combat, close options panel and exit out of command line
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat") -- This event should not be unregistered if RBZ is disabled

    -- If the player loses or gains control of the character, it is one of the signs of taxi use
    self:RegisterEvent("PLAYER_CONTROL_LOST", "CheckTaxi")
    self:RegisterEvent("PLAYER_CONTROL_GAINED", "CheckTaxi")

     -- Check Sholazar Basin factions
     self:RegisterEvent("UPDATE_FACTION", "GetSholazarBasinRep")

    -- Set watched faction when the player first loads into the game
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "LoginReload")

    -- Check if a faction tabard is equipped or changed
    self:RegisterEvent("UNIT_INVENTORY_CHANGED", "GetTabardID")
    self:RegisterEvent("UNIT_AURA", "GetTabardBuffData")
end

function RepByZone:OnDisable()
    -- Stop watching most events if RBZ is disabled
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("ZONE_CHANGED")
    self:UnregisterEvent("ZONE_CHANGED_INDOORS")
    self:UnregisterEvent("PLAYER_CONTROL_LOST")
    self:UnregisterEvent("PLAYER_CONTROL_GAINED")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:UnregisterEvent("UPDATE_FACTION")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
    self:UnregisterEvent("UNIT_AURA")

    -- Wipe variables when RBZ is disabled
    isOnTaxi = nil
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

-- The user has reset the DB, or created a new one
function RepByZone:RefreshConfig(event, database, ...)
    db = self.db.profile
    db.watchedRepID, db.watchedRepName = self:GetRacialRep()
    self.racialRepID, self.racialRepName = self:GetRacialRep()

    -- update both zones and subzones
    instancesAndFactions = self:InstancesAndFactionList()
    zonesAndFactions = self:ZoneAndFactionList()
    subZonesAndFactions = self:SubZonesAndFactionsList()
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

function RepByZone:LoginReload(event, isInitialLogin, isReloadingUi)
    self:GetRacialRep()
    self:GetSholazarBasinRep()
    self:GetTabardID()

    instancesAndFactions = instancesAndFactions or self:InstancesAndFactionList()
    zonesAndFactions = zonesAndFactions or self:ZoneAndFactionList()
    subZonesAndFactions = subZonesAndFactions or self:SubZonesAndFactionsList()

    self:SwitchedZones()
end

-------------------- Reputation code starts here --------------------
-- Sholazar Basin has three possible zone factions, retun factionID based on player's quest progress
function RepByZone:GetSholazarBasinRep()
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
function RepByZone:GetTabardID(event, unit)
    if unit == "player" then
        local newID = GetInventoryItemID(unit, INVSLOT_TABARD)
        if newID ~= tabardID then
            tabardID = newID
            self:SwitchedZones()
        end
    end
end

function RepByZone:GetTabardBuffData()
    if not db.useFactionTabards then
        return nil
    end

    local buffID = select(10, UnitAura("player"))
    local factionID
    local data = faction_tabard_auraIDs[buffID]
    if data then
        factionID = data[1] -- TODO: verify which dungeons can benefit from tabards
        return factionID
    end

    return nil
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
-- Player switched zones, subzones, or instances, set watched faction
function RepByZone:SwitchedZones()
    local uiMapID = C_Map.GetBestMapForUnit("player")
    if not uiMapID then return end -- Possible zoning issues, exit out unless we have valid map data

    if isOnTaxi then
        if not db.watchOnTaxi then
            -- On taxi but don't switch
            return
        end
    end

    local watchedFactionID, hasTabard
    local inInstance = IsInInstance() and select(8, GetInstanceInfo())
    local _, isDungeon = GetInstanceInfo()
    local subZone = GetMinimapZoneText()
    local factionName, isWatched
    local backupRepID = (db.watchedRepID == nil and self.racialRepID ~= nil) or (self.racialRepID == nil and db.watchedRepID ~= nil)

    if inInstance and isDungeon == "party" then
        watchedFactionID = self:GetTabardBuffData()
        hasTabard = watchedFactionID
    end

    -- Apply instance data
    if inInstance then
        if hasTabard then
            return
        else
            -- Player is not wearing a tabard or is not in a 5 person dungeon
            for instanceID, factionID in pairs(instancesAndFactions) do
                if instanceID == inInstance then
                    watchedFactionID = factionID
                    break
                end
            end
        end
    end

    -- Apply world zone data
    if inInstance then
        return
    else
        for zoneID, factionID in pairs(zonesAndFactions) do
            if zoneID == uiMapID then
                watchedFactionID = factionID
                break
            end
        end
    end

    if db.watchSubZones then
        -- Check if the player has a tabard in a dungeon; if yes, don't loop through subzone data
        if hasTabard then return end

        -- Blizzard provided areaIDs
        for areaID, factionID in pairs(subZonesAndFactions) do
            if C_Map.GetAreaInfo(areaID) == subZone then
                watchedFactionID = factionID
                break
            end
        end
        -- Our localized missing Blizzard areaIDs
        for areaName, factionID in pairs(CitySubZonesAndFactions) do
            if L[areaName] == subZone then
                watchedFactionID = factionID
                break
            end
        end
    end

    watchedFactionID = watchedFactionID or backupRepID

    -- Set the watched factionID
    if type(watchedFactionID) == "number" then
        factionName, _, _, _, _, _, _, _, _, _, _, isWatched = GetFactionInfoByID(watchedFactionID)

        if factionName and not isWatched then
            C_Reputation.SetWatchedFaction(watchedFactionID)
            if db.verbose then
                self:Print(L["Now watching %s"]:format(factionName))
            end
        end
    elseif type(watchedFactionID) ~= "number" then
        C_Reputation.SetWatchedFaction(0) -- Clear watched faction
    end
end