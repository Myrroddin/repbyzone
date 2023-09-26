-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local DISABLE = DISABLE
local ENABLE = ENABLE
local GetFactionInfoByID = GetFactionInfoByID
local JUST_OR = JUST_OR
local LibStub = LibStub
local NONE = NONE
local type = type

------------------- Get addon reference --------------------
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")

function RepByZone:GetOptions()
    local db = self.db.profile
    local defaultRepID, defaultRepName
    defaultRepID, defaultRepName = self:GetRacialRep()
    db.watchedRepID = db.watchedRepID or defaultRepID
    db.watchedRepName = db.watchedRepName or defaultRepName
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
                    useFactionTabards = {
                        order = 50,
                        name = L["Faction Tabards Reputation"],
                        desc = L["Instead of older instance reputation, watch the equipped faction tabard instead."],
                        type = "toggle",
                        get = function () return db.useFactionTabards end,
                        set = function (info, value)
                            db.useFactionTabards = value
                            if value then
                                self:RegisterEvent("UNIT_INVENTORY_CHANGED", "GetEquippedTabard")
                                self:GetEquippedTabard()
                            else
                                self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
                                self:SwitchedZones()
                            end
                        end
                    },
                    delayGetFactionInfoByID = {
                        order = 90,
                        name = L["Delay Setting the Watched Faction"],
                        desc = L["Whenever the player changes locations, there is a delay by fractions of a second before data is available."],
                        type = "range",
                        width = 1.5,
                        get = function() return db.delayGetFactionInfoByID end,
                        set = function(info, value)
                            db.delayGetFactionInfoByID = value
                        end,
                        bigStep = 0.25,
                        min = 0.10,
                        max = 1.0,
                        softMin = 0.10,
                        softMax = 1.0,
                        step = 0.05
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