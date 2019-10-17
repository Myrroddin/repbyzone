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
local isOnTaxi = false

-- Get the character's racial factionID and factionName
local function GetRacialRep()
    local _, playerRace = UnitRace("player")
    local racialRepID = playerRace == "Dwarf" and 47
    or playerRace == "Gnome" and 54
    or playerRace == "Human" and 72
    or playerRace == "NightElf" and 69
    or playerRace == "Orc" and 76
    or playerRace == "Tauren" and 81
    or playerRace == "Troll" and 530
    or playerRace == "Scourge" and 68

    local racialRepName = GetFactionInfoByID(racialRepID)
    return racialRepID, racialRepName
end

function RepByZone:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("RepByZoneDB", defaults, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    self:SetEnabledState(self.db.char.enabled)
    db = self.db.char

    zonesAndFactions = self:ZoneAndFactionList() -- Data.lua
    instancesAndFactions = self:InstancesAndFactionList() -- Data.lua
    subZonesAndFactions = self:SubZonesAndFactions() -- Data.lua

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
    local racialRepID, racialRepName = GetRacialRep()
    db.defaultRepID = db.defaultRepID or racialRepID
    db.defaultRepName = db.defaultRepName or racialRepName

    if UnitOnTaxi("player") then
        isOnTaxi = true
    end

   -- Set initial watched faction correctly during login
    self:SwitchedZones()
end

function RepByZone:OnEnable()
    -- Set initial watched faction correctly during login
    self:SwitchedZones()
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "SwitchedZones")
    self:RegisterEvent("ZONE_CHANGED", "SwitchedSubZones")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "SwitchedSubZones")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat")
    self:RegisterEvent("ACTIONBAR_UPDATE_USABLE", "CheckTaxi")
end

function RepByZone:OnDisable()
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("ZONE_CHANGED")
    self:UnregisterEvent("ZONE_CHANGED_INDOORS")
    self:UnregisterEvent("ACTIONBAR_UPDATE_USABLE")
end

function RepByZone:RefreshConfig()
    db = self.db.char
end

function RepByZone:SlashHandler()
    if UnitAffectingCombat("player") then
        if Dialog.OpenFrames["RepByZone"] then
            Dialog:Close("RepByZone")
        end
        return
    end

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
end

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
        -- self:Print("DEBUG: SetWatchedFactionByFactionID name:", name)
        -- self:Print("DEBUG: SetWatchedFactionByFactionID index:", i)
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
    if isOnTaxi and not db.watchOnTaxi then return end -- on taxi but don't watch

    local UImapID = IsInInstance() and select(8, GetInstanceInfo()) or C_Map.GetBestMapForUnit("player")
    local locationsAndFactions = IsInInstance() and self:InstanceAndFactionList() or self:ZoneAndFactionList()
    -- self:Print("DEBUG: Current UImapID is", UImapID)
    for zoneID, factionID in pairs(locationsAndFactions) do
        if zoneID == UImapID then
            -- self:Print("DEBUG: zoneID and UImapID match")
            self:SetWatchedFactionByFactionID(factionID)
            break
        end
    end
end

-- Player entered a subzone, check if it has a faction
function RepByZone:SwitchedSubZones()
    if not db.watchSubZones then return end
    if isOnTaxi and not db.watchOnTaxi then return end -- on taxi but don't watch

    self:SwitchedZones()
    local subZone = GetSubZoneText()
    for babbleSubZone, factionID in pairs(subZonesAndFactions) do
        if babbleSubZone == subZone then
            self:SetWatchedFactionByFactionID(factionID)
        end
    end
end