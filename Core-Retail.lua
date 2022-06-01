local RepByZone = LibStub("AceAddon-3.0"):NewAddon("RepByZone", "AceEvent-3.0", "LibAboutPanel-2.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")
local Dialog = LibStub("AceConfigDialog-3.0")

-- Local variables
local db
local isOnTaxi
local instancesAndFactions
local zonesAndFactions
local subZonesAndFactions
local A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
local H = UnitFactionGroup("player") == "Horde" and HORDE

-- Table to localize subzones that Blizzard does not provide areaIDs
local CitySubZonesAndFactions = CitySubZonesAndFactions or {
	-- ["Subzone"] = factionID
    ["A Hero's Welcome"] = A and 1094 or H and 1124, -- The Silver Covenant or The Sunreavers
    ["Aldor Rise"] = 932, -- The Aldor
    ["Deeprun Tram"] = 72, -- Stormwind
	["Dwarven District"] = 47, -- Ironforge
    ["Scryer's Tier"] = 934, -- The Scryers
    ["Shrine of Unending Light"] = 932, -- The Aldor
    ["The Beer Garden"] = A and 1094 or H and 1124, -- The Silver Covenant or The Sunreavers
    ["The Crimson Dawn"] = 1124, -- The Sunreavers
    ["The Filthy Animal"] = A and 1094 or H and 1124, -- The Silver Covenant or The Sunreavers
	["The Salty Sailor Tavern"] = 21, -- Booty Bay
    ["The Seer's Library"] = 934, -- The Scryers
    ["The Silver Blade"] = 1094, -- The Silver Covenant
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
    [126434]    = {1353},   -- Tushui Pandaren

    -- Horde
    [93825]     = {76},     -- Orgrimmar
    [93827]     = {530},    -- Darkspear
    [94462]     = {68},     -- Undercity
    [94463]     = {81},     -- Thunder Bluff
    [93828]     = {911},    -- Silvermoon City
    [126436]    = {1352},   -- Huojin Pandaren
}

-- WoD garrison bodyguard code
local bodyguardRep
local followerQuests = {
    -- questID = factionID
    [36877] = 1736, -- Tormmok
    [36899] = 1738, -- Defender Illona
    [36902] = 1740, -- Aeda Brightdawn
    [36989] = 1733, -- Delvar Ironfist
    [36901] = 1739, -- Vivianne
    [36900] = 1737, -- Talonpriest Ishaal
    [36936] = 1741, -- Leorajh
}
RepByZone.WoDFollowerZones = {
    [525]   = true, -- Frostfire Ridge
    [534]   = true, -- Tanaan Jungle
    [535]   = true, -- Talador
    [539]   = true, -- Shadowmoon Valley
    [542]   = true, -- Spires of Arak
    [543]   = true, -- Gorgrond
    [550]   = true, -- Nagrand
    [582]   = true, -- Lunarfall
    [590]   = true, -- Frostwall
}

