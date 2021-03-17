local RepByZone = LibStub("AceAddon-3.0"):NewAddon("RepByZone", "AceEvent-3.0", "LibAboutPanel-2.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")
local Dialog = LibStub("AceConfigDialog-3.0")

-- Local variables
local db
local defaults = {
    char = {
        enabled = true,
        watchSubZones = true,
        verbose = true,
        watchOnTaxi = false,
        useClassRep = true,
    }
}
local isOnTaxi
local instancesAndFactions
local zonesAndFactions
local subZonesAndFactions

-- Get the character's racial factionID and factionName
function RepByZone:GetRacialRep()
    local _, playerRace = UnitRace("player")
    --@retail@
    local H = UnitFactionGroup("player") == "Horde"
    local A = UnitFactionGroup("player") == "Alliance"
    --@end-retail@

    local racialRepID = playerRace == "Dwarf" and 47 -- Ironforge
    or playerRace == "Gnome" and 54 -- Gnomeregan
    or playerRace == "Human" and 72 -- Stormwind
    or playerRace == "NightElf" and 69 -- Darnassus
    or playerRace == "Orc" and 76 -- Orgrimmar
    or playerRace == "Tauren" and 81 -- Thunder Bluff
    or playerRace == "Troll" and 530 -- Darkspear Trolls
    or playerRace == "Scourge" and 68 -- Undercity
    --@retail@
    or playerRace == "Goblin" and 1133 -- Bilgewater Cartel
    or playerRace == "Draenei" and 930 -- Exodar
    or playerRace == "Worgen" and 1134 -- Gilneas
    or playerRace == "BloodElf" and 911 -- Sukvermoon City
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
    --@end-retail@

    -- classes have factions
    local classRepID = nil
    local _, classFileName = UnitClass("player")
    if self.db.char.useClassRep then
        classRepID = classFileName == "ROGUE" and 349 -- Ravenholdt
        or classFileName == "DRUID" and 609 -- Cenarion Circle
        --@retail@
        or classFileName == "SHAMAN" and 1135 -- The Earthen Ring
        or classFileName == "DEATHKNIGHT" and 1098 -- Knights of the Ebon Blade
        or classFileName == "MAGE" and 1090 -- Kirin Tor
        --@end-retail@
    end

    racialRepID = classRepID or racialRepID
    local racialRepName = GetFactionInfoByID(racialRepID)
    return racialRepID, racialRepName
end

function RepByZone:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("RepByZoneDB", defaults, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    self.db.RegisterCallback(self, "OnNewProfile", "RefreshConfig")
    self:SetEnabledState(self.db.char.enabled)
    db = self.db.char

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

    -- Populate db.defaultRep
    self.racialRepID, self.racialRepName = self:GetRacialRep()
    db.watchedRepID = db.watchedRepID or self.racialRepID
    db.watchedRepName = db.watchedRepName or self.racialRepName
    db.watchedName = nil -- fix old typo

    -- Check taxi status
    isOnTaxi = UnitOnTaxi("player")

    --@retail@
    self.covenantRepID = self:CovenantToFactionID()
    --@end-retail@

    -- Cache instance, zone, and subzone data
    instancesAndFactions = self:InstancesAndFactionList()
    zonesAndFactions = self:ZoneAndFactionList()
    subZonesAndFactions = self:SubZonesAndFactions()

    -- Set initial watched faction correctly during login
    self:DelayUpdate()
end

function RepByZone:OnEnable()
    -- All events that deal with entering a new zone or subzone are handled with the same function
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "DelayUpdate")
    self:RegisterEvent("ZONE_CHANGED", "DelayUpdate")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "DelayUpdate")
    -- If player is in combat, close options panel and exit out of command line
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat")
    -- If the player loses or gains control of the character, it is one of the signs of taxi use
    self:RegisterEvent("PLAYER_CONTROL_LOST", "CheckTaxi")
    self:RegisterEvent("PLAYER_CONTROL_GAINED", "CheckTaxi")

    --@retail@
    if UnitFactionGroup("player") == nil then
        self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT", "CheckPandaren")
    end
    self:RegisterEvent("COVENANT_CHOSEN", "JoinedCovenant")
    self.covenantRepID = self:CovenantToFactionID()
    --@end-retail@

    -- Check taxi status
    isOnTaxi = UnitOnTaxi("player")

    -- Set initial watched faction correctly during enable
    self:DelayUpdate()
