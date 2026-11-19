--[[
	GroupWatch — Tooltips
	=====================
	Tooltip injection: appends the GroupWatch lists (and their notes) for the
	hovered player to unit tooltips and to Group Finder search results.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local L = ns.L
local C_LFGList = G.C_LFGList
local Enum = G.Enum
local GameTooltip = G.GameTooltip
local GetPlayerInfoByGUID = G.GetPlayerInfoByGUID
local TooltipDataProcessor = G.TooltipDataProcessor
local TooltipUtil = G.TooltipUtil
local UnitExists = G.UnitExists
local hooksecurefunc = G.hooksecurefunc
local ipairs, pairs, pcall, type = G.ipairs, G.pairs, G.pcall, G.type
local strsplit = G.strsplit
local string_format = G.string_format
local table_insert, table_sort = G.table_insert, G.table_sort

-- ---------------------------------------------------------------------------
-- Name resolution
-- ---------------------------------------------------------------------------
local function GetPlayerFullNameFromTooltip(tooltip, data)
	local unit, name

	if TooltipUtil and TooltipUtil.GetDisplayedUnit then
		local ok, resUnit = pcall(TooltipUtil.GetDisplayedUnit, tooltip)
		if ok and resUnit and type(resUnit) == "string" then
			unit = resUnit
		end
	end

	if not unit and tooltip and tooltip.GetUnit then
		local ok, resName, resUnit = pcall(tooltip.GetUnit, tooltip)
		if ok then
			if resUnit and type(resUnit) == "string" then
				unit = resUnit
			end
			if resName and type(resName) == "string" then
				name = resName
			end
		end
	end

	if unit then
		local ok, exists = pcall(UnitExists, unit)
		if ok and exists then
			local fullName = ns.GetPlayerFullNameFromUnit(unit)
			if fullName then
				return fullName
			end
		end
	end

	if type(data) == "table" and data.guid then
		local ok, isPlayerGUID = pcall(function()
			return type(data.guid) == "string" and data.guid:find("^Player%-")
		end)

		if ok and isPlayerGUID and GetPlayerInfoByGUID then
			-- GetPlayerInfoByGUID returns: class, classFilename, race,
			-- raceFilename, sex, name (6th), realm (7th). Positional unpack
			-- must stay in this order; never parse/store GUID substrings
			-- as persistent ids.
			local okInfo, _, _, _, _, _, pName, pRealm = pcall(GetPlayerInfoByGUID, data.guid)
			if okInfo and type(pName) == "string" and pName ~= "" then
				pRealm = ns.NormalizeRealm(pRealm)
				return pName .. "-" .. pRealm
			end
		end
	end

	if name and type(name) == "string" and name ~= "" then
		local ok, hasHash = pcall(function()
			return name:find("#")
		end)
		if ok and not hasHash then
			return ns.GetFullName(name)
		end
	end

	return nil
end

-- ---------------------------------------------------------------------------
-- Note injection
-- ---------------------------------------------------------------------------
function ns.AppendNotesToTooltip(tooltip, fullName)
	if not tooltip or not tooltip.AddLine or type(fullName) ~= "string" then
		return
	end
	if type(GroupWatchDB) ~= "table" or type(GroupWatchDB.lists) ~= "table" then
		return
	end

	local name = strsplit("-", fullName, 2)

	local entries = {}
	for lName, lData in pairs(GroupWatchDB.lists) do
		if type(lData) == "table" and type(lData.players) == "table" then
			local inList = lData.players[fullName] or (name and lData.players[name])
			if inList then
				local note
				if type(lData.notes) == "table" then
					note = lData.notes[fullName] or (name and lData.notes[name])
				end
				table_insert(entries, {
					list = lName,
					note = (type(note) == "string" and note ~= "") and note or nil,
				})
			end
		end
	end

	if #entries == 0 then
		return
	end

	table_sort(entries, function(a, b)
		if ns.IsDefaultList(a.list) and not ns.IsDefaultList(b.list) then
			return true
		end
		if not ns.IsDefaultList(a.list) and ns.IsDefaultList(b.list) then
			return false
		end
		return a.list < b.list
	end)

	local noteHeader = L["NOTE_HEADER"] or "Note"

	tooltip:AddLine(" ")
	for _, entry in ipairs(entries) do
		if entry.note then
			if ns.IsDefaultList(entry.list) then
				tooltip:AddLine(
					string_format("|cff00ccffGroupWatch %s:|r |cffffffff%s|r", noteHeader, entry.note),
					1,
					1,
					1,
					true
				)
			else
				tooltip:AddLine(
					string_format(
						"|cff00ccffGroupWatch|r (|cffffd100%s|r) - |cff00ccff%s:|r |cffffffff%s|r",
						entry.list,
						noteHeader,
						entry.note
					),
					1,
					1,
					1,
					true
				)
			end
		else
			tooltip:AddLine(string_format("|cff00ccffGroupWatch:|r |cffffd100%s|r", entry.list), 1, 1, 1, true)
		end
	end
end

local function OnTooltipSetUnit(tooltip, data)
	local fullName = GetPlayerFullNameFromTooltip(tooltip, data)
	if fullName then
		ns.AppendNotesToTooltip(tooltip, fullName)
	end
end

-- ---------------------------------------------------------------------------
-- Hook registration
-- ---------------------------------------------------------------------------
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
	if Enum.TooltipDataType.Unit then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
	end

	if Enum.TooltipDataType.GroupFinderSearchResult then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.GroupFinderSearchResult, function(tooltip, data)
			if type(data) ~= "table" or not data.id then
				return
			end
			local ok, searchResult = pcall(C_LFGList.GetSearchResultInfo, data.id)
			if ok and type(searchResult) == "table" and type(searchResult.leaderName) == "string" then
				local fullName = ns.GetFullName(searchResult.leaderName)
				if fullName then
					ns.AppendNotesToTooltip(tooltip, fullName)
				end
			end
		end)
	end
elseif GameTooltip and GameTooltip.HookScript then
	GameTooltip:HookScript("OnTooltipSetUnit", function(self)
		OnTooltipSetUnit(self)
	end)
end

if LFGListUtil_SetSearchEntryTooltip then
	hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", function(tooltip, resultID)
		if not resultID then
			return
		end
		local ok, searchResult = pcall(C_LFGList.GetSearchResultInfo, resultID)
		if ok and type(searchResult) == "table" and type(searchResult.leaderName) == "string" then
			local fullName = ns.GetFullName(searchResult.leaderName)
			if fullName then
				ns.AppendNotesToTooltip(tooltip, fullName)
			end
		end
	end)
end
