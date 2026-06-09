--[[
LibAboutPanel-2.0: WoW Lua library for displaying addon metadata in Blizzard's Options and AceConfig-3.0-compatible tables.
This file contains the core implementation, inline localization table, and public API annotations.
--]]

assert(LibStub, "LibAboutPanel-2.0 requires LibStub")

---@class LibAboutPanel-2.0.AceOption
---@field order integer
---@field name string
---@field type "description"|"input"
---@field desc string?
---@field fontSize "small"|"medium"|"large"?
---@field width "full"|number?
---@field get fun(): string?

---@class LibAboutPanel-2.0.AceOptionsTable
---@field name string
---@field type "group"
---@field args table<string, LibAboutPanel-2.0.AceOption>

---@class LibAboutPanel-2.0.AboutFrame : Frame
---@field name string
---@field parent string?

---@class LibAboutPanel-2.0: table
---@field embeds table<table, true> Tracks addon tables this library has been embedded into.
---@field aboutTable table<string, LibAboutPanel-2.0.AceOptionsTable> Cached AceConfig-compatible options tables, keyed by addon name.
---@field aboutFrame table<string, LibAboutPanel-2.0.AboutFrame> Cached Blizzard Settings frames, keyed by addon name.
---@field editbox EditBox Shared editbox used by clickable copy fields.
---@field CreateAboutPanel fun(self: LibAboutPanel-2.0, addon: string, parent?: string): LibAboutPanel-2.0.AboutFrame
---@field AboutOptionsTable fun(self: LibAboutPanel-2.0, addon: string): LibAboutPanel-2.0.AceOptionsTable
---@field Embed fun(self: LibAboutPanel-2.0, target: table): table
local lib = LibStub:NewLibrary("LibAboutPanel-2.0", 118)
if not lib then return end

-- Localize frequently used Lua and WoW API functions for performance.
local pairs, strmatch = pairs, strmatch
local format, gsub, tostring, upper, lower = string.format, string.gsub, tostring, string.upper, string.lower
local GetLocale, CreateFrame = GetLocale, CreateFrame
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata -- retrieves .toc metadata like Title, Notes, Author, etc.

-- Localization shim: returns the key itself if no translation exists.
---@type table<string, string>
local L = setmetatable({}, {
	---@param t table<string, string>
	---@param k string
	---@return string
	__index = function(t, k)
		local v = tostring(k)
		rawset(t, k, v)
		return v
	end
})

local locale = GetLocale() -- current game client locale

-- Inline localization blocks.
-- These packager tokens intentionally live in this file so the library can ship as a single Lua file.
if locale == "deDE" then
--@localization(locale="deDE", format="lua_additive_table")@
elseif locale == "esES" then
--@localization(locale="esES", format="lua_additive_table")@
elseif locale == "esMX" then
--@localization(locale="esMX", format="lua_additive_table")@
elseif locale == "frFR" then
--@localization(locale="frFR", format="lua_additive_table")@
elseif locale == "itIT" then
--@localization(locale="itIT", format="lua_additive_table")@
elseif locale == "koKR" then
--@localization(locale="koKR", format="lua_additive_table")@
elseif locale == "ptBR" then
--@localization(locale="ptBR", format="lua_additive_table")@
elseif locale == "ruRU" then
--@localization(locale="ruRU", format="lua_additive_table")@
elseif locale == "zhCN" then
--@localization(locale="zhCN", format="lua_additive_table")@
elseif locale == "zhTW" then
--@localization(locale="zhTW", format="lua_additive_table")@
end

-- Persistent tables: preserve state across library upgrades and allow caching for performance.
lib.embeds		= lib.embeds or {}
lib.aboutTable	= lib.aboutTable or {}
lib.aboutFrame	= lib.aboutFrame or {}

-- -----------------------------------------------------
-- Helper functions to standardize metadata lookups and parsing from .toc files.
-- -----------------------------------------------------

