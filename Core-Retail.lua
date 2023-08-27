local RepByZone = LibStub("AceAddon-3.0"):NewAddon("RepByZone", "AceEvent-3.0", "LibAboutPanel-2.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")
local Dialog = LibStub("AceConfigDialog-3.0")

-- Local variables
local db
local _, isOnTaxi
local instancesAndFactions
local zonesAndFactions
local subZonesAndFactions
local A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
local H = UnitFactionGroup("player") == "Horde" and HORDE

-- Table to localize subzones that Blizzard does not provide areaIDs
local CitySubZonesAndFactions = {
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
    ["The Roasted Ram"] = 2510, -- Valdrakken Accord
	["The Salty Sailor Tavern"] = 21, -- Booty Bay
    ["The Seer's Library"] = 934, -- The Scryers
    ["The Silver Blade"] = 1094, -- The Silver Covenant
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
    [83079]     = 1353,     -- Tushui Pandaren

    -- Horde
    [45581]     = 76,       -- Orgrimmar
    [45582]     = 530,      -- Darkspear Trolls
    [45583]     = 68,       -- Undercity
    [45584]     = 81,       -- Thunder Bluff
    [45585]     = 911,      -- Silvermoon City
    [83080]     = 1352,     -- Huojin Pandaren
}
--[[
local faction_tabard_auraIDs = {
    -- [auraID] = factionID
    -- Alliance
    [93795]     = 72,       -- Stormwind City
    [93805]     = 47,       -- Ironforge
    [93821]     = 54,       -- Gnomeregan
    [93806]     = 69,       -- Darnassus
    [93811]     = 930,      -- Exodar
    [126434]    = 1353,     -- Tushui Pandaren

    -- Horde
    [93825]     = 76,       -- Orgrimmar
    [93827]     = 530,      -- Darkspear
    [94462]     = 68,       -- Undercity
    [94463]     = 81,       -- Thunder Bluff
    [93828]     = 911,      -- Silvermoon City
    [126436]    = 1352,     -- Huojin Pandaren
}
]]--

-- WoD garrison bodyguard code
local bodyguardRepID
local followerQuests = {
    -- [questID] = factionID
    [36877]     = 1736,     -- Tormmok
    [36899]     = 1738,     -- Defender Illona
    [36902]     = 1740,     -- Aeda Brightdawn
    [36989]     = 1733,     -- Delvar Ironfist
    [36901]     = 1739,     -- Vivianne
    [36900]     = 1737,     -- Talonpriest Ishaal
    [36936]     = 1741,     -- Leorajh
}
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
    or playerRace == "Dracthyr" and (A and 2524 or H and 2523) -- Obsidian Warders or Dark Talons

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
    or playerRace == "Dracthyr" and A and 72 or H and 76 -- Stormwind or Orgrimmar

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

    -- These events never get unregistered
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "LoginReload")
end

function RepByZone:OnEnable()
    -- All events that deal with entering a new zone or subzone are handled with the same function
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "SwitchedZones")
    self:RegisterEvent("ZONE_CHANGED", "SwitchedZones")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "SwitchedZones")

    -- If the player loses or gains control of the character, it is one of the signs of taxi use
    self:RegisterEvent("PLAYER_CONTROL_LOST", "CheckTaxi")
    self:RegisterEvent("PLAYER_CONTROL_GAINED", "CheckTaxi")

    -- Pandaren do not start Alliance or Horde
    if UnitFactionGroup("player") == nil then
        self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT", "GetPandarenRep")
    end

    -- See if the player belongs to a Covenant, picks one, or changes Covenants
    self:RegisterEvent("COVENANT_CHOSEN", "GetCovenantRep")

    -- Check if a WoD garrison bodyguard is assigned
    self:RegisterEvent("CHAT_MSG_MONSTER_SAY", "GetbodyguardRepID")
    self:RegisterEvent("GOSSIP_CLOSED", "GetbodyguardRepID")

    -- Check Sholazar Basin and Wrathion/Sabellian factions
    self:RegisterEvent("UPDATE_FACTION", "GetMultiRepIDsForZones")

    -- Check if a faction tabard is equipped or changed
    self:RegisterEvent("UNIT_INVENTORY_CHANGED", "GetFactionIDFromTabardID")
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

