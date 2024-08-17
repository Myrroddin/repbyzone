---@diagnostic disable: duplicate-set-field, undefined-global, undefined-field
-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local After = C_Timer.After
local ALLIANCE = FACTION_ALLIANCE
local CollapseFactionHeader = C_Reputation.CollapseFactionHeader
local enum = Enum.CovenantType
local ExpandFactionHeader = C_Reputation.ExpandFactionHeader
local FACTION_INACTIVE = FACTION_INACTIVE
local GetActiveCovenantID = C_Covenants.GetActiveCovenantID
local GetAreaInfo = C_Map.GetAreaInfo
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetFactionDataByIndex = C_Reputation.GetFactionDataByIndex
local GetFactionDataByID = C_Reputation.GetFactionDataByID
local GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation
local GetFriendshipReputationRanks = C_GossipInfo.GetFriendshipReputationRanks
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

-- WoD garrison bodyguard code
local bodyguardRepID

RepByZone.WoDFollowerZones = {
    [525]       = true,     -- Frostfire Ridge
    [534]       = true,     -- Tanaan Jungle
    [535]       = true,     -- Talador
    [539]       = true,     -- Shadowmoon Valley
    [542]       = true,     -- Spires of Arak
    [543]       = true,     -- Gorgrond
    [550]       = true,     -- Nagrand
    [582]       = true,     -- Lunarfall
    [590]       = true,     -- Frostwall
}

local bodyguard_quests = {
    -- [questID] = factionID
    [36877]     = 1736,     -- Tormmok
    [36898]     = 1733,     -- Delvar Ironfist
    [36899]     = 1738,     -- Defender Illona
    [36900]     = 1737,     -- Talonpriest Ishaal
    [36901]     = 1739,     -- Vivianne
    [36902]     = 1740,     -- Aeda Brightdawn
    [36936]     = 1741,     -- Leorajh
}

-- Covenant code
local covenantReps = {
    [enum.Kyrian]       = 2407,     -- The Ascended
    [enum.Venthyr]      = 2413,     -- Court of Harvesters
    [enum.NightFae]     = 2422,     -- Night Fae
    [enum.Necrolord]    = 2410,     -- The Undying Army
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
    ["HighmountainTauren"]  = 81,       -- Thunder Bluff
    ["LightforgedDraenei"]  = 930,      -- Exodar
    ["Nightborne"]          = 911,      -- Silvermoon City
    ["VoidElf"]             = 69,       -- Darnassus
    ["DarkIronDwarf"]       = 47,       -- Ironforge
    ["KulTiran"]            = 72,       -- Stormwind
    ["MagharOrc"]           = 76,       -- Orgrimmar
    ["Mechagnome"]          = 54,       -- Gnomeregan
    ["Vulpera"]             = 76,       -- Orgrimmar
    ["ZandalariTroll"]      = 530,      -- Darkspear Trolls
    ["Dracthyr"]            = A and 524 or H and 2523,  -- Obsidian Warders or Dark Talons
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
        watchWoDBodyGuards      = {
            ["**"] = true
        }
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

    -- These events never get unregistered
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "InCombat")
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

    -- See if the player belongs to a Covenant, picks one, or changes Covenants
    self:RegisterEvent("COVENANT_CHOSEN", "GetCovenantRep")

    -- Check if a WoD garrison bodyguard is assigned
    self:RegisterEvent("CHAT_MSG_MONSTER_SAY", "UpdateActiveBodyguardRepID")
    self:RegisterEvent("GOSSIP_CLOSED", "UpdateActiveBodyguardRepID")

    -- Check Sholazar Basin and Wrathion/Sabellian factions
    self:RegisterEvent("UPDATE_FACTION", "GetMultiRepIDsForZones")

    -- Check if a faction tabard is equipped or changed
    self:RegisterEvent("UNIT_INVENTORY_CHANGED", "GetEquippedTabard")

    -- We are zoning into an instance
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "EnteringInstance")

    -- Set up variables that are not available as early as OnInitialize()
    self:SetUpVariables()
