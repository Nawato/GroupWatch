--[[
	GroupWatch — Detection
	======================
	Group roster scanning. Pure logic, no UI: whenever the group roster
	changes we look for watched players and announce them.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local L = ns.L
local GetNumGroupMembers = G.GetNumGroupMembers
local GetRealmName = G.GetRealmName
local IsInGroup, IsInRaid = G.IsInGroup, G.IsInRaid
local UnitName = G.UnitName
local UnitIsUnit = G.UnitIsUnit
local ipairs, next, pairs = G.ipairs, G.next, G.pairs
local pcall = G.pcall
local type = G.type
local print = G.print
local string_format = G.string_format
local strtrim = G.strtrim
local wipe = G.wipe

-- Players already announced during the current group session. A single
-- GROUP_ROSTER_UPDATE is not a single event in practice (zoning, role checks,
-- subgroup swaps and ready checks all fire it), so without this cache every
-- fire replays all alerts. Departed players are forgotten again below, so a
-- rejoin still announces them.
local announcedInSession = {}

-- Format a list message without ever throwing: a user-edited message like
-- "100%" (stray %) makes string.format error, which must not break
-- GROUP_ROSTER_UPDATE. Falls back to the raw message plus the name.
local function SafeFormatMessage(lData, fullName, defaultMsg)
	local msg = defaultMsg
	if type(lData) == "table" and type(lData.message) == "string" and lData.message ~= "" then
		msg = lData.message
	end
	local ok, res = pcall(string_format, msg, fullName)
	if ok and type(res) == "string" then
		return res
	end
	return msg .. " (" .. tostring(fullName) .. ")"
end

function ns.CheckGroup()
	if not IsInGroup() or type(GroupWatchDB) ~= "table" or type(GroupWatchDB.lists) ~= "table" then
		wipe(announcedInSession)
		return
	end

	-- fullName -> { listName, ... }, cached in DB.lua and only rebuilt when
	-- list membership changes.
	local watched = ns.GetWatchedIndex()
	if type(watched) ~= "table" or next(watched) == nil then
		wipe(announcedInSession)
		return
	end

	local numMembers = (GetNumGroupMembers and GetNumGroupMembers()) or 0
	if type(numMembers) ~= "number" then
		return
	end
	local prefix = IsInRaid() and "raid" or "party"

	local L_DEFAULT_GROUP_MSG = L["DEFAULT_GROUP_MSG"]
	local currentMembers = {}

	for i = 1, numMembers do
		local unit = (prefix == "party" and i == numMembers) and "player" or (prefix .. i)
		local okName, name, realm = pcall(UnitName, unit)
		if not okName then
			name, realm = nil, nil
		end

		if type(name) == "string" and name ~= "" then
			local okSelf, isSelf = pcall(UnitIsUnit, unit, "player")
			if not okSelf or not isSelf then
				if type(realm) ~= "string" or realm == "" then
					realm = (GetRealmName and GetRealmName() or ""):gsub("%s+", "")
				else
					realm = strtrim(realm):gsub("%s+", "")
				end
				local fullName = name .. "-" .. realm
				currentMembers[fullName] = true

				local lists = watched[fullName]
				if lists and not announcedInSession[fullName] then
					announcedInSession[fullName] = true
					for _, lName in ipairs(lists) do
						local lData = GroupWatchDB.lists[lName]
						if type(lData) == "table" then
							local outMsg = SafeFormatMessage(lData, fullName, L_DEFAULT_GROUP_MSG)
							print("|cffff0000[GroupWatch - " .. lName .. "]|r " .. outMsg)
							if lData.sound and lData.sound ~= 0 then
								ns.PlayListSound(lData.sound)
							end
						end
					end
				end
			end
		end
	end

	-- Clean up members who left (or are no longer watched) so a future join
	-- triggers a fresh alert.
	for pName in pairs(announcedInSession) do
		if not currentMembers[pName] or not watched[pName] then
			announcedInSession[pName] = nil
		end
	end
end