-- Converts a string to title case (e.g., "john DOE" -> "John Doe").
---@param str string
---@return string
local function TitleCase(str)
	return gsub(str, "(%a)(%a+)", function(a, b)
		return upper(a) .. lower(b)
	end)
end

-- Removes leading and trailing whitespace.
---@param text string?
---@return string?
local function Trim(text)
	if not text then return end
	return text:gsub("^%s+", ""):gsub("%s+$", "")
end

-- Normalizes whitespace and removes hidden newline characters.
---@param text string?
---@return string?
local function NormalizeWhitespace(text)
	if not text then return end

	-- Remove CR/LF from .toc metadata.
	text = text:gsub("[\r\n]", "")

	-- Trim edges.
	text = Trim(text)

	-- Collapse internal whitespace.
	text = text and text:gsub("%s+", " ")

	return text
end

-- Fetches metadata from the addon .toc, using localized fields if available.
---@param addon string
---@param field string
---@param localized boolean?
---@return string?
local function GetMeta(addon, field, localized)
	if localized and locale ~= "enUS" then
		local v = GetAddOnMetadata(addon, field .. "-" .. locale)
		if v then return v end
	end
	return GetAddOnMetadata(addon, field)
end

---@param addon string
---@return string?
local function GetTitle(addon)
	local title = GetMeta(addon, "Title", true)
	return NormalizeWhitespace(title)
end

---@param addon string
---@return string?
local function GetNotes(addon)
	local notes = GetMeta(addon, "Notes", true)
	return NormalizeWhitespace(notes)
end

---@param addon string
---@return string?
local function GetCredits(addon)
	local credits = GetAddOnMetadata(addon, "X-Credits")
	return NormalizeWhitespace(credits)
end

-- Retrieves category field from .toc.
---@param addon string
---@return string?
local function GetCategory(addon)
	local category = GetMeta(addon, "Category", true)

	if not category then
		category = GetMeta(addon, "X-Category", true)
	end

	return NormalizeWhitespace(category)
end

-- Parses and normalizes date fields from .toc, handling repo keyword expansion.
---@param addon string
---@return string?
local function GetAddOnDate(addon)
	local date = GetAddOnMetadata(addon, "X-Date") or GetAddOnMetadata(addon, "X-ReleaseDate")
	if not date then return end

	date = date:gsub("%$Date: (.-) %$", "%1")
	date = date:gsub("%$LastChangedDate: (.-) %$", "%1")

	return NormalizeWhitespace(date)
end

-- Formats author field, appending guild/server/faction info if present.
---@param addon string
---@return string?
local function GetAuthor(addon)
	local author = GetAddOnMetadata(addon, "Author")
	if not author then return end
	author = TitleCase(author)

	local server	= GetAddOnMetadata(addon, "X-Author-Server")
	local guild		= GetAddOnMetadata(addon, "X-Author-Guild")
	local faction	= GetAddOnMetadata(addon, "X-Author-Faction")

	if server then
		author = author .. " " .. format(L["on the %s realm"], TitleCase(server)) .. "."
	end
	if guild then
		author = author .. " <" .. guild .. ">"
	end
	if faction then
		faction = TitleCase(faction)
		faction = gsub(faction, "Alliance", FACTION_ALLIANCE)
		faction = gsub(faction, "Horde", FACTION_HORDE)
		author = author .. " (" .. faction .. ")"
	end

	return NormalizeWhitespace(author)
end

-- Parses version field, handling repo keywords and developer build tags.
---@param addon string
---@return string?
local function GetVersion(addon)
	local version = GetAddOnMetadata(addon, "Version")
	if not version then return end

	version = gsub(version, "%.?%$Revision: (%d+) %$", " -rev.%1")
	version = gsub(version, "%.?%$Rev: (%d+) %$", " -rev.%1")
	version = gsub(version, "%.?%$LastChangedRevision: (%d+) %$", " -rev.%1")
	version = gsub(version, "r2", L["Repository"])
	version = gsub(version, "wowi:revision", L["Repository"])
	version = gsub(version, "@.+", L["Developer Build"])

	local revision = GetAddOnMetadata(addon, "X-Project-Revision")
	if revision then version = version .. " -rev." .. revision end

	return NormalizeWhitespace(version)
