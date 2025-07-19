---@diagnostic disable: duplicate-set-field, undefined-global
-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local DISABLE = DISABLE
local ENABLE = ENABLE
local GetFactionInfoByID = GetFactionInfoByID
local JUST_OR = JUST_OR
local LibStub = LibStub
local NONE = NONE
local type = type

------------------- Get addon reference --------------------
---@class RepByZone: AceAddon, AceEvent-3.0, AceConsole-3.0
local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")

function RepByZone:GetOptions()
    local db = self.db
    local defaultRepID, defaultRepName = self:GetRacialRep()
    db.char.watchedRepID = db.char.watchedRepID or defaultRepID
    db.char.watchedRepName = db.char.watchedRepName or defaultRepName
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
                get = function() return db.profile.enabled end,
                set = function(_, value)
                    db.profile.enabled = value
                    if value then
                        self:Enable()
                        self:PLAYER_ENTERING_WORLD(_, true) -- Force an update of the saved variables
                    else
                        self:Disable()
                    end
                end
            },
            factionStuff = {
                order = 20,
                name = L["Reputation Settings"],
                type = "group",
                disabled = function() return not db.profile.enabled end,
                args = {
                    watchSubZones = {
                        order = 10,
                        name = L["Watch Subzones"],
                        desc = L["Switch watched faction based on subzones."],
                        type = "toggle",
                        get = function() return db.profile.watchSubZones end,
                        set = function(_, value)
                            db.profile.watchSubZones = value
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
                        get = function() return db.profile.verbose end,
                        set = function(_, value) db.profile.verbose = value end
                    },
                    watchOnTaxi = {
                        order = 30,
                        name = L["Switch on taxi"],
                        desc = L["Switch watched faction while you are on a taxi."],
                        type = "toggle",
                        get = function() return db.profile.watchOnTaxi end,
                        set = function(_, value)
                            db.profile.watchOnTaxi = value
                        end
                    },
                    useFactionTabards = {
                        order = 40,
                        name = L["Faction Tabards Reputation"],
                        desc = L["Instead of older instance reputation, watch the equipped faction tabard instead."],
                        type = "toggle",
                        width = 1.5,
                        get = function () return db.profile.useFactionTabards end,
                        set = function (_, value)
                            db.profile.useFactionTabards = value
                            if value then
                                self:RegisterEvent("UNIT_INVENTORY_CHANGED", "GetEquippedTabard")
                            else
                                self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
                            end
                            self:SwitchedZones()
                        end
                    },
                    ignoreExaltedTabards = {
                        order = 50,
                        name = L["Ignore Exalted Faction Tabards"],
                        desc = L["Stop watching dungeon tabards at Exalted"],
                        type = "toggle",
                        width = 1.5,
                        disabled = function() return not db.profile.useFactionTabards end,
                        get = function() return db.profile.ignoreExaltedTabards end,
                        set = function(_, value)
                            db.profile.ignoreExaltedTabards = value
                            self:SwitchedZones()
                        end
                    },
                    delayGetFactionDataByID = {
                        order = 90,
                        name = L["Delay Setting the Watched Faction"],
                        desc = L["Whenever the player changes locations, there is a delay by fractions of a second before data is available."],
                        type = "range",
                        width = 1.5,
                        get = function() return db.global.delayGetFactionDataByID end,
                        set = function(_, value)
                            db.global.delayGetFactionDataByID = value
                        end,
                        bigStep = 0.25,
                        min = 0.10,
                        max = 1.0,
                        softMin = 0.10,
                        softMax = 1.0,
                        step = 0.05
                    },
                    defaultRep = {
                        order = 110,
                        name = L["Default watched faction"],
                        desc = L["Defaults to your racial faction per character."],
                        type = "select",
                        width = 1.5,
                        values = function() return self:GetAllFactions() end,
                        get = function()
                            if db.char.watchedRepID == nil then
                                db.char.watchedRepID, db.char.watchedRepName = self:GetRacialRep()
                            end
                            return db.char.watchedRepID
                        end,
                        set = function(_, value)
                            db.char.watchedRepID = value
                            db.char.watchedRepName = type(value) == "number" and GetFactionInfoByID(value) or NONE
                            self.fallbackRepID = type(value) == "number" and value or 0
                            self:SwitchedZones()
                        end
                    }
                }
            }
        }
    }
    return options
end