--[[
	GroupWatch — Core
	=================
	Namespace bootstrap, shared constants, utilities and the localized globals
	every other module builds on. This file must be loaded first (right after
	Locales.lua) because all other modules read from `ns`.
]]

local ADDON_NAME, ns = ...

-- ---------------------------------------------------------------------------
-- Locale table (populated by Locales.lua, which is loaded before this file)
-- ---------------------------------------------------------------------------
local L = ns.L or setmetatable({}, {
	__index = function(t, k)
		return k
	end,
})
ns.L = L

-- ---------------------------------------------------------------------------
-- Global function localization (Lua performance)
-- ---------------------------------------------------------------------------
-- Kept in a single table so every module shares one source of truth. Modules
-- pull the entries they need into file-locals, e.g.:
--     local pairs, print = ns.Globals.pairs, ns.Globals.print
ns.Globals = {
	pairs = pairs,
	ipairs = ipairs,
	next = next,
	type = type,
	tostring = tostring,
	select = select,
	pcall = pcall,
	print = print,
	strsplit = strsplit,
	strtrim = strtrim,
	tinsert = tinsert,
	PlaySound = PlaySound,
	PlaySoundFile = PlaySoundFile,
	GetRealmName = GetRealmName,
	GetNormalizedRealmName = GetNormalizedRealmName,
	Ambiguate = Ambiguate,
	GetNumGroupMembers = GetNumGroupMembers,
	IsInGroup = IsInGroup,
	IsInRaid = IsInRaid,
	UnitName = UnitName,
	UnitExists = UnitExists,
	UnitIsPlayer = UnitIsPlayer,
	UnitIsUnit = UnitIsUnit,
	CreateFrame = CreateFrame,
	UIParent = UIParent,
	Minimap = Minimap,
	GameTooltip = GameTooltip,
	GetCursorPosition = GetCursorPosition,
	IsMouseButtonDown = IsMouseButtonDown,
	IsKeyDown = IsKeyDown,
	UnitClass = UnitClass,
	C_Timer = C_Timer,
	Menu = Menu,
	MenuUtil = MenuUtil,
	TooltipDataProcessor = TooltipDataProcessor,
	TooltipUtil = TooltipUtil,
	Enum = Enum,
	C_BattleNet = C_BattleNet,
	C_LFGList = C_LFGList,
	IsLoggedIn = IsLoggedIn,
	hooksecurefunc = hooksecurefunc,
	StaticPopup_Show = StaticPopup_Show,
	StaticPopup_Hide = StaticPopup_Hide,
	AcceptGroup = AcceptGroup,
	DeclineGroup = DeclineGroup,
	GetPlayerInfoByGUID = GetPlayerInfoByGUID,
	GetTime = GetTime,
	UnitGroupRolesAssigned = UnitGroupRolesAssigned,
	C_ChatInfo = C_ChatInfo,
	C_RestrictedActions = C_RestrictedActions,
	LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME,
	string_format = string.format,
	string_len = string.len,
	string_gsub = string.gsub,
	string_lower = string.lower,
	string_find = string.find,
	table_insert = table.insert,
	table_sort = table.sort,
	wipe = wipe,
	math_max = math.max,
	math_min = math.min,
	math_abs = math.abs,
	math_rad = math.rad,
	math_deg = math.deg,
	math_cos = math.cos,
	math_sin = math.sin,
	math_atan2 = math.atan2,
}

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
ns.DEFAULT_SOUND = 8959

-- Built-in sound options. A positive id is a Blizzard SoundKit id.
--
-- The user's own sound files (the Sounds/ folder of the addon directory) are
-- not listed here: they are found at runtime and added to the menu by
-- Sound.lua, keyed by their file name.
ns.SOUND_OPTIONS = {
	{ name = L["SOUND_WARNING"], id = 8959 },
	{ name = L["SOUND_RAID_WARNING"], id = 12867 },
	{ name = L["SOUND_BELL"], id = 8960 },
	{ name = L["SOUND_WHISTLE"], id = 8958 },
	{ name = L["SOUND_READY_CHECK"], id = 8960 },
	{ name = L["SOUND_COIN"], id = 865 },
	{ name = L["SOUND_ACHIEVEMENT"], id = 12891 },
	{ name = L["SOUND_EXPLOSION"], id = 8957 },
	{ name = L["SOUND_NONE"], id = 0 },
}

-- ---------------------------------------------------------------------------
-- Shared UI state
-- ---------------------------------------------------------------------------
ns.selectedPlayer = nil
ns.selectedList = nil

-- ---------------------------------------------------------------------------
-- Utilities
-- ---------------------------------------------------------------------------
local pairs, ipairs = ns.Globals.pairs, ns.Globals.ipairs
local type = ns.Globals.type
local string_format = ns.Globals.string_format
local strsplit, strtrim = ns.Globals.strsplit, ns.Globals.strtrim
local tostring = ns.Globals.tostring

