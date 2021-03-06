local RepByZone = LibStub("AceAddon-3.0"):NewAddon("RepByZone", "AceEvent-3.0", "LibAboutPanel-2.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")
local Dialog = LibStub("AceConfigDialog-3.0")

-- Local variables
local db
local isOnTaxi
local instancesAndFactions
local zonesAndFactions
local subZonesAndFactions

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
    local H = UnitFactionGroup("player") == "Horde"
    local A = UnitFactionGroup("player") == "Alliance"
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
    or playerRace == "HighmountainTauren" and 1828 or 81 -- Highmountain Tribe or Thunder Bluff
    or playerRace == "VoidElf" and 2170 or 69 -- Argussian Reach or Danassus
    or playerRace == "Mechagnome" and 2391 or 54 -- Rustbolt Resistance or Gnomeregan
    or playerRace == "Vulpera" and 2158 or 76 -- Voldunai or Orgrimmar
    or playerRace == "KulTiran" and 2160 or 72 -- Proudmoore Admiralty or Stormwind
    or playerRace == "ZandalariTroll" and 2103 or 530 -- Zandalari Empire or Darkspear Trolls
    or playerRace == "Nightborne" and 1859 or 911 -- The Nightfallen or Silvermoon City
    or playerRace == "MagharOrc" and 941 or 76 -- The Mag'har or Orgrimmar
    or playerRace == "DarkIronDwarf" and 59 or 47 -- Thorium Brotherhood or Ironforge
    or playerRace == "LightforgedDraenei" and 2165 or 930 -- Army of the Light or Exodar

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
    local function CheckRace()
        for i = 1, GetNumFactions() do
            local name, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionID = GetFactionInfo(i)
            if name and not isHeader then
                if factionID == racialRepID then
                    whichID, whichName = factionID, name
                end
            end
        end
    end
    CheckRace()

    -- Check if the player has discoverd the class faction
    if useClassRep then
        for i = 1, GetNumFactions() do
            local name, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionID = GetFactionInfo(i)
            if name and not isHeader then
                if factionID == classRepID then
                    whichID, whichName = factionID, name
                end
            end
        end
        -- Either no class faction or player hasn't discovered it yet
        if not whichID then
            CheckRace()
        end
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
        watchOnTaxi = false,
        useClassRep = true,
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
end

function RepByZone:OnEnable()
    -- Populate variables
    isOnTaxi = UnitOnTaxi("player")
    self.covenantRepID = self:CovenantToFactionID()
    db.watchedRepID = db.watchedRepID or self:GetRacialRep()
    db.watchedRepName = GetFactionInfoByID(db.watchedRepID)
    if self.racialRepID == nil then
        self:GetRacialRep()
    end

    -- Cache instance, zone, and subzone data
    instancesAndFactions = self:InstancesAndFactionList()
    zonesAndFactions = self:ZoneAndFactionList()
    subZonesAndFactions = self:SubZonesAndFactions()

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
    self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT", "CheckPandaren")
    self:CheckPandaren()

    -- See if the player belongs to a Covenant, picks one, or changes Covenants
    self:RegisterEvent("COVENANT_CHOSEN", "JoinedCovenant")
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

    -- Wipe variables when RBZ is disabled
    isOnTaxi = nil
    instancesAndFactions = nil
    zonesAndFactions = nil
    subZonesAndFactions = nil
    self.covenantRepID = nil
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

function RepByZone:CheckTaxi()
    isOnTaxi = UnitOnTaxi("player")
end

function RepByZone:LoginReload(event, isInitialLogin, isReloadingUi)
    if self.covenantRepID == nil then
        self.covenantRepID = self:CovenantToFactionID()
    end
    self:SwitchedZones()
end

local covenantReps = {
    [Enum.CovenantType.Kyrian] = 2407, -- The Ascended
    [Enum.CovenantType.Venthyr] = 2413, -- Court of Harvesters
    [Enum.CovenantType.NightFae] = 2422, -- Night Fae
    [Enum.CovenantType.Necrolord] = 2410, -- The Undying Army
}

function RepByZone:CovenantToFactionID()
    local id = C_Covenants.GetActiveCovenantID()
    return covenantReps[id]
end

function RepByZone:JoinedCovenant(event, covenantID)
    self.covenantRepID = self:CovenantToFactionID()
    self:SwitchedZones()
end

function RepByZone:CheckPandaren(event, success)
    local A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
    local H = UnitFactionGroup("player") == "Horde" and HORDE
    if success then
        A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
        H = UnitFactionGroup("player") == "Horde" and HORDE
        if UnitFactionGroup("player") ~= nil then
            self:GetRacialRep()
            if db.watchedRepID == 1216 then
                db.watchedRepID, db.watchedRepName = self:GetRacialRep()
                self:Print(L["You have joined the faction %s, switching watched saved variable to %s."]:format(A or H, db.watchedRepName))
                self:SwitchedZones()
            end
        end
    end
    if A or H then
        self:UnregisterEvent(event)
    end
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
-- Table to localize subzones that Blizzard does not provide areaIDs
local H = UnitFactionGroup("player") == "Horde"
local A = UnitFactionGroup("player") == "Alliance"
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

-- Sholazar Basin has three possible zone factions, retun factionID based on player's quest progress
function RepByZone:CheckSholazarBasin()
    local whichID
    local frenzyHeartStanding = select(3, GetFactionInfoByID(1104))
    local oraclesStanding = select(3, GetFactionInfoByID(1105))

    if frenzyHeartStanding <= 3 then
        whichID = 1105
    elseif oraclesStanding <= 3 then
        whichID = 1104
    elseif frenzyHeartStanding == 0 or oraclesStanding == 0 then
        whichID = db.watchedRepID or self.racialRepID
    end

    return whichID
end

-- Player switched zones, subzones, or instances, set watched faction
function RepByZone:SwitchedZones()
    if isOnTaxi then
        if not db.watchOnTaxi then
            -- On taxi but don't switch
            return
        end
    end

    local faction -- Predefine the variable for later use like tabards and bodyguards. Still need it now, however
    local inInstance = IsInInstance() and select(8, GetInstanceInfo())
    local subZone = GetMinimapZoneText()

    if db.watchSubZones then
        -- Blizzard provided areaIDs
        for areaID, factionID in pairs(subZonesAndFactions) do
            if C_Map.GetAreaInfo(areaID) == subZone then
                if self:SetWatchedFactionByFactionID(factionID) then
                    return
                end
            end
        end
        -- Our localized missing Blizzard areaIDs
        for areaName, factionID in pairs(CitySubZonesAndFactions) do
            if L[areaName] == subZone then
                if self:SetWatchedFactionByFactionID(factionID) then
                    return
                end
            end
        end
    end

    if inInstance then
        -- Apply instance data
        for instanceID, factionID in pairs(instancesAndFactions) do
            if instanceID == inInstance then
                if self:SetWatchedFactionByFactionID(factionID) then
                    return
                end
            end
        end
    else
        -- Apply world zone data
        local UImapID = C_Map.GetBestMapForUnit("player")
        for zoneID, factionID in pairs(zonesAndFactions) do
            if zoneID == UImapID then
                if self:SetWatchedFactionByFactionID(factionID) then
                    return
                end
            end
        end
    end

    -- If no data is found, use default watched faction or race/class faction
    faction = db.watchedRepID or self.racialRepID
    if not self:SetWatchedFactionByFactionID(faction) then
        -- Player does not want a default watched faction
        SetWatchedFactionIndex(0) -- Clear watched faction
    end
end