-- Covenant code
local covenantReps = {
    [Enum.CovenantType.Kyrian] = 2407, -- The Ascended
    [Enum.CovenantType.Venthyr] = 2413, -- Court of Harvesters
    [Enum.CovenantType.NightFae] = 2422, -- Night Fae
    [Enum.CovenantType.Necrolord] = 2410, -- The Undying Army
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

    local _, playerRace = UnitRace("player")
    local whichID, whichName

    local racialRepID = playerRace == "Dwarf" and 47 -- Ironforge
    or playerRace == "Gnome" and 54 -- Gnomeregan
    or playerRace == "Human" and 72 -- Stormwind
    or playerRace == "NightElf" and 69 -- Darnassus
    or playerRace == "Orc" and 76 -- Orgrimmar
    or playerRace == "Tauren" and 81 -- Thunder Bluff
    or playerRace == "Troll" and 530 -- Darkspear Trolls
    or playerRace == "Scourge" and 68 -- Undercity
    or playerRace == "Goblin" and 1133 -- Bilgewater Cartel
    or playerRace == "Draenei" and 930 -- Exodar
    or playerRace == "Worgen" and 1134 -- Gilneas
    or playerRace == "BloodElf" and 911 -- Silvermoon City
    or playerRace == "Pandaren" and (A and 1353 or H and 1352 or 1216) -- Tushui Pandaren or Huojin Pandaren or Shang Xi's Academy
    or playerRace == "HighmountainTauren" and 1828 -- Highmountain Tribe
    or playerRace == "VoidElf" and 2170 -- Argussian Reach
    or playerRace == "Mechagnome" and 2391 -- Rustbolt Resistance
    or playerRace == "Vulpera" and 2158 -- Voldunai
    or playerRace == "KulTiran" and 2160 -- Proudmoore Admiralty
    or playerRace == "ZandalariTroll" and 2103 -- Zandalari Empire
    or playerRace == "Nightborne" and 1859 -- The Nightfallen
    or playerRace == "MagharOrc" and 941 -- The Mag'har
    or playerRace == "DarkIronDwarf" and 59 -- Thorium Brotherhood
    or playerRace == "LightforgedDraenei" and 2165 -- Army of the Light

    local fallbackRacialRepID = playerRace == "Dwarf" and 47 -- Ironforge
    or playerRace == "Gnome" and 54 -- Gnomeregan
    or playerRace == "Human" and 72 -- Stormwind
    or playerRace == "NightElf" and 69 -- Darnassus
    or playerRace == "Orc" and 76 -- Orgrimmar
    or playerRace == "Tauren" and 81 -- Thunder Bluff
    or playerRace == "Troll" and 530 -- Darkspear Trolls
    or playerRace == "Scourge" and 68 -- Undercity
    or playerRace == "Goblin" and 1133 -- Bilgewater Cartel
    or playerRace == "Draenei" and 930 -- Exodar
    or playerRace == "Worgen" and 1134 -- Gilneas
    or playerRace == "BloodElf" and 911 -- Silvermoon City
    or playerRace == "Pandaren" and (A and 1353 or H and 1352 or 1216) -- Tushui Pandaren or Huojin Pandaren or Shang Xi's Academy
    or playerRace == "HighmountainTauren" and 81 -- Thunder Bluff
    or playerRace == "VoidElf" and 69 -- Darnassus
    or playerRace == "Mechagnome" and 54 -- Gnomeregan
    or playerRace ==  "Vulpera" and 76 -- Orgrimmar
    or playerRace == "KulTian" and 72 -- Stormwind
    or playerRace == "ZandalariTroll" and 530 -- Darkspear Trolls
    or playerRace == "Nightborne" and 911 -- Silvermoon City
    or playerRace == "MagharOrc" and 76 -- Orgrimmar
    or playerRace == "DarkIronDwarf" and 47 -- Ironforge
    or playerRace == "LightforgedDraenei" and 930 -- Exodar

    -- Classes have factions
    local _, classFileName = UnitClass("player")
    local classRepID = classFileName == "ROGUE" and 349 -- Ravenholdt
    or classFileName == "DRUID" and 609 -- Cenarion Circle
    or classFileName == "SHAMAN" and 1135 -- The Earthen Ring
    or classFileName == "DEATHKNIGHT" and 1098 -- Knights of the Ebon Blade
    or classFileName == "MAGE" and 1090 -- Kirin Tor
    or classFileName == "MONK" and 1341 -- The August Celestials

    self:OpenAllFactionHeaders()

    -- Check if the player has discovered the race faction
    local function CheckRaceRep()
        for i = 1, GetNumFactions() do
            local name, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionID = GetFactionInfo(i)
            if name and not isHeader then
                if factionID == racialRepID then
                    return factionID, name
                end
            end
        end
    end
    whichID, whichName = CheckRaceRep()

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

    -- If allied race reps are not known, use fallback
    local function CheckFallbackRaceRep()
        for i = 1, GetNumFactions() do
            local name, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionID = GetFactionInfo(i)
            if name and not isHeader then
                if factionID == fallbackRacialRepID then
                    return factionID, name
                end
            end
        end
    end
    if not whichID then
        whichID, whichName = CheckFallbackRaceRep()
    end

    self:CloseAllFactionHeaders()

    self.racialRepID = useClassRep and classRepID or racialRepID
    self.racialRepName = GetFactionInfoByID(self.racialRepID)
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
        watchWoDBodyGuards = {
            ["**"] = true
        }
    }
}

-- Ace3 code
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
end