function ns.GetDefaultListName()
	if type(GroupWatchDB) == "table" and type(GroupWatchDB.lists) == "table" then
		if GroupWatchDB.lists[L["DEFAULT_LIST_NAME"]] then
			return L["DEFAULT_LIST_NAME"]
		end
		if GroupWatchDB.lists["Standard"] then
			return "Standard"
		end
		if GroupWatchDB.lists["Default"] then
			return "Default"
		end
		for name in pairs(GroupWatchDB.lists) do
			return name
		end
	end
	return L["DEFAULT_LIST_NAME"]
end

function ns.IsDefaultList(listName)
	return listName == "Standard" or listName == "Default" or listName == L["DEFAULT_LIST_NAME"]
end

function ns.GetFullName(unitOrName)
	if type(unitOrName) ~= "string" or unitOrName == "" then
		return nil
	end
	unitOrName = unitOrName:gsub("%*", "")
	local name, realm = strsplit("-", unitOrName, 2)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	name = strtrim(name)
	if name == "" then
		return nil
	end
	realm = ns.NormalizeRealm(realm)
	return name .. "-" .. realm
end

--- The player's own realm, normalized (no spaces) for use in "Name-Realm"
--- keys. Prefers GetNormalizedRealmName where the client offers it and
--- falls back to GetRealmName. Never throws: without either API (or when
--- both fail) it returns "".
function ns.GetHomeRealm()
	local g = ns.Globals
	if g.GetNormalizedRealmName then
		local ok, res = pcall(g.GetNormalizedRealmName)
		if ok and type(res) == "string" and strtrim(res) ~= "" then
			return strtrim(res):gsub("%s+", "")
		end
	end
	if g.GetRealmName then
		local ok, res = pcall(g.GetRealmName)
		if ok and type(res) == "string" then
			return res:gsub("%s+", "")
		end
	end
	return ""
end

--- Normalize a realm fragment for "Name-Realm" keys: a usable realm is
--- trimmed of surrounding and embedded spaces, anything else falls back to
--- the home realm. Never throws.
function ns.NormalizeRealm(realm)
	if type(realm) == "string" and strtrim(realm) ~= "" then
		return strtrim(realm):gsub("%s+", "")
	end
	return ns.GetHomeRealm()
end

--- Short display form of a "Name-Realm" key via Ambiguate where the client
--- offers it, otherwise the full key unchanged. Never throws. Callers that
--- need a stable identity must keep using the full key; this is display
--- only, never a persistent id.
function ns.GetDisplayName(fullName)
	if type(fullName) ~= "string" or fullName == "" then
		return fullName
	end
	local Ambiguate = ns.Globals.Ambiguate
	if Ambiguate then
		local ok, res = pcall(Ambiguate, fullName, "short")
		if ok and type(res) == "string" and res ~= "" then
			return res
		end
	end
	return fullName
end

--- Resolve a global by name at call time. Used for the secret-value guards,
--- which are absent on older clients and must stay testable/injectable.
local function ResolveGlobal(name)
	local g = ns.Globals
	local value = g[name]
	if value == nil and type(_G) == "table" then
		value = rawget(_G, name)
	end
	return value
end

--- True when a value may be read safely outside the client's secret-value
--- sandbox. `issecretvalue`/`canaccessvalue` are 12.0+ APIs: on older clients
--- (or in tests) the helpers are absent and every plain Lua value passes.
--- Never throws.
function ns.IsPlainValue(value)
	local issecretvalue = ResolveGlobal("issecretvalue")
	if type(issecretvalue) == "function" then
		local ok, isSecret = pcall(issecretvalue, value)
		if ok and isSecret == true then
			return false
		end
	end

	local canaccessvalue = ResolveGlobal("canaccessvalue")
	if type(canaccessvalue) == "function" then
		local ok, canAccess = pcall(canaccessvalue, value)
		if ok and canAccess == false then
			return false
		end
	end

	return true
end

--- True when a table may be indexed safely. `canaccesstable` is 12.0+; when
--- absent the table is assumed accessible and the caller's own type checks
--- decide. Never throws.
function ns.CanAccessTable(tbl)
	if type(tbl) ~= "table" then
		return false
	end
	local canaccesstable = ResolveGlobal("canaccesstable")
	if type(canaccesstable) == "function" then
		local ok, canAccess = pcall(canaccesstable, tbl)
		if ok and canAccess == false then
			return false
		end
	end
	return true
end

--- Append the generic "restricted by the client" line to a tooltip. Used by
--- the LFG tooltip paths when a secret value prevents reading the data.
function ns.AppendRestrictedTooltipLine(tooltip)
	if type(tooltip) ~= "table" or type(tooltip.AddLine) ~= "function" then
		return
	end
	local line = "|cff00ccffGroupWatch:|r " .. (L["MSG_LFG_RESTRICTED"] or "LFG applicant details are restricted.")
	pcall(tooltip.AddLine, tooltip, line, 0.7, 0.7, 0.7, true)
end

-- ---------------------------------------------------------------------------
-- UI refresh callback
-- ---------------------------------------------------------------------------
-- No-op stub. UI_MainWindow.lua overrides this with the real implementation so
-- that the data layer never has to know about the window frame.
function ns.RefreshUI() end
