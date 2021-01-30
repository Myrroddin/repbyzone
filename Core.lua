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
    }
}
local zonesAndFactions = zonesAndFactions or {}
local instancesAndFactions = instancesAndFactions or {}
local subZonesAndFactions = subZonesAndFactions or {}
local isOnTaxi

-- Get the character's racial factionID and factionName
local function GetRacialRep()
    local _, playerRace = UnitRace("player")
    --@retail@
    local H = UnitFactionGroup("player") == "Horde"
    local A = UnitFactionGroup("player") == "Alliance"
    local _, classFileName = UnitClass("player")
    --@end-retail@
    local racialRepID = playerRace == "Dwarf" and 47
    or playerRace == "Gnome" and 54
    or playerRace == "Human" and 72
    or playerRace == "NightElf" and 69
    or playerRace == "Orc" and 76
    or playerRace == "Tauren" and 81
    or playerRace == "Troll" and 530
    or playerRace == "Scourge" and 68
    --@retail@
    or playerRace == "Goblin" and 1133
    or playerRace == "Draenei" and 930
    or playerRace == "Worgen" and 1134
    or playerRace == "BloodElf" and 911
    or playerRace == "Pandaren" and (A and 1353 or H and 1352 or 1216)
    or playerRace == "HighmountainTauren" and 1828
    or playerRace == "VoidElf" and 2170
    or playerRace == "Mechagnome" and 2391
    or playerRace == "Vulpera" and 2158
    or playerRace == "KulTiran" and 2160
    or playerRace == "ZandalariTroll" and 2103
    or playerRace == "Nightborne" and 1859
    or playerRace == "MagharOrc" and 941
    or playerRace == "DarkIronDwarf" and 47
    or playerRace == "LightforgedDraenei" and 2165

    -- classes have factions
    local classRepID = classFileName == "DEATHKNIGHT" and 1098
    or classFileName == "DEMONHUNTER" and (A and 69 or H and 911)

    racialRepID = classRepID or racialRepID
    --@end-retail@

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

    zonesAndFactions = self:ZoneAndFactionList() -- ClassicData.lua or RetailData.lua
    instancesAndFactions = self:InstancesAndFactionList() -- ClassicData.lua or RetailInstanceData.lua
    subZonesAndFactions = self:SubZonesAndFactions() -- ClassicData.lua or RetailData.lua

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
    self.racialRepID, self.racialRepName = GetRacialRep()
    db.watchedRepID = db.watchedRepID or self.racialRepID
    db.watchedName = db.watchedRepName or self.racialRepName

    --@retail@
    self.covenantRepID = self:CovenantToFactionID()
    --@end-retail@
end

function RepByZone:OnEnable()
    -- All events that deal with entering a new zone or subzone are handled with the same function
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "SwitchedSubZones")
    self:RegisterEvent("ZONE_CHANGED", "SwitchedSubZones")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "SwitchedSubZones")
    -- If player is in combat, close options panel and exit out of command line
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat")
    -- There is no direct event to check if the player is on a taxi so check if the action bar is usable
    self:RegisterEvent("ACTIONBAR_UPDATE_USABLE", "CheckTaxi")

    --@retail@
    if UnitFactionGroup("player") == nil then
        self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT", "CheckPandaren")
    end
    self:RegisterEvent("COVENANT_CHOSEN", "JoinedCovenant")
    --@end-retail@

    -- Check taxi status only if RBZ is enabled on login
    if UnitOnTaxi("player") then
        isOnTaxi = true
    end

    -- Set initial watched faction correctly during login
    self:SwitchedSubZones()
end

function RepByZone:OnDisable()
    -- Stop watching most events if RBZ is disabled
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("ZONE_CHANGED")
    self:UnregisterEvent("ZONE_CHANGED_INDOORS")
    self:UnregisterEvent("ACTIONBAR_UPDATE_USABLE")

    --@retail@
    self:UnregisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
    self:UnregisterEvent("COVENANT_CHOSEN")
    --@end-retail@

    -- Wipe variables when RBZ is disabled
    isOnTaxi = nil
