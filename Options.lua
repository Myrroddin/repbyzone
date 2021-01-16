local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")

function RepByZone:GetOptions()
    local db = self.db.char
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
                args = {
                    watchSubZones = {
                        order = 10,
                        name = L["Watch Subzones"],
                        desc = L["Switch watched faction based on subzones."],
                        descStyle = "inline",
                        type = "toggle",
                        width = "double",
                        get = function() return db.watchSubZones end,
                        set = function(info, value)
                            db.watchSubZones = value
                            if value then
                                self:RegisterEvent("ZONE_CHANGED", "SwitchedSubZones")
                                self:RegisterEvent("ZONE_CHANGED_INDOORS", "SwitchedSubZones")
                                self:SwitchedSubZones()
                            else
                                self:UnregisterEvent("ZONE_CHANGED")
                                self:UnregisterEvent("ZONE_CHANGED_INDOORS")
                            end
                        end
                    },
                    verbose = {
                        order = 20,
                        name = L["Verbose"],
                        desc = L["Print to chat when you switch watched faction."],
                        descStyle = "inline",
                        type = "toggle",
                        width = "double",
                        get = function() return db.verbose end,
                        set = function(info, value) db.verbose = value end
                    },
                    watchOnTaxi = {
                        order = 30,
                        name = L["Switch on taxi"],
                        desc = L["Switch watched faction while you are on a taxi."],
                        descStyle = "inline",
                        type = "toggle",
                        width = "double",
                        get = function() return db.watchOnTaxi end,
                        set = function(info, value) db.watchOnTaxi = value end
                    },
                    defaultRep = {
                        order = 100,
                        name = L["Default watched faction"],
                        desc = L["Defaults to your racial faction per character."],
                        type = "select",
                        values = function() return self:GetAllFactions() end,
                        get = function() return db.watchedRepID end,
                        set = function(info, value)
                            db.watchedRepID = value
                            db.watchedRepName = GetFactionInfoByID(value)
                        end
                    }
                }
            }
        }
    }
    return options
end