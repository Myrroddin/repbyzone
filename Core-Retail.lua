-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local ALLIANCE = ALLIANCE
local C_Covenants = C_Covenants
local C_GossipInfo = C_GossipInfo
local C_Map = C_Map
local C_QuestLog = C_QuestLog
local C_Reputation = C_Reputation
local C_Timer = C_Timer
local CollapseFactionHeader = CollapseFactionHeader
local Enum = Enum
local ExpandFactionHeader = ExpandFactionHeader
local FACTION_INACTIVE = FACTION_INACTIVE
local GetFactionInfo = GetFactionInfo
local GetFactionInfoByID = GetFactionInfoByID
local GetInstanceInfo = GetInstanceInfo
local GetInventoryItemID = GetInventoryItemID
local GetMinimapZoneText = GetMinimapZoneText
local GetNumFactions = GetNumFactions
local HORDE = HORDE
local INVSLOT_TABARD = INVSLOT_TABARD
local IsInInstance = IsInInstance
local IsPlayerNeutral = IsPlayerNeutral
local LibStub = LibStub
local NONE = NONE
local pairs = pairs
local select = select
local type = type
local UnitAffectingCombat = UnitAffectingCombat
local UnitFactionGroup = UnitFactionGroup
local UnitOnTaxi = UnitOnTaxi
local UnitRace = UnitRace
local wipe = wipe

------------------- Create the addon --------------------
local RepByZone = LibStub("AceAddon-3.0"):NewAddon("RepByZone", "AceEvent-3.0", "AceConsole-3.0", "LibAboutPanel-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")
local Dialog = LibStub("AceConfigDialog-3.0")

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
    [L["The Seer's Library"]]       = 934,      -- The Scryers
    [L["The Silver Blade"]]         = 1094,     -- The Silver Covenant
	[L["Tinker Town"]]              = 54,       -- Gnomeregan
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
    [Enum.CovenantType.Kyrian]      = 2407,     -- The Ascended
    [Enum.CovenantType.Venthyr]     = 2413,     -- Court of Harvesters
    [Enum.CovenantType.NightFae]    = 2422,     -- Night Fae
    [Enum.CovenantType.Necrolord]   = 2410,     -- The Undying Army
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
        delayGetFactionInfoByID = 0.25,
        delayListUpdates        = 5,
        enabled                 = true,
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
    }
}

