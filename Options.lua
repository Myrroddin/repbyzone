local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")

function RepByZone:GetOptions()
    local db = self.db.profile
    self.racialRepID, self.racialRepName = self:GetRacialRep()
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
                        get = function() return db.watchSubZones end,
                        set = function(info, value)
                            db.watchSubZones = value
                            if value then
                                self:RegisterEvent("ZONE_CHANGED")
                                self:RegisterEvent("ZONE_CHANGED_INDOORS")
                                self:SwitchedZones()
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
                        get = function() return db.verbose end,
                        set = function(info, value) db.verbose = value end
                    },
                    watchOnTaxi = {
                        order = 30,
                        name = L["Switch on taxi"],
                        desc = L["Switch watched faction while you are on a taxi."],
                        descStyle = "inline",
                        type = "toggle",
                        get = function() return db.watchOnTaxi end,
                        set = function(info, value)
                            db.watchOnTaxi = value
                        end
                    },
                    useClassRep = {
                        order = 40,
                        name = L["Override some default racial reps with class reps."],
                        desc = function() return (L["Your class reputation is %s"]):format(self.racialRepName) end,
                        descStyle = "inline",
                        type = "toggle",
                        get = function() return db.useClassRep end,
                        set = function(info, value)
                            db.useClassRep = value
                            self.racialRepID, self.racialRepName = self:GetRacialRep()
                            self:SwitchedZones()
                        end
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
                            if db.watchedRepID == "0-none" then
                                db.watchedRepName = NONE
                            else
                                db.watchedRepName = GetFactionInfoByID(value)
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