end

function RepByZone:OnDisable()
    -- Stop watching most events if RBZ is disabled
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("ZONE_CHANGED")
    self:UnregisterEvent("ZONE_CHANGED_INDOORS")
    self:UnregisterEvent("PLAYER_CONTROL_LOST")
    self:UnregisterEvent("PLAYER_CONTROL_GAINED")
    self:UnregisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
    self:UnregisterEvent("COVENANT_CHOSEN")
    self:UnregisterEvent("CHAT_MSG_MONSTER_SAY")
    self:UnregisterEvent("GOSSIP_CLOSED")
    self:UnregisterEvent("UPDATE_FACTION")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function RepByZone:SlashHandler()
    -- Check if player is in combat, exit out and close options panels if that's the case
    local isInCombat = self:InCombat()
    if isInCombat then return end

    Settings.OpenToCategory("RepByZone")
end

-- The user has reset the profile or created a new profile
function RepByZone:RefreshConfig(callback)
    if callback == "OnProfileReset" then
        self.db:ResetDB(DEFAULT)
        self.db.global.initialized = true
    end
    db = self.db
    self:SetUpVariables()
end

-- Initialize tables and variables, or reset them if the user resets the profile
function RepByZone:SetUpVariables()
    -- Initialize or verify part of the profile database
    local defaultRepID, defaultRepName = self:GetRacialRep()
    self.racialRepID = defaultRepID
    db.char.watchedRepID = db.char.watchedRepID or defaultRepID
    db.char.watchedRepName = db.char.watchedRepName or defaultRepName

    -- Populate variables, some of which update the faction lists and call RepByZone:SwitchedZones()
    bodyguardRepID = self:GetActiveBodyguardRepID()
    self:CheckTaxi()
    self:GetCovenantRep()
    self:GetSholazarBasinRep()
    self:GetWrathionOrSabellianRep()
    self:GetEquippedTabard(_, "player")

    if not IsPlayerNeutral() then
        -- Alliance or Horde characters cannot use Shang Xi's Academy, and we missed updating them
        if db.char.watchedRepID == 1216 then
            self:GetPandarenRep("NEUTRAL_FACTION_SELECT_RESULT", true)
        end
    end

    -- no need to calculate the fallback reputation unless the user changes the setting
    self.fallbackRepID = type(db.char.watchedRepID) == "number" and db.char.watchedRepID or 0
end

------------------- Event handlers starts here --------------------
function RepByZone:InCombat()
    if UnitAffectingCombat("player") then
        return true
    end
    return false
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
        A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
        H = UnitFactionGroup("player") == "Horde" and HORDE
        if A or H then
            -- Update data
            self:UnregisterEvent(event)
            db.char.watchedRepID, db.char.watchedRepName = self:GetRacialRep()
            zonesAndFactions = self:ZoneAndFactionList()
            self:Print(L["You have joined the %s, switching watched saved variable to %s."]:format(A or H, db.char.watchedRepName))
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

-- Sholazar Basin has three possible zone factions
function RepByZone:GetSholazarBasinRep()
    local newSholazarRepID, frenzyHeartData, oraclesData
    frenzyHeartData = GetFactionDataByID(1104)
    oraclesData = GetFactionDataByID(1105)

    -- nil check
    if not frenzyHeartData or not oraclesData then return end

    local frenzyHeartStanding = frenzyHeartData.reaction
    local oraclesStanding = oraclesData.reaction

    if frenzyHeartStanding <= 3 then
        newSholazarRepID = 1105 -- Frenzyheart hated, return Oracles
    elseif oraclesStanding <= 3 then
        newSholazarRepID = 1104 -- Oracles hated, return Frenzyheart
    elseif (frenzyHeartStanding == 0) or (oraclesStanding == 0) then
        newSholazarRepID = self.fallbackRepID
    end

    if newSholazarRepID ~= self.sholazarRepID then
        self.sholazarRepID = newSholazarRepID

        -- update both zones and subzones
        zonesAndFactions = self:ZoneAndFactionList()
        subZonesAndFactions = self:SubZonesAndFactionsList()
        self:SwitchedZones()
    end
