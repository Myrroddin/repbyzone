local RepByZone = LibStub("AceAddon-3.0"):GetAddon("RepByZone")
local L = LibStub("AceLocale-3.0"):GetLocale("RepByZone")
--@version-retail@
local media = LibStub("LibSharedMedia-3.0")
--@end-version-retail@

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
                        end
                    },
                    --@version-retail@
                    watchWoDBodyGuards = {
                        order = 100,
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
                            [579]       = C_Map.GetMapInfo(579).name .. " " .. LEVEL .. " " .. 1, -- Lunarfall Excavation 1
                            [580]       = C_Map.GetMapInfo(580).name .. " " .. LEVEL .. " " .. 2, -- Lunarfall Excavation 2
                            [581]       = C_Map.GetMapInfo(581).name .. " " .. LEVEL .. " " .. 3, -- Lunarfall Excavation 3
                            [582]       = C_Map.GetMapInfo(582).name, -- Lunarfall
                            [585]       = C_Map.GetMapInfo(585).name .. " " .. LEVEL .. " " .. 1, -- Frostwall Mine 1
                            [586]       = C_Map.GetMapInfo(586).name .. " " .. LEVEL .. " " .. 2, -- Frostwall Mine 2
                            [587]       = C_Map.GetMapInfo(587).name .. " " .. LEVEL .. " " .. 3, -- Frostwall Mine 3
                            [588]       = C_Map.GetMapInfo(588).name, -- Ashran
                            [590]       = C_Map.GetMapInfo(590).name, -- Frostwall
                            [622]       = C_Map.GetMapInfo(622).name, -- Stormshield
                        },
                        get = function(info, index)
                            local value = db.watchWoDBodyGuards[index]
                            if value then
                                self.WoDFollowerZones[index] = value
                            else
                                self.WoDFollowerZones[index] = nil
                            end
                            return db.watchWoDBodyGuards[index] and value
                        end,
                        set = function(info, index, value)
                            db.watchWoDBodyGuards[index] = value
                            if db.watchWoDBodyGuards[index] then
                                self.WoDFollowerZones[index] = value
                            else
                                self.WoDFollowerZones[index] = nil
                            end
                            self:SwitchedZones()
                        end
                    },
                    --@end-version-retail@
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
                            if db.watchedRepID == "0-none" then
                                db.watchedRepName = NONE
                            else
                                db.watchedRepName = GetFactionInfoByID(value)
                            end
                        end
                    }
                }
            }
        }
    }
    return options
end