end

-- Normalizes and translates license/copyright fields.
---@param addon string
---@return string?
local function GetLicense(addon)
	local license = GetAddOnMetadata(addon, "X-License") or GetAddOnMetadata(addon, "X-Copyright")
	if not license then return end

	-- Preserve known license identifiers.
	if not (strmatch(license, "^MIT%f[%A]") or strmatch(license, "^GNU%f[%A]")) then
		license = TitleCase(license)
	end

	-- Normalize copyright keyword.
	license = gsub(license, "[cC]opyright", L["Copyright"] .. " ©")

	-- Normalize (c) markers.
	license = gsub(license, "%([cC]%)", "©")

	-- Remove duplicate symbols.
	license = gsub(license, "©%s*©", "©")

	-- Normalize spacing.
	license = gsub(license, "%s+", " ")

	-- Normalize "All Rights Reserved".
	license = gsub(license, "[aA]ll%s+[rR]ights%s+[rR]eserved", L["All Rights Reserved"])

	return NormalizeWhitespace(license)
end

-- Maps locale abbreviations to Blizzard's global language constants.
---@type table<string, string>
local localeMap = {
	["enUS"] = LFG_LIST_LANGUAGE_ENUS, ["deDE"] = LFG_LIST_LANGUAGE_DEDE,
	["esES"] = LFG_LIST_LANGUAGE_ESES, ["esMX"] = LFG_LIST_LANGUAGE_ESMX,
	["frFR"] = LFG_LIST_LANGUAGE_FRFR, ["itIT"] = LFG_LIST_LANGUAGE_ITIT,
	["koKR"] = LFG_LIST_LANGUAGE_KOKR, ["ptBR"] = LFG_LIST_LANGUAGE_PTBR,
	["ruRU"] = LFG_LIST_LANGUAGE_RURU, ["zhCN"] = LFG_LIST_LANGUAGE_ZHCN,
	["zhTW"] = LFG_LIST_LANGUAGE_ZHTW
}

---@param addon string
---@return string?
local function GetLocalizations(addon)
	local translations = GetAddOnMetadata(addon, "X-Localizations")
	if translations then
		for k, v in pairs(localeMap) do
			translations = translations:gsub(k, v)
		end
	end
	return NormalizeWhitespace(translations)
end

-- Retrieves website and email fields, formatting for display/copy.
---@param addon string
---@return string?
local function GetWebsite(addon)
	local site = GetAddOnMetadata(addon, "X-Website")
	if not site then return end

	local normalizedSite = NormalizeWhitespace(site)
	if not normalizedSite then return end

	return "|cff77ccff" .. gsub(normalizedSite, "https?://", "")
end

---@param addon string
---@return string?
local function GetEmail(addon)
	local email = GetAddOnMetadata(addon, "X-Email") or GetAddOnMetadata(addon, "Email") or GetAddOnMetadata(addon, "eMail")
	if not email then return end

	local normalizedEmail = NormalizeWhitespace(email)
	if not normalizedEmail then return end

	return "|cff77ccff" .. normalizedEmail
end

-- -----------------------------------------------------
-- Shared editbox UI for copying fields (email, website) in About panel.
-- -----------------------------------------------------

---@class LibAboutPanel-2.0.CopyButton : Button
---@field value string

---@type EditBox
local editbox = CreateFrame("EditBox", nil, nil, "InputBoxTemplate")
editbox:Hide()
editbox:SetFontObject("GameFontHighlightSmall")
editbox:SetScript("OnEscapePressed", editbox.Hide)
editbox:SetScript("OnEnterPressed", editbox.Hide)
editbox:SetScript("OnEditFocusLost", editbox.Hide)
editbox:SetScript("OnEditFocusGained", editbox.HighlightText)
editbox:SetScript("OnTextChanged", function(self)
	self:SetText(self:GetParent().value) -- always reset to original
	self:HighlightText() -- auto-select text for copy
end)
lib.editbox = editbox