function RepByZone:OnEnable()
    -- Populate variables
    isOnTaxi = UnitOnTaxi("player")
    instancesAndFactions = instancesAndFactions or self:InstancesAndFactionList()
    zonesAndFactions = zonesAndFactions or self:ZoneAndFactionList()
    subZonesAndFactions = subZonesAndFactions or self:SubZonesAndFactions()

    -- All events that deal with entering a new zone or subzone are handled with the same function
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "SwitchedZones")
    self:RegisterEvent("ZONE_CHANGED", "SwitchedZones")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "SwitchedZones")

    -- If player is in combat, close options panel and exit out of command line
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat")

    -- If the player loses or gains control of the character, it is one of the signs of taxi use
    self:RegisterEvent("PLAYER_CONTROL_LOST", "CheckTaxi")
    self:RegisterEvent("PLAYER_CONTROL_GAINED", "CheckTaxi")

    -- Set watched faction when the player first loads into the game
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "LoginReload")

    -- Pandaren do not start Alliance or Horde
    if UnitFactionGroup("player") == nil then
        self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT", "GetPandarenRep")
    end

    -- See if the player belongs to a Covenant, picks one, or changes Covenants
    self:RegisterEvent("COVENANT_CHOSEN", "GetCovenantRep")

    -- Check if a WoD garrison bodyguard is assigned
    self:RegisterEvent("CHAT_MSG_MONSTER_SAY", "GetBodyguardRep")
    self:RegisterEvent("GOSSIP_CLOSED", "GetBodyguardRep")

    -- Check Sholazar Basin factions
    self:RegisterEvent("UPDATE_FACTION", "GetSholazarBasinRep")

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
    self:UnregisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
    self:UnregisterEvent("COVENANT_CHOSEN")
    self:UnregisterEvent("CHAT_MSG_MONSTER_SAY")
    self:UnregisterEvent("GOSSIP_CLOSED")
    self:UnregisterEvent("UPDATE_FACTION")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
    self:UnregisterEvent("UNIT_AURA")

    -- Wipe variables when RBZ is disabled
    isOnTaxi = nil
end

function RepByZone:SlashHandler()
    -- Check if player is in combat, exit out and close options panels if that's the case
    self:InCombat()

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
end

------------------- Event handlers starts here --------------------
function RepByZone:InCombat()
    if UnitAffectingCombat("player") then
        if Dialog.OpenFrames["RepByZone"] then
            Dialog:Close("RepByZone")
        end
        return
    end
end

-- Is the player on a taxi
function RepByZone:CheckTaxi()
    isOnTaxi = UnitOnTaxi("player")
end

-- Handled during first login
function RepByZone:LoginReload(event, isInitialLogin, isReloadingUi)
    instancesAndFactions = instancesAndFactions or self:InstancesAndFactionList()
    zonesAndFactions = zonesAndFactions or self:ZoneAndFactionList()
    subZonesAndFactions = subZonesAndFactions or self:SubZonesAndFactions()

    self:GetCovenantRep()
    self:GetBodyguardRep()
    self:GetSholazarBasinRep()
    self:GetPandarenRep()
    self:GetRacialRep()
    self:GetTabardID()
        
    self:SwitchedZones()
end

-- What Covenant does the player belong to, if any
function RepByZone:CovenantToFactionID()
    local id = C_Covenants.GetActiveCovenantID()
    return covenantReps[id]
end

function RepByZone:GetCovenantRep(event, ...)
    local newCovenantRepID = self:CovenantToFactionID()
    if newCovenantRepID ~= self.covenantRepID then
        self.covenantRepID = newCovenantRepID
        instancesAndFactions = self:InstancesAndFactionList()
        zonesAndFactions = self:ZoneAndFactionList()
        subZonesAndFactions = self:SubZonesAndFactions()
        self:SwitchedZones()
    end
end

-- Pandaren code
function RepByZone:GetPandarenRep(event, success)
    A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
    H = UnitFactionGroup("player") == "Horde" and HORDE
    if A or H then
        zonesAndFactions = self:ZoneAndFactionList()
        self:UnregisterEvent(event)
        if db.watchedRepID or self.racialRepID == 1216 then
            db.watchedRepID, db.watchedRepName = self:GetRacialRep()
            self:Print(L["You have joined the %s, switching watched saved variable to %s."]:format(A or H, db.watchedRepName))
            self:SwitchedZones()
        end
    end
end

-- WoD bodyguard code
function RepByZone:GetBodyguardRep()
    local newBodyguardRep
    for questID, factionID in pairs(followerQuests) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
            newBodyguardRep = factionID
            break
        end
    end
    if newBodyguardRep ~= bodyguardRep then
        bodyguardRep = newBodyguardRep
        self:SwitchedZones()
    end
end

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
        zonesAndFactions = self:ZoneAndFactionList()
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
        return false
    end

    AuraUtil.ForEachAura("player", "HELPFUL", maxCount, function(...)
        if maxCount and maxCount <= 0 then
            return false
        end

        local buffID = select(10, ...)
        local factionID
        local data = faction_tabard_auraIDs[buffID]
        if data then
            factionID = data[1] -- TODO: verify which dungeons can benefit from tabards
            return factionID
        end
    end)
