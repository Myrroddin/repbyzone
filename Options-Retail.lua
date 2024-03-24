-- Grab local references to global variables. We are trading RAM to decrease CPU usage and hopefully increase FPS
local C_Map = C_Map
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
                set = function(info, value)
                    db.profile.enabled = value
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
                disabled = function() return not db.profile.enabled end,
                args = {
                    watchSubZones = {
                        order = 10,
                        name = L["Watch Subzones"],
                        desc = L["Switch watched faction based on subzones."],
                        type = "toggle",
                        get = function() return db.profile.watchSubZones end,
                        set = function(info, value)
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
                        set = function(info, value) db.profile.verbose = value end
                    },
                    watchOnTaxi = {
                        order = 30,
                        name = L["Switch on taxi"],
                        desc = L["Switch watched faction while you are on a taxi."],
                        type = "toggle",
                        get = function() return db.profile.watchOnTaxi end,
                        set = function(info, value)
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
                        set = function (info, value)
                            db.profile.useFactionTabards = value
                            if value then
                                self:RegisterEvent("UNIT_INVENTORY_CHANGED", "GetEquippedTabard")
                                self:GetEquippedTabard()
                            else
                                self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
                                self:GetEquippedTabard()
                            end
                            self:SwitchedZones()
                        end
                    },
                    delayGetFactionInfoByID = {
                        order = 90,
                        name = L["Delay Setting the Watched Faction"],
                        desc = L["Whenever the player changes locations, there is a delay by fractions of a second before data is available."],
                        type = "range",
                        width = 1.5,
                        get = function() return db.profile.delayGetFactionInfoByID end,
                        set = function(info, value)
                            db.profile.delayGetFactionInfoByID = value
                        end,
                        bigStep = 0.25,
                        min = 0.10,
                        max = 1.0,
                        softMin = 0.10,
                        softMax = 1.0,
                        step = 0.05
                    },
                    delayListUpdates = {
                        order = 100,
                        name = L["Delay data updates"],
                        desc = L["The Waking Shores data could slow down if you gain a lot of reputation quickly. Delay the updates."],
                        type = "range",
                        width = 1.5,
                        get = function() return db.profile.delayListUpdates end,
                        set = function(info, value)
                            db.profile.delayListUpdates = value
                        end,
                        bigStep = 5,
                        min = 3,
                        max = 30,
                        softMin = 3,
                        softMax = 30,
                        step = 1
                    },
                    watchWoDBodyGuards = {
                        order = 110,
                        name = L["Watch WoD garrison bodyguard faction."],
                        desc = L["This prefers the bodyguard reputation over zone or subzone reputations for Warlords of Draenor content."],
                        type = "multiselect",
                        dialogControl = "Dropdown",
                        width = 1.5,
                        values = {
                            [525]       = C_Map.GetMapInfo(525).name, -- Frostfire Ridge
                            [534]       = C_Map.GetMapInfo(534).name, -- Tanaan Jungle
                            [535]       = C_Map.GetMapInfo(535).name, -- Talador
                            [539]       = C_Map.GetMapInfo(539).name, -- Shadowmoon Valley
                            [542]       = C_Map.GetMapInfo(542).name, -- Spires of Arak
                            [543]       = C_Map.GetMapInfo(543).name, -- Gorgrond
                            [550]       = C_Map.GetMapInfo(550).name, -- Nagrand
                            [582]       = C_Map.GetMapInfo(582).name, -- Lunarfall
                            [590]       = C_Map.GetMapInfo(590).name, -- Frostwall
                        },
                        get = function(info, index)
                            local value = db.profile.watchWoDBodyGuards[index]
                            self.WoDFollowerZones[index] = value
                            return db.profile.watchWoDBodyGuards[index] and value
                        end,
                        set = function(info, index, value)
                            db.profile.watchWoDBodyGuards[index] = value
                            self.WoDFollowerZones[index] = value
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
                            if db.char.watchedRepID == nil then
                                db.char.watchedRepID, db.char.watchedRepName = self:GetRacialRep()
                            end
                            return db.char.watchedRepID
                        end,
                        set = function(info, value)
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