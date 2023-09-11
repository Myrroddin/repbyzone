-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local _G = _G
local DISABLE = _G.DISABLE
local ENABLE = _G.ENABLE
local GetFactionInfoByID = _G.GetFactionInfoByID
local JUST_OR = _G.JUST_OR
local LibStub = _G.LibStub
local NONE = _G.NONE
local type = _G.type

------------------- Get addon reference --------------------
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")

function RepByZone:GetOptions()
    local db = self.db.profile
    self:GetRacialRep()
    local options = {
        name = "RepByZone",
        handler = RepByZone,
        type = "group",
        childGroups = "tab",
        args = {
            enableDisable = {
                order = 10,
                name = ENABLE .. " " .. JUST_OR .. " " .. DISABLE,
                desc = L["Toggle RepByZone on or off."],
                descStyle = "inline",
                type = "toggle",
                width = "full",
                get = function() return db.enabled end,
                set = function(info, value)
                    db.enabled = value
                    if value then
                        self:OnEnable()
                    else
                        self:OnDisable()
                    end
                end
            },
            factionStuff = {
                order = 20,
                name = L["Reputation Settings"],
                type = "group",
                disabled = function() return not db.enabled end,
                args = {
                    watchSubZones = {
                        order = 10,
                        name = L["Watch Subzones"],
                        desc = L["Switch watched faction based on subzones."],
                        type = "toggle",
                        get = function() return db.watchSubZones end,
                        set = function(info, value)
                            db.watchSubZones = value
                            if value then
                                self:RegisterEvent("ZONE_CHANGED", "SwitchedZones")
                                self:RegisterEvent("ZONE_CHANGED_INDOORS", "SwitchedZones")
                            else
                                self:UnregisterEvent("ZONE_CHANGED")
                                self:UnregisterEvent("ZONE_CHANGED_INDOORS")
                            end
                            self:SwitchedZones()
                        end
                    },
                    verbose = {
                        order = 20,
                        name = L["Verbose"],
                        desc = L["Print to chat when you switch watched faction."],
                        type = "toggle",
                        get = function() return db.verbose end,
                        set = function(info, value) db.verbose = value end
                    },
                    watchOnTaxi = {
                        order = 30,
                        name = L["Switch on taxi"],
                        desc = L["Switch watched faction while you are on a taxi."],
                        type = "toggle",
                        get = function() return db.watchOnTaxi end,
                        set = function(info, value)
                            db.watchOnTaxi = value
                        end
                    },
                    useClassRep = {
                        order = 40,
                        name = L["Override some default racial reps with class reps."],
                        desc = function()
                            if self.racialRepName == nil then
                                self:GetRacialRep()
                            end
                            return (L["Your class reputation is %s"]):format(self.racialRepName)
                        end,
                        type = "toggle",
                        width = "double",
                        get = function() return db.useClassRep end,
                        set = function(info, value)
                            db.useClassRep = value
                            self:GetRacialRep()
                            self:SwitchedZones()
                        end
                    },
                    useFactionTabards = {
                        order = 50,
                        name = L["Faction Tabards Reputation"],
                        desc = L["Instead of older instance reputation, watch the equipped faction tabard instead."],
                        type = "toggle",
                        get = function () return db.useFactionTabards end,
                        set = function (info, value)
                            db.useFactionTabards = value
                            self:SwitchedZones()
                        end
                    },
                    defaultRep = {
                        order = 200,
                        name = L["Default watched faction"],
                        desc = L["Defaults to your racial faction per character."],
                        type = "select",
                        width = 1.5,
                        values = function() return self:GetAllFactions() end,
                        get = function()
                            if db.watchedRepID == nil then
                                db.watchedRepID, db.watchedRepName = self:GetRacialRep()
                            end
                            return db.watchedRepID
                        end,
                        set = function(info, value)
                            db.watchedRepID = value
                            if type(value) == "number" then
                                db.watchedRepName = GetFactionInfoByID(value)
                            elseif type(value) == "string" then
                                db.watchedRepName = NONE
                            else
                                db.watchedRepID, db.watchedRepName = self:GetRacialRep()
                            end
                            self:SwitchedZones()
                        end
                    }
                }
            }
        }
    }
    return options
end