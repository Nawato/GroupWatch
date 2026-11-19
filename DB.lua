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
local type = G.type
local string_format = G.string_format
local table_insert = G.table_insert

-- ---------------------------------------------------------------------------
-- Schema
-- ---------------------------------------------------------------------------
function ns.InitDB()
	if type(GroupWatchDB) ~= "table" then
		GroupWatchDB = {}
	end
	if type(GroupWatchDB.lists) ~= "table" then
		local defName = L["DEFAULT_LIST_NAME"]
		GroupWatchDB.lists = {
			[defName] = {
				message = L["DEFAULT_GROUP_MSG"],
				sound = ns.DEFAULT_SOUND,
				collapsed = false,
				players = {},
				notes = {},
			},
		}
	end
	if type(GroupWatchDB.minimap) ~= "table" then
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

	for lName, listData in pairs(GroupWatchDB.lists) do
		if type(listData) ~= "table" then
			GroupWatchDB.lists[lName] = {
				message = L["DEFAULT_GROUP_MSG"],
				sound = ns.DEFAULT_SOUND,
				collapsed = false,
				players = {},
				notes = {},
			}
		else
			if type(listData.players) ~= "table" then
				listData.players = {}
			end
			if type(listData.notes) ~= "table" then
				listData.notes = {}
			end
		end
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
	if type(GroupWatchDB) == "table" and type(GroupWatchDB.lists) == "table" then
		for lName, lData in pairs(GroupWatchDB.lists) do
			if type(lData) == "table" and type(lData.players) == "table" then
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
	local listData = GroupWatchDB.lists[listName]
	if type(listData) ~= "table" then
		print("|cffffaa00[GroupWatch]|r " .. string_format(L["MSG_LIST_NOT_FOUND"], listName))
		return
	end
	if type(listData.players) ~= "table" then
		listData.players = {}
	end

	listData.players[fullName] = true
	if type(listData.notes) ~= "table" then
		listData.notes = {}
	end
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
	if type(GroupWatchDB.lists) ~= "table" then
		return
	end
	for lName, lData in pairs(GroupWatchDB.lists) do
		if type(lData) == "table" and (not listName or listName == lName) then
			if type(lData.players) == "table" and lData.players[fullName] then
				lData.players[fullName] = nil
				if type(lData.notes) == "table" then
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
	if type(GroupWatchDB.lists) ~= "table" then
		return
	end
	local source = GroupWatchDB.lists[sourceList]
	local target = GroupWatchDB.lists[targetList]
	if type(source) ~= "table" or type(target) ~= "table" then
		return
	end

	if type(source.players) ~= "table" then
		source.players = {}
	end
	if type(target.players) ~= "table" then
		target.players = {}
	end
	local note
	if type(source.notes) == "table" then
		note = source.notes[pName]
	end

	-- Remove from source
	source.players[pName] = nil
	if type(source.notes) == "table" then
		source.notes[pName] = nil
	end

	-- Add to target
	target.players[pName] = true
	if note then
		if type(target.notes) ~= "table" then
			target.notes = {}
		end
		target.notes[pName] = note
	end

	ns.InvalidateWatchedIndex()
	ns.RefreshUI()
end

function ns.CopyPlayer(pName, sourceList, targetList)
	ns.InitDB()
	if type(GroupWatchDB.lists) ~= "table" then
		return
	end
	local source = GroupWatchDB.lists[sourceList]
	local target = GroupWatchDB.lists[targetList]
	if type(source) ~= "table" or type(target) ~= "table" then
		return
	end

	local note
	if type(source.notes) == "table" then
		note = source.notes[pName]
	end

	-- Add to target
	if type(target.players) ~= "table" then
		target.players = {}
	end
	target.players[pName] = true
	if note then
		if type(target.notes) ~= "table" then
			target.notes = {}
		end
		target.notes[pName] = note
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
	if type(GroupWatchDB.lists) ~= "table" then
		return
	end
	local listData = GroupWatchDB.lists[listName]
	if type(listData) ~= "table" or type(listData.players) ~= "table" then
		return
	end
	if type(playerName) ~= "string" or not listData.players[playerName] then
		return
	end

	if type(listData.notes) ~= "table" then
		listData.notes = {}
	end
	if type(note) ~= "string" then
		note = ""
	end
	note = note:gsub("^%s+", ""):gsub("%s+$", "")
	if note == "" then
		listData.notes[playerName] = nil
	else
		listData.notes[playerName] = note
	end

	ns.RefreshUI()
end