end

function RepByZone:RefreshConfig(event, database, ...)
    db = database.char
    db.watchedRepID, db.watchedRepName = GetRacialRep()
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
    local checkIfTaxi = UnitOnTaxi("player")
    if checkIfTaxi == isOnTaxi then return end
    isOnTaxi = checkIfTaxi
    self:SwitchedSubZones()
end

--@retail@
local covenantReps = {
    -- [Enum.CovenantType.None] = nil, -- don't assign a faction if the player isn't in a covenant
    [Enum.CovenantType.Kyrian] = 2407, -- The Ascended
    [Enum.CovenantType.Venthyr] = 2413, -- Court of Harvesters
    [Enum.CovenantType.NightFae] = 2422, -- Night Fae
    [Enum.CovenantType.Necrolord] = 2410, -- The Undying Army
}

function RepByZone:CovenantToFactionID(covenantID)
    local id = covenantID or C_Covenants.GetActiveCovenantID()
    return covenantReps[id]
end

function RepByZone:CheckPandaren(self, success)
    if success then
        local A = UnitFactionGroup("player") == "Alliance" and ALLIANCE
        local H = UnitFactionGroup("player") == "Horde" and HORDE
        if UnitFactionGroup("player") ~= nil then
            self.racialRepID, self.racialRepName = GetRacialRep()
            if db.watchedRepID == 1216 then
                db.watchedRepID, db.watchedRepName = GetRacialRep()
                self:Print(L["You have joined the faction %s, switching watched saved variable to %s."]:format(A or H, db.watchedRepName))
            end
            self:UnregisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
        end
    end
end

function RepByZone:JoinedCovenant(self, covenantID)
    self.covenantRepID = self:CovenantToFactionID(covenantID)
    self:SwitchedSubZones()
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
        end
    end
    self:CloseAllFactionHeaders()
end

-- Player switched zones, set watched faction
function RepByZone:SwitchedZones()
    local UImapID = IsInInstance() and select(8, GetInstanceInfo()) or C_Map.GetBestMapForUnit("player")
    local locationsAndFactions = IsInInstance() and self:InstancesAndFactionList() or self:ZoneAndFactionList()
    local watchedFactionID = db.watchedRepID or self.racialRepID

    for zoneID, factionID in pairs(locationsAndFactions) do
        if zoneID == UImapID then
            self:SetWatchedFactionByFactionID(factionID or watchedFactionID)
            break
        end
    end
end

-- Table to localize subzones that Blizzard does not provide areaIDs
local CitySubZonesAndFactions = CitySubZonesAndFactions or {
	-- ["Subzone"] = factionID
	["Dwarven District"] = 47, -- Ironforge
	["The Salty Sailor Tavern"] = 21, -- Booty Bay
	["Tinker Town"] = 54, -- Gnomeregan Exiles
	["Valley of Spirits"] = 530, -- Darkspear Trolls
	["Valley of Wisdom"] = 81, -- Thunder Bluff
}

-- Player entered a subzone, check if it has a faction
function RepByZone:SwitchedSubZones()
    if isOnTaxi and not db.watchOnTaxi then return end -- On taxi but don't watch
    local watchedFactionID = db.watchedRepID or self.racialRepID
    self:SwitchedZones() -- Now core zone next
    if not db.watchSubZones then return end

    local subZone = GetMinimapZoneText()
	-- Blizzard provided areaIDs
    for areaID, factionID in pairs(subZonesAndFactions) do
        if C_Map.GetAreaInfo(areaID) == subZone then
            self:SetWatchedFactionByFactionID(factionID or watchedFactionID)
            break
        end
    end
	-- Our localized missing Blizzard areaIDs
	for areaName, factionID in pairs(CitySubZonesAndFactions) do
		if L[areaName] == subZone then
			self:SetWatchedFactionByFactionID(factionID or watchedFactionID)
			break
		end
	end
end