end

-- The Waking Shores has three possible zone factions
function RepByZone:GetWrathionOrSabellianRep(isInCombat)
    if isInCombat then return end

    local newDragonFlightRepID = 2510 -- start with Valdrakken Accord
    self.dragonflightRepID = 2510 -- start with Valdrakken Accord
    local wrathionFriendshipInfo = GetFriendshipReputation(2517)
    local sabellianFriendshipInfo = GetFriendshipReputation(2518)

    local wrathionRankInfo = GetFriendshipReputationRanks(2517)
    local sabellianRankInfo = GetFriendshipReputationRanks(2518)

    local wrathionMaxRep = wrathionFriendshipInfo and wrathionFriendshipInfo.maxRep or 0 -- use 0 instead of possible nil
    local sabellianMaxRep = sabellianFriendshipInfo and sabellianFriendshipInfo.maxRep or 0 -- use 0 instead of possible nil

    local wrathionNextThreshold = wrathionFriendshipInfo and wrathionFriendshipInfo.nextThreshold or 0 -- use 0 instead of possible nil
    local sabellianNextThreshold = sabellianFriendshipInfo and sabellianFriendshipInfo.nextThreshold or 0 -- use 0 instead of possible nil

    local wrathionCurrentRepAmount = wrathionMaxRep % wrathionNextThreshold
    local sabellianCurrentRepAmount = sabellianMaxRep % sabellianNextThreshold

    if (wrathionRankInfo and wrathionRankInfo.currentLevel) > (sabellianRankInfo and sabellianRankInfo.currentLevel) then
        newDragonFlightRepID = 2517 -- Wrathion is higher
    elseif (sabellianRankInfo and sabellianRankInfo.currentLevel) > (wrathionRankInfo and wrathionRankInfo.currentLevel) then
        newDragonFlightRepID = 2518 -- Sabellian is higher
    elseif (wrathionRankInfo and wrathionRankInfo.currentLevel) == (sabellianRankInfo and sabellianRankInfo.currentLevel) then
        -- they are the same rank or the factions are unknown, verify
        if wrathionCurrentRepAmount > sabellianCurrentRepAmount then
            newDragonFlightRepID = 2517 -- Wrathion is higher
        elseif sabellianCurrentRepAmount > wrathionCurrentRepAmount then
            newDragonFlightRepID = 2518 -- Sabellian is higher
        end
    end

    if newDragonFlightRepID ~= self.dragonflightRepID then
        self.dragonflightRepID = newDragonFlightRepID
        instancesAndFactions = self:InstancesAndFactionList()
        zonesAndFactions = self:ZoneAndFactionList()
        subZonesAndFactions = self:SubZonesAndFactionsList()

        -- update rep bar
        self:SwitchedZones()
    end
end