---@param self LibAboutPanel-2.0.CopyButton
local function OpenEditbox(self)
	editbox:SetParent(self)
	editbox:SetAllPoints(self)
	editbox:SetText(self.value)
	editbox:Show()
end

---@param self Frame
local function ShowTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText(L["Click and press Ctrl-C to copy"])
end

local function HideTooltip()
	GameTooltip:Hide()
end

-- -----------------------------------------------------
-- Creates the About panel in Blizzard's Interface Options / Settings UI.
-- -----------------------------------------------------

---Creates and caches a Blizzard Settings about panel for an addon.
---
---The addon parameter should be the addon's folder/.toc name. If parent is provided,
---the panel is registered as a child "About" panel under that parent addon.
---@param addon string Addon folder/.toc name.
---@param parent string? Parent addon name for child panels.
---@return LibAboutPanel-2.0.AboutFrame frame The created or cached about panel frame.
function lib:CreateAboutPanel(addon, parent)
	if addon == self then
		error("LibAboutPanel-2.0: 'addon' must be the addon's folder/.toc name, not self.", 2)
	end

	addon = addon:gsub(" ", "") -- some APIs don't like spaces in addon name
	addon = parent or addon

	local frame = lib.aboutFrame[addon]
	if frame then return frame end -- reuse cached

	frame = CreateFrame("Frame", addon.."AboutPanel", UIParent)
	---@cast frame LibAboutPanel-2.0.AboutFrame
	local title_str = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title_str:SetPoint("TOPLEFT", 16, -16)
	title_str:SetText((parent and GetTitle(addon) or addon) .. " - " .. L["About"])

	-- Add notes paragraph if present.
	local notes = GetNotes(addon)
	local notes_str
	if notes then
		notes_str = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		notes_str:SetHeight(32)
		notes_str:SetPoint("TOPLEFT", title_str, "BOTTOMLEFT", 0, -8)
		notes_str:SetPoint("RIGHT", frame, -32, 0)
		notes_str:SetNonSpaceWrap(true)
		notes_str:SetJustifyH("LEFT")
		notes_str:SetText(notes)
	end

	-- Dynamically stack info fields.
	local i = 0
	local prev_label = nil

	---@param field string
	---@param text string?
	---@param editable boolean?
	local function SetAboutInfo(field, text, editable)
		if not text then return end
		i = i + 1
		local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", (i == 1 and (notes and notes_str or title_str) or prev_label), "BOTTOMLEFT", i == 1 and -2 or 0, -10)
		label:SetWidth(80)
		label:SetJustifyH("RIGHT")
		label:SetText(field)
		prev_label = label

		local detail = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		detail:SetPoint("TOPLEFT", label, "TOPRIGHT", 4, 0)
		detail:SetPoint("RIGHT", frame, -16, 0)
		detail:SetJustifyH("LEFT")
		detail:SetText(text)

		if editable then
			---@type LibAboutPanel-2.0.CopyButton
			local button = CreateFrame("Button", nil, frame)
			button:SetAllPoints(detail)
			button.value = text
			button:SetScript("OnClick", OpenEditbox)
			button:SetScript("OnEnter", ShowTooltip)
			button:SetScript("OnLeave", HideTooltip)
		end
	end

	-- Add fields conditionally if metadata exists.
	SetAboutInfo(GAME_VERSION_LABEL,	GetVersion(addon))
	SetAboutInfo(L["Author"],			GetAuthor(addon))
	SetAboutInfo(L["Email"],			GetEmail(addon), true)
	SetAboutInfo(L["Date"],				GetAddOnDate(addon))
	SetAboutInfo(CATEGORY,				GetCategory(addon))
	SetAboutInfo(L["License"],			GetLicense(addon))
	SetAboutInfo(L["Credits"],			GetCredits(addon))
	SetAboutInfo(L["Website"],			GetWebsite(addon), true)
	SetAboutInfo(L["Localizations"],	GetLocalizations(addon))

	-- Register with Blizzard's modern Settings system.
	frame.name = not parent and addon or L["About"]
	frame.parent = parent
	Settings.RegisterCanvasLayoutCategory(frame)

	lib.aboutFrame[addon] = frame
	return frame