end

-------------------- Reputation code starts here --------------------
local repsCollapsed = {} -- Obey user's settings about headers opened or closed
-- Open all faction headers
function RepByZone:OpenAllFactionHeaders()
    local i = 1
	while i <= GetNumFactions() do
		local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(i)
		if isHeader then
			repsCollapsed[name] = isCollapsed
			if name == FACTION_INACTIVE then
				if not isCollapsed then
					CollapseFactionHeader(i)
				end
				break
			elseif isCollapsed then
				ExpandFactionHeader(i)
			end
		end
		i = i + 1
	end
end

-- Close all faction headers
function RepByZone:CloseAllFactionHeaders()
    local i = 1
	while i <= GetNumFactions() do
		local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(i)
		if isHeader then
			if isCollapsed and not repsCollapsed[name] then
				ExpandFactionHeader(i)
			elseif repsCollapsed[name] and not isCollapsed then
				CollapseFactionHeader(i)
			end
		end
		i = i + 1
	end
	wipe(repsCollapsed)
end

function RepByZone:GetAllFactions()
    -- Will not return factions the user has marked as inactive
    self:OpenAllFactionHeaders()
    local factionList = {}

    for i = 1, GetNumFactions() do
        local name, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionID = GetFactionInfo(i)
        if not isHeader then
            factionList[factionID] = name
        end
    end
    factionList["0-none"] = NONE

    self:CloseAllFactionHeaders()
    return factionList
end

-- Blizzard sets watched faction by index, not by factionID so create our own API
function RepByZone:SetWatchedFactionByFactionID(id)
    if type(id) ~= "number" then return end

    self:OpenAllFactionHeaders()
    for i = 1, GetNumFactions() do
        local name, _, standingID, _, _, _, _, _, isHeader, _, _, isWatched, _, factionID = GetFactionInfo(i)
        if id == factionID then
            if not isWatched then
                SetWatchedFactionIndex(i)
                if db.verbose then
                    self:Print(L["Now watching %s"]:format(name))
                end
            end
            self:CloseAllFactionHeaders()
            return name, id
        end
    end
    self:CloseAllFactionHeaders()
end

-------------------- Watched faction code starts here --------------------
-- Player switched zones, subzones, or instances, set watched faction
function RepByZone:SwitchedZones()
    local UImapID = C_Map.GetBestMapForUnit("player")
    if not UImapID then return end -- Possible zoning issues, exit out unless we have valid map data

    if isOnTaxi then
        if not db.watchOnTaxi then
            -- On taxi but don't switch
            return
        end
    end

    local faction
    local inInstance = IsInInstance() and select(8, GetInstanceInfo())
    local _, isDungeon, difficultyID = GetInstanceInfo()
    local parentMapID = C_Map.GetMapInfo(UImapID).parentMapID
    local subZone = GetMinimapZoneText()
    local isWoDZone = self.WoDFollowerZones[UImapID] or (self.WoDFollowerZones[UImapID] == nil and self.WoDFollowerZones[parentMapID])

    if isDungeon == "party" and tabardID ~= nil then
        faction = self:GetTabardBuffData()
    end

    if inInstance then
        if not faction then
            for instanceID, factionID in pairs(instancesAndFactions) do
                if instanceID == inInstance then
                    faction = factionID
                    break
                end
            end
        end
    else
        -- Apply world zone data
        for zoneID, factionID in pairs(zonesAndFactions) do
            if zoneID == UImapID then
                faction = factionID
                break
            end
        end
    end

    if db.watchSubZones then
        -- Blizzard provided areaIDs
        for areaID, factionID in pairs(subZonesAndFactions) do
            if C_Map.GetAreaInfo(areaID) == subZone then
                faction = factionID
                break
            end
        end
        -- Our localized missing Blizzard areaIDs
        for areaName, factionID in pairs(CitySubZonesAndFactions) do
            if L[areaName] == subZone then
                faction = factionID
                break
            end
        end
    end

    if isWoDZone and bodyguardRep then
        -- Override in WoD zones only if a bodyguard exists
        faction = bodyguardRep
    end

    if not faction then
        faction = (db.watchedRepID == nil and self.racialRepID ~= nil) or (self.racialRepID == nil and db.watchedRepID ~= nil)
    end

    if self:SetWatchedFactionByFactionID(faction) then
        return
    elseif db.watchedRepID == "0-none" then
        SetWatchedFactionIndex(0) -- Clear watched faction
    end
end