-- Ace3 code
function RepByZone:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("RepByZoneDB", defaults, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    -- reset the AceDB-3.0 DB on the first run, as we migrated from character profiles to the Default profile
    if not self.db.profile.initialized then
        self.db:RegisterDefaults(defaults)
        self.db:ResetDB("Default")
        self.db.profile.initialized = true
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

    -- Close option panel if opened, otherwise open option panel
    if Dialog.OpenFrames["RepByZone"] then
        Dialog:Close("RepByZone")
    else
        Dialog:Open("RepByZone")
    end
end

-- The user has reset the profile or created a new profile
function RepByZone:RefreshConfig()
    db = self.db
    self:SetUpVariables(true) -- true == new or reset profile
end

-- Initialize tables and variables, or reset them if the user resets the profile
function RepByZone:SetUpVariables(newOrResetProfile)
    -- Initialize or verify part of the profile database
    local defaultRepID, defaultRepName = self:GetRacialRep()
    db.char.watchedRepID = db.char.watchedRepID or defaultRepID
    db.char.watchedRepName = db.char.watchedRepName or defaultRepName

    -- Populate variables, some of which update the faction lists and call RepByZone:SwitchedZones()
    bodyguardRepID = self:GetActiveBodyguardRepID()
    self:CheckTaxi()
    self:GetCovenantRep()
    self:GetSholazarBasinRep()
    self:GetWrathionOrSabellianRep()
    self:GetPandarenRep()
    self:GetEquippedTabard()

    -- The profile was reset by the user, refresh db.watchedRepID and db.watchedRepName
    if newOrResetProfile then
        db.char.watchedRepID, db.char.watchedRepName = defaultRepID, defaultRepName
    end

    if not IsPlayerNeutral() then
        -- We missed Pandaren players joining either the Alliance or Horde, update
        if db.char.watchedRepID == 1216 then
            db.char.watchedRepID = A and 1353 or H and 1352
            db.char.watchedRepName = GetFactionInfoByID(db.watchedRepID)
        end
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

-- Is the player on a taxi
function RepByZone:CheckTaxi()
    isOnTaxi = UnitOnTaxi("player")
end

-- What Covenant does the player belong to, if any
function RepByZone:CovenantToFactionID()
    local id = C_Covenants.GetActiveCovenantID()
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
            self:Print(L["You have joined the %s, switching watched saved variable to %s."]:format(A or H, db.watchedRepName))
            self:SwitchedZones()
        end
    end
end

-- WoD bodyguard code
function RepByZone:GetActiveBodyguardRepID()
    local newBodyguardRepID
    for questID in pairs(bodyguard_quests) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
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
    local newSholazarRepID
    local frenzyHeartStanding = select(3, GetFactionInfoByID(1104))
    local oraclesStanding = select(3, GetFactionInfoByID(1105))

    if frenzyHeartStanding <= 3 then
        newSholazarRepID = 1105 -- Frenzyheart hated, return Oracles
    elseif oraclesStanding <= 3 then
        newSholazarRepID = 1104 -- Oracles hated, return Frenzyheart
    elseif (frenzyHeartStanding == 0) or (oraclesStanding == 0) then
        newSholazarRepID = db.watchedRepID
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
function RepByZone:GetWrathionOrSabellianRep(event)
    local newDragonFlightRepID = 2510 -- start with Valdrakken Accord
    self.dragonflightRepID = 2510 -- start with Valdrakken Accord
    local wrathionFriendshipInfo = C_GossipInfo.GetFriendshipReputation(2517)
    local sabellianFriendshipInfo = C_GossipInfo.GetFriendshipReputation(2518)

    local wrathionRankInfo = C_GossipInfo.GetFriendshipReputationRanks(2517)
    local sabellianRankInfo = C_GossipInfo.GetFriendshipReputationRanks(2518)

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

        -- update databases
        if event then
            -- delay rebuilding the data lists so they aren't updated each time the player gains reputation
            C_Timer.After(db.profile.delayListUpdates, function()
                instancesAndFactions = self:InstancesAndFactionList()
                zonesAndFactions = self:ZoneAndFactionList()
                subZonesAndFactions = self:SubZonesAndFactionsList()
            end)
        else
            -- no delay because this is initialization when the player logs into the game
            instancesAndFactions = self:InstancesAndFactionList()
            zonesAndFactions = self:ZoneAndFactionList()
            subZonesAndFactions = self:SubZonesAndFactionsList()
        end

        -- update rep bar
        self:SwitchedZones()
    end
end

function RepByZone:GetMultiRepIDsForZones(event)
    local uiMapID = C_Map.GetBestMapForUnit("player")
    -- possible zoning issues, exit out unless we have valid map data
    if not uiMapID then return end
    local parentMapID = C_Map.GetMapInfo(uiMapID).parentMapID

    if uiMapID == 119 or parentMapID == 119 then
        -- Sholazar Basin
        self:GetSholazarBasinRep()
    elseif uiMapID == 2022 or parentMapID == 2022 then
        -- Valdrakken Accord, Wrathion, or Sabellian in Waking Shores
        self:GetWrathionOrSabellianRep(event) -- pass the event to GetWrathionOrSabellianRep()
    else
        -- wrong zones, exit
        return
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

-- Entering an instance
function RepByZone:EnteringInstance()
    self:SwitchedZones()
end

-- Player switched zones, subzones, or instances, set watched faction
function RepByZone:SwitchedZones(event)
    if not db.profile.enabled then return end -- Exit if the addon is disabled

    -- Possible zoning issues, exit out unless we have valid map data
    local uiMapID = C_Map.GetBestMapForUnit("player")
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
    local _, watchedFactionID, factionName, isWatched
    local hasDungeonTabard, lookUpSubZones = false, false
    local inInstance, instanceType = IsInInstance()
    local whichInstanceID = inInstance and select(8, GetInstanceInfo())
    local parentMapID = C_Map.GetMapInfo(uiMapID).parentMapID
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
        -- Battlegrounds and warfronts are the only instances with subzones
        if inInstance and instanceType ~= "pvp" then
            lookUpSubZones = false
        end

        -- Don't loop through subzones if the player is watching a bodyguard rep
        if isWoDZone and bodyguardRepID then
            lookUpSubZones = false
        end
    end

    watchedFactionID = type(db.char.watchedRepID) == "number" and db.char.watchedRepID or 0
    watchedFactionID = (hasDungeonTabard and tabardID)
    or not hasDungeonTabard and (inInstance and instancesAndFactions[whichInstanceID])
    or not lookUpSubZones and (isWoDZone and bodyguardRepID)
    or lookUpSubZones and (citySubZonesAndFactions[subZone] or subZonesAndFactions[subZone])
    or (not inInstance and zonesAndFactions[uiMapID])

    -- WoW has a delay whenever the player changes instance/zone/subzone/tabard; factionName and isWatched aren't available immediately, so delay the lookup, then set the watched faction on the bar
    C_Timer.After(db.profile.delayGetFactionInfoByID, function()
        if type(watchedFactionID) == "number" and watchedFactionID > 0 then
            -- We have a factionID for the instance/zone/subzone/tabard or we don't have a factionID and db.watchedRepIDD is a number
            factionName, _, _, _, _, _, _, _, _, _, _, isWatched = GetFactionInfoByID(watchedFactionID)
            if factionName and not isWatched then
                C_Reputation.SetWatchedFaction(watchedFactionID)
                if db.profile.verbose then
                    self:Print(L["Now watching %s"]:format(factionName))
                end
            end
        else
            -- There is nothing in the database and db.watchedRepID == "0-none"; blank the bar
            C_Reputation.SetWatchedFaction(0)
        end
    end)
end