-- First login or entering an instance
function RepByZone:LoginReload(_, isInitialLogin, isReloadingUi)
    if isReloadingUi then return end
    local defaultRepID, defaultRepName
    local inInstance, instanceType = IsInInstance()

    if isInitialLogin then
        -- Populate variables
        isOnTaxi = UnitOnTaxi("player")
        self:GetCovenantRep()
        self:GetbodyguardRepID()
        self:GetMultiRepIDsForZones()
        self:GetPandarenRep()
        defaultRepID, defaultRepName = self:GetRacialRep()
        db.watchedRepID = db.watchedRepID or defaultRepID
        db.watchedRepName = db.watchedRepName or defaultRepName
        self:GetFactionIDFromTabardID()

        instancesAndFactions = self:InstancesAndFactionList()
        zonesAndFactions = self:ZoneAndFactionList()
        subZonesAndFactions = self:SubZonesAndFactionsList()
    end

    if db.enabled then
        if db.useFactionTabards then
            -- Entering an instance, check if tabardID and 5 person dungeon are valid
            if inInstance and instanceType == "party" then
                if type(tabardID) == "number" then
                    local factionName, _, _, _, _, _, _, _, _, _, _, isWatched = GetFactionInfoByID(tabardID)
                    if factionName and not isWatched then
                        C_Reputation.SetWatchedFaction(tabardID)
                        if db.verbose then
                            self:Print(L["Now watching %s"]:format(factionName))
                        end
                    end
                else
                    -- tabardID is not a number
                    self:SwitchedZones()
                end
            else
                -- We aren't in an instance or the instanceType is not party
                self:SwitchedZones()
            end
        end
    end
end

-- The user has reset the DB or created a new profile
function RepByZone:RefreshConfig()
    db = self.db.profile
    db.watchedRepID, db.watchedRepName = nil, nil

    self:LoginReload(_, true, false) -- Trigger isInitialLogin
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
            -- update data
            self:UnregisterEvent(event)
            if db.watchedRepID or self.racialRepID == 1216 then
                db.watchedRepID, db.watchedRepName = self:GetRacialRep()
                self.racialRepID, self.GetRacialRep = self:GetRacialRep()
                zonesAndFactions = self:ZoneAndFactionList()
                self:Print(L["You have joined the %s, switching watched saved variable to %s."]:format(A or H, db.watchedRepName))
                self:SwitchedZones()
            end
        end
    end
end

-- WoD bodyguard code
function RepByZone:GetbodyguardRepID()
    local newBodyguardRepID
    for questID, factionID in pairs(followerQuests) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
            newBodyguardRepID = factionID
            break
        end
    end
    if newBodyguardRepID ~= bodyguardRepID then
        bodyguardRepID = newBodyguardRepID
        self:SwitchedZones()
    end
end

-- Sholazar Basin has three possible zone factions; some DF subzones have two; retun factionID based on player's quest progress
function RepByZone:GetMultiRepIDsForZones()
    -- Sholazar Basin
    local newSholazarRepID
    local frenzyHeartStanding = select(3, GetFactionInfoByID(1104))
    local oraclesStanding = select(3, GetFactionInfoByID(1105))

    if frenzyHeartStanding <= 3 then
        newSholazarRepID = 1105 -- Frenzyheart hated, return Oracles
    elseif oraclesStanding <= 3 then
        newSholazarRepID = 1104 -- Oracles hated, return Frenzyheart
    elseif (frenzyHeartStanding == 0) or (oraclesStanding == 0) then
        newSholazarRepID = db.watchedRepID or self.racialRepID
    end

    if newSholazarRepID ~= self.sholazarRepID then
        self.sholazarRepID = newSholazarRepID

        -- update both zones and subzones
        zonesAndFactions = self:ZoneAndFactionList()
        subZonesAndFactions = self:SubZonesAndFactionsList()
        self:SwitchedZones()
    end

    -- Wrathion or Sabellian in Dragonflight
    local newDragonFlightRepID = 2510 -- start with Valdrakken Accord
    self.dragonflightRepID = 2510 -- start with Valdrakken Accord
    local wrathionFriendshipInfo = C_GossipInfo.GetFriendshipReputation(2517)
    local sabellionFriendshipInfo = C_GossipInfo.GetFriendshipReputation(2518)

    local wrathionRankInfo = C_GossipInfo.GetFriendshipReputationRanks(2517)
    local sabellionRankInfo = C_GossipInfo.GetFriendshipReputationRanks(2518)

    local wrathionMaxRep = wrathionFriendshipInfo and wrathionFriendshipInfo.maxRep or 0 -- use 0 instead of possible nil
    local sabellionMaxRep = sabellionFriendshipInfo and sabellionFriendshipInfo.maxRep or 0 -- use 0 instead of possible nil

    local wrathionNextThreshold = wrathionFriendshipInfo and wrathionFriendshipInfo.nextThreshold or 0 -- use 0 instead of possible nil
    local sabellionNextThreshold = sabellionFriendshipInfo and sabellionFriendshipInfo.nextThreshold or 0 -- use 0 instead of possible nil

    local wrathionCurrentRepAmount = wrathionMaxRep % wrathionNextThreshold
    local sabellionCurrentRepAmount = sabellionMaxRep % sabellionNextThreshold

    if (wrathionRankInfo and wrathionRankInfo.currentLevel) > (sabellionRankInfo and sabellionRankInfo.currentLevel) then
        newDragonFlightRepID = 2517 -- Wrathion is higher
    elseif (sabellionRankInfo and sabellionRankInfo.currentLevel) > (wrathionRankInfo and wrathionRankInfo.currentLevel) then
        newDragonFlightRepID = 2518 -- Sabellian is higher
    elseif (wrathionRankInfo and wrathionRankInfo.currentLevel) == (sabellionRankInfo and sabellionRankInfo.currentLevel) then
        -- they are the same rank or the factions are unknown, verify
        if wrathionCurrentRepAmount > sabellionCurrentRepAmount then
            newDragonFlightRepID = 2517 -- Wrathion is higher
        elseif sabellionCurrentRepAmount > wrathionCurrentRepAmount then
            newDragonFlightRepID = 2518 -- Sabellian is higher
        end
    end

    if newDragonFlightRepID ~= self.dragonflightRepID then
        self.dragonflightRepID = newDragonFlightRepID

        -- update both zones and subzones
        instancesAndFactions = self:InstancesAndFactionList()
        zonesAndFactions = self:ZoneAndFactionList()
        subZonesAndFactions = self:SubZonesAndFactionsList()
        self:SwitchedZones()
    end
