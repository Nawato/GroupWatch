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
	normalizedRealm = nil, -- GetNormalizedRealmName return (or { err=... })
	ambiguateErr = nil, -- error to throw from Ambiguate (nil = no throw)
	inGroup = false,
	inRaid = false,
	numMembers = 0,
	bnetInfo = {}, -- bnetID -> info table or { err=... }
	guidInfo = {}, -- guid -> { name=..., realm=... }
	lfg = {}, -- searchResultID -> result table or { err=... }
	playedSounds = {},
	printLog = {},
	locale = "enUS",
	-- Auto actions / LFG applicant stubs
	secretValues = {}, -- value -> truthy for issecretvalue
	noAccessTables = {}, -- table -> truthy for canaccesstable
	lockdown = false,
	restrictionState = nil,
	time = 0,
	accepted = 0,
	declined = 0,
	popupHidden = {},
	unitRoles = {},
	applicants = {},
	applicantInfo = {}, -- token -> info table or { err=... }
	applicantMembers = {}, -- token -> { [index] = { name=..., tank=..., ... } }
	activeEntry = nil, -- table or { err=... }
	activityInfo = {}, -- activityID -> info table or { err=... }
	numInvited = 0,
	getApplicantsCalls = 0,
	lfgInviteCalls = {},
	lfgDeclineCalls = {},
}

function Stubs.reset()
	Stubs.realm = "My Realm"
	Stubs.normalizedRealm = nil
	Stubs.ambiguateErr = nil
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
	Stubs.secretValues = {}
	Stubs.noAccessTables = {}
	Stubs.lockdown = false
	Stubs.restrictionState = nil
	Stubs.time = 0
	Stubs.accepted = 0
	Stubs.declined = 0
	Stubs.popupHidden = {}
	Stubs.unitRoles = {}
	Stubs.applicants = {}
	Stubs.applicantInfo = {}
	Stubs.applicantMembers = {}
	Stubs.activeEntry = nil
	Stubs.activityInfo = {}
	Stubs.numInvited = 0
	Stubs.getApplicantsCalls = 0
	Stubs.lfgInviteCalls = {}
	Stubs.lfgDeclineCalls = {}
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

function GetNormalizedRealmName()
	local v = Stubs.normalizedRealm
	if type(v) == "table" and v.err then
		error(v.err)
	end
	return v
end

function Ambiguate(fullName, context)
	if Stubs.ambiguateErr then
		error(Stubs.ambiguateErr)
	end
	if type(fullName) ~= "string" then
		return fullName
	end
	if context == "short" then
		return (fullName:gsub("%-.*$", ""))
	end
	return fullName
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
	GetApplicants = function()
		Stubs.getApplicantsCalls = Stubs.getApplicantsCalls + 1
		return Stubs.applicants
	end,
	GetApplicantInfo = function(token)
		local info = Stubs.applicantInfo[token]
		if type(info) == "table" and info.err then
			error(info.err)
		end
		return info
	end,
	GetApplicantMemberInfo = function(token, index)
		local members = Stubs.applicantMembers[token]
		local member = type(members) == "table" and members[index] or nil
		if type(member) == "table" and member.err then
			error(member.err)
		end
		if type(member) ~= "table" then
			return nil
		end
		return member.name, member.class, member.localizedClass, member.level, member.itemLevel, member.honorLevel,
			member.tank, member.healer, member.damage, member.assignedRole, member.relationship
	end,
	GetActiveEntryInfo = function()
		local entry = Stubs.activeEntry
		if type(entry) == "table" and entry.err then
			error(entry.err)
		end
		return entry
	end,
	GetActivityInfoTable = function(activityID)
		local info = Stubs.activityInfo[activityID]
		if type(info) == "table" and info.err then
			error(info.err)
		end
		return info
	end,
	GetNumInvitedApplicantMembers = function()
		return Stubs.numInvited
	end,
	InviteApplicant = function(token)
		Stubs.lfgInviteCalls[#Stubs.lfgInviteCalls + 1] = token
	end,
	DeclineApplicant = function(token)
		Stubs.lfgDeclineCalls[#Stubs.lfgDeclineCalls + 1] = token
	end,
}

function issecretvalue(value)
	return Stubs.secretValues[value] == true
end

function canaccessvalue(value)
	if Stubs.secretValues[value] == true then
		return false
	end
	return true
end

function canaccesstable(tbl)
	return Stubs.noAccessTables[tbl] ~= true
end

C_ChatInfo = {
	InChatMessagingLockdown = function()
		return Stubs.lockdown
	end,
}

C_RestrictedActions = {
	GetAddOnRestrictionState = function()
		return Stubs.restrictionState
	end,
}

LE_PARTY_CATEGORY_HOME = 1

function GetTime()
	return Stubs.time
end

function UnitGroupRolesAssigned(unit)
	local role = Stubs.unitRoles[unit]
	if type(role) == "table" and role.err then
		error(role.err)
	end
	return role
end

function AcceptGroup()
	Stubs.accepted = Stubs.accepted + 1
end

function DeclineGroup()
	Stubs.declined = Stubs.declined + 1
end

function StaticPopup_Hide(which)
	Stubs.popupHidden[#Stubs.popupHidden + 1] = which
end

-- Capture addon output instead of printing it.
function print(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[#parts + 1] = tostring(select(i, ...))
	end
	Stubs.printLog[#Stubs.printLog + 1] = table.concat(parts, " ")
end

return Stubs
