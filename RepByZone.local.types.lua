---@meta

---@alias RepByZoneFactionSelection integer|string
---@alias RepByZoneFactionList table<RepByZoneFactionSelection, string>
---@alias RepByZoneBooleanLookup table<integer|string, boolean>

---@param factionIndex integer
---@return string? name
---@return string? description
---@return integer? standingID
---@return integer? barMin
---@return integer? barMax
---@return integer? barValue
---@return boolean? atWarWith
---@return boolean? canToggleAtWar
---@return boolean? isHeader
---@return boolean? isCollapsed
---@return boolean? hasRep
---@return boolean? isWatched
---@return boolean? isChild
---@return integer? factionID
function GetFactionInfo(factionIndex) end

---@param factionID integer
---@return string? name
---@return string? description
---@return integer? standingID
---@return integer? barMin
---@return integer? barMax
---@return integer? barValue
---@return boolean? atWarWith
---@return boolean? canToggleAtWar
---@return boolean? isHeader
---@return boolean? isCollapsed
---@return boolean? hasRep
---@return boolean? isWatched
---@return integer? factionID
function GetFactionInfoByID(factionID) end

---@param factionIndex integer
function CollapseFactionHeader(factionIndex) end

---@param factionIndex integer
function ExpandFactionHeader(factionIndex) end

---@return integer
function GetNumFactions() end

---@param factionIndex integer
function SetWatchedFactionIndex(factionIndex) end

---@class RepByZoneProfile
---@field enabled boolean
---@field verbose boolean
---@field watchOnTaxi boolean
---@field watchSubZones boolean
---@field ignoreExaltedTabards boolean
---@field useFactionTabards boolean
---@field watchWoDBodyGuards RepByZoneBooleanLookup

---@class RepByZoneCharacterData
---@field watchedRepID RepByZoneFactionSelection?
---@field watchedRepName string?

---@class RepByZoneGlobalData
---@field delayGetFactionDataByID number
---@field initialized boolean?
---@field current_db_version integer?

---@class RepByZoneSavedVariables
---@field profile RepByZoneProfile
---@field char RepByZoneCharacterData
---@field global RepByZoneGlobalData

---@class RepByZoneDatabase : RepByZoneSavedVariables
---@field RegisterCallback fun(target: table, eventName: string, methodName: string)
---@field RegisterDefaults fun(self: RepByZoneDatabase, defaults: RepByZoneSavedVariables)
---@field ResetDB fun(self: RepByZoneDatabase, noChildren?: boolean)

---@class RepByZoneAddon : AceAddon
---@field db RepByZoneDatabase
---@field fallbackRepID integer?
---@field racialRepID integer?
---@field covenantRepID integer?
---@field dragonflightRepID integer?
---@field WoDFollowerZones table<integer, boolean>
---@field tabardExemptDungeons table<integer, boolean>
---@field AboutOptionsTable fun(self: RepByZoneAddon, addonName: string): table
---@field CheckTaxi fun(self: RepByZoneAddon)
---@field CloseAllFactionHeaders fun(self: RepByZoneAddon)
---@field CovenantToFactionID fun(self: RepByZoneAddon): integer?
---@field Disable fun(self: RepByZoneAddon)
---@field Enable fun(self: RepByZoneAddon)
---@field GetActiveBodyguardRepID fun(self: RepByZoneAddon): integer?
---@field GetAllFactions fun(self: RepByZoneAddon): RepByZoneFactionList
---@field GetCovenantRep fun(self: RepByZoneAddon)
---@field GetEquippedTabard fun(self: RepByZoneAddon, event?: string, unit?: string)
---@field GetMultiRepIDsForZones fun(self: RepByZoneAddon)
---@field GetOptions fun(self: RepByZoneAddon): table
---@field GetPandarenRep fun(self: RepByZoneAddon, event?: string, success?: boolean)
---@field GetRacialRep fun(self: RepByZoneAddon): integer?, string?
---@field GetWrathionOrSabellianRep fun(self: RepByZoneAddon)
---@field InstancesAndFactionList fun(self: RepByZoneAddon): table<integer, integer>
---@field OpenAllFactionHeaders fun(self: RepByZoneAddon)
---@field PLAYER_ENTERING_WORLD fun(self: RepByZoneAddon, event?: string, isInitialLogin?: boolean, isReloadingUi?: boolean)
---@field Print fun(self: RepByZoneAddon, message: string)
---@field RefreshConfig fun(self: RepByZoneAddon, callback?: string)
---@field RegisterChatCommand fun(self: RepByZoneAddon, command: string, method: string)
---@field RegisterEvent fun(self: RepByZoneAddon, event: string, method?: string)
---@field SetEnabledState fun(self: RepByZoneAddon, enabled: boolean)
---@field SetUpVariables fun(self: RepByZoneAddon)
---@field SlashHandler fun(self: RepByZoneAddon)
---@field SubZonesAndFactionsList fun(self: RepByZoneAddon): table<string, integer>
---@field SwitchedZones fun(self: RepByZoneAddon, event?: string)
---@field UnregisterAllEvents fun(self: RepByZoneAddon)
---@field UnregisterEvent fun(self: RepByZoneAddon, event: string)
---@field UpdateActiveBodyguardRepID fun(self: RepByZoneAddon)
---@field ZoneAndFactionList fun(self: RepByZoneAddon): table<integer, integer>
