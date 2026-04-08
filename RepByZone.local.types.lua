---@meta

---@param factionID integer
---@return string? name
---@return string? description
---@return integer? standingID
---@return integer? barMin
---@return integer? barMax
---@return integer? barValue
---@return integer? atWarWith
---@return integer? canToggleAtWar
---@return boolean? isHeader
---@return boolean? isCollapsed
---@return boolean? hasRep
---@return boolean? isWatched
---@return integer? factionID
function GetFactionInfoByID(factionID) end

---@class RepByZoneProfile
---@field enabled boolean
---@field ignoreExaltedTabards boolean
---@field useFactionTabards boolean
---@field verbose boolean
---@field watchOnTaxi boolean
---@field watchSubZones boolean
---@field watchWoDBodyGuards table<integer, boolean>

---@class RepByZoneCharacterData
---@field watchedRepID integer|string?
---@field watchedRepName string?

---@class RepByZoneGlobalData
---@field delayGetFactionDataByID number

---@class RepByZoneSavedVariables
---@field profile RepByZoneProfile
---@field char RepByZoneCharacterData
---@field global RepByZoneGlobalData

---@class RepByZoneAddon : AceAddon
---@field db RepByZoneSavedVariables
---@field fallbackRepID integer
---@field WoDFollowerZones table<integer, boolean>
---@field GetAllFactions fun(self: RepByZoneAddon): table<integer|string, string>
---@field GetOptions fun(self: RepByZoneAddon): table
---@field GetRacialRep fun(self: RepByZoneAddon): integer?, string?
---@field PLAYER_ENTERING_WORLD fun(self: RepByZoneAddon, event: unknown?, isInitialLogin: boolean?, isReloadingUi: boolean?)
---@field RegisterEvent fun(self: RepByZoneAddon, event: string, method?: string)
---@field SwitchedZones fun(self: RepByZoneAddon)
---@field UnregisterEvent fun(self: RepByZoneAddon, event: string)
