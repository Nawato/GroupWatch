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
local ipairs, next, pairs = G.ipairs, G.next, G.pairs
local print = G.print
local string_format = G.string_format
local table_insert = G.table_insert

function ns.CheckGroup()
	if not IsInGroup() or not GroupWatchDB or not GroupWatchDB.lists then
		return
	end

	local numMembers = GetNumGroupMembers()
	local prefix = IsInRaid() and "raid" or "party"

	-- Build a reverse index: fullName -> { listName, ... } so we don't scan
	-- every list for every group member (O(members * lists) -> O(members + hits)).
	local watched = {}
	for lName, lData in pairs(GroupWatchDB.lists) do
		if lData.players then
			for pName in pairs(lData.players) do
				if not watched[pName] then
					watched[pName] = {}
				end
				table_insert(watched[pName], lName)
			end
		end
	end

	if next(watched) == nil then
		return
	end

	local L_DEFAULT_GROUP_MSG = L["DEFAULT_GROUP_MSG"]

	for i = 1, numMembers do
		local unit = (prefix == "party" and i == numMembers) and "player" or (prefix .. i)
		local name, realm = UnitName(unit)

		if name and unit ~= "player" then
			if not realm or realm == "" then
				realm = GetRealmName():gsub("%s+", "")
			end
			local fullName = name .. "-" .. realm

			local lists = watched[fullName]
			if lists then
				for _, lName in ipairs(lists) do
					local lData = GroupWatchDB.lists[lName]
					if lData then
						local outMsg = string_format(lData.message or L_DEFAULT_GROUP_MSG, fullName)
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