end

-- -----------------------------------------------------
-- Creates an AceConfig-3.0-compatible options table for About info.
-- -----------------------------------------------------

---Creates and caches an AceConfig-3.0-compatible options table for an addon.
---
---This function only constructs the options table. The caller is responsible for
---registering it with AceConfig-3.0 and displaying it with AceConfigDialog-3.0.
---@param addon string Addon folder/.toc name.
---@return LibAboutPanel-2.0.AceOptionsTable optionsTable The created or cached options table.
function lib:AboutOptionsTable(addon)
	if addon == self then
		error("LibAboutPanel-2.0: 'addon' must be the addon's folder/.toc name, not self.", 2)
	end

	addon = addon:gsub(" ", "") -- some APIs don't like spaces in addon name

	local Table = lib.aboutTable[addon]
	if Table then return Table end

	---@type LibAboutPanel-2.0.AceOptionsTable
	Table = {
		name = L["About"],
		type = "group",
		args = {
			title = {
				order = 1,
				name = "|cffe6cc80" .. (GetTitle(addon) or addon) .. "|r",
				type = "description",
				fontSize = "large",
			}
		}
	}

	-- Helper to add fields.
	---@param order integer
	---@param label string
	---@param text string?
	---@param asInput boolean?
	local function addField(order, label, text, asInput)
		if not text then return end
		if asInput then
			Table.args[label] = {
				order = order,
				name = "|cffe6cc80" .. L[label] .. ": |r",
				desc = L["Click and press Ctrl-C to copy"],
				type = "input", -- AceConfig input box
				width = "full",
				get = function() return text end,
			}
		else
			Table.args[label] = {
				order = order,
				name = "|cffe6cc80" .. L[label] .. ": |r" .. text,
				type = "description",
			}
		end
	end

	-- Add optional fields.
	local notes = GetNotes(addon)
	if notes then
		Table.args.blank = { order = 2, name = "", type = "description" }
		Table.args.notes = { order = 3, name = notes, type = "description", fontSize = "medium" }
	end

	addField(5,		GAME_VERSION_LABEL,	GetVersion(addon))
	addField(6,		"Author",			GetAuthor(addon))
	addField(7,		"Email",			GetEmail(addon), true)
	addField(8,		"Date",				GetAddOnDate(addon))
	addField(9,		CATEGORY,			GetCategory(addon))
	addField(10,	"License",			GetLicense(addon))
	addField(11,	"Credits",			GetCredits(addon))
	addField(12,	"Website",			GetWebsite(addon), true)
	addField(13,	"Localizations",	GetLocalizations(addon))

	lib.aboutTable[addon] = Table
	return Table
end

-- -----------------------------------------------------
-- Embeds LibAboutPanel-2.0 API into target addon object for easy usage.
-- -----------------------------------------------------

---@alias LibAboutPanelMixin
---| "CreateAboutPanel"
---| "AboutOptionsTable"

---@type LibAboutPanelMixin[]
local mixins = { "CreateAboutPanel", "AboutOptionsTable" }

---Embeds LibAboutPanel-2.0's public API methods into a target addon object.
---@generic T: table
---@param target T Target addon object.
---@return T target The same target table, with LibAboutPanel-2.0 methods attached.
function lib:Embed(target)
	for _, name in pairs(mixins) do
		target[name] = self[name]
	end
	self.embeds[target] = true
	return target
end

-- Upgrades previously embedded addons if a new version of the library is loaded.
for target, _ in pairs(lib.embeds) do
	lib:Embed(target)
end