end

-- Tabard code
function RepByZone:GetFactionIDFromTabardID(_, unit)
    if unit ~= "player" then return end
    local inInstance, instanceType = IsInInstance()

    if not db.useFactionTabards then
        tabardID = nil
    end

    if db.enabled then
        if IsEquippedItemType(INVTYPE_TABARD) and db.useFactionTabards then
            if inInstance and instanceType == "party" then
                for itemID, factionID in pairs(tabard_itemIDs_to_factionIDs) do
                    if IsEquippedItem(itemID) then
                        tabardID = factionID
                        break
                    end
                end
            end
        end

        self:SwitchedZones()
    end
end
--[[
function RepByZone:GetTabardBuffData()
    local newTabardFactionID, buffID

    local function BuffIterator(...)
        buffID = select(10, ...)
        for spellID, tabardFactionID in pairs(faction_tabard_auraIDs) do
            if buffID == spellID then
                newTabardFactionID = tabardFactionID
                return true
            end
        end
    end

    AuraUtil.ForEachAura("player", "PLAYER|HELPFUL", nil, BuffIterator)

    if newTabardFactionID ~= tabardID then
        tabardID = newTabardFactionID
    end

    if not db.useFactionTabards then
        tabardID = nil
    end

    if not IsEquippedItemType(INVTYPE_TABARD) then
        tabardID = nil
    end

    self:LoginReload()
end
]]--

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

    local _, watchedFactionID, factionName, isWatched
    local inInstance = IsInInstance()
    local whichInstanceID = inInstance and select(8, GetInstanceInfo())
    local parentMapID = C_Map.GetMapInfo(uiMapID).parentMapID
    local subZone = GetMinimapZoneText()
    local isWoDZone = self.WoDFollowerZones[uiMapID] or (self.WoDFollowerZones[uiMapID] == nil and self.WoDFollowerZones[parentMapID])
    local backupRepID = (db.watchedRepID == nil and self.racialRepID ~= nil) or (self.racialRepID == nil and db.watchedRepID ~= nil)

    -- Apply instance reputations
    if inInstance and type(tabardID) ~= "number" then
        for instanceID, factionID in pairs(instancesAndFactions) do
            if instanceID == whichInstanceID then
                watchedFactionID = factionID
                break
            end
        end
    elseif inInstance and type(tabardID) == "number" then
        -- tabardID will be a number in party dungeons when the player has a faction tabard equipped
        watchedFactionID = tabardID
    end

    -- Override in WoD zones only if a bodyguard exists
    if isWoDZone and bodyguardRepID then
        watchedFactionID = bodyguardRepID
    end

    -- Apply world zone data
    if (isWoDZone and bodyguardRepID) or inInstance then
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
        if type(tabardID) == "number" then return end

        -- Don't loop through subzones if the player is watching a bodyguard rep
        if isWoDZone and bodyguardRepID then return end

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