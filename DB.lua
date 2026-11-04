--[[
	GroupWatch — DB
	===============
	Data layer: SavedVariables schema, player/list CRUD and note storage.

	Every write goes through `ns.RefreshUI()` (a callback implemented by
	UI_MainWindow.lua) instead of touching the window frame directly, so the
	data layer stays independent of the UI.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local L = ns.L
local pairs, print = G.pairs, G.print
local string_format = G.string_format
local table_insert = G.table_insert

-- ---------------------------------------------------------------------------
-- Schema
-- ---------------------------------------------------------------------------
function ns.InitDB()
	if not GroupWatchDB then
		GroupWatchDB = {}
	end
	if not GroupWatchDB.lists then
		local defName = L["DEFAULT_LIST_NAME"]
		GroupWatchDB.lists = {
			[defName] = {
				message = L["DEFAULT_GROUP_MSG"],
				sound = ns.DEFAULT_SOUND,
				collapsed = false,
				players = {},
			},
		}
	end
	if not GroupWatchDB.minimap then
		GroupWatchDB.minimap = {
			hide = false,
			angle = 225,
		}
	end

	-- The user's own sound files, by name (the file name without its
	-- extension). See Sound.lua.
	if type(GroupWatchDB.userSounds) ~= "table" then
		GroupWatchDB.userSounds = {}
	end

	for _, listData in pairs(GroupWatchDB.lists) do
		listData.notes = listData.notes or {}
	end

	ns.InvalidateWatchedIndex()
end

-- ---------------------------------------------------------------------------
-- Watched-player reverse index
-- ---------------------------------------------------------------------------
local watchedIndex = nil

--- Drop the cached fullName -> { listName, ... } index. Every write that can
--- change list membership has to call this before refreshing the UI.
function ns.InvalidateWatchedIndex()
	watchedIndex = nil
end

--- Reverse index of every watched character: fullName -> { listName, ... }.
--- Built on demand and reused across roster updates until the data changes,
--- so Detection does not rebuild it on every GROUP_ROSTER_UPDATE.
function ns.GetWatchedIndex()
	if watchedIndex then
		return watchedIndex
	end

	local index = {}
	if GroupWatchDB and GroupWatchDB.lists then
		for lName, lData in pairs(GroupWatchDB.lists) do
			if lData.players then
				for pName in pairs(lData.players) do
					local lists = index[pName]
					if not lists then
						lists = {}
						index[pName] = lists
					end
					table_insert(lists, lName)
				end
			end
		end
	end

	watchedIndex = index
	return index
end

-- ---------------------------------------------------------------------------
-- Player CRUD
-- ---------------------------------------------------------------------------
function ns.AddPlayer(listName, fullName)
	if not fullName or fullName == "" then
		return
	end
	fullName = ns.GetFullName(fullName)
	if not fullName then
		return
	end

	ns.InitDB()
	listName = listName or ns.GetDefaultListName()
	if not GroupWatchDB.lists[listName] then
		print("|cffffaa00[GroupWatch]|r " .. string_format(L["MSG_LIST_NOT_FOUND"], listName))
		return
	end

	GroupWatchDB.lists[listName].players[fullName] = true
	GroupWatchDB.lists[listName].notes = GroupWatchDB.lists[listName].notes or {}
	print("|cff00ff00[GroupWatch]|r " .. string_format(L["MSG_PLAYER_ADDED"], fullName, listName))
	ns.InvalidateWatchedIndex()
	ns.RefreshUI()
end

function ns.RemovePlayer(fullName, listName)
	if not fullName or fullName == "" then
		return
	end
	fullName = ns.GetFullName(fullName)
	if not fullName then
		return
	end

	ns.InitDB()
	for lName, lData in pairs(GroupWatchDB.lists) do
		if not listName or listName == lName then
			if lData.players[fullName] then
				lData.players[fullName] = nil
				if lData.notes then
					lData.notes[fullName] = nil
				end
				print("|cffff0000[GroupWatch]|r " .. string_format(L["MSG_PLAYER_REMOVED"], fullName, lName))
			end
		end
	end
	ns.InvalidateWatchedIndex()
	if ns.selectedPlayer == fullName then
		ns.selectedPlayer = nil
	end
	ns.RefreshUI()
end

function ns.MovePlayer(pName, sourceList, targetList)
	ns.InitDB()
	if not GroupWatchDB.lists[sourceList] or not GroupWatchDB.lists[targetList] then
		return
	end

	GroupWatchDB.lists[sourceList].players = GroupWatchDB.lists[sourceList].players or {}
	GroupWatchDB.lists[targetList].players = GroupWatchDB.lists[targetList].players or {}
	local note = GroupWatchDB.lists[sourceList].notes and GroupWatchDB.lists[sourceList].notes[pName]

	-- Remove from source
	GroupWatchDB.lists[sourceList].players[pName] = nil
	if GroupWatchDB.lists[sourceList].notes then
		GroupWatchDB.lists[sourceList].notes[pName] = nil
	end

	-- Add to target
	GroupWatchDB.lists[targetList].players[pName] = true
	if note then
		GroupWatchDB.lists[targetList].notes = GroupWatchDB.lists[targetList].notes or {}
		GroupWatchDB.lists[targetList].notes[pName] = note
	end

	ns.InvalidateWatchedIndex()
	ns.RefreshUI()
end

function ns.CopyPlayer(pName, sourceList, targetList)
	ns.InitDB()
	if not GroupWatchDB.lists[sourceList] or not GroupWatchDB.lists[targetList] then
		return
	end

	local note = GroupWatchDB.lists[sourceList].notes and GroupWatchDB.lists[sourceList].notes[pName]

	-- Add to target
	GroupWatchDB.lists[targetList].players[pName] = true
	if note then
		GroupWatchDB.lists[targetList].notes = GroupWatchDB.lists[targetList].notes or {}
		GroupWatchDB.lists[targetList].notes[pName] = note
	end

	ns.InvalidateWatchedIndex()
	ns.RefreshUI()
end

-- ---------------------------------------------------------------------------
-- List CRUD
-- ---------------------------------------------------------------------------
function ns.CreateList(listName)
	if not listName or listName == "" then
		return
	end
	ns.InitDB()
	if GroupWatchDB.lists[listName] then
		print("|cffffaa00[GroupWatch]|r " .. string_format(L["MSG_LIST_EXISTS"], listName))
		return
	end

	GroupWatchDB.lists[listName] = {
		message = L["DEFAULT_GROUP_MSG"],
		sound = ns.DEFAULT_SOUND,
		collapsed = false,
		players = {},
		notes = {},
	}
	ns.selectedList = listName
	print("|cff00ff00[GroupWatch]|r " .. string_format(L["MSG_LIST_CREATED"], listName))
	ns.InvalidateWatchedIndex()
	ns.RefreshUI()
end

function ns.RenameList(oldName, newName)
	if not oldName or not newName or oldName == "" or newName == "" then
		return
	end
	if oldName == newName then
		return
	end

	ns.InitDB()
	if not GroupWatchDB.lists[oldName] then
		print("|cffffaa00[GroupWatch]|r " .. string_format(L["MSG_LIST_NOT_FOUND"], oldName))
		return
	end

	if GroupWatchDB.lists[newName] then
		print("|cffffaa00[GroupWatch]|r " .. string_format(L["MSG_LIST_EXISTS"], newName))
		return
	end

	-- Migrate list structure, preserving players and note history
	GroupWatchDB.lists[newName] = GroupWatchDB.lists[oldName]
	GroupWatchDB.lists[oldName] = nil

	if ns.selectedList == oldName then
		ns.selectedList = newName
	end

	ns.InvalidateWatchedIndex()
	ns.RefreshUI()
end

function ns.DeleteList(listName)
	if not listName or listName == "" then
		return
	end
	if ns.IsDefaultList(listName) then
		print("|cffff0000[GroupWatch]|r " .. L["MSG_CANNOT_DELETE_DEFAULT"])
		return
	end

	ns.InitDB()
	if GroupWatchDB.lists[listName] then
		GroupWatchDB.lists[listName] = nil
		print("|cffff0000[GroupWatch]|r " .. string_format(L["MSG_LIST_DELETED"], listName))
		ns.selectedList = ns.GetDefaultListName()
		ns.InvalidateWatchedIndex()
		ns.RefreshUI()
	end
end

-- ---------------------------------------------------------------------------
-- Notes
-- ---------------------------------------------------------------------------
function ns.SavePlayerNote(listName, playerName, note)
	ns.InitDB()
	local listData = GroupWatchDB.lists[listName]
	if not listData or not listData.players or not listData.players[playerName] then
		return
	end

	listData.notes = listData.notes or {}
	note = (note or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if note == "" then
		listData.notes[playerName] = nil
	else
		listData.notes[playerName] = note
	end

	ns.RefreshUI()
end
