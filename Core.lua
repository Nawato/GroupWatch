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
	GetRealmName = GetRealmName,
	GetNumGroupMembers = GetNumGroupMembers,
	IsInGroup = IsInGroup,
	IsInRaid = IsInRaid,
	UnitName = UnitName,
	UnitExists = UnitExists,
	UnitIsPlayer = UnitIsPlayer,
	CreateFrame = CreateFrame,
	UIParent = UIParent,
	Minimap = Minimap,
	GameTooltip = GameTooltip,
	GetCursorPosition = GetCursorPosition,
	IsMouseButtonDown = IsMouseButtonDown,
	IsKeyDown = IsKeyDown,
	UnitClass = UnitClass,
	GetNumRaidMembers = GetNumRaidMembers,
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
	GetPlayerInfoByGUID = GetPlayerInfoByGUID,
	string_format = string.format,
	string_len = string.len,
	string_gsub = string.gsub,
	string_lower = string.lower,
	table_insert = table.insert,
	table_sort = table.sort,
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

-- Available sound options
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
local string_format = ns.Globals.string_format
local strsplit, strtrim = ns.Globals.strsplit, ns.Globals.strtrim
local tostring = ns.Globals.tostring

function ns.GetSoundNameByID(soundID)
	for _, s in ipairs(ns.SOUND_OPTIONS) do
		if s.id == soundID then
			return s.name
		end
	end
	return string_format(L["SOUND_CUSTOM"], soundID or 0)
end

function ns.GetDefaultListName()
	if GroupWatchDB and GroupWatchDB.lists then
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
	if not unitOrName or unitOrName == "" then
		return nil
	end
	unitOrName = tostring(unitOrName):gsub("%*", "")
	local name, realm = strsplit("-", unitOrName, 2)
	if not name or name == "" then
		return nil
	end
	name = strtrim(name)
	if name == "" then
		return nil
	end
	if not realm or realm == "" then
		realm = ns.Globals.GetRealmName():gsub("%s+", "")
	else
		realm = strtrim(realm):gsub("%s+", "")
	end
	return name .. "-" .. realm
end

-- ---------------------------------------------------------------------------
-- UI refresh callback
-- ---------------------------------------------------------------------------
-- No-op stub. UI_MainWindow.lua overrides this with the real implementation so
-- that the data layer never has to know about the window frame.
function ns.RefreshUI() end