end

function RepByZone:OnDisable()
    -- Stop watching most events if RBZ is disabled
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("ZONE_CHANGED")
    self:UnregisterEvent("ZONE_CHANGED_INDOORS")
    self:UnregisterEvent("PLAYER_CONTROL_LOST")
    self:UnregisterEvent("PLAYER_CONTROL_GAINED")

    --@retail@
    self:UnregisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
    self:UnregisterEvent("COVENANT_CHOSEN")
    --@end-retail@

    -- Wipe variables when RBZ is disabled
    isOnTaxi = nil
end

function RepByZone:RefreshConfig(event, database, ...)
    db = database.char
    db.watchedRepID, db.watchedRepName = self:GetRacialRep()
    self.racialRepID, self.racialRepName = self:GetRacialRep()
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

function RepByZone:DelayUpdate()
    C_Timer.After(0.5, function() RepByZone:SwitchedZones() end)
end

--@retail@
local covenantReps = {
    [Enum.CovenantType.None] = RepByZone.racialRepID, -- use racial rep if player hasn't joined a covenant
    [Enum.CovenantType.Kyrian] = 2407, -- The Ascended
    [Enum.CovenantType.Venthyr] = 2413, -- Court of Harvesters
    [Enum.CovenantType.NightFae] = 2422, -- Night Fae
    [Enum.CovenantType.Necrolord] = 2410, -- The Undying Army
}

function RepByZone:CovenantToFactionID(covenantID)
    local id = covenantID or C_Covenants.GetActiveCovenantID()
    return covenantReps[id]
end

function RepByZone:CheckPandaren(event, success)
    if success then
        local A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
        local H = UnitFactionGroup("player") == "Horde" and HORDE
        if UnitFactionGroup("player") ~= nil then
            self.racialRepID, self.racialRepName = self:GetRacialRep()
            if db.watchedRepID == 1216 then
                db.watchedRepID, db.watchedRepName = self:GetRacialRep()
                self:Print(L["You have joined the faction %s, switching watched saved variable to %s."]:format(A or H, db.watchedRepName))
            end
            self:DelayUpdate()
            self:UnregisterEvent(event)
        end
    end
end

function RepByZone:JoinedCovenant(event, covenantID)
    self.covenantRepID = self:CovenantToFactionID(covenantID)
    self:DelayUpdate()
end
--@end-retail@

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
local CitySubZonesAndFactions = CitySubZonesAndFactions or {
	-- ["Subzone"] = factionID
	["Dwarven District"] = 47, -- Ironforge
	["The Salty Sailor Tavern"] = 21, -- Booty Bay
	["Tinker Town"] = 54, -- Gnomeregan Exiles
	["Valley of Spirits"] = 530, -- Darkspear Trolls
	["Valley of Wisdom"] = 81, -- Thunder Bluff
}

-- Player switched zones, subzones, or instances, set watched faction
function RepByZone:SwitchedZones()
    if isOnTaxi then
        if not db.watchOnTaxi then
            -- On taxi but don't switch
            return
        end
    end

    if WorldMapFrame:IsShown() then
		-- Don't switch while the map is open
		return
	end

    local faction -- Predefine the variable for later use like tabards and bodyguards. Still need it now, however
    local inInstance = IsInInstance() and select(8, GetInstanceInfo())
    local subZone = GetMinimapZoneText()

    if inInstance then
        -- Apply instance data
        for instanceID, factionID in pairs(instancesAndFactions) do
            if instanceID == inInstance then
                if self:SetWatchedFactionByFactionID(factionID) then
                    return
                end
            end
        end
        -- Some instances have subzone data
        if db.watchSubZones then
            -- Blizzard provided areaIDs
            for areaID, factionID in pairs(subZonesAndFactions) do
                if C_Map.GetAreaInfo(areaID) == subZone then
                    if self:SetWatchedFactionByFactionID(factionID) then
                        return
                    end
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
        -- Apply subzone data
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
    end

    -- If no data is found, use default watched faction or race/class faction
    faction = db.watchedRepID or self.racialRepID
    if not self:SetWatchedFactionByFactionID(faction) then
        -- Player does not want a default watched faction
        SetWatchedFactionIndex(0) -- Clear watched faction
    end
end