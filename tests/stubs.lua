-- GroupWatch P0 tests — WoW API stubs.
--
-- Loaded with dofile() BEFORE any addon file, because Core.lua captures
-- these globals into ns.Globals at load time. Run with:
--   lua tests/run.lua        (from the addon directory)
-- Works on Lua 5.1 through 5.5 (uses only shared syntax).

local _unpack = table.unpack or unpack

Stubs = {
	realm = "My Realm",
	units = {}, -- unit -> { name=..., realm=... } or { err=... }
	isPlayer = {}, -- unit -> truthy
	exists = {}, -- unit -> truthy (default: unit known in units table)
	class = {}, -- unit -> class token
	inGroup = false,
	inRaid = false,
	numMembers = 0,
	bnetInfo = {}, -- bnetID -> info table or { err=... }
	guidInfo = {}, -- guid -> { name=..., realm=... }
	lfg = {}, -- searchResultID -> result table or { err=... }
	playedSounds = {},
	printLog = {},
	locale = "enUS",
}

function Stubs.reset()
	Stubs.realm = "My Realm"
	Stubs.units = {}
	Stubs.isPlayer = {}
	Stubs.exists = {}
	Stubs.class = {}
	Stubs.inGroup = false
	Stubs.inRaid = false
	Stubs.numMembers = 0
	Stubs.bnetInfo = {}
	Stubs.guidInfo = {}
	Stubs.lfg = {}
	Stubs.playedSounds = {}
	Stubs.printLog = {}
	Stubs.locale = "enUS"
	GroupWatchDB = nil
end

-- ---------------------------------------------------------------------------
-- Lua string helpers missing outside WoW
-- ---------------------------------------------------------------------------

function strsplit(delim, str, pieces)
	if type(str) ~= "string" or type(delim) ~= "string" or delim == "" then
		return nil
	end
	local out = {}
	local start = 1
	while true do
		if pieces and (#out + 1) >= pieces then
			out[#out + 1] = str:sub(start)
			break
		end
		local s, e = str:find(delim, start, true)
		if not s then
			out[#out + 1] = str:sub(start)
			break
		end
		out[#out + 1] = str:sub(start, s - 1)
		start = e + 1
	end
	return _unpack(out)
end

function strtrim(s)
	if type(s) ~= "string" then
		return s
	end
	return (s:match("^%s*(.-)%s*$"))
end

function wipe(t)
	if type(t) == "table" then
		for k in pairs(t) do
			t[k] = nil
		end
	end
	return t
end

-- ---------------------------------------------------------------------------
-- WoW client API
-- ---------------------------------------------------------------------------

function GetLocale()
	return Stubs.locale
end

function GetRealmName()
	return Stubs.realm
end

function UnitName(unit)
	local u = Stubs.units[unit]
	if u == nil then
		return nil, nil
	end
	if type(u) == "table" and u.err then
		error(u.err)
	end
	if type(u) == "table" then
		return u.name, u.realm
	end
	return u, nil
end

function UnitIsPlayer(unit)
	return Stubs.isPlayer[unit]
end

function UnitExists(unit)
	if Stubs.exists[unit] ~= nil then
		return Stubs.exists[unit]
	end
	return Stubs.units[unit] ~= nil
end

function UnitIsUnit(a, b)
	return a == b
end

function UnitClass(unit)
	return nil, Stubs.class[unit]
end

function IsInGroup()
	return Stubs.inGroup
end

function IsInRaid()
	return Stubs.inRaid
end

function GetNumGroupMembers()
	return Stubs.numMembers
end

function GetPlayerInfoByGUID(guid)
	local g = Stubs.guidInfo[guid]
	if g == nil then
		return nil
	end
	if g.err then
		error(g.err)
	end
	return "c", "c", "c", "c", "c", g.name, g.realm
end

C_BattleNet = {
	GetAccountInfoByID = function(id)
		local info = Stubs.bnetInfo[id]
		if type(info) == "table" and info.err then
			error(info.err)
		end
		return info
	end,
}

C_LFGList = {
	GetSearchResultInfo = function(id)
		local r = Stubs.lfg[id]
		if type(r) == "table" and r.err then
			error(r.err)
		end
		return r
	end,
}

-- Capture addon output instead of printing it.
function print(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[#parts + 1] = tostring(select(i, ...))
	end
	Stubs.printLog[#Stubs.printLog + 1] = table.concat(parts, " ")
end

return Stubs