function RepByZone:GetMultiRepIDsForZones()
    local uiMapID = GetBestMapForUnit("player")
    -- possible zoning issues, exit out unless we have valid map data
    if not uiMapID then return end
    local parentMapID = GetMapInfo(uiMapID).parentMapID
    local subZone = GetMinimapZoneText()
    local isInCombat = self:InCombat()
    local factionData, newtabardStandingStatus = nil, false
    local inInstance, instanceType = IsInInstance()

    if tabardID then
        factionData = GetFactionDataByID(tabardID)
    end
    if factionData then
        newtabardStandingStatus = factionData.reaction == MAX_REPUTATION_REACTION
    end

    if uiMapID == 119 or parentMapID == 119 then
        -- Sholazar Basin
        self:GetSholazarBasinRep()
        return
    end

    if (subZone == GetAreaInfo(13720)) or (subZone == GetAreaInfo(13717)) then
        -- Valdrakken Accord, Wrathion, or Sabellian in Dragonbane Keep or Obsidian Citadel
        self:GetWrathionOrSabellianRep(isInCombat) -- pass combat status to GetWrathionOrSabellianRep()
        return
    end

    -- learn if the player is wearing a dungeon faction tabard and update if required
    if inInstance and instanceType == "party" then
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
    local newTabardID, newTabardRep, factionData
    newTabardID = GetInventoryItemID(unit, INVSLOT_TABARD)
    tabardStandingStatus = false

    if newTabardID then
        newTabardRep = tabard_itemIDs_to_factionIDs[newTabardID]
        if newTabardRep then
            factionData = GetFactionDataByID(newTabardRep)
            if factionData then
                tabardStandingStatus = factionData.reaction == MAX_REPUTATION_REACTION
            end
        end
    end

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
-- Get the character's racial factionID and factionName
function RepByZone:GetRacialRep()
    local racialRepID, racialRepName, factionData
    racialRepID = player_races_to_factionIDs[playerRace]
    if not racialRepID then
        racialRepID = A and 72 or H and 76 -- Known factionIDs in case Blizzard adds new races and the addon hasn't been updated
    end
    factionData = GetFactionDataByID(racialRepID)
    if factionData then
        racialRepName = GetFactionDataByID(racialRepID).name
    end
    return racialRepID, racialRepName
end

-- Entering an instance
function RepByZone:EnteringInstance(_, isInitialLogin, isReloadingUi)
    if isInitialLogin or isReloadingUi then
        return
    else
        After(1, function() self:SwitchedZones() end)
    end
end

-- Player switched zones, subzones, or instances, set watched faction
function RepByZone:SwitchedZones(event)
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

    -- Apply instance reputations. Garrisons return false for inInstance and "party" for instanceType, which is good, we can filter them out
    if inInstance and instanceType == "party" then
        hasDungeonTabard = false
        lookUpSubZones = false
        -- Certain dungeons do not benefit from tabards
        if self.tabardExemptDungeons[whichInstanceID] then
            return
        end
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
        -- Stromgarde Keep and The Battle for Stromgarde are the only instances with subzones which are different than the main instance data
        if (inInstance and whichInstanceID ~= 1155) or (inInstance and whichInstanceID ~= 1804) then
            lookUpSubZones = false
        end

        -- Don't loop through subzones if the player is watching a bodyguard rep
        if isWoDZone and bodyguardRepID then
            lookUpSubZones = false
        end
    end

    watchedFactionID = watchedFactionID
    or (inInstance and (hasDungeonTabard and tabardID))
    or (lookUpSubZones and (citySubZonesAndFactions[subZone] or subZonesAndFactions[subZone]))
    or (inInstance and instancesAndFactions[whichInstanceID])
    or (not lookUpSubZones and (isWoDZone and bodyguardRepID))
    or (not inInstance and (zonesAndFactions[uiMapID] or zonesAndFactions[parentMapID]))
    or self.fallbackRepID

    -- WoW has a delay whenever the player changes instance/zone/subzone/tabard; factionName and isWatched aren't available immediately, so delay the lookup, then set the watched faction on the bar
    After(db.global.delayGetFactionDataByID, function()
        if type(watchedFactionID) == "number" and watchedFactionID > 0 then
            -- We have a factionID to watch either from the databases or the default watched factionID is a number greater than or equal to 1
            factionData = GetFactionDataByID(watchedFactionID)
            if factionData and not factionData.isWatched then
                SetWatchedFactionByID(watchedFactionID)
                if db.profile.verbose then
                    self:Print(L["Now watching %s"]:format(factionData.name))
                end
            end
        else
            -- There is no factionID to watch based on the databases and the user set the default watched factionID to "0-none"
            SetWatchedFactionByID(0)
        end
    end)
end