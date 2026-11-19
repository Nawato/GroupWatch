--[[
	GroupWatch — ContextMenu
	=======================
	Right-click integration: injects GroupWatch entries into the Blizzard
	unit / friend / guild context menus.

	Also hosts the shared "resolve a unit into Name-Realm" helper that the
	tooltip module reuses.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local L = ns.L
local GetRealmName = G.GetRealmName
local Menu = G.Menu
local UnitIsPlayer, UnitName = G.UnitIsPlayer, G.UnitName
local ipairs, pairs, pcall = G.ipairs, G.pairs, G.pcall
local type = G.type
local strtrim = G.strtrim
local string_format = G.string_format
local table_insert, table_sort = G.table_insert, G.table_sort
local tostring = G.tostring

-- ---------------------------------------------------------------------------
-- Name resolution
-- ---------------------------------------------------------------------------
function ns.GetPlayerFullNameFromUnit(unit)
	if type(unit) ~= "string" then
		return nil
	end
	local ok, isPlayer = pcall(UnitIsPlayer, unit)
	if not ok or not isPlayer then
		return nil
	end

	local okName, name, realm = pcall(UnitName, unit)
	if not okName or type(name) ~= "string" or name == "" then
		return nil
	end
	name = strtrim(name)
	if name == "" then
		return nil
	end
	if type(realm) ~= "string" or realm == "" then
		realm = (GetRealmName and GetRealmName() or ""):gsub("%s+", "")
	else
		realm = strtrim(realm):gsub("%s+", "")
	end
	return name .. "-" .. realm
end

function ns.GetPlayerFullNameFromContext(contextData)
	if type(contextData) ~= "table" then
		return nil
	end

	if contextData.unit then
		local fullName = ns.GetPlayerFullNameFromUnit(contextData.unit)
		if fullName then
			return fullName
		end
	end

	local name = contextData.name
	local server = contextData.server or contextData.realm
	if type(name) == "string" and name ~= "" then
		name = name:gsub("%*", "")
		name = strtrim(name)
		if not name:find("#") then
			if type(server) == "string" and server ~= "" and not name:find("-") then
				server = strtrim(server):gsub("%s+", "")
				return name .. "-" .. server
			else
				return ns.GetFullName(name)
			end
		end
	end

	local bnetID = contextData.bnetAccountID
	local accountInfo = contextData.accountInfo
	if type(accountInfo) ~= "table" and bnetID ~= nil and G.C_BattleNet and G.C_BattleNet.GetAccountInfoByID then
		local ok, res = pcall(G.C_BattleNet.GetAccountInfoByID, bnetID)
		if ok and type(res) == "table" then
			accountInfo = res
		end
	end
	if type(accountInfo) == "table" and type(accountInfo.gameAccountInfo) == "table" then
		local gameInfo = accountInfo.gameAccountInfo
		local charName = gameInfo.characterName
		local realmName = gameInfo.realmName
		if type(charName) == "string" and charName ~= "" then
			charName = strtrim(charName)
			if type(realmName) ~= "string" or realmName == "" then
				realmName = (GetRealmName and GetRealmName() or ""):gsub("%s+", "")
			else
				realmName = strtrim(realmName):gsub("%s+", "")
			end
			return charName .. "-" .. realmName
		end
	end

	local memberInfo = contextData.memberInfo
	if type(memberInfo) == "table" and type(memberInfo.name) == "string" then
		return ns.GetFullName(memberInfo.name)
	end

	return nil
end

-- ---------------------------------------------------------------------------
-- Menu injection
-- ---------------------------------------------------------------------------
if Menu and Menu.ModifyMenu then
	local function GroupWatchMenuHandler(ownerRegion, rootDescription, contextData)
		local fullName = ns.GetPlayerFullNameFromContext(contextData)
		if not fullName then
			return
		end

		ns.InitDB()
		if type(GroupWatchDB) ~= "table" or type(GroupWatchDB.lists) ~= "table" then
			return
		end

		rootDescription:CreateDivider()
		local mainSubMenu = rootDescription:CreateButton("GroupWatch")

		local sortedLists = {}
		for lName in pairs(GroupWatchDB.lists) do
			table_insert(sortedLists, lName)
		end
		table_sort(sortedLists, function(a, b)
			if ns.IsDefaultList(a) and not ns.IsDefaultList(b) then
				return true
			end
			if not ns.IsDefaultList(a) and ns.IsDefaultList(b) then
				return false
			end
			return a < b
		end)

		for _, lName in ipairs(sortedLists) do
			local lData = GroupWatchDB.lists[lName]
			local listSubMenu = mainSubMenu:CreateButton(string_format(L["CONTEXT_LIST"], lName))
			if type(lData) == "table" and type(lData.players) == "table" and lData.players[fullName] then
				listSubMenu:CreateButton(L["CONTEXT_REMOVE"], function()
					ns.RemovePlayer(fullName, lName)
				end)
			else
				listSubMenu:CreateButton(L["CONTEXT_ADD"], function()
					ns.AddPlayer(lName, fullName)
				end)
			end
		end
	end

	local CONTEXT_MENU_TAGS = {
		"MENU_UNIT_PLAYER",
		"MENU_UNIT_PARTY",
		"MENU_UNIT_RAID_PLAYER",
		"MENU_UNIT_RAID",
		"MENU_UNIT_FRIEND",
		"MENU_UNIT_CHAT_ROSTER",
		"MENU_UNIT_COMMUNITY_MEMBER",
		"MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
		"MENU_UNIT_COMMUNITIES_MEMBER",
		"MENU_UNIT_BN_FRIEND",
		"MENU_UNIT_TARGET",
		"MENU_UNIT_FOCUS",
		"MENU_UNIT_SELF",
		"MENU_UNIT_ENEMY_PLAYER",
		"MENU_UNIT_GUILD",
		"MENU_UNIT_GUILD_OFFLINE",
	}

	for _, tag in ipairs(CONTEXT_MENU_TAGS) do
		Menu.ModifyMenu(tag, GroupWatchMenuHandler)
	end
end
