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
                    defaultRep = {
                        order = 30,
                        name = L["Default watched faction"],
                        desc = "",
                        type = "select",
                        values = function() return self:GetAllFactions() end,
                        get = function() return db.defaultRepID end,
                        set = function(info, value)
                            db.defaultRepID = value
                        end
                    }
                }
            }
        }
    }
    return options
end